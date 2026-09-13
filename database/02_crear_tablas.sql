-- ============================================
-- PharmaSmart - Script 02
-- Creación de Tablas de Dominio + Tablas de Negocio
-- Ejecutar como PHARMA_USER
-- Autor: Luis Alberto Ariza Villamizar
-- Universidad Popular del Cesar
-- ============================================

SET SERVEROUTPUT ON;
SET ECHO ON;

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

PROMPT ========================================
PROMPT Creando tablas de dominio...
PROMPT ========================================

-- ============================================
-- TABLAS DE DOMINIO (Catálogos de valores permitidos)
-- ============================================

-- ---------------------------------------------------
-- DOMINIO: ESTADOS_GENERALES
-- ---------------------------------------------------
CREATE TABLE DOM_ESTADOS_GENERALES (
    CODIGO CHAR(1) PRIMARY KEY,
    NOMBRE VARCHAR2(30) NOT NULL,
    DESCRIPCION VARCHAR2(80) NOT NULL
);

COMMENT ON TABLE DOM_ESTADOS_GENERALES IS 'Estados genéricos: Activo/Inactivo';
COMMENT ON COLUMN DOM_ESTADOS_GENERALES.CODIGO IS 'A=Activo, I=Inactivo';
COMMENT ON COLUMN DOM_ESTADOS_GENERALES.NOMBRE IS 'Nombre legible del estado';
COMMENT ON COLUMN DOM_ESTADOS_GENERALES.DESCRIPCION IS 'Descripción detallada del estado';

INSERT INTO DOM_ESTADOS_GENERALES (CODIGO, NOMBRE, DESCRIPCION) VALUES ('A', 'Activo', 'El registro está activo y visible en el sistema');
INSERT INTO DOM_ESTADOS_GENERALES (CODIGO, NOMBRE, DESCRIPCION) VALUES ('I', 'Inactivo', 'El registro ha sido dado de baja lógica');

-- ---------------------------------------------------
-- DOMINIO: ESTADOS_LOTE
-- ---------------------------------------------------
CREATE TABLE DOM_ESTADOS_LOTE (
    CODIGO CHAR(1) PRIMARY KEY,
    NOMBRE VARCHAR2(30) NOT NULL,
    DESCRIPCION VARCHAR2(100) NOT NULL
);

COMMENT ON TABLE DOM_ESTADOS_LOTE IS 'Estados específicos para lotes de inventario';
COMMENT ON COLUMN DOM_ESTADOS_LOTE.CODIGO IS 'A=Activo, B=Agotado, V=Vencido, C=Cuarentena';

INSERT INTO DOM_ESTADOS_LOTE (CODIGO, NOMBRE, DESCRIPCION) VALUES ('A', 'Activo', 'Lote con stock disponible para la venta. Estado por defecto al ingresar mercadería.');
INSERT INTO DOM_ESTADOS_LOTE (CODIGO, NOMBRE, DESCRIPCION) VALUES ('B', 'Agotado', 'Lote sin stock. Se asigna automáticamente cuando CANTIDAD_ACTUAL llega a cero tras una venta.');
INSERT INTO DOM_ESTADOS_LOTE (CODIGO, NOMBRE, DESCRIPCION) VALUES ('V', 'Vencido', 'Lote cuya fecha de vencimiento ha sido superada. Se asigna por trigger TRG_VERIFICAR_VENCIMIENTO.');
INSERT INTO DOM_ESTADOS_LOTE (CODIGO, NOMBRE, DESCRIPCION) VALUES ('C', 'Cuarentena', 'Lote retenido por alerta sanitaria, retiro legal del Invima o sospecha de falsificación.');

-- ---------------------------------------------------
-- DOMINIO: ESTADOS_VENTA
-- ---------------------------------------------------
CREATE TABLE DOM_ESTADOS_VENTA (
    CODIGO CHAR(1) PRIMARY KEY,
    NOMBRE VARCHAR2(30) NOT NULL,
    DESCRIPCION VARCHAR2(100) NOT NULL
);

COMMENT ON TABLE DOM_ESTADOS_VENTA IS 'Estados posibles de una factura de venta';
COMMENT ON COLUMN DOM_ESTADOS_VENTA.CODIGO IS 'A=Activa, N=Anulada';

INSERT INTO DOM_ESTADOS_VENTA (CODIGO, NOMBRE, DESCRIPCION) VALUES ('A', 'Activa', 'Venta vigente. El stock fue descontado y la factura es válida.');
INSERT INTO DOM_ESTADOS_VENTA (CODIGO, NOMBRE, DESCRIPCION) VALUES ('N', 'Anulada', 'Venta anulada por administrador o farmacéutico. El stock fue restaurado a los lotes correspondientes.');

-- ---------------------------------------------------
-- DOMINIO: ESTADOS_ALERTA
-- ---------------------------------------------------
CREATE TABLE DOM_ESTADOS_ALERTA (
    CODIGO CHAR(1) PRIMARY KEY,
    NOMBRE VARCHAR2(30) NOT NULL,
    DESCRIPCION VARCHAR2(100) NOT NULL
);

COMMENT ON TABLE DOM_ESTADOS_ALERTA IS 'Estados de las alertas de inflación';
COMMENT ON COLUMN DOM_ESTADOS_ALERTA.CODIGO IS 'P=Pendiente, A=Atendida';

INSERT INTO DOM_ESTADOS_ALERTA (CODIGO, NOMBRE, DESCRIPCION) VALUES ('P', 'Pendiente', 'Alerta generada que aún no ha sido revisada por el administrador.');
INSERT INTO DOM_ESTADOS_ALERTA (CODIGO, NOMBRE, DESCRIPCION) VALUES ('A', 'Atendida', 'Alerta revisada y gestionada por el administrador.');

-- ---------------------------------------------------
-- DOMINIO: ESTADOS_NOTIFICACION
-- ---------------------------------------------------
CREATE TABLE DOM_ESTADOS_NOTIFICACION (
    CODIGO CHAR(1) PRIMARY KEY,
    NOMBRE VARCHAR2(30) NOT NULL,
    DESCRIPCION VARCHAR2(100) NOT NULL
);

COMMENT ON TABLE DOM_ESTADOS_NOTIFICACION IS 'Estados de las notificaciones de fidelización';
COMMENT ON COLUMN DOM_ESTADOS_NOTIFICACION.CODIGO IS 'P=Pendiente, E=Enviada, L=Leída';

INSERT INTO DOM_ESTADOS_NOTIFICACION (CODIGO, NOMBRE, DESCRIPCION) VALUES ('P', 'Pendiente', 'Notificación generada pero aún no enviada al Bot de Telegram.');
INSERT INTO DOM_ESTADOS_NOTIFICACION (CODIGO, NOMBRE, DESCRIPCION) VALUES ('E', 'Enviada', 'Notificación enviada exitosamente al paciente por Telegram.');
INSERT INTO DOM_ESTADOS_NOTIFICACION (CODIGO, NOMBRE, DESCRIPCION) VALUES ('L', 'Leída', 'El paciente abrió y leyó la notificación en Telegram.');

-- ---------------------------------------------------
-- DOMINIO: ROLES_USUARIO
-- ---------------------------------------------------
CREATE TABLE DOM_ROLES_USUARIO (
    CODIGO CHAR(1) PRIMARY KEY,
    NOMBRE VARCHAR2(30) NOT NULL,
    DESCRIPCION VARCHAR2(150) NOT NULL
);

COMMENT ON TABLE DOM_ROLES_USUARIO IS 'Roles de usuario del sistema';
COMMENT ON COLUMN DOM_ROLES_USUARIO.CODIGO IS '1=Admin, 2=Cajero, 3=Farmaceutico, 4=Auditor';

INSERT INTO DOM_ROLES_USUARIO (CODIGO, NOMBRE, DESCRIPCION) VALUES ('1', 'Administrador', 'Acceso total al sistema. Puede modificar parámetros, descuentos, anular ventas, ver auditoría y gestionar usuarios.');
INSERT INTO DOM_ROLES_USUARIO (CODIGO, NOMBRE, DESCRIPCION) VALUES ('2', 'Cajero', 'Acceso limitado al punto de venta y consulta de inventario. No puede modificar descuentos ni anular ventas.');
INSERT INTO DOM_ROLES_USUARIO (CODIGO, NOMBRE, DESCRIPCION) VALUES ('3', 'Farmacéutico', 'Puede anular ventas, registrar ajustes de inventario y ver reportes. Responsable sanitario.');
INSERT INTO DOM_ROLES_USUARIO (CODIGO, NOMBRE, DESCRIPCION) VALUES ('4', 'Auditor', 'Solo consulta de reportes, historiales y trazabilidad. Sin permisos de escritura.');

-- ---------------------------------------------------
-- DOMINIO: TIPOS_AJUSTE
-- ---------------------------------------------------
CREATE TABLE DOM_TIPOS_AJUSTE (
    CODIGO CHAR(1) PRIMARY KEY,
    NOMBRE VARCHAR2(30) NOT NULL,
    DESCRIPCION VARCHAR2(150) NOT NULL
);

COMMENT ON TABLE DOM_TIPOS_AJUSTE IS 'Tipos de ajuste de inventario permitidos';
COMMENT ON COLUMN DOM_TIPOS_AJUSTE.CODIGO IS 'A=Averia, V=Vencido, R=RetiroLegal, C=ConteoCiclico';

INSERT INTO DOM_TIPOS_AJUSTE (CODIGO, NOMBRE, DESCRIPCION) VALUES ('A', 'Avería', 'Daño físico del producto: rotura de envase, exposición a humedad, temperatura inadecuada.');
INSERT INTO DOM_TIPOS_AJUSTE (CODIGO, NOMBRE, DESCRIPCION) VALUES ('V', 'Vencido', 'Retiro por fecha de vencimiento superada. Se registra para trazabilidad de destrucción.');
INSERT INTO DOM_TIPOS_AJUSTE (CODIGO, NOMBRE, DESCRIPCION) VALUES ('R', 'Retiro Legal', 'Retiro ordenado por Invima o laboratorio fabricante por alerta sanitaria o lote defectuoso.');
INSERT INTO DOM_TIPOS_AJUSTE (CODIGO, NOMBRE, DESCRIPCION) VALUES ('C', 'Conteo Cíclico', 'Corrección por diferencia detectada en conteo físico de inventario programado.');

-- ---------------------------------------------------
-- DOMINIO: TIPOS_ALERTA_FIDELIZACION
-- ---------------------------------------------------
CREATE TABLE DOM_TIPOS_ALERTA_FIDELIZACION (
    CODIGO CHAR(1) PRIMARY KEY,
    NOMBRE VARCHAR2(30) NOT NULL,
    DESCRIPCION VARCHAR2(150) NOT NULL
);

COMMENT ON TABLE DOM_TIPOS_ALERTA_FIDELIZACION IS 'Tipos de alertas para el programa de fidelización';
COMMENT ON COLUMN DOM_TIPOS_ALERTA_FIDELIZACION.CODIGO IS 'V=Vencimiento, R=Reposicion, S=Stock bajo, P=Personalizada';

INSERT INTO DOM_TIPOS_ALERTA_FIDELIZACION (CODIGO, NOMBRE, DESCRIPCION) VALUES ('V', 'Vencimiento próximo', 'Se notifica al paciente cuando su medicamento recurrente está próximo a vencer (ventana crítica). Incluye descuento automático.');
INSERT INTO DOM_TIPOS_ALERTA_FIDELIZACION (CODIGO, NOMBRE, DESCRIPCION) VALUES ('R', 'Reposición', 'Recordatorio periódico para que el paciente reponga su medicamento de tratamiento crónico.');
INSERT INTO DOM_TIPOS_ALERTA_FIDELIZACION (CODIGO, NOMBRE, DESCRIPCION) VALUES ('S', 'Stock bajo', 'Alerta cuando el medicamento recurrente del paciente tiene existencias limitadas en inventario.');
INSERT INTO DOM_TIPOS_ALERTA_FIDELIZACION (CODIGO, NOMBRE, DESCRIPCION) VALUES ('P', 'Personalizada', 'Notificación manual enviada por el farmacéutico para comunicaciones específicas.');

-- ---------------------------------------------------
-- DOMINIO: ACCIONES_HISTORIAL
-- ---------------------------------------------------
CREATE TABLE DOM_ACCIONES_HISTORIAL (
    CODIGO CHAR(1) PRIMARY KEY,
    NOMBRE VARCHAR2(30) NOT NULL,
    DESCRIPCION VARCHAR2(100) NOT NULL
);

COMMENT ON TABLE DOM_ACCIONES_HISTORIAL IS 'Tipos de acciones registradas en el historial de cambios';
COMMENT ON COLUMN DOM_ACCIONES_HISTORIAL.CODIGO IS 'C=Crear, M=Modificar, E=Eliminar';

INSERT INTO DOM_ACCIONES_HISTORIAL (CODIGO, NOMBRE, DESCRIPCION) VALUES ('C', 'Crear', 'Se estableció un descuento individual donde antes no existía.');
INSERT INTO DOM_ACCIONES_HISTORIAL (CODIGO, NOMBRE, DESCRIPCION) VALUES ('M', 'Modificar', 'Se cambió el valor de un descuento individual existente.');
INSERT INTO DOM_ACCIONES_HISTORIAL (CODIGO, NOMBRE, DESCRIPCION) VALUES ('E', 'Eliminar', 'Se eliminó el descuento individual. El producto vuelve a usar el descuento general.');

-- ---------------------------------------------------
-- DOMINIO: CONTROL_MEDICAMENTOS
-- ---------------------------------------------------
CREATE TABLE DOM_CONTROL_MEDICAMENTOS (
    CODIGO CHAR(1) PRIMARY KEY,
    NOMBRE VARCHAR2(30) NOT NULL,
    DESCRIPCION VARCHAR2(150) NOT NULL
);

COMMENT ON TABLE DOM_CONTROL_MEDICAMENTOS IS 'Clasificación de medicamentos según control sanitario';
COMMENT ON COLUMN DOM_CONTROL_MEDICAMENTOS.CODIGO IS 'S=Controlado, N=No controlado';

INSERT INTO DOM_CONTROL_MEDICAMENTOS (CODIGO, NOMBRE, DESCRIPCION) VALUES ('S', 'Control especial', 'Medicamento de control especial: narcóticos, psicotrópicos, estupefacientes. Requiere registro adicional y verificación de identidad del comprador según normativa Invima.');
INSERT INTO DOM_CONTROL_MEDICAMENTOS (CODIGO, NOMBRE, DESCRIPCION) VALUES ('N', 'Venta libre', 'Medicamento de venta sin restricciones. No requiere registro especial para su dispensación.');

COMMIT;

PROMPT ========================================
PROMPT Tablas de dominio creadas: 10
PROMPT ========================================

PROMPT ========================================
PROMPT Creando tablas de negocio...
PROMPT ========================================

-- ---------------------------------------------------
-- USUARIOS
-- ---------------------------------------------------
CREATE TABLE USUARIOS (
    ID_USUARIO NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    NOMBRE_USUARIO VARCHAR2(30) NOT NULL UNIQUE,
    HASH_CONTRASENA VARCHAR2(128) NOT NULL,
    NOMBRE_COMPLETO VARCHAR2(80) NOT NULL,
    ROL CHAR(1) NOT NULL,
    DOCUMENTO_IDENTIDAD VARCHAR2(15) NOT NULL UNIQUE,
    ESTADO CHAR(1) DEFAULT 'A',
    FECHA_CREACION DATE DEFAULT SYSDATE,
    CONSTRAINT FK_USUARIOS_ROL FOREIGN KEY (ROL) REFERENCES DOM_ROLES_USUARIO(CODIGO),
    CONSTRAINT FK_USUARIOS_ESTADO FOREIGN KEY (ESTADO) REFERENCES DOM_ESTADOS_GENERALES(CODIGO)
);

COMMENT ON TABLE USUARIOS IS 'Usuarios del sistema: administradores, cajeros, farmaceuticos y auditores';
COMMENT ON COLUMN USUARIOS.ROL IS '1=Admin, 2=Cajero, 3=Farmaceutico, 4=Auditor. Ver DOM_ROLES_USUARIO';
COMMENT ON COLUMN USUARIOS.ESTADO IS 'A=Activo, I=Inactivo. Ver DOM_ESTADOS_GENERALES';

-- ---------------------------------------------------
-- PRODUCTOS
-- ---------------------------------------------------
CREATE TABLE PRODUCTOS (
    ID_PRODUCTO NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    CODIGO VARCHAR2(15) NOT NULL UNIQUE,
    NOMBRE VARCHAR2(80) NOT NULL,
    DESCRIPCION VARCHAR2(100),
    ES_CONTROLADO CHAR(1) DEFAULT 'N',
    STOCK_MINIMO NUMBER(5) DEFAULT 0,
    DESCUENTO_PROXIMIDAD_VENCIMIENTO NUMBER(3,2),
    ESTADO CHAR(1) DEFAULT 'A',
    CONSTRAINT CK_PRODUCTOS_DESCUENTO CHECK (DESCUENTO_PROXIMIDAD_VENCIMIENTO IS NULL OR (DESCUENTO_PROXIMIDAD_VENCIMIENTO >= 0 AND DESCUENTO_PROXIMIDAD_VENCIMIENTO <= 1)),
    CONSTRAINT FK_PRODUCTOS_CONTROL FOREIGN KEY (ES_CONTROLADO) REFERENCES DOM_CONTROL_MEDICAMENTOS(CODIGO),
    CONSTRAINT FK_PRODUCTOS_ESTADO FOREIGN KEY (ESTADO) REFERENCES DOM_ESTADOS_GENERALES(CODIGO)
);

COMMENT ON TABLE PRODUCTOS IS 'Catalogo maestro de productos (sin stock)';
COMMENT ON COLUMN PRODUCTOS.ES_CONTROLADO IS 'S=Controlado, N=No controlado. Ver DOM_CONTROL_MEDICAMENTOS';
COMMENT ON COLUMN PRODUCTOS.ESTADO IS 'A=Activo, I=Inactivo. Ver DOM_ESTADOS_GENERALES';
COMMENT ON COLUMN PRODUCTOS.DESCUENTO_PROXIMIDAD_VENCIMIENTO IS 'NULL = usar descuento general del sistema';

-- ---------------------------------------------------
-- LOTES
-- ---------------------------------------------------
CREATE TABLE LOTES (
    ID_LOTE NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    CODIGO_LOTE VARCHAR2(20) NOT NULL,
    ID_PRODUCTO NUMBER NOT NULL,
    FECHA_FABRICACION DATE NOT NULL,
    FECHA_VENCIMIENTO DATE NOT NULL,
    PRECIO_COMPRA NUMBER(10,2) NOT NULL,
    PRECIO_VENTA NUMBER(10,2) NOT NULL,
    CANTIDAD_ACTUAL NUMBER(6) NOT NULL CHECK (CANTIDAD_ACTUAL >= 0),
    CANTIDAD_INICIAL NUMBER(6) NOT NULL,
    ESTADO CHAR(1) DEFAULT 'A',
    CONSTRAINT CK_LOTES_FECHAS CHECK (FECHA_VENCIMIENTO > FECHA_FABRICACION),
    CONSTRAINT CK_LOTES_PRECIOS CHECK (PRECIO_VENTA >= PRECIO_COMPRA),
    CONSTRAINT FK_LOTES_PRODUCTO FOREIGN KEY (ID_PRODUCTO) REFERENCES PRODUCTOS(ID_PRODUCTO),
    CONSTRAINT FK_LOTES_ESTADO FOREIGN KEY (ESTADO) REFERENCES DOM_ESTADOS_LOTE(CODIGO)
);

COMMENT ON TABLE LOTES IS 'Cada compra al proveedor genera un lote independiente';
COMMENT ON COLUMN LOTES.ESTADO IS 'A=Activo, B=Agotado, V=Vencido, C=Cuarentena. Ver DOM_ESTADOS_LOTE';
COMMENT ON COLUMN LOTES.FECHA_VENCIMIENTO IS 'Debe ser mayor a la fecha de fabricación (constraint CK_LOTES_FECHAS)';

-- ---------------------------------------------------
-- CLIENTES
-- ---------------------------------------------------
CREATE TABLE CLIENTES (
    ID_CLIENTE NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    DOCUMENTO VARCHAR2(15) NOT NULL UNIQUE,
    NOMBRE_COMPLETO VARCHAR2(80) NOT NULL,
    TELEFONO VARCHAR2(15) NOT NULL,
    CORREO VARCHAR2(60),
    CHAT_ID VARCHAR2(30),
    MEDICAMENTO_RECURRENTE VARCHAR2(80),
    ESTADO CHAR(1) DEFAULT 'A',
    CONSTRAINT FK_CLIENTES_ESTADO FOREIGN KEY (ESTADO) REFERENCES DOM_ESTADOS_GENERALES(CODIGO)
);

COMMENT ON TABLE CLIENTES IS 'Pacientes del programa de fidelizacion';
COMMENT ON COLUMN CLIENTES.ESTADO IS 'A=Activo, I=Inactivo. Ver DOM_ESTADOS_GENERALES';
COMMENT ON COLUMN CLIENTES.CHAT_ID IS 'ID de chat de Telegram para notificaciones';

-- ---------------------------------------------------
-- VENTAS
-- ---------------------------------------------------
CREATE TABLE VENTAS (
    ID_VENTA NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    NUMERO_FACTURA VARCHAR2(20) NOT NULL UNIQUE,
    FECHA_VENTA DATE DEFAULT SYSDATE NOT NULL,
    ID_USUARIO NUMBER NOT NULL,
    ID_CLIENTE NUMBER,
    SUBTOTAL NUMBER(10,2) NOT NULL,
    DESCUENTO_TOTAL NUMBER(10,2) DEFAULT 0,
    TOTAL NUMBER(10,2) NOT NULL,
    ESTADO CHAR(1) DEFAULT 'A',
    FECHA_ANULACION DATE,
    ANULADA_POR NUMBER,
    CONSTRAINT CK_VENTAS_TOTAL CHECK (TOTAL >= 0),
    CONSTRAINT FK_VENTAS_USUARIO FOREIGN KEY (ID_USUARIO) REFERENCES USUARIOS(ID_USUARIO),
    CONSTRAINT FK_VENTAS_CLIENTE FOREIGN KEY (ID_CLIENTE) REFERENCES CLIENTES(ID_CLIENTE),
    CONSTRAINT FK_VENTAS_ESTADO FOREIGN KEY (ESTADO) REFERENCES DOM_ESTADOS_VENTA(CODIGO),
    CONSTRAINT FK_VENTAS_ANULADA_POR FOREIGN KEY (ANULADA_POR) REFERENCES USUARIOS(ID_USUARIO)
);

COMMENT ON TABLE VENTAS IS 'Cabecera de facturas';
COMMENT ON COLUMN VENTAS.ESTADO IS 'A=Activa, N=Anulada. Ver DOM_ESTADOS_VENTA';

-- ---------------------------------------------------
-- DETALLES_VENTAS
-- ---------------------------------------------------
CREATE TABLE DETALLES_VENTAS (
    ID_DETALLE NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_VENTA NUMBER NOT NULL,
    ID_PRODUCTO NUMBER NOT NULL,
    ID_LOTE NUMBER NOT NULL,
    CANTIDAD NUMBER(5) NOT NULL CHECK (CANTIDAD > 0),
    PRECIO_APLICADO NUMBER(10,2) NOT NULL,
    DESCUENTO_UNITARIO NUMBER(10,2) DEFAULT 0,
    CONSTRAINT FK_DETALLES_VENTA FOREIGN KEY (ID_VENTA) REFERENCES VENTAS(ID_VENTA),
    CONSTRAINT FK_DETALLES_PRODUCTO FOREIGN KEY (ID_PRODUCTO) REFERENCES PRODUCTOS(ID_PRODUCTO),
    CONSTRAINT FK_DETALLES_LOTE FOREIGN KEY (ID_LOTE) REFERENCES LOTES(ID_LOTE)
);

COMMENT ON TABLE DETALLES_VENTAS IS 'Trazabilidad de cada item vendido con producto y lote exacto';
COMMENT ON COLUMN DETALLES_VENTAS.ID_PRODUCTO IS 'Producto vendido (redundancia controlada para consultas rapidas)';

-- ---------------------------------------------------
-- AJUSTES_INVENTARIO
-- ---------------------------------------------------
CREATE TABLE AJUSTES_INVENTARIO (
    ID_AJUSTE NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_LOTE NUMBER NOT NULL,
    TIPO CHAR(1) NOT NULL,
    CANTIDAD NUMBER(6) NOT NULL,
    MOTIVO VARCHAR2(100) NOT NULL,
    FECHA_AJUSTE DATE DEFAULT SYSDATE NOT NULL,
    ID_RESPONSABLE NUMBER NOT NULL,
    CONSTRAINT FK_AJUSTES_LOTE FOREIGN KEY (ID_LOTE) REFERENCES LOTES(ID_LOTE),
    CONSTRAINT FK_AJUSTES_USUARIO FOREIGN KEY (ID_RESPONSABLE) REFERENCES USUARIOS(ID_USUARIO),
    CONSTRAINT FK_AJUSTES_TIPO FOREIGN KEY (TIPO) REFERENCES DOM_TIPOS_AJUSTE(CODIGO)
);

COMMENT ON TABLE AJUSTES_INVENTARIO IS 'Auditoria de mermas, averias y retiros';
COMMENT ON COLUMN AJUSTES_INVENTARIO.TIPO IS 'A=Averia, V=Vencido, R=RetiroLegal, C=ConteoCiclico. Ver DOM_TIPOS_AJUSTE';

-- ---------------------------------------------------
-- PARAMETROS_SISTEMA
-- ---------------------------------------------------
CREATE TABLE PARAMETROS_SISTEMA (
    ID_PARAMETRO NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    CLAVE VARCHAR2(40) NOT NULL UNIQUE,
    VALOR VARCHAR2(30) NOT NULL,
    DESCRIPCION VARCHAR2(80)
);

COMMENT ON TABLE PARAMETROS_SISTEMA IS 'Configuracion global del sistema';

-- ---------------------------------------------------
-- HISTORIAL_PARAMETROS
-- ---------------------------------------------------
CREATE TABLE HISTORIAL_PARAMETROS (
    ID_HISTORIAL NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    CLAVE_PARAMETRO VARCHAR2(40) NOT NULL,
    VALOR_ANTERIOR VARCHAR2(30) NOT NULL,
    VALOR_NUEVO VARCHAR2(30) NOT NULL,
    MOTIVO VARCHAR2(80) NOT NULL,
    FECHA_CAMBIO DATE DEFAULT SYSDATE NOT NULL,
    ID_USUARIO NUMBER NOT NULL,
    DIRECCION_IP VARCHAR2(15),
    CONSTRAINT FK_HP_USUARIO FOREIGN KEY (ID_USUARIO) REFERENCES USUARIOS(ID_USUARIO)
);

COMMENT ON TABLE HISTORIAL_PARAMETROS IS 'Auditoria de cambios en parametros del sistema';

-- ---------------------------------------------------
-- HISTORIAL_DESCUENTOS
-- ---------------------------------------------------
CREATE TABLE HISTORIAL_DESCUENTOS (
    ID_HISTORIAL NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_PRODUCTO NUMBER NOT NULL,
    CODIGO_PRODUCTO VARCHAR2(15) NOT NULL,
    NOMBRE_PRODUCTO VARCHAR2(80) NOT NULL,
    DESCUENTO_ANTERIOR NUMBER(3,2),
    DESCUENTO_NUEVO NUMBER(3,2),
    ACCION CHAR(1) NOT NULL,
    MOTIVO VARCHAR2(80) NOT NULL,
    FECHA_CAMBIO DATE DEFAULT SYSDATE NOT NULL,
    ID_USUARIO NUMBER NOT NULL,
    DIRECCION_IP VARCHAR2(15),
    CONSTRAINT FK_HD_PRODUCTO FOREIGN KEY (ID_PRODUCTO) REFERENCES PRODUCTOS(ID_PRODUCTO),
    CONSTRAINT FK_HD_USUARIO FOREIGN KEY (ID_USUARIO) REFERENCES USUARIOS(ID_USUARIO),
    CONSTRAINT FK_HD_ACCION FOREIGN KEY (ACCION) REFERENCES DOM_ACCIONES_HISTORIAL(CODIGO)
);

COMMENT ON TABLE HISTORIAL_DESCUENTOS IS 'Auditoria de descuentos individuales por producto';
COMMENT ON COLUMN HISTORIAL_DESCUENTOS.ACCION IS 'C=Crear, M=Modificar, E=Eliminar. Ver DOM_ACCIONES_HISTORIAL';

-- ---------------------------------------------------
-- ALERTAS_INFLACION
-- ---------------------------------------------------
CREATE TABLE ALERTAS_INFLACION (
    ID_ALERTA NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_PRODUCTO NUMBER NOT NULL,
    CODIGO_PRODUCTO VARCHAR2(15) NOT NULL,
    PRECIO_ANTERIOR NUMBER(10,2) NOT NULL,
    PRECIO_NUEVO NUMBER(10,2) NOT NULL,
    PORCENTAJE_INCREMENTO NUMBER(5,2) NOT NULL,
    FECHA_ALERTA DATE DEFAULT SYSDATE NOT NULL,
    ESTADO CHAR(1) DEFAULT 'P',
    ATENDIDA_POR NUMBER,
    FECHA_ATENCION DATE,
    CONSTRAINT FK_AI_PRODUCTO FOREIGN KEY (ID_PRODUCTO) REFERENCES PRODUCTOS(ID_PRODUCTO),
    CONSTRAINT FK_AI_USUARIO FOREIGN KEY (ATENDIDA_POR) REFERENCES USUARIOS(ID_USUARIO),
    CONSTRAINT FK_AI_ESTADO FOREIGN KEY (ESTADO) REFERENCES DOM_ESTADOS_ALERTA(CODIGO)
);

COMMENT ON TABLE ALERTAS_INFLACION IS 'Alertas por incremento de precios de proveedores';
COMMENT ON COLUMN ALERTAS_INFLACION.ESTADO IS 'P=Pendiente, A=Atendida. Ver DOM_ESTADOS_ALERTA';

-- ---------------------------------------------------
-- ALERTAS_FIDELIZACION
-- ---------------------------------------------------
CREATE TABLE ALERTAS_FIDELIZACION (
    ID_ALERTA NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ID_CLIENTE NUMBER NOT NULL,
    ID_PRODUCTO NUMBER,
    ID_LOTE NUMBER,
    TIPO_ALERTA CHAR(1) NOT NULL,
    MENSAJE VARCHAR2(200) NOT NULL,
    FECHA_ENVIO DATE DEFAULT SYSDATE,
    ESTADO CHAR(1) DEFAULT 'P',
    FECHA_LEIDA DATE,
    CONSTRAINT FK_AF_CLIENTE FOREIGN KEY (ID_CLIENTE) REFERENCES CLIENTES(ID_CLIENTE),
    CONSTRAINT FK_AF_PRODUCTO FOREIGN KEY (ID_PRODUCTO) REFERENCES PRODUCTOS(ID_PRODUCTO),
    CONSTRAINT FK_AF_LOTE FOREIGN KEY (ID_LOTE) REFERENCES LOTES(ID_LOTE),
    CONSTRAINT FK_AF_TIPO FOREIGN KEY (TIPO_ALERTA) REFERENCES DOM_TIPOS_ALERTA_FIDELIZACION(CODIGO),
    CONSTRAINT FK_AF_ESTADO FOREIGN KEY (ESTADO) REFERENCES DOM_ESTADOS_NOTIFICACION(CODIGO)
);

COMMENT ON TABLE ALERTAS_FIDELIZACION IS 'Notificaciones del programa de fidelizacion';
COMMENT ON COLUMN ALERTAS_FIDELIZACION.TIPO_ALERTA IS 'V=Vencimiento, R=Reposicion, S=Stock bajo, P=Personalizada';
COMMENT ON COLUMN ALERTAS_FIDELIZACION.ESTADO IS 'P=Pendiente envio, E=Enviada, L=Leida. Ver DOM_ESTADOS_NOTIFICACION';

COMMIT;

PROMPT ========================================
PROMPT Tablas creadas: 12 de negocio + 10 de dominio = 22
PROMPT ========================================
EXIT;