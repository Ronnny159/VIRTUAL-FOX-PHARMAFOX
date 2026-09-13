-- ============================================
-- PharmaSmart - Script 11
-- Creación de Triggers
-- Ejecutar como PHARMA_USER
-- Autor: Luis Alberto Ariza Villamizar
-- Universidad Popular del Cesar
-- ============================================

SET SERVEROUTPUT ON;
SET ECHO ON;

PROMPT ========================================
PROMPT Creando triggers...
PROMPT ========================================

-- ============================================
-- TRIGGER 1: Alerta de inflación
-- Compara el precio de compra del nuevo lote con el lote anterior
-- del mismo producto y genera una alerta si supera el umbral.
-- Se crea DESHABILITADO para la carga inicial.
-- ============================================
CREATE OR REPLACE TRIGGER TRG_ALERTA_INFLACION
    BEFORE INSERT ON LOTES
    FOR EACH ROW
DECLARE
    v_precio_anterior NUMBER(10,2);
    v_incremento NUMBER(7,2);
    v_umbral NUMBER(5,2) := 5.00;
    v_codigo_producto VARCHAR2(15);
    v_umbral_str VARCHAR2(30);
BEGIN
    -- *** CORRECCIÓN 1 ***: Si el lote nace vencido, no alertar inflación
    IF :NEW.ESTADO = 'V' THEN
        RETURN;
    END IF;

    -- Obtener umbral desde parámetros del sistema
    BEGIN
        SELECT VALOR INTO v_umbral_str
        FROM PARAMETROS_SISTEMA
        WHERE CLAVE = 'UMBRAL_ALERTA_INFLACION';
        v_umbral := TO_NUMBER(TRIM(v_umbral_str));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN v_umbral := 5.00;
        WHEN VALUE_ERROR THEN v_umbral := 5.00;
    END;

    -- *** CORRECCIÓN 2 ***: Buscar el lote anterior por FECHA_FABRICACION,
    -- no por ID_LOTE (evita problemas con concurrencia y con la carga inicial)
    BEGIN
        SELECT PRECIO_COMPRA INTO v_precio_anterior
        FROM (
            SELECT PRECIO_COMPRA
            FROM LOTES
            WHERE ID_PRODUCTO = :NEW.ID_PRODUCTO
              AND ESTADO IN ('A', 'B')
              AND FECHA_FABRICACION < :NEW.FECHA_FABRICACION
            ORDER BY FECHA_FABRICACION DESC, ID_LOTE DESC
        )
        WHERE ROWNUM = 1;

        IF v_precio_anterior IS NOT NULL AND v_precio_anterior > 0 THEN
            v_incremento := ((:NEW.PRECIO_COMPRA - v_precio_anterior) / v_precio_anterior) * 100;

            IF v_incremento >= v_umbral THEN
                SELECT CODIGO INTO v_codigo_producto
                FROM PRODUCTOS
                WHERE ID_PRODUCTO = :NEW.ID_PRODUCTO;

                INSERT INTO ALERTAS_INFLACION (
                    ID_PRODUCTO, CODIGO_PRODUCTO, PRECIO_ANTERIOR,
                    PRECIO_NUEVO, PORCENTAJE_INCREMENTO
                ) VALUES (
                    :NEW.ID_PRODUCTO, v_codigo_producto, v_precio_anterior,
                    :NEW.PRECIO_COMPRA, ROUND(v_incremento, 2)
                );
            END IF;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN NULL;  -- No hay lote anterior
        WHEN VALUE_ERROR THEN NULL;
    END;
END;
/

-- Se deshabilita para evitar alertas durante la carga inicial
ALTER TRIGGER TRG_ALERTA_INFLACION DISABLE;

PROMPT TRG_ALERTA_INFLACION creado (DESHABILITADO).

-- ============================================
-- TRIGGER 2: Validación de fechas de vencimiento
-- Valida que la fecha de vencimiento sea posterior a la de fabricación
-- y marca automáticamente como 'V' si ya venció.
-- Se deja HABILITADO porque es una validación de integridad.
-- ============================================
CREATE OR REPLACE TRIGGER TRG_VERIFICAR_VENCIMIENTO
    BEFORE INSERT OR UPDATE ON LOTES
    FOR EACH ROW
BEGIN
    -- Validar que vencimiento > fabricación
    IF :NEW.FECHA_VENCIMIENTO <= :NEW.FECHA_FABRICACION THEN
        RAISE_APPLICATION_ERROR(-20005, 
            'La fecha de vencimiento debe ser posterior a la fecha de fabricación.');
    END IF;
    
    -- Marcar automáticamente como vencido si la fecha ya pasó
    IF :NEW.FECHA_VENCIMIENTO <= SYSDATE THEN
        :NEW.ESTADO := 'V';
    END IF;
END;
/

PROMPT TRG_VERIFICAR_VENCIMIENTO creado (HABILITADO).

-- ============================================
-- TRIGGER 3: Validación de consistencia producto-lote
-- *** NUEVO ***: Evita que se registre un detalle de venta con un
-- producto que no corresponde al lote especificado.
-- Se deja HABILITADO.
-- ============================================
CREATE OR REPLACE TRIGGER TRG_VALIDAR_PRODUCTO_LOTE
    BEFORE INSERT OR UPDATE ON DETALLES_VENTAS
    FOR EACH ROW
DECLARE
    v_id_producto_lote NUMBER;
BEGIN
    -- Obtener el producto real del lote
    SELECT ID_PRODUCTO INTO v_id_producto_lote
    FROM LOTES
    WHERE ID_LOTE = :NEW.ID_LOTE;

    -- Validar coincidencia
    IF v_id_producto_lote != :NEW.ID_PRODUCTO THEN
        RAISE_APPLICATION_ERROR(-20060, 
            'Inconsistencia: el lote ' || :NEW.ID_LOTE || 
            ' pertenece al producto ' || v_id_producto_lote || 
            ', no al producto ' || :NEW.ID_PRODUCTO || '.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20061, 
            'El lote especificado (ID: ' || :NEW.ID_LOTE || ') no existe.');
END;
/

PROMPT TRG_VALIDAR_PRODUCTO_LOTE creado (HABILITADO).

COMMIT;

PROMPT ========================================
PROMPT Resumen de triggers:
PROMPT   TRG_ALERTA_INFLACION      -> DESHABILITADO
PROMPT   TRG_VERIFICAR_VENCIMIENTO -> HABILITADO
PROMPT   TRG_VALIDAR_PRODUCTO_LOTE -> HABILITADO
PROMPT ========================================
PROMPT El trigger de inflación se activará al final del script 12.
PROMPT ========================================

EXIT;