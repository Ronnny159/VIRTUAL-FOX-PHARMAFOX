-- ============================================
-- PharmaSmart - Script 06
-- Package PKG_PHARMASMART_FEFO
-- Motor de rotación FEFO (First Expired, First Out)
-- Ejecutar como PHARMA_USER
-- Autor: Luis Alberto Ariza Villamizar
-- Universidad Popular del Cesar
-- ============================================

SET SERVEROUTPUT ON;
SET ECHO ON;

CREATE OR REPLACE PACKAGE PKG_PHARMASMART_FEFO AS
    
    -- Obtener un lote por su ID
    FUNCTION OBTENER_LOTE_POR_ID(p_id_lote NUMBER) RETURN T_LOTE_INFO;
    
    -- Listar lotes activos de un producto ordenados por FEFO
    PROCEDURE OBTENER_LOTES_POR_PRODUCTO(p_id_producto NUMBER, p_cursor OUT SYS_REFCURSOR);
    
    -- Listar todos los lotes activos
    PROCEDURE OBTENER_LOTES_ACTIVOS(p_cursor OUT SYS_REFCURSOR);
    
    -- *** FUNCIÓN CLAVE ***: Selecciona el lote FEFO para un producto
    FUNCTION SELECCIONAR_FEFO(p_id_producto NUMBER) RETURN T_LOTE_INFO;
    
    -- Insertar un nuevo lote
    PROCEDURE INSERTAR_LOTE(
        p_codigo_lote VARCHAR2,
        p_id_producto NUMBER,
        p_fecha_fabricacion DATE,
        p_fecha_vencimiento DATE,
        p_precio_compra NUMBER,
        p_precio_venta NUMBER,
        p_cantidad_inicial NUMBER,
        p_id_lote OUT NUMBER
    );
    
    -- Actualizar stock de un lote
    PROCEDURE ACTUALIZAR_STOCK(
        p_id_lote NUMBER,
        p_cantidad NUMBER,
        p_estado CHAR
    );
    
    -- Marcar lotes vencidos automáticamente
    PROCEDURE MARCAR_LOTES_VENCIDOS;
    
END PKG_PHARMASMART_FEFO;
/

CREATE OR REPLACE PACKAGE BODY PKG_PHARMASMART_FEFO AS

    -- ========================================
    -- OBTENER_LOTE_POR_ID
    -- ========================================
    FUNCTION OBTENER_LOTE_POR_ID(p_id_lote NUMBER) RETURN T_LOTE_INFO IS
        v_result T_LOTE_INFO;
    BEGIN
        SELECT T_LOTE_INFO(
            ID_LOTE, CODIGO_LOTE, ID_PRODUCTO, FECHA_VENCIMIENTO,
            PRECIO_COMPRA, PRECIO_VENTA, CANTIDAD_ACTUAL, ESTADO
        )
        INTO v_result
        FROM LOTES
        WHERE ID_LOTE = p_id_lote;
        
        RETURN v_result;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN 
            RETURN NULL;
    END;

    -- ========================================
    -- OBTENER_LOTES_POR_PRODUCTO
    -- ========================================
    PROCEDURE OBTENER_LOTES_POR_PRODUCTO(p_id_producto NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT 
                ID_LOTE, CODIGO_LOTE, ID_PRODUCTO, 
                FECHA_FABRICACION, FECHA_VENCIMIENTO,
                PRECIO_COMPRA, PRECIO_VENTA, 
                CANTIDAD_ACTUAL, CANTIDAD_INICIAL, ESTADO
            FROM LOTES 
            WHERE ID_PRODUCTO = p_id_producto 
              AND ESTADO = 'A'
              AND CANTIDAD_ACTUAL > 0
            ORDER BY FECHA_VENCIMIENTO ASC, PRECIO_COMPRA ASC;
    END;

    -- ========================================
    -- OBTENER_LOTES_ACTIVOS
    -- ========================================
    PROCEDURE OBTENER_LOTES_ACTIVOS(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT 
                ID_LOTE, CODIGO_LOTE, ID_PRODUCTO, 
                FECHA_FABRICACION, FECHA_VENCIMIENTO,
                PRECIO_COMPRA, PRECIO_VENTA, 
                CANTIDAD_ACTUAL, CANTIDAD_INICIAL, ESTADO
            FROM LOTES 
            WHERE ESTADO = 'A' 
              AND CANTIDAD_ACTUAL > 0
              AND FECHA_VENCIMIENTO > SYSDATE
            ORDER BY FECHA_VENCIMIENTO ASC;
    END;

    -- ========================================
    -- SELECCIONAR_FEFO
    -- *** CORAZÓN DEL SISTEMA ***
    -- Selecciona el lote con fecha de vencimiento más próxima
    -- ========================================
    FUNCTION SELECCIONAR_FEFO(p_id_producto NUMBER) RETURN T_LOTE_INFO IS
        v_result T_LOTE_INFO;
    BEGIN
        SELECT T_LOTE_INFO(
            ID_LOTE, CODIGO_LOTE, ID_PRODUCTO, FECHA_VENCIMIENTO,
            PRECIO_COMPRA, PRECIO_VENTA, CANTIDAD_ACTUAL, ESTADO
        )
        INTO v_result
        FROM (
            SELECT 
                ID_LOTE, CODIGO_LOTE, ID_PRODUCTO, FECHA_VENCIMIENTO,
                PRECIO_COMPRA, PRECIO_VENTA, CANTIDAD_ACTUAL, ESTADO
            FROM LOTES
            WHERE ID_PRODUCTO = p_id_producto 
              AND CANTIDAD_ACTUAL > 0
              AND ESTADO = 'A' 
              AND FECHA_VENCIMIENTO > SYSDATE
            ORDER BY FECHA_VENCIMIENTO ASC, PRECIO_COMPRA ASC
        ) 
        WHERE ROWNUM = 1;
        
        RETURN v_result;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN 
            RETURN NULL;
    END;

    -- ========================================
    -- INSERTAR_LOTE
    -- ========================================
    PROCEDURE INSERTAR_LOTE(
        p_codigo_lote VARCHAR2,
        p_id_producto NUMBER,
        p_fecha_fabricacion DATE,
        p_fecha_vencimiento DATE,
        p_precio_compra NUMBER,
        p_precio_venta NUMBER,
        p_cantidad_inicial NUMBER,
        p_id_lote OUT NUMBER
    ) IS
    BEGIN
        -- Validaciones básicas
        IF p_fecha_vencimiento <= p_fecha_fabricacion THEN
            RAISE_APPLICATION_ERROR(-20001, 
                'La fecha de vencimiento debe ser posterior a la fecha de fabricación.');
        END IF;
        
        IF p_precio_venta < p_precio_compra THEN
            RAISE_APPLICATION_ERROR(-20002, 
                'El precio de venta no puede ser menor al precio de compra.');
        END IF;
        
        IF p_cantidad_inicial <= 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 
                'La cantidad inicial debe ser mayor a cero.');
        END IF;
        
        -- Insertar lote
        INSERT INTO LOTES (
            CODIGO_LOTE, ID_PRODUCTO, FECHA_FABRICACION, FECHA_VENCIMIENTO,
            PRECIO_COMPRA, PRECIO_VENTA, CANTIDAD_ACTUAL, CANTIDAD_INICIAL, ESTADO
        ) VALUES (
            p_codigo_lote, p_id_producto, p_fecha_fabricacion, p_fecha_vencimiento,
            p_precio_compra, p_precio_venta, p_cantidad_inicial, p_cantidad_inicial, 'A'
        )
        RETURNING ID_LOTE INTO p_id_lote;
        
        -- SIN COMMIT: lo maneja Java
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;

    -- ========================================
    -- ACTUALIZAR_STOCK
    -- ========================================
    PROCEDURE ACTUALIZAR_STOCK(
        p_id_lote NUMBER,
        p_cantidad NUMBER,
        p_estado CHAR
    ) IS
        v_cantidad_actual NUMBER;
    BEGIN
        -- Bloquear el lote para evitar condiciones de carrera
        SELECT CANTIDAD_ACTUAL INTO v_cantidad_actual
        FROM LOTES
        WHERE ID_LOTE = p_id_lote
        FOR UPDATE;
        
        -- Validar que no quede negativa
        IF v_cantidad_actual - p_cantidad < 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 
                'Stock insuficiente. Disponible: ' || v_cantidad_actual || 
                ', solicitado: ' || p_cantidad);
        END IF;
        
        UPDATE LOTES 
        SET CANTIDAD_ACTUAL = CANTIDAD_ACTUAL - p_cantidad,
            ESTADO = p_estado
        WHERE ID_LOTE = p_id_lote;
        
        -- SIN COMMIT: lo maneja Java
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20005, 'El lote especificado no existe.');
        WHEN OTHERS THEN
            RAISE;
    END;

    -- ========================================
    -- MARCAR_LOTES_VENCIDOS
    -- Actualiza el estado de lotes cuya fecha ya pasó
    -- ========================================
    PROCEDURE MARCAR_LOTES_VENCIDOS IS
        v_count NUMBER;
    BEGIN
        UPDATE LOTES 
        SET ESTADO = 'V'
        WHERE FECHA_VENCIMIENTO <= SYSDATE 
          AND ESTADO = 'A' 
          AND CANTIDAD_ACTUAL > 0;
        
        v_count := SQL%ROWCOUNT;
        
        IF v_count > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Lotes marcados como vencidos: ' || v_count);
        END IF;
        
        -- SIN COMMIT: lo maneja Java
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;

END PKG_PHARMASMART_FEFO;
/

COMMIT;
PROMPT ========================================
PROMPT Package PKG_PHARMASMART_FEFO creado.
PROMPT ========================================
EXIT;