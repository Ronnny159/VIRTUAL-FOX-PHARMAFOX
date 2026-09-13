-- ============================================
-- PharmaSmart - Script 01
-- Creación de Tablespace y Usuario
-- Ejecutar como SYSDBA
-- Autor: Luis Alberto Ariza Villamizar
-- Universidad Popular del Cesar
-- ============================================

SET SERVEROUTPUT ON;
SET ECHO ON;
SET LINESIZE 200;

PROMPT ========================================
PROMPT Iniciando instalación de PharmaSmart
PROMPT ========================================

-- Eliminar si existe (para reinstalación limpia)
BEGIN
    EXECUTE IMMEDIATE 'DROP USER PHARMA_USER CASCADE';
    DBMS_OUTPUT.PUT_LINE('Usuario PHARMA_USER eliminado.');
EXCEPTION
    WHEN OTHERS THEN 
        DBMS_OUTPUT.PUT_LINE('Usuario PHARMA_USER no existe. Continuando...');
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLESPACE TS_PHARMASMART INCLUDING CONTENTS AND DATAFILES';
    DBMS_OUTPUT.PUT_LINE('Tablespace TS_PHARMASMART eliminado.');
EXCEPTION
    WHEN OTHERS THEN 
        DBMS_OUTPUT.PUT_LINE('Tablespace TS_PHARMASMART no existe. Continuando...');
END;
/

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLESPACE TS_PHARMASMART_TEMP INCLUDING CONTENTS AND DATAFILES';
    DBMS_OUTPUT.PUT_LINE('Tablespace temporal eliminado.');
EXCEPTION
    WHEN OTHERS THEN 
        DBMS_OUTPUT.PUT_LINE('Tablespace temporal no existe. Continuando...');
END;
/

-- Crear Tablespace de datos
CREATE TABLESPACE TS_PHARMASMART
    DATAFILE 'ts_pharmasmart01.dbf' 
    SIZE 100M 
    AUTOEXTEND ON 
    NEXT 50M 
    MAXSIZE 2G
    EXTENT MANAGEMENT LOCAL 
    SEGMENT SPACE MANAGEMENT AUTO;

-- Crear Tablespace temporal
CREATE TEMPORARY TABLESPACE TS_PHARMASMART_TEMP
    TEMPFILE 'ts_pharmasmart_temp01.dbf'
    SIZE 50M
    AUTOEXTEND ON
    NEXT 25M
    MAXSIZE 500M;

-- Crear usuario
CREATE USER PHARMA_USER
    IDENTIFIED BY Pharma123
    DEFAULT TABLESPACE TS_PHARMASMART
    TEMPORARY TABLESPACE TS_PHARMASMART_TEMP
    QUOTA UNLIMITED ON TS_PHARMASMART;

-- Otorgar permisos
GRANT CREATE SESSION TO PHARMA_USER;
GRANT CREATE TABLE TO PHARMA_USER;
GRANT CREATE VIEW TO PHARMA_USER;
GRANT CREATE SEQUENCE TO PHARMA_USER;
GRANT CREATE PROCEDURE TO PHARMA_USER;
GRANT CREATE TRIGGER TO PHARMA_USER;
GRANT CREATE TYPE TO PHARMA_USER;
GRANT CREATE SYNONYM TO PHARMA_USER;
GRANT DEBUG CONNECT SESSION TO PHARMA_USER;
GRANT DEBUG ANY PROCEDURE TO PHARMA_USER;

COMMIT;

-- Verificación
PROMPT ========================================
PROMPT Verificando creación:
PROMPT ========================================
SELECT 'Tablespace creado: TS_PHARMASMART' AS MENSAJE FROM DUAL;
SELECT 'Tablespace temporal creado: TS_PHARMASMART_TEMP' AS MENSAJE FROM DUAL;
SELECT 'Usuario creado: PHARMA_USER / Pharma123' AS MENSAJE FROM DUAL;
SELECT 'Instalación del Script 01 completada.' AS MENSAJE FROM DUAL;
PROMPT ========================================

EXIT;