-- ============================================
-- PharmaSmart - Script 04
-- Creación de Secuencias
-- Ejecutar como PHARMA_USER
-- Autor: Luis Alberto Ariza Villamizar
-- Universidad Popular del Cesar
-- ============================================

SET SERVEROUTPUT ON;
SET ECHO ON;

PROMPT ========================================
PROMPT Creando secuencias...
PROMPT ========================================

-- Secuencia para numeración de facturas
CREATE SEQUENCE SEQ_NUMERO_FACTURA 
    START WITH 1000 
    INCREMENT BY 1 
    NOCACHE 
    NOCYCLE;

-- Secuencias de auditoría (por si se requieren en el futuro)
CREATE SEQUENCE SEQ_HISTORIAL_PARAMETRO 
    START WITH 1 
    INCREMENT BY 1 
    NOCACHE 
    NOCYCLE;

CREATE SEQUENCE SEQ_HISTORIAL_DESCUENTO 
    START WITH 1 
    INCREMENT BY 1 
    NOCACHE 
    NOCYCLE;

CREATE SEQUENCE SEQ_ALERTA_INFLACION 
    START WITH 1 
    INCREMENT BY 1 
    NOCACHE 
    NOCYCLE;

CREATE SEQUENCE SEQ_ALERTA_FIDELIZACION 
    START WITH 1 
    INCREMENT BY 1 
    NOCACHE 
    NOCYCLE;

COMMIT;

PROMPT ========================================
PROMPT Secuencias creadas: 5
PROMPT ========================================
EXIT;