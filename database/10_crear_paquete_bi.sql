-- ============================================
-- PharmaSmart - Script 10
-- Package PKG_PHARMASMART_BI
-- Business Intelligence y reportes
-- Ejecutar como PHARMA_USER
-- Autor: Luis Alberto Ariza Villamizar
-- Universidad Popular del Cesar
-- ============================================

SET SERVEROUTPUT ON;
SET ECHO ON;

CREATE OR REPLACE PACKAGE PKG_PHARMASMART_BI AS
    
    PROCEDURE OBTENER_TOP_PRODUCTOS(p_top NUMBER DEFAULT 10, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_BOTTOM_PRODUCTOS(p_bottom NUMBER DEFAULT 10, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE RESUMEN_VENTAS(p_desde DATE, p_hasta DATE, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE PRODUCTOS_POR_VENCER(p_dias NUMBER DEFAULT 30, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE RESUMEN_INVENTARIO(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE PRODUCTOS_BAJO_STOCK(p_cursor OUT SYS_REFCURSOR);
    
END PKG_PHARMASMART_BI;
/

CREATE OR REPLACE PACKAGE BODY PKG_PHARMASMART_BI AS

    -- ========================================
    -- OBTENER_TOP_PRODUCTOS
    -- ========================================
    PROCEDURE OBTENER_TOP_PRODUCTOS(p_top NUMBER DEFAULT 10, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT 
                p.CODIGO, p.NOMBRE, 
                SUM(dv.CANTIDAD) AS UNIDADES_VENDIDAS, 
                SUM(dv.CANTIDAD * dv.PRECIO_APLICADO) AS TOTAL_VENDIDO
            FROM DETALLES_VENTAS dv 
            JOIN LOTES l ON dv.ID_LOTE = l.ID_LOTE 
            JOIN PRODUCTOS p ON l.ID_PRODUCTO = p.ID_PRODUCTO 
            JOIN VENTAS v ON dv.ID_VENTA = v.ID_VENTA
            WHERE v.ESTADO = 'A' 
            GROUP BY p.CODIGO, p.NOMBRE 
            ORDER BY SUM(dv.CANTIDAD) DESC 
            FETCH FIRST p_top ROWS ONLY; 
    END;

    -- ========================================
    -- OBTENER_BOTTOM_PRODUCTOS
    -- ========================================
    PROCEDURE OBTENER_BOTTOM_PRODUCTOS(p_bottom NUMBER DEFAULT 10, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT 
                p.CODIGO, p.NOMBRE, 
                SUM(dv.CANTIDAD) AS UNIDADES_VENDIDAS, 
                SUM(dv.CANTIDAD * dv.PRECIO_APLICADO) AS TOTAL_VENDIDO
            FROM DETALLES_VENTAS dv 
            JOIN LOTES l ON dv.ID_LOTE = l.ID_LOTE 
            JOIN PRODUCTOS p ON l.ID_PRODUCTO = p.ID_PRODUCTO 
            JOIN VENTAS v ON dv.ID_VENTA = v.ID_VENTA
            WHERE v.ESTADO = 'A' 
            GROUP BY p.CODIGO, p.NOMBRE 
            ORDER BY SUM(dv.CANTIDAD) ASC 
            FETCH FIRST p_bottom ROWS ONLY; 
    END;

    -- ========================================
    -- RESUMEN_VENTAS
    -- ========================================
    PROCEDURE RESUMEN_VENTAS(p_desde DATE, p_hasta DATE, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT 
                TO_CHAR(FECHA_VENTA, 'DD/MM/YYYY') AS FECHA, 
                COUNT(*) AS TOTAL_VENTAS, 
                SUM(TOTAL) AS TOTAL_FACTURADO, 
                SUM(DESCUENTO_TOTAL) AS TOTAL_DESCUENTOS
            FROM VENTAS 
            WHERE FECHA_VENTA BETWEEN p_desde AND p_hasta 
              AND ESTADO = 'A' 
            GROUP BY TO_CHAR(FECHA_VENTA, 'DD/MM/YYYY'), TRUNC(FECHA_VENTA) 
            ORDER BY TRUNC(FECHA_VENTA) DESC; 
    END;

    -- ========================================
    -- PRODUCTOS_POR_VENCER
    -- ========================================
    PROCEDURE PRODUCTOS_POR_VENCER(p_dias NUMBER DEFAULT 30, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT 
                l.CODIGO_LOTE, 
                p.NOMBRE AS PRODUCTO, 
                l.FECHA_VENCIMIENTO, 
                l.CANTIDAD_ACTUAL, 
                TRUNC(l.FECHA_VENCIMIENTO - SYSDATE) AS DIAS_RESTANTES
            FROM LOTES l 
            JOIN PRODUCTOS p ON l.ID_PRODUCTO = p.ID_PRODUCTO
            WHERE l.ESTADO = 'A' 
              AND l.CANTIDAD_ACTUAL > 0 
              AND l.FECHA_VENCIMIENTO BETWEEN SYSDATE AND SYSDATE + p_dias 
            ORDER BY l.FECHA_VENCIMIENTO ASC; 
    END;

    -- ========================================
    -- RESUMEN_INVENTARIO
    -- ========================================
    PROCEDURE RESUMEN_INVENTARIO(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT 
                p.CODIGO, p.NOMBRE, 
                COUNT(l.ID_LOTE) AS TOTAL_LOTES, 
                SUM(NVL(l.CANTIDAD_ACTUAL, 0)) AS STOCK_TOTAL, 
                SUM(NVL(l.CANTIDAD_ACTUAL, 0) * NVL(l.PRECIO_VENTA, 0)) AS VALOR_INVENTARIO
            FROM PRODUCTOS p 
            LEFT JOIN LOTES l ON p.ID_PRODUCTO = l.ID_PRODUCTO 
                              AND l.ESTADO = 'A'
            WHERE p.ESTADO = 'A' 
            GROUP BY p.CODIGO, p.NOMBRE 
            ORDER BY p.NOMBRE; 
    END;

    -- ========================================
    -- PRODUCTOS_BAJO_STOCK
    -- ========================================
    PROCEDURE PRODUCTOS_BAJO_STOCK(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT 
                p.CODIGO, p.NOMBRE, p.STOCK_MINIMO,
                NVL(SUM(l.CANTIDAD_ACTUAL), 0) AS STOCK_ACTUAL,
                p.STOCK_MINIMO - NVL(SUM(l.CANTIDAD_ACTUAL), 0) AS FALTANTE
            FROM PRODUCTOS p 
            LEFT JOIN LOTES l ON p.ID_PRODUCTO = l.ID_PRODUCTO 
                              AND l.ESTADO = 'A'
            WHERE p.ESTADO = 'A' 
            GROUP BY p.CODIGO, p.NOMBRE, p.STOCK_MINIMO 
            HAVING NVL(SUM(l.CANTIDAD_ACTUAL), 0) < p.STOCK_MINIMO
            ORDER BY FALTANTE DESC; 
    END;

END PKG_PHARMASMART_BI;
/

COMMIT;
PROMPT ========================================
PROMPT Package PKG_PHARMASMART_BI creado.
PROMPT ========================================
EXIT;