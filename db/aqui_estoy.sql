DROP DATABASE IF EXISTS aqui_estoy;
CREATE DATABASE aqui_estoy CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE aqui_estoy;
SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- ============================
-- USUARIOS, ROLES Y PERMISOS
-- ============================

CREATE TABLE usuarios (
  id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador del usuario',
  nombres             VARCHAR(80)  NOT NULL COMMENT 'Nombres',
  apellidos           VARCHAR(80)  NOT NULL COMMENT 'Apellidos',
  tipo_documento      ENUM('CC','TI','CE','PASAPORTE','OTRO') NULL COMMENT 'Tipo de documento de identidad',
  documento_identidad VARCHAR(20)  NULL COMMENT 'Número de documento de identidad',
  fecha_nacimiento    DATE         NULL COMMENT 'Fecha de nacimiento',
  telefono            VARCHAR(20)  NULL COMMENT 'Teléfono de contacto',
  correo              VARCHAR(150) NOT NULL COMMENT 'Correo electrónico (se usa para iniciar sesión)',
  contrasena_hash     VARCHAR(255) NOT NULL COMMENT 'Hash bcrypt/argon2 de la contraseña. Nunca la contraseña en texto plano',
  estado              ENUM('activo','inactivo','bloqueado') NOT NULL DEFAULT 'activo' COMMENT 'Estado del usuario',
  ultimo_acceso       DATETIME     NULL COMMENT 'Último inicio de sesión (UTC)',
  creado_en           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creación (UTC)',
  actualizado_en      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Fecha de última actualización (UTC)',
  PRIMARY KEY (id),
  UNIQUE KEY uq_usuarios_correo (correo),
  UNIQUE KEY uq_usuarios_documento (tipo_documento, documento_identidad)
) ENGINE=InnoDB COMMENT='Personas que inician sesión en la plataforma (administran o monitorean)';

CREATE TABLE roles (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador del rol',
  codigo      VARCHAR(50)  NOT NULL COMMENT 'Código interno estable',
  nombre      VARCHAR(80)  NOT NULL COMMENT 'Nombre visible del rol',
  descripcion VARCHAR(255) NULL COMMENT 'Descripción del rol',
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_codigo (codigo)
) ENGINE=InnoDB COMMENT='Catálogo de roles dentro de una cuenta familiar';

CREATE TABLE permisos (
  id          INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador del permiso',
  codigo      VARCHAR(80)  NOT NULL COMMENT 'Código interno estable',
  modulo      VARCHAR(40)  NOT NULL COMMENT 'Módulo al que pertenece',
  descripcion VARCHAR(255) NULL COMMENT 'Qué permite hacer',
  PRIMARY KEY (id),
  UNIQUE KEY uq_permisos_codigo (codigo)
) ENGINE=InnoDB COMMENT='Catálogo de acciones permitidas en el sistema';


-- =============================================
-- PLANES, NIVELES DE SERVICIO (MORA) Y CUENTAS
-- =============================================

CREATE TABLE miembros_cuenta (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador de la membresía',
  cuenta_id             BIGINT UNSIGNED NOT NULL COMMENT 'Cuenta',
  usuario_id            BIGINT UNSIGNED NOT NULL COMMENT 'Usuario que pertenece a la cuenta',
  rol_id                INT UNSIGNED    NOT NULL COMMENT 'Rol que tiene el usuario en ESTA cuenta',
  parentesco            VARCHAR(40)     NULL COMMENT 'Etiqueta libre: madre, padre, tía...',
  estado                ENUM('activo','invitado','suspendido','retirado') NOT NULL DEFAULT 'activo' COMMENT 'Estado de la membresía',
  invitado_por_usuario_id BIGINT UNSIGNED NULL COMMENT 'Quién lo agregó',
  creado_en             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de ingreso (UTC)',
  actualizado_en        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Última actualización (UTC)',
  PRIMARY KEY (id),
  UNIQUE KEY uq_miembro_cuenta_usuario (cuenta_id, usuario_id),
  KEY idx_miembros_usuario (usuario_id),
  KEY idx_miembros_rol (rol_id),
  CONSTRAINT fk_miembros_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id),
  CONSTRAINT fk_miembros_rol     FOREIGN KEY (rol_id)     REFERENCES roles (id),
  CONSTRAINT fk_miembros_invita  FOREIGN KEY (invitado_por_usuario_id) REFERENCES usuarios (id) ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Usuarios de una cuenta y su rol en ella (N:M cuentas-usuarios con rol)';


-- ===================================================
-- PERSONAS MONITOREADAS, DISPOSITIVOS Y ASIGNACIONES
-- ===================================================

CREATE TABLE personas_monitoreadas (
  id               BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador de la persona monitoreada',
  cuenta_id        BIGINT UNSIGNED NOT NULL COMMENT 'Cuenta a la que pertenece',
  usuario_id       BIGINT UNSIGNED NULL COMMENT 'Solo si la persona además tiene su propio usuario; NULL en la mayoría de casos',
  nombres          VARCHAR(80)  NOT NULL COMMENT 'Nombres',
  apellidos        VARCHAR(80)  NOT NULL COMMENT 'Apellidos',
  tipo             ENUM('nino','adulto_mayor','otro') NOT NULL COMMENT 'Tipo de persona monitoreada',
  parentesco       VARCHAR(40)  NULL COMMENT 'Etiqueta libre: hijo, abuela...',
  fecha_nacimiento DATE         NULL COMMENT 'Fecha de nacimiento',
  foto_url         VARCHAR(255) NULL COMMENT 'URL de la foto',
  notas            VARCHAR(500) NULL COMMENT 'Notas del cuidador',
  estado           ENUM('activa','pausada','archivada') NOT NULL DEFAULT 'activa' COMMENT 'Estado (no se borra, se archiva)',
  creado_en        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creación (UTC)',
  actualizado_en   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Última actualización (UTC)',
  PRIMARY KEY (id),
  UNIQUE KEY uq_personas_usuario (usuario_id),
  KEY idx_personas_cuenta_estado (cuenta_id, estado),
  CONSTRAINT fk_personas_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Niños o adultos mayores que se monitorean (no son necesariamente usuarios)';

CREATE TABLE dispositivos (
  id                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador del dispositivo',
  cuenta_id              BIGINT UNSIGNED NOT NULL COMMENT 'Cuenta dueña del dispositivo',
  usuario_propietario_id BIGINT UNSIGNED NOT NULL COMMENT 'Usuario que lo registró y responde por él',
  alias                  VARCHAR(80)  NULL COMMENT 'Nombre amigable (ej. Celular de Santiago)',
  tipo                   ENUM('celular','reloj_gps','pulsera_gps','rastreador_gps','otro') NOT NULL DEFAULT 'celular' COMMENT 'Tipo de dispositivo',
  marca                  VARCHAR(50)  NULL COMMENT 'Marca',
  modelo                 VARCHAR(80)  NULL COMMENT 'Modelo',
  imei                   VARCHAR(20)  NULL COMMENT 'IMEI si aplica',
  identificador_unico    VARCHAR(100) NOT NULL COMMENT 'ID único del hardware o de la instalación de la app',
  sistema_operativo      VARCHAR(30)  NULL COMMENT 'Android, iOS, firmware...',
  version_so             VARCHAR(30)  NULL COMMENT 'Versión del sistema operativo o firmware',
  version_app            VARCHAR(20)  NULL COMMENT 'Versión de la app instalada',
  clave_api_hash         VARCHAR(255) NULL COMMENT 'Hash de la clave con la que el dispositivo se autentica en la API',
  estado                 ENUM('activo','inactivo','bloqueado') NOT NULL DEFAULT 'activo' COMMENT 'Estado del dispositivo',
  ultima_conexion        DATETIME     NULL COMMENT 'Última vez que reportó datos (UTC)',
  nivel_bateria          TINYINT UNSIGNED NULL COMMENT 'Último nivel de batería conocido (0-100)',
  registrado_en          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de registro (UTC)',
  actualizado_en         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Última actualización (UTC)',
  PRIMARY KEY (id),
  UNIQUE KEY uq_dispositivos_identificador (identificador_unico),
  UNIQUE KEY uq_dispositivos_imei (imei),
  KEY idx_dispositivos_cuenta (cuenta_id, estado),
  KEY idx_dispositivos_propietario (usuario_propietario_id),
  CONSTRAINT fk_disp_propietario FOREIGN KEY (usuario_propietario_id) REFERENCES usuarios (id),
  CONSTRAINT chk_disp_bateria CHECK (nivel_bateria IS NULL OR nivel_bateria <= 100)
) ENGINE=InnoDB COMMENT='Hardware que reporta ubicación: hoy un celular, mañana pulsera o rastreador';

CREATE TABLE asignaciones_dispositivo (
  id                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador de la asignación',
  dispositivo_id         BIGINT UNSIGNED NOT NULL COMMENT 'Dispositivo',
  persona_monitoreada_id BIGINT UNSIGNED NOT NULL COMMENT 'Persona que lo lleva en ese periodo',
  asignado_desde         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Inicio de la asignación (UTC)',
  asignado_hasta         DATETIME NULL COMMENT 'Fin de la asignación. NULL = asignación vigente',
  asignado_por_usuario_id BIGINT UNSIGNED NULL COMMENT 'Quién hizo la asignación',
  vigente_clave          BIGINT UNSIGNED GENERATED ALWAYS AS (IF(asignado_hasta IS NULL, dispositivo_id, NULL)) STORED COMMENT 'Calculado: garantiza una sola asignación vigente por dispositivo',
  PRIMARY KEY (id),
  UNIQUE KEY uq_asignacion_vigente (vigente_clave),
  KEY idx_asig_persona (persona_monitoreada_id, asignado_hasta),
  KEY idx_asig_dispositivo (dispositivo_id, asignado_desde),
  CONSTRAINT fk_asig_dispositivo FOREIGN KEY (dispositivo_id) REFERENCES dispositivos (id),
  CONSTRAINT fk_asig_persona     FOREIGN KEY (persona_monitoreada_id) REFERENCES personas_monitoreadas (id),
  CONSTRAINT fk_asig_usuario     FOREIGN KEY (asignado_por_usuario_id) REFERENCES usuarios (id) ON DELETE SET NULL,
  CONSTRAINT chk_asig_fechas CHECK (asignado_hasta IS NULL OR asignado_hasta >= asignado_desde)
) ENGINE=InnoDB COMMENT='Historial de qué persona lleva cada dispositivo (permite cambiar sin perder historia)';


-- ============
-- UBICACIONES
-- ============

CREATE TABLE ubicaciones (
  id                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador de la ubicación',
  dispositivo_id         BIGINT UNSIGNED NOT NULL COMMENT 'Dispositivo que reportó',
  persona_monitoreada_id BIGINT UNSIGNED NOT NULL COMMENT 'Persona asignada al dispositivo cuando se capturó',
  latitud                DECIMAL(10,7) NOT NULL COMMENT 'Latitud en grados decimales',
  longitud               DECIMAL(10,7) NOT NULL COMMENT 'Longitud en grados decimales',
  precision_m            DECIMAL(7,2)  NULL COMMENT 'Precisión horizontal estimada (metros)',
  altitud_m              DECIMAL(7,2)  NULL COMMENT 'Altitud (metros)',
  velocidad_kmh          DECIMAL(6,2)  NULL COMMENT 'Velocidad (km/h)',
  rumbo_grados           DECIMAL(5,2)  NULL COMMENT 'Dirección de movimiento (0-360)',
  nivel_bateria          TINYINT UNSIGNED NULL COMMENT 'Batería al capturar (0-100)',
  estado                 ENUM('valida','baja_precision','descartada') NOT NULL DEFAULT 'valida' COMMENT 'Calidad de la lectura',
  capturada_en           DATETIME(3) NOT NULL COMMENT 'Momento exacto de captura en el dispositivo (UTC)',
  recibida_en            DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'Momento en que la recibió el servidor (UTC)',
  PRIMARY KEY (id),
  UNIQUE KEY uq_ubicaciones_disp_captura (dispositivo_id, capturada_en),
  CONSTRAINT fk_ubic_dispositivo FOREIGN KEY (dispositivo_id) REFERENCES dispositivos (id),
  CONSTRAINT fk_ubic_persona     FOREIGN KEY (persona_monitoreada_id) REFERENCES personas_monitoreadas (id)
) ENGINE=InnoDB COMMENT='Historial GPS (tabla grande: se purga según el plan)';

CREATE TABLE ultimas_ubicaciones (
  persona_monitoreada_id BIGINT UNSIGNED NOT NULL COMMENT 'Persona (una fila por persona)',
  dispositivo_id         BIGINT UNSIGNED NOT NULL COMMENT 'Dispositivo que reportó la última ubicación',
  latitud                DECIMAL(10,7) NOT NULL COMMENT 'Última latitud',
  longitud               DECIMAL(10,7) NOT NULL COMMENT 'Última longitud',
  precision_m            DECIMAL(7,2)  NULL COMMENT 'Precisión (metros)',
  velocidad_kmh          DECIMAL(6,2)  NULL COMMENT 'Velocidad (km/h)',
  nivel_bateria          TINYINT UNSIGNED NULL COMMENT 'Batería (0-100)',
  capturada_en           DATETIME(3) NOT NULL COMMENT 'Captura en el dispositivo (UTC)',
  recibida_en            DATETIME(3) NOT NULL COMMENT 'Recepción en el servidor (UTC)',
  actualizada_en         DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT 'Última vez que se actualizó la fila (UTC)',
  PRIMARY KEY (persona_monitoreada_id),
  KEY idx_ultimas_dispositivo (dispositivo_id),
  CONSTRAINT fk_ultimas_persona     FOREIGN KEY (persona_monitoreada_id) REFERENCES personas_monitoreadas (id) ON DELETE CASCADE,
  CONSTRAINT fk_ultimas_dispositivo FOREIGN KEY (dispositivo_id) REFERENCES dispositivos (id)
) ENGINE=InnoDB COMMENT='Copia de la última ubicación por persona: la app consulta aquí, no el historial';

-- ==============
-- ZONAS SEGURAS
-- ==============

CREATE TABLE zonas_seguras (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador de la zona',
  cuenta_id     BIGINT UNSIGNED NOT NULL COMMENT 'Cuenta dueña de la zona',
  nombre        VARCHAR(80)  NOT NULL COMMENT 'Nombre (Casa, Colegio...)',
  tipo          ENUM('casa','colegio','familiar','trabajo','otro') NOT NULL DEFAULT 'otro' COMMENT 'Tipo de lugar',
  direccion     VARCHAR(200) NULL COMMENT 'Dirección en texto (opcional)',
  latitud       DECIMAL(10,7) NOT NULL COMMENT 'Latitud del centro',
  longitud      DECIMAL(10,7) NOT NULL COMMENT 'Longitud del centro',
  radio_m       INT UNSIGNED NOT NULL COMMENT 'Radio en metros',
  estado        ENUM('activa','inactiva') NOT NULL DEFAULT 'activa' COMMENT 'Estado de la zona',
  creado_por_usuario_id BIGINT UNSIGNED NULL COMMENT 'Quién la creó',
  creado_en     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creación (UTC)',
  actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Última actualización (UTC)',
  PRIMARY KEY (id),
  UNIQUE KEY uq_zonas_cuenta_nombre (cuenta_id, nombre),
  CONSTRAINT fk_zonas_creador  FOREIGN KEY (creado_por_usuario_id) REFERENCES usuarios (id) ON DELETE SET NULL,
  CONSTRAINT chk_zonas_coord CHECK (latitud BETWEEN -90 AND 90 AND longitud BETWEEN -180 AND 180),
  CONSTRAINT chk_zonas_radio CHECK (radio_m BETWEEN 50 AND 5000)
) ENGINE=InnoDB COMMENT='Zonas circulares (centro + radio) definidas por la cuenta';

CREATE TABLE zonas_personas (
  id                       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador de la asignación',
  zona_segura_id           BIGINT UNSIGNED NOT NULL COMMENT 'Zona',
  persona_monitoreada_id   BIGINT UNSIGNED NOT NULL COMMENT 'Persona vigilada en esa zona',
  activa                   TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = se evalúa esta zona para la persona',
  notificar_entrada        TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Alertar al entrar',
  notificar_salida         TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Alertar al salir',
  minutos_fuera_para_alerta SMALLINT UNSIGNED NULL COMMENT 'Minutos fuera de la zona para alertar permanencia. NULL = no aplica',
  distancia_aviso_m        SMALLINT UNSIGNED NULL COMMENT 'Metros extra alrededor de la zona para avisar aproximación. NULL = no aplica',
  horario_inicio           TIME NULL COMMENT 'Inicio de la ventana en que se vigila. NULL = siempre',
  horario_fin              TIME NULL COMMENT 'Fin de la ventana en que se vigila',
  dentro_actualmente       TINYINT(1) NULL COMMENT 'Estado actual: 1 dentro, 0 fuera, NULL aún sin evaluar',
  estado_desde             DATETIME NULL COMMENT 'Desde cuándo está en ese estado (UTC)',
  permanencia_notificada   TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 si ya se envió la alerta de permanencia fuera',
  creado_en                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creación (UTC)',
  actualizado_en           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Última actualización (UTC)',
  PRIMARY KEY (id),
  UNIQUE KEY uq_zonaper_zona_persona (zona_segura_id, persona_monitoreada_id),
  KEY idx_zonaper_persona (persona_monitoreada_id, activa),
  CONSTRAINT fk_zonaper_zona    FOREIGN KEY (zona_segura_id) REFERENCES zonas_seguras (id) ON DELETE CASCADE,
  CONSTRAINT fk_zonaper_persona FOREIGN KEY (persona_monitoreada_id) REFERENCES personas_monitoreadas (id) ON DELETE CASCADE
) ENGINE=InnoDB COMMENT='Qué zonas vigila cada persona, su configuración y su estado dentro/fuera (N:M)';

-- =========================
-- ALERTAS Y NOTIFICACIONES
-- =========================

CREATE TABLE tipos_alerta (
  id                 INT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador del tipo',
  codigo             VARCHAR(40)  NOT NULL COMMENT 'Código interno (salida_zona, bateria_baja...)',
  nombre             VARCHAR(80)  NOT NULL COMMENT 'Nombre visible',
  categoria          ENUM('zona','dispositivo','seguridad','cuenta') NOT NULL COMMENT 'Agrupación',
  prioridad_defecto  ENUM('baja','media','alta','critica') NOT NULL DEFAULT 'media' COMMENT 'Prioridad con la que nace',
  activo             TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = el sistema puede generarla',
  descripcion        VARCHAR(255) NULL COMMENT 'Descripción',
  PRIMARY KEY (id),
  UNIQUE KEY uq_tipos_alerta_codigo (codigo)
) ENGINE=InnoDB COMMENT='Catálogo de tipos de alerta';

CREATE TABLE alertas (
  id                     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador de la alerta',
  cuenta_id              BIGINT UNSIGNED NOT NULL COMMENT 'Cuenta que debe recibirla',
  tipo_alerta_id         INT UNSIGNED NOT NULL COMMENT 'Tipo de alerta',
  prioridad              ENUM('baja','media','alta','critica') NOT NULL COMMENT 'Prioridad de esta alerta',
  persona_monitoreada_id BIGINT UNSIGNED NULL COMMENT 'Persona afectada (NULL en alertas de cuenta)',
  dispositivo_id         BIGINT UNSIGNED NULL COMMENT 'Dispositivo relacionado',
  zona_segura_id         BIGINT UNSIGNED NULL COMMENT 'Zona relacionada',
  ubicacion_id           BIGINT UNSIGNED NULL COMMENT 'Ubicación que la originó (se pone NULL si la ubicación se purga)',
  latitud                DECIMAL(10,7) NULL COMMENT 'Copia de la latitud del evento (sobrevive a la purga)',
  longitud               DECIMAL(10,7) NULL COMMENT 'Copia de la longitud del evento',
  mensaje                VARCHAR(255) NOT NULL COMMENT 'Texto que verá el usuario',
  datos                  JSON NULL COMMENT 'Datos adicionales del evento',
  estado                 ENUM('pendiente','atendida','descartada') NOT NULL DEFAULT 'pendiente' COMMENT 'Estado de atención',
  leida                  TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1 si algún miembro ya la vio',
  leida_en               DATETIME NULL COMMENT 'Cuándo se leyó (UTC)',
  atendida_por_usuario_id BIGINT UNSIGNED NULL COMMENT 'Quién la atendió',
  atendida_en            DATETIME NULL COMMENT 'Fecha de atención (UTC)',
  generada_en            DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'Fecha y hora de generación (UTC)',
  PRIMARY KEY (id),
  KEY idx_alertas_cuenta_estado (cuenta_id, estado, generada_en),
  KEY idx_alertas_persona (persona_monitoreada_id, generada_en),
  KEY idx_alertas_tipo (tipo_alerta_id),
  KEY idx_alertas_dispositivo (dispositivo_id),
  KEY idx_alertas_zona (zona_segura_id),
  KEY idx_alertas_ubicacion (ubicacion_id),
  CONSTRAINT fk_alertas_tipo        FOREIGN KEY (tipo_alerta_id) REFERENCES tipos_alerta (id),
  CONSTRAINT fk_alertas_persona     FOREIGN KEY (persona_monitoreada_id) REFERENCES personas_monitoreadas (id),
  CONSTRAINT fk_alertas_dispositivo FOREIGN KEY (dispositivo_id) REFERENCES dispositivos (id),
  CONSTRAINT fk_alertas_zona        FOREIGN KEY (zona_segura_id) REFERENCES zonas_seguras (id) ON DELETE SET NULL,
  CONSTRAINT fk_alertas_ubicacion   FOREIGN KEY (ubicacion_id) REFERENCES ubicaciones (id) ON DELETE SET NULL,
  CONSTRAINT fk_alertas_atendio     FOREIGN KEY (atendida_por_usuario_id) REFERENCES usuarios (id) ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Eventos importantes detectados por el sistema';

CREATE TABLE notificaciones (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador de la notificación',
  alerta_id      BIGINT UNSIGNED NOT NULL COMMENT 'Alerta que la originó',
  usuario_id     BIGINT UNSIGNED NOT NULL COMMENT 'Destinatario',
  canal          ENUM('app','correo','sms','whatsapp','push') NOT NULL COMMENT 'Canal de envío',
  estado         ENUM('pendiente','enviada','entregada','leida','fallida') NOT NULL DEFAULT 'pendiente' COMMENT 'Estado del envío',
  destino        VARCHAR(255) NULL COMMENT 'Correo, teléfono o token usado al enviar',
  intentos       TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Intentos de envío',
  id_externo     VARCHAR(120) NULL COMMENT 'ID del mensaje en el proveedor (SMS, correo, WhatsApp...)',
  ultimo_error   VARCHAR(255) NULL COMMENT 'Último error de envío',
  programada_en  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Cuándo debe enviarse (UTC)',
  enviada_en     DATETIME NULL COMMENT 'Cuándo se envió (UTC)',
  leida_en       DATETIME NULL COMMENT 'Cuándo la leyó el usuario (UTC)',
  creado_en      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creación (UTC)',
  PRIMARY KEY (id),
  UNIQUE KEY uq_notif_alerta_usuario_canal (alerta_id, usuario_id, canal),
  KEY idx_notif_cola (estado, canal, programada_en),
  KEY idx_notif_bandeja (usuario_id, canal, estado),
  CONSTRAINT fk_notif_alerta  FOREIGN KEY (alerta_id)  REFERENCES alertas (id) ON DELETE CASCADE,
  CONSTRAINT fk_notif_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
) ENGINE=InnoDB COMMENT='Un envío de una alerta a un usuario por un canal (bandeja y cola de envíos)';


-- ============================
-- SUSCRIPCIONES, PAGOS Y MORA
-- ============================

CREATE TABLE suscripciones (
  id                    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador de la suscripción',
  cuenta_id             BIGINT UNSIGNED NOT NULL COMMENT 'Cuenta suscrita',
  plan_id               INT UNSIGNED NOT NULL COMMENT 'Plan contratado',
  estado                ENUM('activa','vencida','cancelada') NOT NULL DEFAULT 'activa' COMMENT 'activa = al día; vencida = pasó la fecha sin pago; cancelada = terminó',
  fecha_inicio          DATE NOT NULL COMMENT 'Inicio de la suscripción',
  periodo_inicio        DATE NOT NULL COMMENT 'Inicio del periodo de facturación actual',
  fecha_vencimiento     DATE NULL COMMENT 'Fecha límite de pago del periodo actual. NULL en planes gratuitos',
  renovacion_automatica TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1 = se cobra de nuevo al vencer',
  cancelada_en          DATETIME NULL COMMENT 'Cuándo se canceló (UTC)',
  creado_en             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creación (UTC)',
  actualizado_en        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Última actualización (UTC)',
  vigente_clave         BIGINT UNSIGNED GENERATED ALWAYS AS (IF(estado IN ('activa','vencida'), cuenta_id, NULL)) STORED COMMENT 'Calculado: una sola suscripción vigente por cuenta',
  PRIMARY KEY (id),
  UNIQUE KEY uq_suscripcion_vigente (vigente_clave),
  KEY idx_susc_cuenta (cuenta_id, creado_en),
  KEY idx_susc_vencimiento (estado, fecha_vencimiento),
  KEY idx_susc_plan (plan_id)
) ENGINE=InnoDB COMMENT='Historial de planes contratados por cada cuenta (cambiar de plan = nueva fila)';

CREATE TABLE pagos (
  id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador del pago',
  cuenta_id           BIGINT UNSIGNED NOT NULL COMMENT 'Cuenta que paga',
  suscripcion_id      BIGINT UNSIGNED NOT NULL COMMENT 'Suscripción que se paga',
  usuario_id          BIGINT UNSIGNED NULL COMMENT 'Usuario que realizó el pago',
  proveedor           ENUM('wompi','mercado_pago','payu','stripe','manual') NOT NULL COMMENT 'Pasarela de pagos',
  referencia_interna  VARCHAR(60)  NOT NULL COMMENT 'Referencia generada por nuestro sistema y enviada a la pasarela',
  referencia_externa  VARCHAR(120) NULL COMMENT 'ID de la transacción en la pasarela',
  metodo_pago         ENUM('tarjeta','pse','nequi','efectivo','otro') NULL COMMENT 'Método (sin datos sensibles)',
  valor               DECIMAL(12,2) NOT NULL COMMENT 'Valor cobrado',
  moneda              CHAR(3) NOT NULL DEFAULT 'COP' COMMENT 'Moneda ISO 4217',
  estado              ENUM('pendiente','aprobado','rechazado','fallido','anulado','reembolsado') NOT NULL DEFAULT 'pendiente' COMMENT 'Estado de la transacción',
  periodo_desde       DATE NULL COMMENT 'Inicio del periodo que cubre el pago',
  periodo_hasta       DATE NULL COMMENT 'Fin del periodo que cubre el pago',
  fecha_pago          DATETIME NULL COMMENT 'Cuándo se aprobó (UTC)',
  respuesta_proveedor JSON NULL COMMENT 'Respuesta de la pasarela (sin datos de tarjeta)',
  creado_en           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de creación (UTC)',
  actualizado_en      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Última actualización (UTC)',
  PRIMARY KEY (id),
  UNIQUE KEY uq_pagos_ref_interna (referencia_interna),
  UNIQUE KEY uq_pagos_proveedor_ref (proveedor, referencia_externa),
  KEY idx_pagos_cuenta (cuenta_id, creado_en),
  KEY idx_pagos_suscripcion (suscripcion_id),
  KEY idx_pagos_estado (estado),
  KEY idx_pagos_usuario (usuario_id),
  CONSTRAINT fk_pagos_susc    FOREIGN KEY (suscripcion_id) REFERENCES suscripciones (id),
  CONSTRAINT fk_pagos_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE SET NULL,
  CONSTRAINT chk_pagos_valor CHECK (valor > 0)
) ENGINE=InnoDB COMMENT='Transacciones con la pasarela. Nunca datos de tarjeta';

CREATE TABLE moras (
  id                  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador del episodio de mora',
  cuenta_id           BIGINT UNSIGNED NOT NULL COMMENT 'Cuenta en mora',
  suscripcion_id      BIGINT UNSIGNED NOT NULL COMMENT 'Suscripción que venció',
  fecha_vencimiento   DATE NOT NULL COMMENT 'Fecha límite que no se cumplió',
  monto_adeudado      DECIMAL(12,2) NOT NULL COMMENT 'Valor adeudado',
  moneda              CHAR(3) NOT NULL DEFAULT 'COP' COMMENT 'Moneda ISO 4217',
  estado              ENUM('abierta','resuelta','cancelada') NOT NULL DEFAULT 'abierta' COMMENT 'Estado del episodio',
  nivel_alcanzado_id  TINYINT UNSIGNED NOT NULL COMMENT 'Nivel más alto al que llegó la mora',
  nivel_actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Último cambio de nivel (UTC)',
  iniciada_en         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Cuándo se detectó (UTC)',
  resuelta_en         DATETIME NULL COMMENT 'Cuándo terminó (UTC)',
  motivo_resolucion   ENUM('pago','cancelacion','condonacion') NULL COMMENT 'Cómo terminó',
  pago_resolucion_id  BIGINT UNSIGNED NULL COMMENT 'Pago que la resolvió',
  abierta_clave       BIGINT UNSIGNED GENERATED ALWAYS AS (IF(estado = 'abierta', cuenta_id, NULL)) STORED COMMENT 'Calculado: una sola mora abierta por cuenta',
  PRIMARY KEY (id),
  UNIQUE KEY uq_mora_abierta (abierta_clave),
  KEY idx_moras_cuenta (cuenta_id, iniciada_en),
  KEY idx_moras_suscripcion (suscripcion_id),
  KEY idx_moras_nivel (nivel_alcanzado_id),
  KEY idx_moras_pago (pago_resolucion_id),
  CONSTRAINT fk_moras_susc   FOREIGN KEY (suscripcion_id) REFERENCES suscripciones (id),
  CONSTRAINT fk_moras_pago   FOREIGN KEY (pago_resolucion_id) REFERENCES pagos (id) ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Historial de episodios de mora de cada cuenta';

-- ==========
-- AUDITORÍA
-- ==========

CREATE TABLE auditoria (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'Identificador del registro',
  usuario_id      BIGINT UNSIGNED NULL COMMENT 'Quien realizó la acción. NULL = el sistema',
  cuenta_id       BIGINT UNSIGNED NULL COMMENT 'Cuenta en cuyo contexto ocurrió',
  accion          VARCHAR(40)  NOT NULL COMMENT 'crear, modificar, eliminar, consultar, iniciar_sesion...',
  modulo          VARCHAR(40)  NOT NULL COMMENT 'Módulo: personas, zonas, ubicacion, pagos...',
  tabla_afectada  VARCHAR(64)  NULL COMMENT 'Tabla del registro afectado',
  registro_id     BIGINT UNSIGNED NULL COMMENT 'ID del registro afectado',
  descripcion     VARCHAR(255) NOT NULL COMMENT 'Texto legible de lo ocurrido',
  direccion_ip    VARCHAR(45)  NULL COMMENT 'IP de origen (IPv4 o IPv6)',
  user_agent      VARCHAR(255) NULL COMMENT 'Navegador o app',
  detalle         JSON NULL COMMENT 'Información adicional (valores antes/después, etc.)',
  creado_en       DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT 'Fecha y hora (UTC)',
  PRIMARY KEY (id),
  KEY idx_aud_usuario (usuario_id, creado_en),
  KEY idx_aud_cuenta (cuenta_id, creado_en),
  KEY idx_aud_modulo_accion (modulo, accion, creado_en),
  KEY idx_aud_registro (tabla_afectada, registro_id),
  CONSTRAINT fk_aud_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='Bitácora de acciones sensibles (solo se inserta, nunca se modifica)';


-- ==================================
-- ALTER TABLE e ÍNDICES ADICIONALES
-- ==================================

-- ---------- Catálogos: roles y permisos ----------
INSERT INTO roles (id, codigo, nombre, descripcion) VALUES
(1,'administrador_principal','Administrador principal','Dueño de la cuenta: control total, incluye pagos'),
(2,'administrador_secundario','Administrador secundario','Gestiona la cuenta, sin manejar la suscripción'),
(3,'familiar','Familiar','Ve la ubicación actual, zonas y alertas'),
(4,'cuidador','Responsable / cuidador','Como familiar, además ve historial y atiende alertas'),
(5,'usuario_basico','Usuario básico','Solo ubicación actual y alertas');

INSERT INTO permisos (id, codigo, modulo, descripcion) VALUES
(1,'ubicacion.ver_actual','ubicacion','Ver la última ubicación'),
(2,'ubicacion.ver_historial','ubicacion','Ver el historial de ubicaciones'),
(3,'personas.ver','personas','Ver personas monitoreadas'),
(4,'personas.gestionar','personas','Crear, editar y archivar personas monitoreadas'),
(5,'dispositivos.ver','dispositivos','Ver dispositivos'),
(6,'dispositivos.gestionar','dispositivos','Registrar, asignar y bloquear dispositivos'),
(7,'zonas.ver','zonas','Ver zonas seguras'),
(8,'zonas.gestionar','zonas','Crear, editar y eliminar zonas seguras'),
(9,'alertas.ver','alertas','Ver alertas'),
(10,'alertas.atender','alertas','Marcar alertas como atendidas'),
(11,'miembros.ver','miembros','Ver miembros de la cuenta'),
(12,'miembros.gestionar','miembros','Agregar, cambiar rol y retirar miembros'),
(13,'suscripcion.ver','suscripcion','Ver plan, pagos y estado de cuenta'),
(14,'suscripcion.gestionar','suscripcion','Cambiar de plan y pagar'),
(15,'auditoria.ver','auditoria','Consultar la bitácora de auditoría');


-- ---------- Catálogo: tipos de alerta ----------
INSERT INTO tipos_alerta (id, codigo, nombre, categoria, prioridad_defecto, descripcion) VALUES
(1,'salida_zona','Salió de zona segura','zona','alta','La persona salió de una zona segura'),
(2,'entrada_zona','Ingresó a zona segura','zona','baja','La persona entró a una zona segura'),
(3,'permanencia_fuera_zona','Permanece fuera de zona','zona','alta','Lleva más del tiempo configurado fuera de la zona'),
(4,'aproximacion_zona','Se acerca a zona segura','zona','baja','La persona se acerca a una zona segura'),
(5,'dispositivo_desconectado','Dispositivo desconectado','dispositivo','alta','El dispositivo dejó de reportar'),
(6,'dispositivo_reconectado','Dispositivo reconectado','dispositivo','baja','El dispositivo volvió a reportar'),
(7,'bateria_baja','Batería baja','dispositivo','media','Batería por debajo del umbral'),
(8,'gps_no_disponible','GPS no disponible','dispositivo','media','El dispositivo reporta sin señal GPS'),
(9,'movimiento_fuera_horario','Movimiento fuera de horario','seguridad','alta','Movimiento fuera del horario permitido'),
(10,'posible_riesgo','Posible situación de riesgo','seguridad','critica','Patrón que sugiere riesgo'),
(11,'cuenta_en_mora','Cuenta en mora','cuenta','alta','La suscripción venció sin pago'),
(12,'servicio_suspendido','Servicio suspendido','cuenta','critica','El servicio fue suspendido por mora');


-- ================
-- DATOS DE PRUEBA
-- ================

-- Contraseña "db_aqui_estoy"
SET @hash = '$2a$12$rAigqEE3EfFLLH.TRMX8qOMzSoO4on3acCEjY7hFcRfWPyZzZijh.'; 

INSERT INTO usuarios (id, nombres, apellidos, tipo_documento, documento_identidad, fecha_nacimiento, telefono, correo, contrasena_hash) VALUES
(1,'Laura','Pérez Restrepo','CC','43111222','1985-04-12','3001234567','laura.perez@example.com',@hash),
(2,'Andrés','Gómez Salazar','CC','71333444','1983-09-30','3007654321','andres.gomez@example.com',@hash),
(3,'Marcela','Pérez Restrepo','CC','43555666','1988-01-20','3012223344','marcela.perez@example.com',@hash),
(4,'Jorge','Rodríguez Cano','CC','98777888','1980-06-05','3105556677','jorge.rodriguez@example.com',@hash);

INSERT INTO miembros_cuenta (cuenta_id, usuario_id, rol_id, parentesco, invitado_por_usuario_id) VALUES
(1,1,1,'Madre',NULL),
(1,2,2,'Padre',1),
(1,3,4,'Tía',1),
(2,4,1,'Padre',NULL);

-- Personas monitoreadas (el hijo y la abuela NO son usuarios del sistema)
INSERT INTO personas_monitoreadas (id, cuenta_id, nombres, apellidos, tipo, parentesco, fecha_nacimiento) VALUES
(1,1,'Santiago','Gómez Pérez','nino','Hijo','2016-05-14'),
(2,1,'Rosa','Restrepo de Pérez','adulto_mayor','Abuela','1952-03-02'),
(3,2,'Mateo','Rodríguez Londoño','nino','Hijo','2015-11-23');

INSERT INTO dispositivos (id, cuenta_id, usuario_propietario_id, alias, tipo, marca, modelo, imei, identificador_unico, sistema_operativo, version_so, version_app, estado, ultima_conexion, nivel_bateria) VALUES
(1,1,1,'Celular de Santiago','celular','Samsung','Galaxy A54','356938035643809','android-8f3a1c9e22b04d77','Android','14','1.0.0','activo',UTC_TIMESTAMP() - INTERVAL 5 MINUTE,63),
(2,1,1,'Celular de la abuela','celular','Xiaomi','Redmi Note 12','867530051234567','android-51be77a0c4d93e18','Android','13','1.0.0','activo',UTC_TIMESTAMP() - INTERVAL 10 MINUTE,14),
(3,2,4,'Celular de Mateo','celular','Motorola','Moto G54','352099001761481','android-c93d0be7a1f2488a','Android','13','1.0.0','activo',UTC_TIMESTAMP() - INTERVAL 3 HOUR,41);

INSERT INTO asignaciones_dispositivo (dispositivo_id, persona_monitoreada_id, asignado_desde, asignado_hasta, asignado_por_usuario_id) VALUES
(1,1,UTC_TIMESTAMP() - INTERVAL 30 DAY,NULL,1),
(2,1,UTC_TIMESTAMP() - INTERVAL 60 DAY,UTC_TIMESTAMP() - INTERVAL 20 DAY,1),
(2,2,UTC_TIMESTAMP() - INTERVAL 20 DAY,NULL,1),
(3,3,UTC_TIMESTAMP() - INTERVAL 40 DAY,NULL,4);

-- Zonas seguras
INSERT INTO zonas_seguras (id, cuenta_id, nombre, tipo, direccion, latitud, longitud, radio_m, creado_por_usuario_id) VALUES
(1,1,'Casa','casa','Itagüí, Antioquia',6.1750000,-75.6100000,300,1),
(2,1,'Colegio','colegio','Itagüí, Antioquia',6.1810000,-75.6040000,150,1),
(3,1,'Casa de la abuela','familiar','Itagüí, Antioquia',6.1900000,-75.5990000,200,1),
(4,2,'Casa','casa','Medellín, Antioquia',6.2005000,-75.5720000,250,4);

-- Qué zonas vigila cada persona (y su estado actual dentro/fuera)
INSERT INTO zonas_personas (zona_segura_id, persona_monitoreada_id, notificar_entrada, notificar_salida, minutos_fuera_para_alerta, distancia_aviso_m, horario_inicio, horario_fin, dentro_actualmente, estado_desde) VALUES
(1,1,1,1,NULL,NULL,NULL,NULL,0,UTC_TIMESTAMP() - INTERVAL 120 MINUTE),
(2,1,1,1,15,100,'06:30:00','15:30:00',0,UTC_TIMESTAMP() - INTERVAL 5 MINUTE),
(3,1,0,1,NULL,NULL,NULL,NULL,0,UTC_TIMESTAMP() - INTERVAL 120 MINUTE),
(3,2,1,1,NULL,NULL,NULL,NULL,1,UTC_TIMESTAMP() - INTERVAL 20 DAY),
(4,3,1,1,NULL,NULL,NULL,NULL,1,UTC_TIMESTAMP() - INTERVAL 40 DAY);

-- Los ids 1 (hace 100 h) es MÁS VIEJO que 3 días: la purga lo elimina.
INSERT INTO ubicaciones (id, dispositivo_id, persona_monitoreada_id, latitud, longitud, precision_m, altitud_m, velocidad_kmh, rumbo_grados, nivel_bateria, estado, capturada_en, recibida_en) VALUES
(1, 1,1,6.1750100,-75.6100200,8.50,1560.0,0.00,NULL,90,'valida',UTC_TIMESTAMP(3) - INTERVAL 100 HOUR,UTC_TIMESTAMP(3) - INTERVAL 100 HOUR + INTERVAL 2 SECOND),
(2, 1,1,6.1750500,-75.6100800,9.00,1560.0,0.00,NULL,85,'valida',UTC_TIMESTAMP(3) - INTERVAL 50 HOUR, UTC_TIMESTAMP(3) - INTERVAL 50 HOUR + INTERVAL 2 SECOND),
(3, 1,1,6.1750300,-75.6100500,7.80,1560.0,0.00,NULL,80,'valida',UTC_TIMESTAMP(3) - INTERVAL 26 HOUR, UTC_TIMESTAMP(3) - INTERVAL 26 HOUR + INTERVAL 2 SECOND),
(4, 1,1,6.1751000,-75.6101000,6.20,1560.0,0.00,NULL,78,'valida',UTC_TIMESTAMP(3) - INTERVAL 180 MINUTE,UTC_TIMESTAMP(3) - INTERVAL 180 MINUTE + INTERVAL 2 SECOND),
(5, 1,1,6.1768000,-75.6075000,5.50,1561.0,18.50,62.00,74,'valida',UTC_TIMESTAMP(3) - INTERVAL 120 MINUTE,UTC_TIMESTAMP(3) - INTERVAL 120 MINUTE + INTERVAL 2 SECOND),
(6, 1,1,6.1790000,-75.6055000,5.00,1563.0,21.00,48.00,72,'valida',UTC_TIMESTAMP(3) - INTERVAL 90 MINUTE, UTC_TIMESTAMP(3) - INTERVAL 90 MINUTE + INTERVAL 2 SECOND),
(7, 1,1,6.1811000,-75.6041000,4.80,1566.0,3.00,40.00,70,'valida',UTC_TIMESTAMP(3) - INTERVAL 60 MINUTE, UTC_TIMESTAMP(3) - INTERVAL 60 MINUTE + INTERVAL 2 SECOND),
(8, 1,1,6.1812000,-75.6039000,4.50,1566.0,0.00,NULL,68,'valida',UTC_TIMESTAMP(3) - INTERVAL 30 MINUTE, UTC_TIMESTAMP(3) - INTERVAL 30 MINUTE + INTERVAL 2 SECOND),
(9, 1,1,6.1840000,-75.6020000,6.00,1568.0,14.00,40.00,63,'valida',UTC_TIMESTAMP(3) - INTERVAL 5 MINUTE,  UTC_TIMESTAMP(3) - INTERVAL 5 MINUTE + INTERVAL 2 SECOND),

(10,2,2,6.1901000,-75.5991000,10.00,1570.0,0.00,NULL,55,'valida',UTC_TIMESTAMP(3) - INTERVAL 26 HOUR, UTC_TIMESTAMP(3) - INTERVAL 26 HOUR + INTERVAL 2 SECOND),
(11,2,2,6.1901000,-75.5991000,9.00,1570.0,0.00,NULL,22,'valida',UTC_TIMESTAMP(3) - INTERVAL 40 MINUTE, UTC_TIMESTAMP(3) - INTERVAL 40 MINUTE + INTERVAL 2 SECOND),
(12,2,2,6.1900000,-75.5990000,35.00,1570.0,0.00,NULL,14,'baja_precision',UTC_TIMESTAMP(3) - INTERVAL 10 MINUTE, UTC_TIMESTAMP(3) - INTERVAL 10 MINUTE + INTERVAL 2 SECOND),

(13,3,3,6.2005000,-75.5720000,7.00,1520.0,0.00,NULL,41,'valida',UTC_TIMESTAMP(3) - INTERVAL 3 HOUR, UTC_TIMESTAMP(3) - INTERVAL 3 HOUR + INTERVAL 2 SECOND);

-- Última ubicación por persona (el backend la actualiza con UPSERT al recibir cada punto)
INSERT INTO ultimas_ubicaciones (persona_monitoreada_id, dispositivo_id, latitud, longitud, precision_m, velocidad_kmh, nivel_bateria, capturada_en, recibida_en)
SELECT persona_monitoreada_id, dispositivo_id, latitud, longitud, precision_m, velocidad_kmh, nivel_bateria, capturada_en, recibida_en
FROM ubicaciones WHERE id IN (9,12,13);

-- Alertas
INSERT INTO alertas (id, cuenta_id, tipo_alerta_id, prioridad, persona_monitoreada_id, dispositivo_id, zona_segura_id, ubicacion_id, latitud, longitud, mensaje, estado, leida, leida_en, atendida_por_usuario_id, atendida_en, generada_en) VALUES
(1,1,1,'media',1,1,1,5,6.1768000,-75.6075000,'Santiago salió de la zona segura "Casa"','atendida',1,UTC_TIMESTAMP() - INTERVAL 118 MINUTE,1,UTC_TIMESTAMP() - INTERVAL 117 MINUTE,UTC_TIMESTAMP(3) - INTERVAL 120 MINUTE),
(2,1,2,'baja',1,1,2,7,6.1811000,-75.6041000,'Santiago llegó a la zona segura "Colegio"','atendida',1,UTC_TIMESTAMP() - INTERVAL 59 MINUTE,2,UTC_TIMESTAMP() - INTERVAL 58 MINUTE,UTC_TIMESTAMP(3) - INTERVAL 60 MINUTE),
(3,1,1,'alta',1,1,2,9,6.1840000,-75.6020000,'Santiago salió de la zona segura "Colegio"','pendiente',0,NULL,NULL,NULL,UTC_TIMESTAMP(3) - INTERVAL 5 MINUTE),
(4,1,7,'media',2,2,NULL,12,6.1900000,-75.5990000,'La batería del celular de Rosa está en 14%','pendiente',0,NULL,NULL,NULL,UTC_TIMESTAMP(3) - INTERVAL 10 MINUTE),
(5,2,5,'alta',3,3,NULL,NULL,6.2005000,-75.5720000,'El celular de Mateo lleva 3 horas sin reportar','pendiente',0,NULL,NULL,NULL,UTC_TIMESTAMP(3) - INTERVAL 150 MINUTE),
(6,2,11,'alta',NULL,NULL,NULL,NULL,NULL,NULL,'Tu suscripción venció. Realiza el pago para evitar restricciones','pendiente',1,UTC_TIMESTAMP() - INTERVAL 10 DAY,NULL,NULL,UTC_TIMESTAMP(3) - INTERVAL 11 DAY);

-- Notificaciones
INSERT INTO notificaciones (alerta_id, usuario_id, canal, estado, destino, intentos, enviada_en, leida_en) VALUES
(3,1,'app','enviada',NULL,1,UTC_TIMESTAMP() - INTERVAL 5 MINUTE,NULL),
(3,1,'push','entregada','fcm-ejemplo-laura-0001',1,UTC_TIMESTAMP() - INTERVAL 5 MINUTE,NULL),
(3,2,'app','pendiente',NULL,0,NULL,NULL),
(3,1,'correo','fallida','laura.perez@example.com',3,NULL,NULL),
(4,1,'app','enviada',NULL,1,UTC_TIMESTAMP() - INTERVAL 10 MINUTE,NULL),
(6,4,'correo','enviada','jorge.rodriguez@example.com',1,UTC_TIMESTAMP() - INTERVAL 11 DAY,UTC_TIMESTAMP() - INTERVAL 10 DAY);
UPDATE notificaciones SET ultimo_error = 'Buzón no disponible (simulado)' WHERE estado = 'fallida';

-- Suscripciones
INSERT INTO suscripciones (id, cuenta_id, plan_id, estado, fecha_inicio, periodo_inicio, fecha_vencimiento) VALUES
(1,1,2,'activa',UTC_DATE() - INTERVAL 70 DAY,UTC_DATE() - INTERVAL 10 DAY,UTC_DATE() + INTERVAL 20 DAY),
(2,2,2,'vencida',UTC_DATE() - INTERVAL 72 DAY,UTC_DATE() - INTERVAL 42 DAY,UTC_DATE() - INTERVAL 12 DAY);

-- Pagos
INSERT INTO pagos (id, cuenta_id, suscripcion_id, usuario_id, proveedor, referencia_interna, referencia_externa, metodo_pago, valor, moneda, estado, periodo_desde, periodo_hasta, fecha_pago) VALUES
(1,1,1,1,'wompi','AE-0001','wompi-tx-11001-aaaa','tarjeta',12900,'COP','aprobado',UTC_DATE() - INTERVAL 70 DAY,UTC_DATE() - INTERVAL 40 DAY,UTC_TIMESTAMP() - INTERVAL 70 DAY),
(2,1,1,1,'wompi','AE-0002','wompi-tx-11002-bbbb','pse',12900,'COP','aprobado',UTC_DATE() - INTERVAL 40 DAY,UTC_DATE() - INTERVAL 10 DAY,UTC_TIMESTAMP() - INTERVAL 37 DAY),
(3,1,1,1,'wompi','AE-0003','wompi-tx-11003-cccc','tarjeta',12900,'COP','aprobado',UTC_DATE() - INTERVAL 10 DAY,UTC_DATE() + INTERVAL 20 DAY,UTC_TIMESTAMP() - INTERVAL 10 DAY),
(4,2,2,4,'wompi','AE-0004','wompi-tx-22001-dddd','tarjeta',12900,'COP','aprobado',UTC_DATE() - INTERVAL 72 DAY,UTC_DATE() - INTERVAL 42 DAY,UTC_TIMESTAMP() - INTERVAL 72 DAY),
(5,2,2,4,'wompi','AE-0005','wompi-tx-22002-eeee','tarjeta',12900,'COP','rechazado',UTC_DATE() - INTERVAL 12 DAY,UTC_DATE() + INTERVAL 18 DAY,NULL);

-- Moras
INSERT INTO moras (cuenta_id, suscripcion_id, fecha_vencimiento, monto_adeudado, estado, nivel_alcanzado_id, nivel_actualizado_en, iniciada_en, resuelta_en, motivo_resolucion, pago_resolucion_id) VALUES
(1,1,UTC_DATE() - INTERVAL 40 DAY,12900,'resuelta',2,UTC_TIMESTAMP() - INTERVAL 39 DAY,UTC_TIMESTAMP() - INTERVAL 39 DAY,UTC_TIMESTAMP() - INTERVAL 37 DAY,'pago',2),
(2,2,UTC_DATE() - INTERVAL 12 DAY,12900,'abierta',3,UTC_TIMESTAMP() - INTERVAL 8 DAY,UTC_TIMESTAMP() - INTERVAL 11 DAY,NULL,NULL,NULL);

-- Auditoría
INSERT INTO auditoria (usuario_id, cuenta_id, accion, modulo, tabla_afectada, registro_id, descripcion, direccion_ip, detalle, creado_en) VALUES
(1,1,'crear','cuentas','cuentas',1,'Laura creó la cuenta Familia Pérez','190.85.10.21',NULL,UTC_TIMESTAMP() - INTERVAL 70 DAY),
(1,1,'crear','personas','personas_monitoreadas',1,'Laura agregó a su hijo Santiago','190.85.10.21','{"parentesco":"Hijo"}',UTC_TIMESTAMP() - INTERVAL 69 DAY),
(1,1,'crear','zonas','zonas_seguras',2,'Laura creó la zona segura Colegio','190.85.10.21','{"radio_m":150}',UTC_TIMESTAMP() - INTERVAL 68 DAY),
(1,1,'eliminar','zonas','zonas_seguras',99,'Laura eliminó la zona segura Gimnasio','190.85.10.21','{"nombre":"Gimnasio"}',UTC_TIMESTAMP() - INTERVAL 5 DAY),
(2,1,'consultar','ubicacion','personas_monitoreadas',1,'Andrés consultó la ubicación de Santiago','181.58.44.7',NULL,UTC_TIMESTAMP() - INTERVAL 2 HOUR),
(NULL,2,'crear','mora','moras',2,'El sistema abrió una mora por suscripción vencida',NULL,'{"dias_vencidos":1}',UTC_TIMESTAMP() - INTERVAL 11 DAY),
(4,2,'modificar','usuarios','usuarios',4,'Jorge actualizó su teléfono','186.29.1.88','{"campo":"telefono"}',UTC_TIMESTAMP() - INTERVAL 20 DAY);



-- =================================================================================
--  CONSULTAS DE PRUEBA  (ejecutar después de 01_esquema.sql y 02_datos_prueba.sql)
-- =================================================================================

-- SET time_zone = '+00:00';

-- -- Variables para no repetir ids
-- SET @cuenta_id  = (SELECT id FROM cuentas WHERE nombre = 'Familia Pérez');
-- SET @persona_id = (SELECT id FROM personas_monitoreadas WHERE nombres = 'Santiago' AND cuenta_id = @cuenta_id);

-- -- Última ubicación de una persona (lee la tabla pequeña, no el historial)
-- SELECT p.nombres, u.latitud, u.longitud, u.precision_m, u.velocidad_kmh, u.nivel_bateria, u.capturada_en
-- FROM ultimas_ubicaciones u
-- JOIN personas_monitoreadas p ON p.id = u.persona_monitoreada_id
-- WHERE u.persona_monitoreada_id = @persona_id;

-- -- Historial de ubicación de los últimos 3 días
-- SELECT id, latitud, longitud, velocidad_kmh, capturada_en
-- FROM ubicaciones
-- WHERE persona_monitoreada_id = @persona_id
--   AND capturada_en >= UTC_TIMESTAMP(3) - INTERVAL 3 DAY
-- ORDER BY capturada_en DESC;

-- -- Igual, pero con los días que permite el plan de la cuenta
-- SELECT u.id, u.latitud, u.longitud, u.capturada_en
-- FROM ubicaciones u
-- JOIN personas_monitoreadas p ON p.id = u.persona_monitoreada_id
-- JOIN vista_retencion_cuenta r ON r.cuenta_id = p.cuenta_id
-- WHERE u.persona_monitoreada_id = @persona_id
--   AND (r.retencion_dias IS NULL OR u.capturada_en >= UTC_TIMESTAMP(3) - INTERVAL r.retencion_dias DAY)
-- ORDER BY u.capturada_en DESC;

-- -- Personas monitoreadas de una familia
-- SELECT p.id, p.nombres, p.apellidos, p.tipo, p.parentesco, p.estado
-- FROM personas_monitoreadas p
-- WHERE p.cuenta_id = @cuenta_id AND p.estado <> 'archivada';

-- -- Dispositivos asociados (con la persona que lo lleva ahora)
-- SELECT d.id, d.alias, d.tipo, d.marca, d.modelo, d.estado, d.ultima_conexion, d.nivel_bateria,
--       CONCAT(p.nombres, ' ', p.apellidos) AS persona_actual
-- FROM dispositivos d
-- LEFT JOIN asignaciones_dispositivo a ON a.dispositivo_id = d.id AND a.asignado_hasta IS NULL
-- LEFT JOIN personas_monitoreadas p ON p.id = a.persona_monitoreada_id
-- WHERE d.cuenta_id = @cuenta_id;

-- -- Zonas seguras de la cuenta y a qué personas están asignadas
-- SELECT z.id, z.nombre, z.tipo, z.latitud, z.longitud, z.radio_m, z.estado,
--       GROUP_CONCAT(p.nombres ORDER BY p.nombres SEPARATOR ', ') AS personas
-- FROM zonas_seguras z
-- LEFT JOIN zonas_personas zp ON zp.zona_segura_id = z.id AND zp.activa = 1
-- LEFT JOIN personas_monitoreadas p ON p.id = zp.persona_monitoreada_id
-- WHERE z.cuenta_id = @cuenta_id
-- GROUP BY z.id, z.nombre, z.tipo, z.latitud, z.longitud, z.radio_m, z.estado;

-- -- Alertas pendientes de la cuenta (las más graves primero)
-- SELECT a.id, t.nombre AS tipo, a.prioridad, p.nombres AS persona, a.mensaje, a.generada_en
-- FROM alertas a
-- JOIN tipos_alerta t ON t.id = a.tipo_alerta_id
-- LEFT JOIN personas_monitoreadas p ON p.id = a.persona_monitoreada_id
-- WHERE a.cuenta_id = @cuenta_id AND a.estado = 'pendiente'
-- ORDER BY FIELD(a.prioridad,'critica','alta','media','baja'), a.generada_en DESC;

-- -- ¿La persona salió de alguna zona segura? (distancia de su última ubicación al centro de cada zona)
-- SELECT z.nombre AS zona,
--       ROUND(ST_Distance_Sphere(POINT(u.longitud, u.latitud), POINT(z.longitud, z.latitud))) AS distancia_m,
--       z.radio_m,
--       IF(ST_Distance_Sphere(POINT(u.longitud, u.latitud), POINT(z.longitud, z.latitud)) > z.radio_m, 'FUERA', 'DENTRO') AS situacion
-- FROM ultimas_ubicaciones u
-- JOIN zonas_personas zp ON zp.persona_monitoreada_id = u.persona_monitoreada_id AND zp.activa = 1
-- JOIN zonas_seguras z   ON z.id = zp.zona_segura_id AND z.estado = 'activa'
-- WHERE u.persona_monitoreada_id = @persona_id;

-- -- Alertas de salida de zona registradas en las últimas 24 horas
-- SELECT a.generada_en, p.nombres, z.nombre AS zona, a.estado
-- FROM alertas a
-- JOIN tipos_alerta t ON t.id = a.tipo_alerta_id AND t.codigo = 'salida_zona'
-- JOIN personas_monitoreadas p ON p.id = a.persona_monitoreada_id
-- LEFT JOIN zonas_seguras z ON z.id = a.zona_segura_id
-- WHERE a.persona_monitoreada_id = @persona_id
--   AND a.generada_en >= UTC_TIMESTAMP(3) - INTERVAL 24 HOUR
-- ORDER BY a.generada_en DESC;

-- -- Estado de la suscripción de cada cuenta
-- SELECT c.nombre AS cuenta, pl.nombre AS plan, s.estado, s.periodo_inicio, s.fecha_vencimiento,
--       DATEDIFF(s.fecha_vencimiento, UTC_DATE()) AS dias_para_vencer
-- FROM cuentas c
-- JOIN suscripciones s ON s.cuenta_id = c.id AND s.estado IN ('activa','vencida')
-- JOIN planes pl ON pl.id = s.plan_id;

-- -- ¿Cuentas en mora? (mora abierta + nivel actual + días vencidos)
-- SELECT c.nombre AS cuenta, n.nombre AS nivel_actual,
--       m.fecha_vencimiento, DATEDIFF(UTC_DATE(), m.fecha_vencimiento) AS dias_vencidos, m.monto_adeudado
-- FROM cuentas c
-- JOIN niveles_servicio n ON n.id = c.nivel_servicio_id
-- LEFT JOIN moras m ON m.cuenta_id = c.id AND m.estado = 'abierta';

-- -- Historial de moras de una cuenta
-- SELECT m.id, m.fecha_vencimiento, m.monto_adeudado, m.estado, n.nombre AS nivel_maximo,
--       m.iniciada_en, m.resuelta_en, m.motivo_resolucion
-- FROM moras m JOIN niveles_servicio n ON n.id = m.nivel_alcanzado_id
-- WHERE m.cuenta_id = @cuenta_id ORDER BY m.iniciada_en DESC;

-- -- Historial de pagos de una cuenta
-- SELECT pg.id, pg.fecha_pago, pg.proveedor, pg.metodo_pago, pg.valor, pg.moneda, pg.estado, pg.referencia_externa
-- FROM pagos pg
-- WHERE pg.cuenta_id = @cuenta_id
-- ORDER BY pg.creado_en DESC;

-- -- Restricciones actuales de una cuenta (el backend las aplica)
-- -- Prueba con la cuenta en mora para ver restricciones reales:
-- SET @cuenta_mora = (SELECT id FROM cuentas WHERE nombre = 'Familia Rodríguez');
-- SELECT c.nombre AS cuenta, n.nombre AS nivel, r.funcionalidad, IF(r.permitido = 1, 'PERMITIDO', 'BLOQUEADO') AS acceso
-- FROM cuentas c
-- JOIN niveles_servicio n ON n.id = c.nivel_servicio_id
-- JOIN restricciones_nivel r ON r.nivel_servicio_id = n.id
-- WHERE c.id = @cuenta_mora
-- ORDER BY r.funcionalidad;

-- -- Auditoría: quién realizó una acción
-- SELECT a.creado_en, COALESCE(CONCAT(u.nombres, ' ', u.apellidos), 'Sistema') AS quien,
--       a.accion, a.modulo, a.descripcion, a.direccion_ip
-- FROM auditoria a
-- LEFT JOIN usuarios u ON u.id = a.usuario_id
-- WHERE a.cuenta_id = @cuenta_id AND a.accion = 'eliminar' AND a.modulo = 'zonas'
-- ORDER BY a.creado_en DESC;

-- -- Extra: permisos efectivos de un usuario en una cuenta
-- SELECT u.nombres, r.nombre AS rol, p.codigo AS permiso
-- FROM miembros_cuenta m
-- JOIN usuarios u ON u.id = m.usuario_id
-- JOIN roles r ON r.id = m.rol_id
-- JOIN rol_permisos rp ON rp.rol_id = r.id
-- JOIN permisos p ON p.id = rp.permiso_id
-- WHERE m.cuenta_id = @cuenta_id AND u.correo = 'marcela.perez@example.com' AND m.estado = 'activo'
-- ORDER BY p.codigo;

-- Extra: guardar una ubicación nueva y actualizar la última (lo hace el backend en una transacción)
-- START TRANSACTION;
--   INSERT INTO ubicaciones (dispositivo_id, persona_monitoreada_id, latitud, longitud, precision_m, capturada_en)
--   VALUES (1, 1, 6.1850000, -75.6010000, 6.0, UTC_TIMESTAMP(3));
--   INSERT INTO ultimas_ubicaciones (persona_monitoreada_id, dispositivo_id, latitud, longitud, precision_m, capturada_en, recibida_en)
--   VALUES (1, 1, 6.1850000, -75.6010000, 6.0, UTC_TIMESTAMP(3), UTC_TIMESTAMP(3))
--   ON DUPLICATE KEY UPDATE
--     dispositivo_id = IF(VALUES(capturada_en) > capturada_en, VALUES(dispositivo_id), dispositivo_id),
--     latitud        = IF(VALUES(capturada_en) > capturada_en, VALUES(latitud), latitud),
--     longitud       = IF(VALUES(capturada_en) > capturada_en, VALUES(longitud), longitud),
--     precision_m    = IF(VALUES(capturada_en) > capturada_en, VALUES(precision_m), precision_m),
--     recibida_en    = IF(VALUES(capturada_en) > capturada_en, VALUES(recibida_en), recibida_en),
--     capturada_en   = GREATEST(capturada_en, VALUES(capturada_en));
-- COMMIT;

-- 15. Extra: limpiar historial vencido (lo normal es que lo llame el backend cada hora)
-- CALL purgar_ubicaciones(5000, @eliminadas);
-- SELECT @eliminadas AS ubicaciones_eliminadas;
