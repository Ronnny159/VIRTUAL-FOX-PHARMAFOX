-- ============================================
-- PharmaSmart - Script 07
-- Package PKG_PHARMASMART_VENTAS
-- Gestión de transacciones comerciales
-- Ejecutar como PHARMA_USER
-- Autor: Luis Alberto Ariza Villamizar
-- Universidad Popular del Cesar
-- ============================================

SET SERVEROUTPUT ON;
SET ECHO ON;

CREATE OR REPLACE PACKAGE PKG_PHARMASMART_VENTAS AS
    
    PROCEDURE CREAR_VENTA(
        p_id_usuario NUMBER, 
        p_id_cliente NUMBER, 
        p_subtotal NUMBER,
        p_descuento_total NUMBER, 
        p_total NUMBER,
        p_id_venta OUT NUMBER, 
        p_numero_factura OUT VARCHAR2
    );
    
    PROCEDURE INSERTAR_DETALLE(
        p_id_venta NUMBER, 
        p_id_producto NUMBER, 
        p_id_lote NUMBER,
        p_cantidad NUMBER, 
        p_precio_aplicado NUMBER, 
        p_descuento_unitario NUMBER
    );
    
    -- *** CORREGIDO ***: Valida que la venta no esté ya anulada
    PROCEDURE ANULAR_VENTA(p_id_venta NUMBER, p_id_usuario NUMBER);
    
    FUNCTION OBTENER_VENTA(p_id_venta NUMBER) RETURN T_VENTA_INFO;
    
    PROCEDURE OBTENER_VENTA_POR_FACTURA(p_numero_factura VARCHAR2, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_VENTAS_USUARIO(p_id_usuario NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_VENTAS_FECHAS(p_desde DATE, p_hasta DATE, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_DETALLES_VENTA(p_id_venta NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_DETALLES_POR_LOTE(p_id_lote NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_AJUSTES_POR_LOTE(p_id_lote NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_AJUSTES_POR_RESPONSABLE(p_id_usuario NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_AJUSTES_POR_FECHAS(p_desde DATE, p_hasta DATE, p_cursor OUT SYS_REFCURSOR);
    
END PKG_PHARMASMART_VENTAS;
/

CREATE OR REPLACE PACKAGE BODY PKG_PHARMASMART_VENTAS AS

    -- ========================================
    -- CREAR_VENTA
    -- Inserta la cabecera de la factura
    -- ========================================
    PROCEDURE CREAR_VENTA(
        p_id_usuario NUMBER, 
        p_id_cliente NUMBER, 
        p_subtotal NUMBER,
        p_descuento_total NUMBER, 
        p_total NUMBER,
        p_id_venta OUT NUMBER, 
        p_numero_factura OUT VARCHAR2
    ) IS
        v_numero VARCHAR2(20);
    BEGIN
        -- Generar número de factura único
        v_numero := 'FAC-' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '-' || 
                    LPAD(SEQ_NUMERO_FACTURA.NEXTVAL, 5, '0');
        
        INSERT INTO VENTAS (
            NUMERO_FACTURA, FECHA_VENTA, ID_USUARIO, ID_CLIENTE, 
            SUBTOTAL, DESCUENTO_TOTAL, TOTAL, ESTADO
        ) VALUES (
            v_numero, SYSDATE, p_id_usuario, p_id_cliente, 
            p_subtotal, p_descuento_total, p_total, 'A'
        )
        RETURNING ID_VENTA INTO p_id_venta;
        
        p_numero_factura := v_numero;
        
        -- SIN COMMIT: lo maneja Java (transacción completa: venta + detalles)
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;

    -- ========================================
    -- INSERTAR_DETALLE
    -- *** CORREGIDO ***: FOR UPDATE + validación stock + sin COMMIT
    -- ========================================
    PROCEDURE INSERTAR_DETALLE(
        p_id_venta NUMBER, 
        p_id_producto NUMBER, 
        p_id_lote NUMBER,
        p_cantidad NUMBER, 
        p_precio_aplicado NUMBER, 
        p_descuento_unitario NUMBER
    ) IS
        v_cantidad_actual NUMBER;
        v_estado_lote CHAR(1);
        v_id_producto_lote NUMBER;
    BEGIN
        -- Validar cantidad
        IF p_cantidad <= 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'La cantidad debe ser mayor a cero.');
        END IF;
        
        -- Bloquear lote y obtener datos actuales (FOR UPDATE previene condiciones de carrera)
        BEGIN
            SELECT CANTIDAD_ACTUAL, ESTADO, ID_PRODUCTO
            INTO v_cantidad_actual, v_estado_lote, v_id_producto_lote
            FROM LOTES
            WHERE ID_LOTE = p_id_lote
            FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20011, 'El lote especificado no existe.');
        END;
        
        -- Validar que el producto coincida con el lote
        IF v_id_producto_lote != p_id_producto THEN
            RAISE_APPLICATION_ERROR(-20012, 
                'Inconsistencia: el lote ' || p_id_lote || 
                ' pertenece al producto ' || v_id_producto_lote || 
                ', no al producto ' || p_id_producto);
        END IF;
        
        -- Validar que el lote esté activo
        IF v_estado_lote != 'A' THEN
            RAISE_APPLICATION_ERROR(-20013, 
                'El lote no está activo. Estado actual: ' || v_estado_lote);
        END IF;
        
        -- Validar stock suficiente
        IF v_cantidad_actual < p_cantidad THEN
            RAISE_APPLICATION_ERROR(-20014, 
                'Stock insuficiente. Disponible: ' || v_cantidad_actual || 
                ', solicitado: ' || p_cantidad);
        END IF;
        
        -- Insertar detalle
        INSERT INTO DETALLES_VENTAS (
            ID_VENTA, ID_PRODUCTO, ID_LOTE, CANTIDAD, 
            PRECIO_APLICADO, DESCUENTO_UNITARIO
        ) VALUES (
            p_id_venta, p_id_producto, p_id_lote, p_cantidad, 
            p_precio_aplicado, p_descuento_unitario
        );
        
        -- Actualizar stock del lote
        UPDATE LOTES 
        SET CANTIDAD_ACTUAL = CANTIDAD_ACTUAL - p_cantidad,
            ESTADO = CASE 
                WHEN (CANTIDAD_ACTUAL - p_cantidad) = 0 THEN 'B' 
                ELSE 'A' 
            END
        WHERE ID_LOTE = p_id_lote;
        
        -- SIN COMMIT: lo maneja Java
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;

    -- ========================================
    -- ANULAR_VENTA
    -- *** CORREGIDO ***: Valida que no esté ya anulada + FOR UPDATE
    -- ========================================
    PROCEDURE ANULAR_VENTA(p_id_venta NUMBER, p_id_usuario NUMBER) IS
        CURSOR c_det IS 
            SELECT ID_LOTE, CANTIDAD 
            FROM DETALLES_VENTAS 
            WHERE ID_VENTA = p_id_venta;
        
        v_estado CHAR(1);
        v_fecha_anulacion DATE;
    BEGIN
        -- *** VALIDACIÓN CRÍTICA ***: Verificar que la venta existe y está activa
        BEGIN
            SELECT ESTADO, FECHA_ANULACION 
            INTO v_estado, v_fecha_anulacion
            FROM VENTAS 
            WHERE ID_VENTA = p_id_venta
            FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20015, 
                    'La venta con ID ' || p_id_venta || ' no existe.');
        END;
        
        IF v_estado = 'N' THEN
            RAISE_APPLICATION_ERROR(-20016, 
                'La venta ya fue anulada el ' || 
                TO_CHAR(v_fecha_anulacion, 'DD/MM/YYYY HH24:MI:SS'));
        END IF;
        
        -- Restaurar stock de cada lote
        FOR det IN c_det LOOP
            UPDATE LOTES 
            SET CANTIDAD_ACTUAL = CANTIDAD_ACTUAL + det.CANTIDAD,
                ESTADO = CASE 
                    WHEN ESTADO = 'B' AND (CANTIDAD_ACTUAL + det.CANTIDAD) > 0 THEN 'A'
                    WHEN ESTADO = 'B' THEN 'A'
                    ELSE ESTADO 
                END
            WHERE ID_LOTE = det.ID_LOTE;
        END LOOP;
        
        -- Marcar venta como anulada
        UPDATE VENTAS 
        SET ESTADO = 'N', 
            FECHA_ANULACION = SYSDATE, 
            ANULADA_POR = p_id_usuario 
        WHERE ID_VENTA = p_id_venta;
        
        -- SIN COMMIT: lo maneja Java
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;

    -- ========================================
    -- OBTENER_VENTA
    -- ========================================
    FUNCTION OBTENER_VENTA(p_id_venta NUMBER) RETURN T_VENTA_INFO IS
        v_result T_VENTA_INFO;
    BEGIN
        SELECT T_VENTA_INFO(ID_VENTA, NUMERO_FACTURA, FECHA_VENTA, TOTAL, ESTADO)
        INTO v_result 
        FROM VENTAS 
        WHERE ID_VENTA = p_id_venta;
        
        RETURN v_result;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN 
            RETURN NULL;
    END;

    -- ========================================
    -- PROCEDIMIENTOS DE CONSULTA
    -- ========================================
    
    PROCEDURE OBTENER_VENTA_POR_FACTURA(p_numero_factura VARCHAR2, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT * FROM VENTAS 
            WHERE NUMERO_FACTURA = p_numero_factura; 
    END;

    PROCEDURE OBTENER_VENTAS_USUARIO(p_id_usuario NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT * FROM VENTAS 
            WHERE ID_USUARIO = p_id_usuario 
              AND ESTADO = 'A' 
            ORDER BY FECHA_VENTA DESC; 
    END;

    PROCEDURE OBTENER_VENTAS_FECHAS(p_desde DATE, p_hasta DATE, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT * FROM VENTAS 
            WHERE FECHA_VENTA BETWEEN p_desde AND p_hasta 
              AND ESTADO = 'A' 
            ORDER BY FECHA_VENTA DESC; 
    END;

    PROCEDURE OBTENER_DETALLES_VENTA(p_id_venta NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT 
                dv.*, p.NOMBRE AS NOMBRE_PRODUCTO, l.CODIGO_LOTE,
                l.FECHA_VENCIMIENTO
            FROM DETALLES_VENTAS dv 
            JOIN PRODUCTOS p ON dv.ID_PRODUCTO = p.ID_PRODUCTO 
            JOIN LOTES l ON dv.ID_LOTE = l.ID_LOTE
            WHERE dv.ID_VENTA = p_id_venta; 
    END;

    PROCEDURE OBTENER_DETALLES_POR_LOTE(p_id_lote NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT * FROM DETALLES_VENTAS 
            WHERE ID_LOTE = p_id_lote; 
    END;

    PROCEDURE OBTENER_AJUSTES_POR_LOTE(p_id_lote NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT * FROM AJUSTES_INVENTARIO 
            WHERE ID_LOTE = p_id_lote 
            ORDER BY FECHA_AJUSTE DESC; 
    END;

    PROCEDURE OBTENER_AJUSTES_POR_RESPONSABLE(p_id_usuario NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT * FROM AJUSTES_INVENTARIO 
            WHERE ID_RESPONSABLE = p_id_usuario 
            ORDER BY FECHA_AJUSTE DESC; 
    END;

    PROCEDURE OBTENER_AJUSTES_POR_FECHAS(p_desde DATE, p_hasta DATE, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT * FROM AJUSTES_INVENTARIO 
            WHERE FECHA_AJUSTE BETWEEN p_desde AND p_hasta 
            ORDER BY FECHA_AJUSTE DESC; 
    END;

END PKG_PHARMASMART_VENTAS;
/

COMMIT;
PROMPT ========================================
PROMPT Package PKG_PHARMASMART_VENTAS creado.
PROMPT ========================================
EXIT;