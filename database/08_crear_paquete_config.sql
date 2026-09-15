-- ============================================
-- PharmaSmart - Script 08 (CORREGIDO)
-- Package PKG_PHARMASMART_CONFIG
-- Incluye: LOGIN, REGISTRO, GESTIÓN DE USUARIOS
-- Correcciones aplicadas:
--   - SALT en hash de contraseña
--   - Longitud mínima de password: 8
--   - SELECT INTO con manejo de excepciones
--   - REGISTRAR_AJUSTE con estados correctos
--   - Sin COMMIT internos (el caller decide)
-- ============================================

SET SERVEROUTPUT ON;
SET ECHO ON;

CREATE OR REPLACE PACKAGE PKG_PHARMASMART_CONFIG AS
    
    -- ========================================
    -- FUNCIONES DE SEGURIDAD
    -- ========================================
    
    -- Genera un SALT aleatorio para el usuario
    FUNCTION GENERAR_SALT RETURN VARCHAR2;
    
    -- Hashea la contraseña con SALT (SHA256)
    FUNCTION HASH_PASSWORD(p_password VARCHAR2, p_salt VARCHAR2) RETURN VARCHAR2;
    
    -- Login: retorna ID_USUARIO si credenciales correctas, NULL si no
    FUNCTION LOGIN(p_nombre_usuario VARCHAR2, p_password VARCHAR2) RETURN NUMBER;
    
    -- Login con información completa (cursor)
    PROCEDURE LOGIN_COMPLETO(
        p_nombre_usuario VARCHAR2, 
        p_password VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    -- Verificar si usuario existe
    FUNCTION USUARIO_EXISTE(p_nombre_usuario VARCHAR2) RETURN BOOLEAN;
    
    -- Verificar si documento ya está registrado
    FUNCTION DOCUMENTO_EXISTE(p_documento VARCHAR2) RETURN BOOLEAN;
    
    -- ========================================
    -- REGISTRO DE NUEVOS USUARIOS
    -- ========================================
    
    -- Registrar nuevo usuario (retorna TRUE si éxito)
    FUNCTION REGISTRAR_USUARIO(
        p_nombre_usuario VARCHAR2,
        p_password VARCHAR2,
        p_nombre_completo VARCHAR2,
        p_rol CHAR,
        p_documento_identidad VARCHAR2
    ) RETURN BOOLEAN;
    
    -- Registrar nuevo usuario con mensaje de error
    PROCEDURE REGISTRAR_USUARIO_PROC(
        p_nombre_usuario VARCHAR2,
        p_password VARCHAR2,
        p_nombre_completo VARCHAR2,
        p_rol CHAR,
        p_documento_identidad VARCHAR2,
        p_success OUT BOOLEAN,
        p_mensaje OUT VARCHAR2
    );
    
    -- ========================================
    -- GESTIÓN DE USUARIOS
    -- ========================================
    
    -- Cambiar contraseña
    FUNCTION CAMBIAR_CONTRASENA(
        p_id_usuario NUMBER,
        p_password_actual VARCHAR2,
        p_password_nueva VARCHAR2
    ) RETURN BOOLEAN;
    
    -- Resetear contraseña (solo admin)
    PROCEDURE RESETEAR_CONTRASENA(
        p_id_usuario NUMBER,
        p_password_nueva VARCHAR2,
        p_id_administrador NUMBER
    );
    
    -- Actualizar perfil de usuario
    PROCEDURE ACTUALIZAR_USUARIO(
        p_id_usuario NUMBER,
        p_nombre_completo VARCHAR2,
        p_rol CHAR,
        p_estado CHAR,
        p_id_administrador NUMBER
    );
    
    -- Cambiar estado de usuario (Activar/Inactivar)
    PROCEDURE CAMBIAR_ESTADO_USUARIO(
        p_id_usuario NUMBER,
        p_nuevo_estado CHAR,
        p_id_administrador NUMBER
    );
    
    -- Eliminar usuario (baja lógica)
    PROCEDURE ELIMINAR_USUARIO(
        p_id_usuario NUMBER,
        p_id_administrador NUMBER
    );
    
    -- Registrar intentos fallidos de login
    PROCEDURE REGISTRAR_INTENTO_FALLIDO(p_id_usuario NUMBER);
    
    -- Resetear intentos fallidos
    PROCEDURE RESETEAR_INTENTOS_FALLIDOS(p_id_usuario NUMBER);
    
    -- Registrar login exitoso
    PROCEDURE REGISTRAR_LOGIN_EXITOSO(p_id_usuario NUMBER);
    
    -- ========================================
    -- CONSULTAS DE USUARIOS
    -- ========================================
    
    PROCEDURE OBTENER_USUARIO_POR_ID(
        p_id_usuario NUMBER, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    PROCEDURE OBTENER_USUARIO_POR_NOMBRE(
        p_nombre VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    PROCEDURE OBTENER_USUARIO_POR_DOCUMENTO(
        p_doc VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    PROCEDURE OBTENER_TODOS_USUARIOS(p_cursor OUT SYS_REFCURSOR);
    
    PROCEDURE OBTENER_USUARIOS_ACTIVOS(p_cursor OUT SYS_REFCURSOR);
    
    PROCEDURE OBTENER_USUARIOS_POR_ROL(
        p_rol CHAR, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    -- ========================================
    -- PARÁMETROS DEL SISTEMA
    -- ========================================
    
    FUNCTION OBTENER_PARAMETRO(p_clave VARCHAR2) RETURN VARCHAR2;
    
    PROCEDURE ACTUALIZAR_DESCUENTO_GENERAL(
        p_nuevo_valor VARCHAR2, 
        p_id_usuario NUMBER, 
        p_motivo VARCHAR2, 
        p_ip VARCHAR2 DEFAULT NULL
    );
    
    PROCEDURE ACTUALIZAR_DESCUENTO_PRODUCTO(
        p_id_producto NUMBER, 
        p_descuento NUMBER, 
        p_id_usuario NUMBER, 
        p_motivo VARCHAR2, 
        p_ip VARCHAR2 DEFAULT NULL
    );
    
    PROCEDURE REGISTRAR_AJUSTE(
        p_id_lote NUMBER, 
        p_tipo CHAR, 
        p_cantidad NUMBER, 
        p_motivo VARCHAR2, 
        p_id_responsable NUMBER
    );
    
    -- ========================================
    -- HISTORIAL Y AUDITORÍA
    -- ========================================
    
    PROCEDURE OBTENER_HISTORIAL_PARAMETROS(
        p_clave VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    PROCEDURE OBTENER_HISTORIAL_POR_USUARIO(
        p_id_usuario NUMBER, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    PROCEDURE OBTENER_HISTORIAL_POR_FECHAS(
        p_desde DATE, 
        p_hasta DATE, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    PROCEDURE OBTENER_HISTORIAL_DESCUENTOS(
        p_id_producto NUMBER, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    PROCEDURE OBTENER_TODO_HISTORIAL_DESCUENTO(p_cursor OUT SYS_REFCURSOR);
    
    -- ========================================
    -- PRODUCTOS
    -- ========================================
    
    PROCEDURE OBTENER_PRODUCTO_POR_CODIGO(
        p_codigo VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    PROCEDURE OBTENER_PRODUCTO_POR_ID(
        p_id_producto NUMBER, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    PROCEDURE OBTENER_PRODUCTO_POR_NOMBRE(
        p_nombre VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    PROCEDURE OBTENER_TODOS_PRODUCTOS(p_cursor OUT SYS_REFCURSOR);
    
    PROCEDURE INSERTAR_PRODUCTO(
        p_codigo VARCHAR2, 
        p_nombre VARCHAR2, 
        p_descripcion VARCHAR2, 
        p_es_controlado CHAR, 
        p_stock_minimo NUMBER, 
        p_descuento NUMBER
    );
    
    PROCEDURE ACTUALIZAR_PRODUCTO(
        p_id_producto NUMBER, 
        p_nombre VARCHAR2, 
        p_descripcion VARCHAR2, 
        p_es_controlado CHAR, 
        p_stock_minimo NUMBER, 
        p_descuento NUMBER
    );
    
    PROCEDURE ELIMINAR_PRODUCTO(p_id_producto NUMBER);
    
    -- ========================================
    -- CLIENTES
    -- ========================================
    
    PROCEDURE OBTENER_CLIENTE_POR_DOCUMENTO(
        p_doc VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    PROCEDURE OBTENER_CLIENTE_POR_ID(
        p_id_cliente NUMBER, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    PROCEDURE OBTENER_CLIENTE_POR_CHAT_ID(
        p_chat VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    );
    
    PROCEDURE OBTENER_CLIENTES_FIDELIZACION(p_cursor OUT SYS_REFCURSOR);
    
    PROCEDURE OBTENER_TODOS_CLIENTES(p_cursor OUT SYS_REFCURSOR);
    
    PROCEDURE INSERTAR_CLIENTE(
        p_doc VARCHAR2, 
        p_nombre VARCHAR2, 
        p_tel VARCHAR2, 
        p_correo VARCHAR2, 
        p_chat VARCHAR2, 
        p_med VARCHAR2
    );
    
    PROCEDURE ACTUALIZAR_CLIENTE(
        p_id_cliente NUMBER, 
        p_nombre VARCHAR2, 
        p_tel VARCHAR2, 
        p_correo VARCHAR2, 
        p_chat VARCHAR2, 
        p_med VARCHAR2
    );
    
    PROCEDURE ACTIVAR_CLIENTE(p_doc VARCHAR2);
    
    PROCEDURE DESACTIVAR_CLIENTE(p_doc VARCHAR2);
    
    -- ========================================
    -- PARÁMETROS (CONSULTAS)
    -- ========================================
    
    PROCEDURE OBTENER_TODOS_PARAMETROS(p_cursor OUT SYS_REFCURSOR);
    
    PROCEDURE INSERTAR_PARAMETRO(
        p_clave VARCHAR2, 
        p_valor VARCHAR2, 
        p_desc VARCHAR2
    );
    
END PKG_PHARMASMART_CONFIG;
/

CREATE OR REPLACE PACKAGE BODY PKG_PHARMASMART_CONFIG AS

    -- ========================================
    -- FUNCIÓN: GENERAR_SALT
    -- ========================================
    FUNCTION GENERAR_SALT RETURN VARCHAR2 IS
        v_salt VARCHAR2(32);
    BEGIN
        BEGIN
            v_salt := RAWTOHEX(DBMS_CRYPTO.RANDOMBYTES(16));
        EXCEPTION
            WHEN OTHERS THEN
                -- Fallback si no hay permisos de crypto
                v_salt := '';
                FOR i IN 1..32 LOOP
                    v_salt := v_salt || CHR(65 + MOD(ABS(DBMS_RANDOM.RANDOM), 26));
                END LOOP;
        END;
        RETURN v_salt;
    END;

    -- ========================================
    -- FUNCIÓN: HASH_PASSWORD (con SALT)
    -- ========================================
    FUNCTION HASH_PASSWORD(p_password VARCHAR2, p_salt VARCHAR2) RETURN VARCHAR2 IS
        v_combinado VARCHAR2(4000);
    BEGIN
        IF p_password IS NULL OR LENGTH(p_password) < 8 THEN
            RAISE_APPLICATION_ERROR(-20030, 'La contraseña debe tener al menos 8 caracteres');
        END IF;
        
        IF p_salt IS NULL OR LENGTH(p_salt) = 0 THEN
            RAISE_APPLICATION_ERROR(-20031, 'El SALT no puede estar vacío');
        END IF;
        
        v_combinado := p_salt || p_password;
        RETURN RAWTOHEX(STANDARD_HASH(UTL_I18N.STRING_TO_RAW(v_combinado, 'AL32UTF8'), 'SHA256'));
    END;

    -- ========================================
    -- FUNCIÓN: LOGIN
    -- ========================================
    FUNCTION LOGIN(p_nombre_usuario VARCHAR2, p_password VARCHAR2) RETURN NUMBER IS
        v_id_usuario NUMBER;
        v_salt VARCHAR2(32);
        v_hash VARCHAR2(128);
        v_estado CHAR(1);
    BEGIN
        -- Validar parámetros
        IF p_nombre_usuario IS NULL OR p_password IS NULL THEN
            RETURN NULL;
        END IF;
        
        -- Obtener usuario con SALT
        BEGIN
            SELECT ID_USUARIO, SALT, HASH_CONTRASENA, ESTADO 
            INTO v_id_usuario, v_salt, v_hash, v_estado
            FROM USUARIOS
            WHERE NOMBRE_USUARIO = UPPER(TRIM(p_nombre_usuario));
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN NULL;
        END;
        
        -- Verificar estado
        IF v_estado = 'I' THEN
            RETURN -1; -- Usuario inactivo
        END IF;
        
        -- Verificar contraseña con SALT
        BEGIN
            IF HASH_PASSWORD(p_password, v_salt) = v_hash THEN
                RETURN v_id_usuario;
            ELSE
                -- Registrar intento fallido
                REGISTRAR_INTENTO_FALLIDO(v_id_usuario);
                RETURN NULL;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
        END;
    END;

    -- ========================================
    -- PROCEDURE: LOGIN_COMPLETO
    -- ========================================
    PROCEDURE LOGIN_COMPLETO(
        p_nombre_usuario VARCHAR2, 
        p_password VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
        v_id NUMBER;
    BEGIN
        v_id := LOGIN(p_nombre_usuario, p_password);
        
        IF v_id IS NOT NULL AND v_id > 0 THEN
            OPEN p_cursor FOR
                SELECT ID_USUARIO, NOMBRE_USUARIO, NOMBRE_COMPLETO, ROL, 
                       DOCUMENTO_IDENTIDAD, ESTADO
                FROM USUARIOS
                WHERE ID_USUARIO = v_id;
        ELSE
            OPEN p_cursor FOR SELECT NULL AS ID_USUARIO FROM DUAL WHERE 1=0;
        END IF;
    END;

    -- ========================================
    -- FUNCIÓN: USUARIO_EXISTE
    -- ========================================
    FUNCTION USUARIO_EXISTE(p_nombre_usuario VARCHAR2) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        IF p_nombre_usuario IS NULL THEN
            RETURN FALSE;
        END IF;
        
        SELECT COUNT(*) INTO v_count
        FROM USUARIOS
        WHERE NOMBRE_USUARIO = UPPER(TRIM(p_nombre_usuario));
        
        RETURN v_count > 0;
    END;

    -- ========================================
    -- FUNCIÓN: DOCUMENTO_EXISTE
    -- ========================================
    FUNCTION DOCUMENTO_EXISTE(p_documento VARCHAR2) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        IF p_documento IS NULL THEN
            RETURN FALSE;
        END IF;
        
        SELECT COUNT(*) INTO v_count
        FROM USUARIOS
        WHERE DOCUMENTO_IDENTIDAD = TRIM(p_documento);
        
        RETURN v_count > 0;
    END;

    -- ========================================
    -- FUNCIÓN: REGISTRAR_USUARIO
    -- ========================================
    FUNCTION REGISTRAR_USUARIO(
        p_nombre_usuario VARCHAR2,
        p_password VARCHAR2,
        p_nombre_completo VARCHAR2,
        p_rol CHAR,
        p_documento_identidad VARCHAR2
    ) RETURN BOOLEAN IS
        v_salt VARCHAR2(32);
        v_hash VARCHAR2(128);
        v_nombre_usuario VARCHAR2(30);
        v_documento VARCHAR2(15);
    BEGIN
        -- Validaciones
        v_nombre_usuario := UPPER(TRIM(p_nombre_usuario));
        v_documento := TRIM(p_documento_identidad);
        
        IF v_nombre_usuario IS NULL OR LENGTH(v_nombre_usuario) < 3 THEN
            RETURN FALSE;
        END IF;
        
        IF p_password IS NULL OR LENGTH(p_password) < 8 THEN
            RETURN FALSE;
        END IF;
        
        IF p_rol NOT IN ('1', '2', '3', '4') THEN
            RETURN FALSE;
        END IF;
        
        IF v_documento IS NULL OR LENGTH(v_documento) < 5 THEN
            RETURN FALSE;
        END IF;
        
        -- Verificar duplicados
        IF USUARIO_EXISTE(v_nombre_usuario) THEN
            RETURN FALSE;
        END IF;
        
        IF DOCUMENTO_EXISTE(v_documento) THEN
            RETURN FALSE;
        END IF;
        
        -- Generar salt y hash
        v_salt := GENERAR_SALT();
        v_hash := HASH_PASSWORD(p_password, v_salt);
        
        -- Insertar usuario
        INSERT INTO USUARIOS (
            NOMBRE_USUARIO, HASH_CONTRASENA, SALT, NOMBRE_COMPLETO,
            ROL, DOCUMENTO_IDENTIDAD, ESTADO, FECHA_CREACION
        ) VALUES (
            v_nombre_usuario, v_hash, v_salt, UPPER(TRIM(p_nombre_completo)),
            p_rol, v_documento, 'A', SYSDATE
        );
        
        RETURN TRUE;
        
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END;

    -- ========================================
    -- PROCEDURE: REGISTRAR_USUARIO_PROC
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
        v_salt VARCHAR2(32);
        v_hash VARCHAR2(128);
        v_nombre_usuario VARCHAR2(30);
        v_documento VARCHAR2(15);
    BEGIN
        -- Limpiar datos
        v_nombre_usuario := UPPER(TRIM(p_nombre_usuario));
        v_documento := TRIM(p_documento_identidad);
        
        -- Validaciones
        IF v_nombre_usuario IS NULL OR LENGTH(v_nombre_usuario) < 3 THEN
            p_success := FALSE;
            p_mensaje := 'El nombre de usuario debe tener al menos 3 caracteres.';
            RETURN;
        END IF;
        
        IF p_password IS NULL OR LENGTH(p_password) < 8 THEN
            p_success := FALSE;
            p_mensaje := 'La contraseña debe tener al menos 8 caracteres.';
            RETURN;
        END IF;
        
        IF p_nombre_completo IS NULL OR LENGTH(TRIM(p_nombre_completo)) < 5 THEN
            p_success := FALSE;
            p_mensaje := 'El nombre completo es requerido (mínimo 5 caracteres).';
            RETURN;
        END IF;
        
        IF p_rol NOT IN ('1', '2', '3', '4') THEN
            p_success := FALSE;
            p_mensaje := 'Rol inválido. Válidos: 1=Admin, 2=Cajero, 3=Farmacéutico, 4=Auditor';
            RETURN;
        END IF;
        
        IF v_documento IS NULL OR LENGTH(v_documento) < 5 THEN
            p_success := FALSE;
            p_mensaje := 'El documento de identidad es requerido.';
            RETURN;
        END IF;
        
        -- Verificar usuario existente
        IF USUARIO_EXISTE(v_nombre_usuario) THEN
            p_success := FALSE;
            p_mensaje := 'El nombre de usuario ya está registrado.';
            RETURN;
        END IF;
        
        -- Verificar documento existente
        IF DOCUMENTO_EXISTE(v_documento) THEN
            p_success := FALSE;
            p_mensaje := 'El documento de identidad ya está registrado.';
            RETURN;
        END IF;
        
        -- Generar salt y hash
        v_salt := GENERAR_SALT();
        v_hash := HASH_PASSWORD(p_password, v_salt);
        
        -- Insertar
        INSERT INTO USUARIOS (
            NOMBRE_USUARIO, HASH_CONTRASENA, SALT, NOMBRE_COMPLETO,
            ROL, DOCUMENTO_IDENTIDAD, ESTADO, FECHA_CREACION
        ) VALUES (
            v_nombre_usuario, v_hash, v_salt, UPPER(TRIM(p_nombre_completo)),
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
    -- FUNCIÓN: CAMBIAR_CONTRASENA
    -- ========================================
    FUNCTION CAMBIAR_CONTRASENA(
        p_id_usuario NUMBER,
        p_password_actual VARCHAR2,
        p_password_nueva VARCHAR2
    ) RETURN BOOLEAN IS
        v_salt VARCHAR2(32);
        v_hash_actual VARCHAR2(128);
        v_hash_nueva VARCHAR2(128);
        v_contador NUMBER;
    BEGIN
        -- Validar nueva contraseña
        IF p_password_nueva IS NULL OR LENGTH(p_password_nueva) < 8 THEN
            RETURN FALSE;
        END IF;
        
        -- Obtener SALT del usuario
        BEGIN
            SELECT SALT INTO v_salt FROM USUARIOS WHERE ID_USUARIO = p_id_usuario;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN FALSE;
        END;
        
        -- Verificar contraseña actual
        v_hash_actual := HASH_PASSWORD(p_password_actual, v_salt);
        
        SELECT COUNT(*) INTO v_contador
        FROM USUARIOS
        WHERE ID_USUARIO = p_id_usuario
          AND HASH_CONTRASENA = v_hash_actual
          AND ESTADO = 'A';
        
        IF v_contador = 0 THEN
            RETURN FALSE;
        END IF;
        
        -- Actualizar contraseña (nuevo hash con el mismo SALT)
        v_hash_nueva := HASH_PASSWORD(p_password_nueva, v_salt);
        
        UPDATE USUARIOS
        SET HASH_CONTRASENA = v_hash_nueva
        WHERE ID_USUARIO = p_id_usuario;
        
        RETURN TRUE;
        
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END;

    -- ========================================
    -- PROCEDURE: RESETEAR_CONTRASENA
    -- ========================================
    PROCEDURE RESETEAR_CONTRASENA(
        p_id_usuario NUMBER,
        p_password_nueva VARCHAR2,
        p_id_administrador NUMBER
    ) IS
        v_rol CHAR(1);
        v_salt VARCHAR2(32);
        v_hash VARCHAR2(128);
    BEGIN
        -- Verificar que quien resetea es administrador
        BEGIN
            SELECT ROL INTO v_rol FROM USUARIOS WHERE ID_USUARIO = p_id_administrador;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20040, 'Administrador no encontrado.');
        END;
        
        IF v_rol != '1' THEN
            RAISE_APPLICATION_ERROR(-20041, 'Solo administradores pueden resetear contraseñas.');
        END IF;
        
        IF p_password_nueva IS NULL OR LENGTH(p_password_nueva) < 8 THEN
            RAISE_APPLICATION_ERROR(-20042, 'La nueva contraseña debe tener al menos 8 caracteres.');
        END IF;
        
        -- Obtener SALT del usuario
        BEGIN
            SELECT SALT INTO v_salt FROM USUARIOS WHERE ID_USUARIO = p_id_usuario;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20043, 'Usuario no encontrado.');
        END;
        
        -- Actualizar
        v_hash := HASH_PASSWORD(p_password_nueva, v_salt);
        
        UPDATE USUARIOS
        SET HASH_CONTRASENA = v_hash,
            INTENTOS_FALLIDOS = 0
        WHERE ID_USUARIO = p_id_usuario;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;

    -- ========================================
    -- PROCEDURE: ACTUALIZAR_USUARIO
    -- ========================================
    PROCEDURE ACTUALIZAR_USUARIO(
        p_id_usuario NUMBER,
        p_nombre_completo VARCHAR2,
        p_rol CHAR,
        p_estado CHAR,
        p_id_administrador NUMBER
    ) IS
        v_rol_admin CHAR(1);
    BEGIN
        -- Verificar permisos
        BEGIN
            SELECT ROL INTO v_rol_admin FROM USUARIOS WHERE ID_USUARIO = p_id_administrador;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20044, 'Administrador no encontrado.');
        END;
        
        IF v_rol_admin != '1' THEN
            RAISE_APPLICATION_ERROR(-20045, 'Solo administradores pueden modificar usuarios.');
        END IF;
        
        IF p_rol NOT IN ('1', '2', '3', '4') THEN
            RAISE_APPLICATION_ERROR(-20046, 'Rol inválido.');
        END IF;
        
        IF p_estado NOT IN ('A', 'I') THEN
            RAISE_APPLICATION_ERROR(-20047, 'Estado inválido.');
        END IF;
        
        -- Actualizar
        UPDATE USUARIOS
        SET NOMBRE_COMPLETO = UPPER(TRIM(p_nombre_completo)),
            ROL = p_rol,
            ESTADO = p_estado
        WHERE ID_USUARIO = p_id_usuario;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20048, 'Usuario no encontrado.');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;

    -- ========================================
    -- PROCEDURE: CAMBIAR_ESTADO_USUARIO
    -- ========================================
    PROCEDURE CAMBIAR_ESTADO_USUARIO(
        p_id_usuario NUMBER,
        p_nuevo_estado CHAR,
        p_id_administrador NUMBER
    ) IS
        v_rol_admin CHAR(1);
    BEGIN
        -- Verificar permisos
        BEGIN
            SELECT ROL INTO v_rol_admin FROM USUARIOS WHERE ID_USUARIO = p_id_administrador;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20050, 'Administrador no encontrado.');
        END;
        
        IF v_rol_admin != '1' THEN
            RAISE_APPLICATION_ERROR(-20051, 'Solo administradores pueden cambiar estados.');
        END IF;
        
        -- No permitir desactivar el propio usuario
        IF p_id_usuario = p_id_administrador AND p_nuevo_estado = 'I' THEN
            RAISE_APPLICATION_ERROR(-20052, 'No puede desactivar su propio usuario.');
        END IF;
        
        UPDATE USUARIOS
        SET ESTADO = p_nuevo_estado
        WHERE ID_USUARIO = p_id_usuario;
        
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20053, 'Usuario no encontrado.');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;

    -- ========================================
    -- PROCEDURE: ELIMINAR_USUARIO (Baja lógica)
    -- ========================================
    PROCEDURE ELIMINAR_USUARIO(
        p_id_usuario NUMBER,
        p_id_administrador NUMBER
    ) IS
    BEGIN
        CAMBIAR_ESTADO_USUARIO(p_id_usuario, 'I', p_id_administrador);
    END;

    -- ========================================
    -- PROCEDURE: REGISTRAR_INTENTO_FALLIDO
    -- ========================================
    PROCEDURE REGISTRAR_INTENTO_FALLIDO(p_id_usuario NUMBER) IS
        v_intentos NUMBER;
    BEGIN
        SELECT NVL(INTENTOS_FALLIDOS, 0) + 1 INTO v_intentos
        FROM USUARIOS WHERE ID_USUARIO = p_id_usuario;
        
        UPDATE USUARIOS
        SET INTENTOS_FALLIDOS = v_intentos
        WHERE ID_USUARIO = p_id_usuario;
        
        -- Bloquear si supera 3 intentos
        IF v_intentos >= 3 THEN
            UPDATE USUARIOS
            SET ESTADO = 'I'
            WHERE ID_USUARIO = p_id_usuario;
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    -- ========================================
    -- PROCEDURE: RESETEAR_INTENTOS_FALLIDOS
    -- ========================================
    PROCEDURE RESETEAR_INTENTOS_FALLIDOS(p_id_usuario NUMBER) IS
    BEGIN
        UPDATE USUARIOS
        SET INTENTOS_FALLIDOS = 0
        WHERE ID_USUARIO = p_id_usuario;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    -- ========================================
    -- PROCEDURE: REGISTRAR_LOGIN_EXITOSO
    -- ========================================
    PROCEDURE REGISTRAR_LOGIN_EXITOSO(p_id_usuario NUMBER) IS
    BEGIN
        UPDATE USUARIOS
        SET INTENTOS_FALLIDOS = 0,
            ULTIMO_LOGIN = SYSDATE
        WHERE ID_USUARIO = p_id_usuario;
    EXCEPTION
        WHEN OTHERS THEN
            NULL;
    END;

    -- ========================================
    -- FUNCIÓN: OBTENER_PARAMETRO
    -- ========================================
    FUNCTION OBTENER_PARAMETRO(p_clave VARCHAR2) RETURN VARCHAR2 IS
        v_valor VARCHAR2(30);
    BEGIN
        SELECT VALOR INTO v_valor FROM PARAMETROS_SISTEMA WHERE CLAVE = p_clave;
        RETURN v_valor;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN 
            RETURN NULL;
        WHEN OTHERS THEN 
            RETURN NULL;
    END;

    -- ========================================
    -- PROCEDURE: ACTUALIZAR_DESCUENTO_GENERAL
    -- ========================================
    PROCEDURE ACTUALIZAR_DESCUENTO_GENERAL(
        p_nuevo_valor VARCHAR2, 
        p_id_usuario NUMBER, 
        p_motivo VARCHAR2, 
        p_ip VARCHAR2 DEFAULT NULL
    ) IS
        v_rol CHAR(1);
        v_anterior VARCHAR2(30);
    BEGIN
        BEGIN
            SELECT ROL INTO v_rol FROM USUARIOS WHERE ID_USUARIO = p_id_usuario;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20060, 'Usuario no encontrado.');
        END;
        
        IF v_rol != '1' THEN
            RAISE_APPLICATION_ERROR(-20061, 'Solo administradores pueden modificar parámetros globales.');
        END IF;
        
        BEGIN
            SELECT VALOR INTO v_anterior FROM PARAMETROS_SISTEMA 
            WHERE CLAVE = 'PORCENTAJE_DESCUENTO_VENCIMIENTO';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20062, 'Parámetro no encontrado.');
        END;
        
        UPDATE PARAMETROS_SISTEMA 
        SET VALOR = p_nuevo_valor 
        WHERE CLAVE = 'PORCENTAJE_DESCUENTO_VENCIMIENTO';
        
        INSERT INTO HISTORIAL_PARAMETROS (
            CLAVE_PARAMETRO, VALOR_ANTERIOR, VALOR_NUEVO, 
            MOTIVO, ID_USUARIO, DIRECCION_IP
        ) VALUES (
            'PORCENTAJE_DESCUENTO_VENCIMIENTO', v_anterior, p_nuevo_valor, 
            p_motivo, p_id_usuario, p_ip
        );
        
    EXCEPTION
        WHEN OTHERS THEN 
            RAISE;
    END;

    -- ========================================
    -- PROCEDURE: ACTUALIZAR_DESCUENTO_PRODUCTO
    -- ========================================
    PROCEDURE ACTUALIZAR_DESCUENTO_PRODUCTO(
        p_id_producto NUMBER, 
        p_descuento NUMBER, 
        p_id_usuario NUMBER, 
        p_motivo VARCHAR2, 
        p_ip VARCHAR2 DEFAULT NULL
    ) IS
        v_rol CHAR(1);
        v_prod PRODUCTOS%ROWTYPE;
        v_accion CHAR(1);
    BEGIN
        BEGIN
            SELECT ROL INTO v_rol FROM USUARIOS WHERE ID_USUARIO = p_id_usuario;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20063, 'Usuario no encontrado.');
        END;
        
        IF v_rol != '1' THEN
            RAISE_APPLICATION_ERROR(-20064, 'Solo administradores pueden modificar descuentos.');
        END IF;
        
        BEGIN
            SELECT * INTO v_prod FROM PRODUCTOS WHERE ID_PRODUCTO = p_id_producto;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20065, 'Producto no encontrado.');
        END;
        
        -- Determinar acción
        IF v_prod.DESCUENTO_PROXIMIDAD_VENCIMIENTO IS NULL AND p_descuento IS NOT NULL THEN
            v_accion := 'C';
        ELSIF v_prod.DESCUENTO_PROXIMIDAD_VENCIMIENTO IS NOT NULL AND p_descuento IS NULL THEN
            v_accion := 'E';
        ELSIF v_prod.DESCUENTO_PROXIMIDAD_VENCIMIENTO != p_descuento THEN
            v_accion := 'M';
        ELSE
            RETURN; -- Sin cambios
        END IF;
        
        INSERT INTO HISTORIAL_DESCUENTOS (
            ID_PRODUCTO, CODIGO_PRODUCTO, NOMBRE_PRODUCTO, 
            DESCUENTO_ANTERIOR, DESCUENTO_NUEVO, ACCION, 
            MOTIVO, ID_USUARIO, DIRECCION_IP
        ) VALUES (
            p_id_producto, v_prod.CODIGO, v_prod.NOMBRE, 
            v_prod.DESCUENTO_PROXIMIDAD_VENCIMIENTO, p_descuento, v_accion, 
            p_motivo, p_id_usuario, p_ip
        );
        
        UPDATE PRODUCTOS 
        SET DESCUENTO_PROXIMIDAD_VENCIMIENTO = p_descuento 
        WHERE ID_PRODUCTO = p_id_producto;
        
    EXCEPTION
        WHEN OTHERS THEN 
            RAISE;
    END;

    -- ========================================
    -- PROCEDURE: REGISTRAR_AJUSTE (CORREGIDO)
    -- ========================================
    PROCEDURE REGISTRAR_AJUSTE(
        p_id_lote NUMBER, 
        p_tipo CHAR, 
        p_cantidad NUMBER, 
        p_motivo VARCHAR2, 
        p_id_responsable NUMBER
    ) IS
        v_estado_actual CHAR(1);
        v_cant_actual NUMBER;
        v_cant_nueva NUMBER;
    BEGIN
        -- Validaciones
        IF p_cantidad <= 0 THEN
            RAISE_APPLICATION_ERROR(-20070, 'La cantidad debe ser positiva.');
        END IF;
        
        IF p_tipo NOT IN ('A','V','R','C') THEN
            RAISE_APPLICATION_ERROR(-20071, 'Tipo de ajuste inválido.');
        END IF;
        
        -- Obtener estado y cantidad actual
        BEGIN
            SELECT ESTADO, CANTIDAD_ACTUAL INTO v_estado_actual, v_cant_actual
            FROM LOTES WHERE ID_LOTE = p_id_lote FOR UPDATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20072, 'Lote no encontrado.');
        END;
        
        -- Calcular nueva cantidad
        v_cant_nueva := v_cant_actual - p_cantidad;
        
        -- Validar que no quede negativa
        IF v_cant_nueva < 0 THEN
            RAISE_APPLICATION_ERROR(-20073, 
                'Cantidad insuficiente en lote. Disponible: ' || v_cant_actual);
        END IF;
        
        -- Determinar nuevo estado (CORREGIDO)
        IF p_tipo = 'V' THEN
            -- Ajuste por vencimiento → VENCIDO
            v_estado_actual := 'V';
        ELSIF p_tipo = 'R' THEN
            -- Retiro legal → CUARENTENA
            v_estado_actual := 'C';
        ELSIF v_cant_nueva = 0 THEN
            -- Se agotó → AGOTADO
            v_estado_actual := 'B';
        END IF;
        
        -- Insertar ajuste
        INSERT INTO AJUSTES_INVENTARIO (
            ID_LOTE, TIPO, CANTIDAD, MOTIVO, ID_RESPONSABLE
        ) VALUES (
            p_id_lote, p_tipo, p_cantidad, p_motivo, p_id_responsable
        );
        
        -- Actualizar lote
        UPDATE LOTES 
        SET CANTIDAD_ACTUAL = v_cant_nueva, 
            ESTADO = v_estado_actual
        WHERE ID_LOTE = p_id_lote;
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END;

    -- ========================================
    -- PROCEDIMIENTOS DE CONSULTA: USUARIOS
    -- ========================================
    
    PROCEDURE OBTENER_USUARIO_POR_ID(
        p_id_usuario NUMBER, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT ID_USUARIO, NOMBRE_USUARIO, NOMBRE_COMPLETO, ROL, 
                   DOCUMENTO_IDENTIDAD, ESTADO, FECHA_CREACION
            FROM USUARIOS WHERE ID_USUARIO = p_id_usuario;
    END;
    
    PROCEDURE OBTENER_USUARIO_POR_NOMBRE(
        p_nombre VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT ID_USUARIO, NOMBRE_USUARIO, HASH_CONTRASENA, SALT, 
                   NOMBRE_COMPLETO, ROL, DOCUMENTO_IDENTIDAD, ESTADO
            FROM USUARIOS 
            WHERE NOMBRE_USUARIO = UPPER(TRIM(p_nombre));
    END;
    
    PROCEDURE OBTENER_USUARIO_POR_DOCUMENTO(
        p_doc VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM USUARIOS WHERE DOCUMENTO_IDENTIDAD = p_doc;
    END;
    
    PROCEDURE OBTENER_TODOS_USUARIOS(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT ID_USUARIO, NOMBRE_USUARIO, NOMBRE_COMPLETO, ROL, 
                   DOCUMENTO_IDENTIDAD, ESTADO, FECHA_CREACION
            FROM USUARIOS ORDER BY NOMBRE_COMPLETO;
    END;
    
    PROCEDURE OBTENER_USUARIOS_ACTIVOS(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT ID_USUARIO, NOMBRE_USUARIO, NOMBRE_COMPLETO, ROL, 
                   DOCUMENTO_IDENTIDAD
            FROM USUARIOS WHERE ESTADO = 'A' ORDER BY NOMBRE_COMPLETO;
    END;
    
    PROCEDURE OBTENER_USUARIOS_POR_ROL(
        p_rol CHAR, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT ID_USUARIO, NOMBRE_USUARIO, NOMBRE_COMPLETO, 
                   DOCUMENTO_IDENTIDAD, ESTADO
            FROM USUARIOS WHERE ROL = p_rol AND ESTADO = 'A' 
            ORDER BY NOMBRE_COMPLETO;
    END;

    -- ========================================
    -- PROCEDIMIENTOS DE CONSULTA: HISTORIAL
    -- ========================================
    
    PROCEDURE OBTENER_HISTORIAL_PARAMETROS(
        p_clave VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM HISTORIAL_PARAMETROS 
            WHERE CLAVE_PARAMETRO = p_clave 
            ORDER BY FECHA_CAMBIO DESC;
    END;
    
    PROCEDURE OBTENER_HISTORIAL_POR_USUARIO(
        p_id_usuario NUMBER, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM HISTORIAL_PARAMETROS 
            WHERE ID_USUARIO = p_id_usuario 
            ORDER BY FECHA_CAMBIO DESC;
    END;
    
    PROCEDURE OBTENER_HISTORIAL_POR_FECHAS(
        p_desde DATE, 
        p_hasta DATE, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM HISTORIAL_PARAMETROS 
            WHERE FECHA_CAMBIO BETWEEN p_desde AND p_hasta 
            ORDER BY FECHA_CAMBIO DESC;
    END;
    
    PROCEDURE OBTENER_HISTORIAL_DESCUENTOS(
        p_id_producto NUMBER, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM HISTORIAL_DESCUENTOS 
            WHERE ID_PRODUCTO = p_id_producto 
            ORDER BY FECHA_CAMBIO DESC;
    END;
    
    PROCEDURE OBTENER_TODO_HISTORIAL_DESCUENTO(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM HISTORIAL_DESCUENTOS 
            ORDER BY FECHA_CAMBIO DESC;
    END;

    -- ========================================
    -- PROCEDIMIENTOS: PRODUCTOS
    -- ========================================
    
    PROCEDURE OBTENER_PRODUCTO_POR_CODIGO(
        p_codigo VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM PRODUCTOS 
            WHERE CODIGO = p_codigo AND ESTADO = 'A';
    END;
    
    PROCEDURE OBTENER_PRODUCTO_POR_ID(
        p_id_producto NUMBER, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM PRODUCTOS WHERE ID_PRODUCTO = p_id_producto;
    END;
    
    PROCEDURE OBTENER_PRODUCTO_POR_NOMBRE(
        p_nombre VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM PRODUCTOS 
            WHERE UPPER(NOMBRE) LIKE '%' || UPPER(p_nombre) || '%' 
            AND ESTADO = 'A';
    END;
    
    PROCEDURE OBTENER_TODOS_PRODUCTOS(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM PRODUCTOS WHERE ESTADO = 'A' ORDER BY NOMBRE;
    END;
    
    PROCEDURE INSERTAR_PRODUCTO(
        p_codigo VARCHAR2, 
        p_nombre VARCHAR2, 
        p_descripcion VARCHAR2, 
        p_es_controlado CHAR, 
        p_stock_minimo NUMBER, 
        p_descuento NUMBER
    ) IS
    BEGIN
        INSERT INTO PRODUCTOS (
            CODIGO, NOMBRE, DESCRIPCION, ES_CONTROLADO, 
            STOCK_MINIMO, DESCUENTO_PROXIMIDAD_VENCIMIENTO
        ) VALUES (
            p_codigo, p_nombre, p_descripcion, p_es_controlado, 
            p_stock_minimo, p_descuento
        );
    END;
    
    PROCEDURE ACTUALIZAR_PRODUCTO(
        p_id_producto NUMBER, 
        p_nombre VARCHAR2, 
        p_descripcion VARCHAR2, 
        p_es_controlado CHAR, 
        p_stock_minimo NUMBER, 
        p_descuento NUMBER
    ) IS
    BEGIN
        UPDATE PRODUCTOS 
        SET NOMBRE = p_nombre, 
            DESCRIPCION = p_descripcion, 
            ES_CONTROLADO = p_es_controlado,
            STOCK_MINIMO = p_stock_minimo, 
            DESCUENTO_PROXIMIDAD_VENCIMIENTO = p_descuento 
        WHERE ID_PRODUCTO = p_id_producto;
    END;
    
    PROCEDURE ELIMINAR_PRODUCTO(p_id_producto NUMBER) IS
    BEGIN
        UPDATE PRODUCTOS SET ESTADO = 'I' WHERE ID_PRODUCTO = p_id_producto;
    END;

    -- ========================================
    -- PROCEDIMIENTOS: CLIENTES
    -- ========================================
    
    PROCEDURE OBTENER_CLIENTE_POR_DOCUMENTO(
        p_doc VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM CLIENTES WHERE DOCUMENTO = p_doc AND ESTADO = 'A';
    END;
    
    PROCEDURE OBTENER_CLIENTE_POR_ID(
        p_id_cliente NUMBER, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM CLIENTES WHERE ID_CLIENTE = p_id_cliente;
    END;
    
    PROCEDURE OBTENER_CLIENTE_POR_CHAT_ID(
        p_chat VARCHAR2, 
        p_cursor OUT SYS_REFCURSOR
    ) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM CLIENTES WHERE CHAT_ID = p_chat AND ESTADO = 'A';
    END;
    
    PROCEDURE OBTENER_CLIENTES_FIDELIZACION(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM CLIENTES 
            WHERE ESTADO = 'A' AND CHAT_ID IS NOT NULL 
            ORDER BY NOMBRE_COMPLETO;
    END;
    
    PROCEDURE OBTENER_TODOS_CLIENTES(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR 
            SELECT * FROM CLIENTES WHERE ESTADO = 'A' ORDER BY NOMBRE_COMPLETO;
    END;
    
    PROCEDURE INSERTAR_CLIENTE(
        p_doc VARCHAR2, 
        p_nombre VARCHAR2, 
        p_tel VARCHAR2, 
        p_correo VARCHAR2, 
        p_chat VARCHAR2, 
        p_med VARCHAR2
    ) IS
    BEGIN
        INSERT INTO CLIENTES (
            DOCUMENTO, NOMBRE_COMPLETO, TELEFONO, CORREO, CHAT_ID, MEDICAMENTO_RECURRENTE
        ) VALUES (
            p_doc, p_nombre, p_tel, p_correo, p_chat, p_med
        );
    END;
    
    PROCEDURE ACTUALIZAR_CLIENTE(
        p_id_cliente NUMBER, 
        p_nombre VARCHAR2, 
        p_tel VARCHAR2, 
        p_correo VARCHAR2, 
        p_chat VARCHAR2, 
        p_med VARCHAR2
    ) IS
    BEGIN
        UPDATE CLIENTES 
        SET NOMBRE_COMPLETO = p_nombre, 
            TELEFONO = p_tel, 
            CORREO = p_correo,
            CHAT_ID = p_chat, 
            MEDICAMENTO_RECURRENTE = p_med 
        WHERE ID_CLIENTE = p_id_cliente;
    END;
    
    PROCEDURE ACTIVAR_CLIENTE(p_doc VARCHAR2) IS
    BEGIN
        UPDATE CLIENTES SET ESTADO = 'A' WHERE DOCUMENTO = p_doc;
    END;
    
    PROCEDURE DESACTIVAR_CLIENTE(p_doc VARCHAR2) IS
    BEGIN
        UPDATE CLIENTES SET ESTADO = 'I' WHERE DOCUMENTO = p_doc;
    END;

    -- ========================================
    -- PROCEDIMIENTOS: PARÁMETROS
    -- ========================================
    
    PROCEDURE OBTENER_TODOS_PARAMETROS(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR SELECT * FROM PARAMETROS_SISTEMA ORDER BY CLAVE;
    END;
    
    PROCEDURE INSERTAR_PARAMETRO(
        p_clave VARCHAR2, 
        p_valor VARCHAR2, 
        p_desc VARCHAR2
    ) IS
    BEGIN
        INSERT INTO PARAMETROS_SISTEMA (CLAVE, VALOR, DESCRIPCION) 
        VALUES (p_clave, p_valor, p_desc);
    END;

END PKG_PHARMASMART_CONFIG;
/

COMMIT;

PROMPT ========================================
PROMPT Package CONFIG creado exitosamente con:
PROMPT   - LOGIN (con SALT + SHA256)
PROMPT   - REGISTRAR_USUARIO (con validaciones)
PROMPT   - CAMBIAR_CONTRASENA (con SALT)
PROMPT   - RESETEAR_CONTRASENA (solo admin)
PROMPT   - GESTIÓN DE USUARIOS (CRUD completo)
PROMPT   - PRODUCTOS (CRUD)
PROMPT   - CLIENTES (CRUD)
PROMPT   - PARÁMETROS (CRUD)
PROMPT   - HISTORIALES (consultas)
PROMPT ========================================

EXIT;