-- ============================================
-- PharmaSmart - Script 05
-- Creación de Tipos Personalizados
-- Ejecutar como PHARMA_USER
-- Autor: Luis Alberto Ariza Villamizar
-- Universidad Popular del Cesar
-- ============================================

SET SERVEROUTPUT ON;
SET ECHO ON;

PROMPT ========================================
PROMPT Creando tipos personalizados...
PROMPT ========================================

-- Tipo para información de lote (usado en FEFO)
CREATE OR REPLACE TYPE T_LOTE_INFO AS OBJECT (
    ID_LOTE NUMBER,
    CODIGO_LOTE VARCHAR2(20),
    ID_PRODUCTO NUMBER,
    FECHA_VENCIMIENTO DATE,
    PRECIO_COMPRA NUMBER(10,2),
    PRECIO_VENTA NUMBER(10,2),
    CANTIDAD_ACTUAL NUMBER,
    ESTADO CHAR(1)
);
/

-- Tipo para información de venta
CREATE OR REPLACE TYPE T_VENTA_INFO AS OBJECT (
    ID_VENTA NUMBER,
    NUMERO_FACTURA VARCHAR2(20),
    FECHA_VENTA DATE,
    TOTAL NUMBER(10,2),
    ESTADO CHAR(1)
);
/

-- Tipo para reportes Top/Bottom productos
CREATE OR REPLACE TYPE T_TOP_PRODUCTO AS OBJECT (
    CODIGO VARCHAR2(15),
    NOMBRE VARCHAR2(80),
    UNIDADES_VENDIDAS NUMBER,
    TOTAL_VENDIDO NUMBER
);
/

-- Tipo para detalle de venta (usado en transacciones)
CREATE OR REPLACE TYPE T_DETALLE_VENTA AS OBJECT (
    ID_PRODUCTO NUMBER,
    CANTIDAD NUMBER,
    PRECIO_APLICADO NUMBER(10,2),
    DESCUENTO_UNITARIO NUMBER(10,2)
);
/

-- Colecciones (tablas de objetos)
CREATE OR REPLACE TYPE T_LOTE_TABLA AS TABLE OF T_LOTE_INFO;
/

CREATE OR REPLACE TYPE T_TOP_PRODUCTO_TABLA AS TABLE OF T_TOP_PRODUCTO;
/

CREATE OR REPLACE TYPE T_DETALLE_VENTA_TABLA AS TABLE OF T_DETALLE_VENTA;
/

COMMIT;

PROMPT ========================================
PROMPT Tipos creados: 7
PROMPT ========================================
EXIT;