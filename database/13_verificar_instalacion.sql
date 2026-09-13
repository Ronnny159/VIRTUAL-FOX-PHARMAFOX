-- ============================================
-- PharmaSmart - Script 13
-- Verificación de Instalación
-- Ejecutar como PHARMA_USER
-- Autor: Luis Alberto Ariza Villamizar
-- Universidad Popular del Cesar
-- ============================================

SET SERVEROUTPUT ON;
SET LINESIZE 200;
SET PAGESIZE 100;

DECLARE
    v_tablas_negocio NUMBER;
    v_tablas_dominio NUMBER;
    v_indices NUMBER;
    v_secuencias NUMBER;
    v_tipos NUMBER;
    v_packages NUMBER;
    v_triggers NUMBER;
    v_users NUMBER;
    v_prods NUMBER;
    v_lotes NUMBER;
    v_clientes NUMBER;
    v_params NUMBER;
    v_lote_id NUMBER;
    v_lote_codigo VARCHAR2(20);
    v_lote_fecha DATE;
    v_lote_stock NUMBER;
    v_param_valor VARCHAR2(30);
    v_count NUMBER;
BEGIN
    -- ========================================
    -- Conteo de tablas de negocio (12 esperadas)
    -- ========================================
    SELECT COUNT(*) INTO v_tablas_negocio
    FROM USER_TABLES
    WHERE TABLE_NAME IN (
        'USUARIOS', 'PRODUCTOS', 'LOTES', 'CLIENTES',
        'VENTAS', 'DETALLES_VENTAS', 'AJUSTES_INVENTARIO',
        'PARAMETROS_SISTEMA', 'HISTORIAL_PARAMETROS',
        'HISTORIAL_DESCUENTOS', 'ALERTAS_INFLACION',
        'ALERTAS_FIDELIZACION'
    );
    
    -- ========================================
    -- Conteo de tablas de dominio (10 esperadas)
    -- ========================================
    SELECT COUNT(*) INTO v_tablas_dominio
    FROM USER_TABLES
    WHERE TABLE_NAME LIKE 'DOM_%';
    
    -- ========================================
    -- Conteo de otros objetos
    -- ========================================
    SELECT COUNT(*) INTO v_indices FROM USER_INDEXES WHERE INDEX_NAME LIKE 'IDX_%';
    SELECT COUNT(*) INTO v_secuencias FROM USER_SEQUENCES WHERE SEQUENCE_NAME LIKE 'SEQ_%';
    SELECT COUNT(*) INTO v_tipos FROM USER_TYPES WHERE TYPE_NAME LIKE 'T_%';
    SELECT COUNT(*) INTO v_packages FROM USER_OBJECTS 
        WHERE OBJECT_TYPE = 'PACKAGE' AND STATUS = 'VALID';
    SELECT COUNT(*) INTO v_triggers FROM USER_OBJECTS 
        WHERE OBJECT_TYPE = 'TRIGGER' AND STATUS = 'VALID';
    
    -- ========================================
    -- Conteo de datos iniciales
    -- ========================================
    SELECT COUNT(*) INTO v_users FROM USUARIOS;
    SELECT COUNT(*) INTO v_prods FROM PRODUCTOS;
    SELECT COUNT(*) INTO v_lotes FROM LOTES;
    SELECT COUNT(*) INTO v_clientes FROM CLIENTES;
    SELECT COUNT(*) INTO v_params FROM PARAMETROS_SISTEMA;
    
    -- ========================================
    -- Reporte
    -- ========================================
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('===========================================');
    DBMS_OUTPUT.PUT_LINE('  PHARMASMART - VERIFICACION DE INSTALACION');
    DBMS_OUTPUT.PUT_LINE('===========================================');
    DBMS_OUTPUT.PUT_LINE('  Usuario: PHARMA_USER');
    DBMS_OUTPUT.PUT_LINE('  Fecha: ' || TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('  OBJETOS DE BASE DE DATOS:');
    DBMS_OUTPUT.PUT_LINE('    Tablas de Negocio: ' || v_tablas_negocio || '/12');
    DBMS_OUTPUT.PUT_LINE('    Tablas de Dominio: ' || v_tablas_dominio || '/10');
    DBMS_OUTPUT.PUT_LINE('    Indices:           ' || v_indices || ' (esperado: 24)');
    DBMS_OUTPUT.PUT_LINE('    Secuencias:        ' || v_secuencias || ' (esperado: 5)');
    DBMS_OUTPUT.PUT_LINE('    Tipos:             ' || v_tipos || ' (esperado: 7)');
    DBMS_OUTPUT.PUT_LINE('    Packages:          ' || v_packages || ' (esperado: 5)');
    DBMS_OUTPUT.PUT_LINE('    Triggers:          ' || v_triggers || ' (esperado: 3)');
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('  DATOS INICIALES:');
    DBMS_OUTPUT.PUT_LINE('    Usuarios:          ' || v_users || ' (esperado: 3)');
    DBMS_OUTPUT.PUT_LINE('    Productos:         ' || v_prods || ' (esperado: 5)');
    DBMS_OUTPUT.PUT_LINE('    Lotes:             ' || v_lotes || ' (esperado: 8)');
    DBMS_OUTPUT.PUT_LINE('    Clientes:          ' || v_clientes || ' (esperado: 2)');
    DBMS_OUTPUT.PUT_LINE('    Parametros:        ' || v_params || ' (esperado: 6)');
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
    
    -- ========================================
    -- Verificar tablas faltantes
    -- ========================================
    FOR t IN (
        SELECT 'USUARIOS' AS TBL FROM DUAL
        UNION ALL SELECT 'PRODUCTOS' FROM DUAL
        UNION ALL SELECT 'LOTES' FROM DUAL
        UNION ALL SELECT 'CLIENTES' FROM DUAL
        UNION ALL SELECT 'VENTAS' FROM DUAL
        UNION ALL SELECT 'DETALLES_VENTAS' FROM DUAL
        UNION ALL SELECT 'AJUSTES_INVENTARIO' FROM DUAL
        UNION ALL SELECT 'PARAMETROS_SISTEMA' FROM DUAL
        UNION ALL SELECT 'HISTORIAL_PARAMETROS' FROM DUAL
        UNION ALL SELECT 'HISTORIAL_DESCUENTOS' FROM DUAL
        UNION ALL SELECT 'ALERTAS_INFLACION' FROM DUAL
        UNION ALL SELECT 'ALERTAS_FIDELIZACION' FROM DUAL
    ) LOOP
        SELECT COUNT(*) INTO v_count FROM USER_TABLES WHERE TABLE_NAME = t.TBL;
        IF v_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('  *** FALTA TABLA: ' || t.TBL);
        END IF;
    END LOOP;
    
    -- ========================================
    -- PRUEBA 1: FEFO
    -- ========================================
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('  PRUEBA FEFO:');
    BEGIN
        SELECT ID_LOTE, CODIGO_LOTE, FECHA_VENCIMIENTO, CANTIDAD_ACTUAL
        INTO v_lote_id, v_lote_codigo, v_lote_fecha, v_lote_stock
        FROM (
            SELECT ID_LOTE, CODIGO_LOTE, FECHA_VENCIMIENTO, CANTIDAD_ACTUAL
            FROM LOTES
            WHERE ID_PRODUCTO = 1
              AND CANTIDAD_ACTUAL > 0
              AND ESTADO = 'A'
              AND FECHA_VENCIMIENTO > SYSDATE
            ORDER BY FECHA_VENCIMIENTO ASC, PRECIO_COMPRA ASC
        ) WHERE ROWNUM = 1;
        
        DBMS_OUTPUT.PUT_LINE('    Producto 1 -> Lote: ' || v_lote_codigo);
        DBMS_OUTPUT.PUT_LINE('    Vence: ' || TO_CHAR(v_lote_fecha, 'DD/MM/YYYY') || 
                             ' | Stock: ' || v_lote_stock);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('    *** No hay lotes disponibles');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('    *** ERROR: ' || SQLERRM);
    END;
    
    -- ========================================
    -- PRUEBA 2: Parámetro del sistema
    -- ========================================
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('  PRUEBA PARAMETRO:');
    BEGIN
        SELECT VALOR INTO v_param_valor
        FROM PARAMETROS_SISTEMA
        WHERE CLAVE = 'PORCENTAJE_DESCUENTO_VENCIMIENTO';
        
        DBMS_OUTPUT.PUT_LINE('    Descuento general: ' || v_param_valor);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('    *** Parametro no encontrado');
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('    *** ERROR: ' || SQLERRM);
    END;
    
    -- ========================================
    -- PRUEBA 3: Paquetes válidos
    -- ========================================
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('  PAQUETES INSTALADOS:');
    FOR p IN (
        SELECT OBJECT_NAME, STATUS 
        FROM USER_OBJECTS 
        WHERE OBJECT_TYPE = 'PACKAGE' 
        ORDER BY OBJECT_NAME
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('    ' || RPAD(p.OBJECT_NAME, 30, '.') || ' ' || p.STATUS);
    END LOOP;
    
    -- ========================================
    -- PRUEBA 4: Estado de triggers
    -- ========================================
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('  TRIGGERS:');
    FOR t IN (SELECT TRIGGER_NAME, STATUS FROM USER_TRIGGERS ORDER BY TRIGGER_NAME) LOOP
        DBMS_OUTPUT.PUT_LINE('    ' || RPAD(t.TRIGGER_NAME, 30, '.') || ' ' || t.STATUS);
    END LOOP;
    
    -- ========================================
    -- Resultado final
    -- ========================================
    DBMS_OUTPUT.PUT_LINE('===========================================');
    
    IF v_tablas_negocio = 12 
       AND v_tablas_dominio = 10
       AND v_packages >= 5 
       AND v_triggers >= 2 
       AND v_users >= 3 
       AND v_prods >= 5 
       AND v_lotes >= 8 THEN
        DBMS_OUTPUT.PUT_LINE('  ESTADO: INSTALACION COMPLETA Y CORRECTA');
    ELSE
        DBMS_OUTPUT.PUT_LINE('  ESTADO: REVISAR - Hay diferencias con lo esperado');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('===========================================');
    DBMS_OUTPUT.PUT_LINE('');
END;
/

EXIT;