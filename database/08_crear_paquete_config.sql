-- ============================================
-- PharmaSmart - Script 08
-- Package PKG_PHARMASMART_CONFIG
-- Autenticación, usuarios, productos, clientes
-- Ejecutar como PHARMA_USER
-- Autor: Luis Alberto Ariza Villamizar
-- Universidad Popular del Cesar
-- ============================================

SET SERVEROUTPUT ON;
SET ECHO ON;

CREATE OR REPLACE PACKAGE PKG_PHARMASMART_CONFIG AS
    
    -- ========================================
    -- SEGURIDAD
    -- ========================================
    FUNCTION HASH_PASSWORD(p_password VARCHAR2) RETURN VARCHAR2;
    FUNCTION LOGIN(p_nombre_usuario VARCHAR2, p_password VARCHAR2) RETURN NUMBER;
    PROCEDURE LOGIN_COMPLETO(p_nombre_usuario VARCHAR2, p_password VARCHAR2, p_cursor OUT SYS_REFCURSOR);
    FUNCTION USUARIO_EXISTE(p_nombre_usuario VARCHAR2) RETURN BOOLEAN;
    FUNCTION DOCUMENTO_EXISTE(p_documento VARCHAR2) RETURN BOOLEAN;
    
    FUNCTION REGISTRAR_USUARIO(
        p_nombre_usuario VARCHAR2,
        p_password VARCHAR2,
        p_nombre_completo VARCHAR2,
        p_rol CHAR,
        p_documento_identidad VARCHAR2
    ) RETURN BOOLEAN;
    
    PROCEDURE REGISTRAR_USUARIO_PROC(
        p_nombre_usuario VARCHAR2,
        p_password VARCHAR2,
        p_nombre_completo VARCHAR2,
        p_rol CHAR,
        p_documento_identidad VARCHAR2,
        p_success OUT BOOLEAN,
        p_mensaje OUT VARCHAR2
    );
    
    FUNCTION CAMBIAR_CONTRASENA(
        p_id_usuario NUMBER,
        p_password_actual VARCHAR2,
        p_password_nueva VARCHAR2
    ) RETURN BOOLEAN;
    
    PROCEDURE RESETEAR_CONTRASENA(
        p_id_usuario NUMBER,
        p_password_nueva VARCHAR2,
        p_id_administrador NUMBER
    );
    
    PROCEDURE ACTUALIZAR_USUARIO(
        p_id_usuario NUMBER,
        p_nombre_completo VARCHAR2,
        p_rol CHAR,
        p_estado CHAR,
        p_id_administrador NUMBER
    );
    
    PROCEDURE CAMBIAR_ESTADO_USUARIO(
        p_id_usuario NUMBER,
        p_nuevo_estado CHAR,
        p_id_administrador NUMBER
    );
    
    PROCEDURE ELIMINAR_USUARIO(
        p_id_usuario NUMBER,
        p_id_administrador NUMBER
    );
    
    -- ========================================
    -- CONSULTAS DE USUARIOS
    -- ========================================
    PROCEDURE OBTENER_USUARIO_POR_CREDENCIALES(p_nombre VARCHAR2, p_hash VARCHAR2, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_USUARIO_POR_ID(p_id_usuario NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_USUARIO_POR_NOMBRE(p_nombre VARCHAR2, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_USUARIO_POR_DOCUMENTO(p_doc VARCHAR2, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_TODOS_USUARIOS(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_USUARIOS_ACTIVOS(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_USUARIOS_POR_ROL(p_rol CHAR, p_cursor OUT SYS_REFCURSOR);
    
    -- ========================================
    -- PARÁMETROS
    -- ========================================
    FUNCTION OBTENER_PARAMETRO(p_clave VARCHAR2) RETURN VARCHAR2;
    PROCEDURE ACTUALIZAR_DESCUENTO_GENERAL(p_nuevo_valor VARCHAR2, p_id_usuario NUMBER, p_motivo VARCHAR2, p_ip VARCHAR2 DEFAULT NULL);
    PROCEDURE ACTUALIZAR_DESCUENTO_PRODUCTO(p_id_producto NUMBER, p_descuento NUMBER, p_id_usuario NUMBER, p_motivo VARCHAR2, p_ip VARCHAR2 DEFAULT NULL);
    PROCEDURE REGISTRAR_AJUSTE(p_id_lote NUMBER, p_tipo CHAR, p_cantidad NUMBER, p_motivo VARCHAR2, p_id_responsable NUMBER);
    
    -- ========================================
    -- HISTORIAL
    -- ========================================
    PROCEDURE OBTENER_HISTORIAL_PARAMETROS(p_clave VARCHAR2, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_HISTORIAL_POR_USUARIO(p_id_usuario NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_HISTORIAL_POR_FECHAS(p_desde DATE, p_hasta DATE, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_HISTORIAL_DESCUENTOS(p_id_producto NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_TODO_HISTORIAL_DESCUENTO(p_cursor OUT SYS_REFCURSOR);
    
    -- ========================================
    -- PRODUCTOS
    -- ========================================
    PROCEDURE OBTENER_PRODUCTO_POR_CODIGO(p_codigo VARCHAR2, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_PRODUCTO_POR_ID(p_id_producto NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_PRODUCTO_POR_NOMBRE(p_nombre VARCHAR2, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_TODOS_PRODUCTOS(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE INSERTAR_PRODUCTO(p_codigo VARCHAR2, p_nombre VARCHAR2, p_descripcion VARCHAR2, p_es_controlado CHAR, p_stock_minimo NUMBER, p_descuento NUMBER);
    PROCEDURE ACTUALIZAR_PRODUCTO(p_id_producto NUMBER, p_nombre VARCHAR2, p_descripcion VARCHAR2, p_es_controlado CHAR, p_stock_minimo NUMBER, p_descuento NUMBER);
    PROCEDURE ELIMINAR_PRODUCTO(p_id_producto NUMBER);
    
    -- ========================================
    -- CLIENTES
    -- ========================================
    PROCEDURE OBTENER_CLIENTE_POR_DOCUMENTO(p_doc VARCHAR2, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_CLIENTE_POR_ID(p_id_cliente NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_CLIENTE_POR_CHAT_ID(p_chat VARCHAR2, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE OBTENER_CLIENTES_FIDELIZACION(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE INSERTAR_CLIENTE(p_doc VARCHAR2, p_nombre VARCHAR2, p_tel VARCHAR2, p_correo VARCHAR2, p_chat VARCHAR2, p_med VARCHAR2);
    PROCEDURE ACTUALIZAR_CLIENTE(p_id_cliente NUMBER, p_nombre VARCHAR2, p_tel VARCHAR2, p_correo VARCHAR2, p_chat VARCHAR2, p_med VARCHAR2);
    
    -- ========================================
    -- PARÁMETROS (CRUD)
    -- ========================================
    PROCEDURE OBTENER_TODOS_PARAMETROS(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE INSERTAR_PARAMETRO(p_clave VARCHAR2, p_valor VARCHAR2, p_desc VARCHAR2);
    
END PKG_PHARMASMART_CONFIG;
/CREATE OR REPLACE PACKAGE BODY PKG_PHARMASMART_CONFIG AS

    -- ========================================
    -- HASH_PASSWORD
    -- *** CORREGIDO ***: No devuelve NULL silenciosamente
    -- ========================================
    FUNCTION HASH_PASSWORD(p_password VARCHAR2) RETURN VARCHAR2 IS
        v_hash VARCHAR2(128);
    BEGIN
        -- Validar entrada
        IF p_password IS NULL OR LENGTH(p_password) = 0 THEN
            RAISE_APPLICATION_ERROR(-20050, 'La contraseña no puede estar vacía.');
        END IF;
        
        v_hash := RAWTOHEX(STANDARD_HASH(UTL_I18N.STRING_TO_RAW(p_password, 'AL32UTF8'), 'SHA256'));
        
        IF v_hash IS NULL THEN
            RAISE_APPLICATION_ERROR(-20051, 'Error crítico al calcular el hash de la contraseña.');
        END IF;
        
        RETURN v_hash;
    EXCEPTION
        WHEN OTHERS THEN
            -- Propagar el error, NO devolver NULL
            RAISE_APPLICATION_ERROR(-20052, 'Error al hashear contraseña: ' || SQLERRM);
    END;
    
    -- ========================================
    -- LOGIN
    -- ========================================
    FUNCTION LOGIN(p_nombre_usuario VARCHAR2, p_password VARCHAR2) RETURN NUMBER IS
        v_id_usuario NUMBER;
        v_hash VARCHAR2(128);
        v_estado CHAR(1);
    BEGIN
        v_hash := HASH_PASSWORD(p_password);
        
        SELECT ID_USUARIO, ESTADO INTO v_id_usuario, v_estado
        FROM USUARIOS
        WHERE NOMBRE_USUARIO = UPPER(TRIM(p_nombre_usuario))
          AND HASH_CONTRASENA = v_hash;
        
        IF v_estado = 'I' THEN
            RETURN -1;  -- Usuario inactivo
        END IF;
        
        RETURN v_id_usuario;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;  -- Credenciales incorrectas
        WHEN OTHERS THEN
            RETURN NULL;
    END;
    
    -- ========================================
    -- LOGIN_COMPLETO
    -- ========================================
    PROCEDURE LOGIN_COMPLETO(p_nombre_usuario VARCHAR2, p_password VARCHAR2, p_cursor OUT SYS_REFCURSOR) IS
        v_hash VARCHAR2(128);
    BEGIN
        v_hash := HASH_PASSWORD(p_password);
        
        OPEN p_cursor FOR
            SELECT ID_USUARIO, NOMBRE_USUARIO, NOMBRE_COMPLETO, ROL, DOCUMENTO_IDENTIDAD, ESTADO
            FROM USUARIOS
            WHERE NOMBRE_USUARIO = UPPER(TRIM(p_nombre_usuario))
              AND HASH_CONTRASENA = v_hash
              AND ESTADO = 'A';
    END;
    
    -- ========================================
    -- USUARIO_EXISTE
    -- ========================================
    FUNCTION USUARIO_EXISTE(p_nombre_usuario VARCHAR2) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM USUARIOS
        WHERE NOMBRE_USUARIO = UPPER(TRIM(p_nombre_usuario));
        
        RETURN v_count > 0;
    END;
    
    -- ========================================
    -- DOCUMENTO_EXISTE
    -- ========================================
    FUNCTION DOCUMENTO_EXISTE(p_documento VARCHAR2) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count
        FROM USUARIOS
        WHERE DOCUMENTO_IDENTIDAD = TRIM(p_documento);
        
        RETURN v_count > 0;
    END;
    
    -- ========================================
    -- REGISTRAR_USUARIO
    -- *** CORREGIDO ***: Valida que el documento sea numérico
    -- ========================================
    FUNCTION REGISTRAR_USUARIO(
        p_nombre_usuario VARCHAR2,
        p_password VARCHAR2,
        p_nombre_completo VARCHAR2,
        p_rol CHAR,
        p_documento_identidad VARCHAR2
    ) RETURN BOOLEAN IS
        v_hash VARCHAR2(128);
        v_nombre_usuario VARCHAR2(30);
        v_documento VARCHAR2(15);
    BEGIN
        v_nombre_usuario := UPPER(TRIM(p_nombre_usuario));
        v_documento := TRIM(p_documento_identidad);
        
        -- Validaciones
        IF USUARIO_EXISTE(v_nombre_usuario) THEN
            RETURN FALSE;
        END IF;
        
        IF DOCUMENTO_EXISTE(v_documento) THEN
            RETURN FALSE;
        END IF;
        
        IF p_rol NOT IN ('1', '2', '3', '4') THEN
            RETURN FALSE;
        END IF;
        
        IF p_password IS NULL OR LENGTH(p_password) < 4 THEN
            RETURN FALSE;
        END IF;
        
        -- Validar documento numérico
        IF NOT REGEXP_LIKE(v_documento, '^[0-9]+$') THEN
            RETURN FALSE;
        END IF;
        
        v_hash := HASH_PASSWORD(p_password);
        
        INSERT INTO USUARIOS (
            NOMBRE_USUARIO, HASH_CONTRASENA, NOMBRE_COMPLETO,
            ROL, DOCUMENTO_IDENTIDAD, ESTADO, FECHA_CREACION
        ) VALUES (
            v_nombre_usuario, v_hash, UPPER(TRIM(p_nombre_completo)),
            p_rol, v_documento, 'A', SYSDATE
        );
        
        -- SIN COMMIT: lo maneja Java
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;
    
    -- ========================================
    -- REGISTRAR_USUARIO_PROC
    -- *** CORREGIDO ***: Validación de documento numérico
    -- ========================================
    PROCEDURE REGISTRAR_USUARIO_PROC(
        p_nombre_usuario VARCHAR2,
        p_password VARCHAR2,
        p_nombre_completo VARCHAR2,
        p_rol CHAR,
        p_documento_identidad VARCHAR2,
        p_success OUT BOOLEAN,
        p_mensaje OUT VARCHAR2
    ) IS
        v_hash VARCHAR2(128);
        v_nombre_usuario VARCHAR2(30);
        v_documento VARCHAR2(15);
    BEGIN
        v_nombre_usuario := UPPER(TRIM(p_nombre_usuario));
        v_documento := TRIM(p_documento_identidad);
        
        -- Validaciones
        IF v_nombre_usuario IS NULL OR LENGTH(v_nombre_usuario) < 3 THEN
            p_success := FALSE;
            p_mensaje := 'El nombre de usuario debe tener al menos 3 caracteres.';
            RETURN;
        END IF;
        
        IF p_password IS NULL OR LENGTH(p_password) < 4 THEN
            p_success := FALSE;
            p_mensaje := 'La contraseña debe tener al menos 4 caracteres.';
            RETURN;
        END IF;
        
        IF p_nombre_completo IS NULL OR LENGTH(p_nombre_completo) < 5 THEN
            p_success := FALSE;
            p_mensaje := 'El nombre completo es requerido.';
            RETURN;
        END IF;
        
        IF p_rol NOT IN ('1', '2', '3', '4') THEN
            p_success := FALSE;
            p_mensaje := 'Rol inválido.';
            RETURN;
        END IF;
        
        IF v_documento IS NULL OR LENGTH(v_documento) < 5 THEN
            p_success := FALSE;
            p_mensaje := 'El documento es requerido (mínimo 5 caracteres).';
            RETURN;
        END IF;
        
        -- *** NUEVO ***: Validar formato numérico
        IF NOT REGEXP_LIKE(v_documento, '^[0-9]+$') THEN
            p_success := FALSE;
            p_mensaje := 'El documento debe contener solo números.';
            RETURN;
        END IF;
        
        IF USUARIO_EXISTE(v_nombre_usuario) THEN
            p_success := FALSE;
            p_mensaje := 'El nombre de usuario ya está registrado.';
            RETURN;
        END IF;
        
        IF DOCUMENTO_EXISTE(v_documento) THEN
            p_success := FALSE;
            p_mensaje := 'El documento ya está registrado.';
            RETURN;
        END IF;
        
        v_hash := HASH_PASSWORD(p_password);
        
        INSERT INTO USUARIOS (
            NOMBRE_USUARIO, HASH_CONTRASENA, NOMBRE_COMPLETO,
            ROL, DOCUMENTO_IDENTIDAD, ESTADO, FECHA_CREACION
        ) VALUES (
            v_nombre_usuario, v_hash, UPPER(TRIM(p_nombre_completo)),
            p_rol, v_documento, 'A', SYSDATE
        );
        
        p_success := TRUE;
        p_mensaje := 'Usuario registrado exitosamente.';
    EXCEPTION
        WHEN OTHERS THEN
            p_success := FALSE;
            p_mensaje := 'Error al registrar usuario: ' || SQLERRM;
    END;
    
    -- ========================================
    -- REGISTRAR_AJUSTE
    -- *** REESCRITO COMPLETAMENTE ***
    -- ========================================
    PROCEDURE REGISTRAR_AJUSTE(
        p_id_lote NUMBER, 
        p_tipo CHAR, 
        p_cantidad NUMBER,    -- Positiva (entrada) o negativa (salida)
        p_motivo VARCHAR2, 
        p_id_responsable NUMBER
    ) IS
        v_cantidad_actual NUMBER;
        v_nueva_cantidad NUMBER;
        v_estado CHAR(1);
        v_estado_lote CHAR(1);
    BEGIN
        -- Validaciones
        IF p_tipo NOT IN ('A','V','R','C') THEN
            RAISE_APPLICATION_ERROR(-20040, 'Tipo de ajuste inválido.');
        END IF;
        
        IF p_cantidad = 0 THEN
            RAISE_APPLICATION_ERROR(-20041, 'La cantidad no puede ser cero.');
        END IF;
        
        IF p_motivo IS NULL OR LENGTH(TRIM(p_motivo)) < 5 THEN
            RAISE_APPLICATION_ERROR(-20042, 'El motivo es obligatorio (mínimo 5 caracteres).');
        END IF;
        
        -- Bloquear lote
        BEGIN
            SELECT CANTIDAD_ACTUAL, ESTADO 
            INTO v_cantidad_actual, v_estado_lote
            FROM LOTES 
            WHERE ID_LOTE = p_id_lote 
            FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20043, 'El lote no existe.');
        END;
        
        -- Calcular nueva cantidad
        v_nueva_cantidad := v_cantidad_actual + p_cantidad;
        
        -- Validar que no quede negativa
        IF v_nueva_cantidad < 0 THEN
            RAISE_APPLICATION_ERROR(-20044, 
                'Ajuste inválido. Stock actual: ' || v_cantidad_actual || 
                ', ajuste: ' || p_cantidad);
        END IF;
        
        -- Determinar nuevo estado
        IF p_tipo = 'V' THEN
            v_estado := 'V';  -- Vencido
        ELSIF p_tipo = 'R' THEN
            v_estado := 'C';  -- Cuarentena
        ELSIF v_nueva_cantidad = 0 THEN
            v_estado := 'B';  -- Agotado
        ELSE
            IF v_estado_lote = 'V' THEN
                v_estado := 'V';
            ELSE
                v_estado := 'A';
            END IF;
        END IF;
        
        -- Registrar ajuste (cantidad en valor absoluto para auditoría)
        INSERT INTO AJUSTES_INVENTARIO (
            ID_LOTE, TIPO, CANTIDAD, MOTIVO, ID_RESPONSABLE
        ) VALUES (
            p_id_lote, p_tipo, ABS(p_cantidad), p_motivo, p_id_responsable
        );
        
        -- Actualizar lote
        UPDATE LOTES 
        SET CANTIDAD_ACTUAL = v_nueva_cantidad, 
            ESTADO = v_estado 
        WHERE ID_LOTE = p_id_lote;
        
        -- SIN COMMIT: lo maneja Java
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;
    
    -- ... (el resto de procedimientos se mantiene igual, 
    --      solo quitar los COMMIT internos)
    
END PKG_PHARMASMART_CONFIG;
/