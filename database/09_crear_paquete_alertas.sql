-- ============================================
-- PharmaSmart - Script 09
-- Package PKG_PHARMASMART_ALERTAS
-- Alertas de inflación y fidelización
-- Ejecutar como PHARMA_USER
-- Autor: Luis Alberto Ariza Villamizar
-- Universidad Popular del Cesar
-- ============================================

SET SERVEROUTPUT ON;
SET ECHO ON;

CREATE OR REPLACE PACKAGE PKG_PHARMASMART_ALERTAS AS
    
    PROCEDURE OBTENER_ALERTAS_INFLACION(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE MARCAR_ALERTA_ATENDIDA(p_id_alerta NUMBER, p_id_usuario NUMBER);
    PROCEDURE ACTUALIZAR_LOTES_VENCIDOS;
    
    PROCEDURE ENVIAR_ALERTA_FIDELIZACION(
        p_id_cliente NUMBER, 
        p_tipo CHAR, 
        p_mensaje VARCHAR2, 
        p_id_producto NUMBER DEFAULT NULL, 
        p_id_lote NUMBER DEFAULT NULL
    );
    
    PROCEDURE OBTENER_ALERTAS_CLIENTE(p_id_cliente NUMBER, p_cursor OUT SYS_REFCURSOR);
    
    PROCEDURE INSERTAR_HISTORIAL_PARAMETRO(
        p_clave_parametro VARCHAR2, 
        p_valor_anterior VARCHAR2, 
        p_valor_nuevo VARCHAR2, 
        p_motivo VARCHAR2, 
        p_id_usuario NUMBER, 
        p_ip VARCHAR2 DEFAULT NULL
    );
    
    PROCEDURE INSERTAR_HISTORIAL_DESCUENTO(
        p_id_producto NUMBER, 
        p_codigo_producto VARCHAR2, 
        p_nombre_producto VARCHAR2, 
        p_descuento_anterior NUMBER, 
        p_descuento_nuevo NUMBER, 
        p_accion CHAR, 
        p_motivo VARCHAR2, 
        p_id_usuario NUMBER, 
        p_ip VARCHAR2 DEFAULT NULL
    );
    
END PKG_PHARMASMART_ALERTAS;
/

CREATE OR REPLACE PACKAGE BODY PKG_PHARMASMART_ALERTAS AS

    -- ========================================
    -- OBTENER_ALERTAS_INFLACION
    -- ========================================
    PROCEDURE OBTENER_ALERTAS_INFLACION(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT 
                ai.ID_ALERTA, ai.ID_PRODUCTO, ai.CODIGO_PRODUCTO,
                p.NOMBRE AS NOMBRE_PRODUCTO,
                ai.PRECIO_ANTERIOR, ai.PRECIO_NUEVO, 
                ai.PORCENTAJE_INCREMENTO, ai.FECHA_ALERTA, 
                ai.ESTADO, ai.ATENDIDA_POR, ai.FECHA_ATENCION
            FROM ALERTAS_INFLACION ai 
            JOIN PRODUCTOS p ON ai.ID_PRODUCTO = p.ID_PRODUCTO
            WHERE ai.ESTADO = 'P' 
            ORDER BY ai.FECHA_ALERTA DESC; 
    END;

    -- ========================================
    -- MARCAR_ALERTA_ATENDIDA
    -- ========================================
    PROCEDURE MARCAR_ALERTA_ATENDIDA(p_id_alerta NUMBER, p_id_usuario NUMBER) IS
    BEGIN 
        UPDATE ALERTAS_INFLACION 
        SET ESTADO = 'A', 
            ATENDIDA_POR = p_id_usuario, 
            FECHA_ATENCION = SYSDATE 
        WHERE ID_ALERTA = p_id_alerta;
        
        -- SIN COMMIT: lo maneja Java
    END;

    -- ========================================
    -- ACTUALIZAR_LOTES_VENCIDOS
    -- ========================================
    PROCEDURE ACTUALIZAR_LOTES_VENCIDOS IS
    BEGIN 
        UPDATE LOTES 
        SET ESTADO = 'V' 
        WHERE FECHA_VENCIMIENTO <= SYSDATE 
          AND ESTADO = 'A' 
          AND CANTIDAD_ACTUAL > 0;
        
        -- SIN COMMIT: lo maneja Java
    END;

    -- ========================================
    -- ENVIAR_ALERTA_FIDELIZACION
    -- ========================================
    PROCEDURE ENVIAR_ALERTA_FIDELIZACION(
        p_id_cliente NUMBER, 
        p_tipo CHAR, 
        p_mensaje VARCHAR2, 
        p_id_producto NUMBER DEFAULT NULL, 
        p_id_lote NUMBER DEFAULT NULL
    ) IS
    BEGIN 
        INSERT INTO ALERTAS_FIDELIZACION (
            ID_CLIENTE, ID_PRODUCTO, ID_LOTE, 
            TIPO_ALERTA, MENSAJE, ESTADO
        ) VALUES (
            p_id_cliente, p_id_producto, p_id_lote, 
            p_tipo, p_mensaje, 'P'
        ); 
        
        -- SIN COMMIT: lo maneja Java
    END;

    -- ========================================
    -- OBTENER_ALERTAS_CLIENTE
    -- ========================================
    PROCEDURE OBTENER_ALERTAS_CLIENTE(p_id_cliente NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN 
        OPEN p_cursor FOR 
            SELECT * FROM ALERTAS_FIDELIZACION 
            WHERE ID_CLIENTE = p_id_cliente 
            ORDER BY FECHA_ENVIO DESC; 
    END;

    -- ========================================
    -- INSERTAR_HISTORIAL_PARAMETRO
    -- ========================================
    PROCEDURE INSERTAR_HISTORIAL_PARAMETRO(
        p_clave_parametro VARCHAR2, 
        p_valor_anterior VARCHAR2, 
        p_valor_nuevo VARCHAR2, 
        p_motivo VARCHAR2, 
        p_id_usuario NUMBER, 
        p_ip VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN 
        INSERT INTO HISTORIAL_PARAMETROS (
            CLAVE_PARAMETRO, VALOR_ANTERIOR, VALOR_NUEVO, 
            MOTIVO, ID_USUARIO, DIRECCION_IP
        ) VALUES (
            p_clave_parametro, p_valor_anterior, p_valor_nuevo, 
            p_motivo, p_id_usuario, p_ip
        ); 
        
        -- SIN COMMIT: lo maneja Java
    END;

    -- ========================================
    -- INSERTAR_HISTORIAL_DESCUENTO
    -- ========================================
    PROCEDURE INSERTAR_HISTORIAL_DESCUENTO(
        p_id_producto NUMBER, 
        p_codigo_producto VARCHAR2, 
        p_nombre_producto VARCHAR2, 
        p_descuento_anterior NUMBER, 
        p_descuento_nuevo NUMBER, 
        p_accion CHAR, 
        p_motivo VARCHAR2, 
        p_id_usuario NUMBER, 
        p_ip VARCHAR2 DEFAULT NULL
    ) IS
    BEGIN 
        INSERT INTO HISTORIAL_DESCUENTOS (
            ID_PRODUCTO, CODIGO_PRODUCTO, NOMBRE_PRODUCTO, 
            DESCUENTO_ANTERIOR, DESCUENTO_NUEVO, ACCION, 
            MOTIVO, ID_USUARIO, DIRECCION_IP
        ) VALUES (
            p_id_producto, p_codigo_producto, p_nombre_producto, 
            p_descuento_anterior, p_descuento_nuevo, p_accion, 
            p_motivo, p_id_usuario, p_ip
        ); 
        
        -- SIN COMMIT: lo maneja Java
    END;

END PKG_PHARMASMART_ALERTAS;
/

COMMIT;
PROMPT ========================================
PROMPT Package PKG_PHARMASMART_ALERTAS creado.
PROMPT ========================================
EXIT;