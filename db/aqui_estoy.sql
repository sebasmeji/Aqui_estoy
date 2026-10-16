USE aqui_estoy;

SET NAMES utf8mb4;

SET time_zone = '+00:00';

-- 1. TABLA: usuarios
CREATE TABLE usuarios (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombres VARCHAR(80) NOT NULL,
    apellidos VARCHAR(80) NOT NULL,
    tipo_documento ENUM(
        'CC',
        'TI',
        'CE',
        'PASAPORTE',
        'OTRO'
    ) NULL,
    documento_identidad VARCHAR(20) NULL,
    telefono VARCHAR(20) NULL,
    correo VARCHAR(150) NOT NULL,
    estado ENUM(
        'activo',
        'inactivo',
        'bloqueado'
    ) NOT NULL DEFAULT 'activo',
    parentesco ENUM(
        'madre',
        'padre',
        'hijo',
        'abuela',
        'otro'
    ) NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_usuarios_correo (correo),
    UNIQUE KEY uq_usuarios_documento (
        tipo_documento,
        documento_identidad
    )
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'Personas que administran o monitorean la plataforma';

-- 2. TABLA: dispositivos
CREATE TABLE dispositivos (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tipo ENUM(
        'celular',
        'tablet',
        'rastreador',
        'otro'
    ) NOT NULL DEFAULT 'celular',
    estado ENUM(
        'activo',
        'inactivo',
        'bloqueado'
    ) NOT NULL DEFAULT 'activo',
    ultima_conexion DATETIME NULL,
    PRIMARY KEY (id),
    KEY idx_dispositivos_estado (estado),
    KEY idx_dispositivos_ultima_conexion (ultima_conexion)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'Dispositivos que reportan la ubicación';

-- 3. TABLA: ubicaciones
CREATE TABLE ubicaciones (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    dispositivos_id BIGINT UNSIGNED NOT NULL,
    usuarios_id BIGINT UNSIGNED NOT NULL,
    latitud DECIMAL(10, 7) NOT NULL,
    longitud DECIMAL(10, 7) NOT NULL,
    precision_m DECIMAL(7, 2) NULL,
    altitud_m DECIMAL(7, 2) NULL,
    velocidad_kmh DECIMAL(6, 2) NULL,
    rumbo_grados DECIMAL(5, 2) NULL,
    nivel_bateria TINYINT UNSIGNED NULL,
    PRIMARY KEY (id),
    KEY idx_ubicaciones_dispositivo (dispositivos_id),
    KEY idx_ubicaciones_usuario (usuarios_id),
    CONSTRAINT fk_ubicaciones_dispositivo FOREIGN KEY (dispositivos_id) REFERENCES dispositivos (id),
    CONSTRAINT fk_ubicaciones_usuario FOREIGN KEY (usuarios_id) REFERENCES usuarios (id),
    CONSTRAINT chk_ubicaciones_latitud CHECK (latitud BETWEEN -90 AND 90),
    CONSTRAINT chk_ubicaciones_longitud CHECK (longitud BETWEEN -180 AND 180),
    CONSTRAINT chk_ubicaciones_bateria CHECK (
        nivel_bateria IS NULL
        OR nivel_bateria <= 100
    ),
    CONSTRAINT chk_ubicaciones_velocidad CHECK (
        velocidad_kmh IS NULL
        OR velocidad_kmh >= 0
    ),
    CONSTRAINT chk_ubicaciones_precision CHECK (
        precision_m IS NULL
        OR precision_m >= 0
    ),
    CONSTRAINT chk_ubicaciones_rumbo CHECK (
        rumbo_grados IS NULL
        OR rumbo_grados BETWEEN 0 AND 360
    )
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'Historial de ubicaciones GPS';

-- 4. TABLA: zonas_seguras
CREATE TABLE zonas_seguras (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre_zona VARCHAR(80) NOT NULL,
    tipo_zona ENUM(
        'casa',
        'colegio',
        'familiar',
        'trabajo',
        'otro'
    ) NOT NULL DEFAULT 'otro',
    estado ENUM('activa', 'inactiva') NOT NULL DEFAULT 'activa',
    actualizado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    KEY idx_zonas_nombre (nombre_zona),
    KEY idx_zonas_estado (estado)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'Zonas seguras registradas en la plataforma';

-- 5. TABLA: notificaciones
CREATE TABLE notificaciones (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    usuario_id BIGINT UNSIGNED NOT NULL,
    canal ENUM(
        'app',
        'correo',
        'sms',
        'whatsapp'
    ) NOT NULL,
    estado ENUM(
        'pendiente',
        'enviada',
        'entregada',
        'leida',
        'fallida'
    ) NOT NULL DEFAULT 'pendiente',
    intentos TINYINT UNSIGNED NOT NULL DEFAULT 3,
    PRIMARY KEY (id),
    KEY idx_notificaciones_usuario (usuario_id),
    KEY idx_notificaciones_cola (estado, canal),
    CONSTRAINT fk_notificaciones_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'Notificaciones dirigidas a los usuarios';

-- 6. TABLA: suscripciones
CREATE TABLE suscripciones (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    usuarios_id BIGINT UNSIGNED NOT NULL,
    estado ENUM(
        'activa',
        'vencida',
        'cancelada'
    ) NOT NULL DEFAULT 'activa',
    fecha_inicio DATE NOT NULL,
    fecha_vencimiento DATE NULL,
    renovacion_automatica TINYINT(1) NOT NULL DEFAULT 1,
    cancelada_en DATETIME NULL,
    PRIMARY KEY (id),
    KEY idx_suscripciones_usuario (usuarios_id),
    KEY idx_suscripciones_estado_vencimiento (estado, fecha_vencimiento),
    CONSTRAINT fk_suscripciones_usuario FOREIGN KEY (usuarios_id) REFERENCES usuarios (id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'Historial de suscripciones de los usuarios';

-- 7. TABLA: pagos
CREATE TABLE pagos (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    suscripciones_id BIGINT UNSIGNED NOT NULL,
    usuario_id BIGINT UNSIGNED NULL,
    metodo_pago ENUM(
        'tarjeta',
        'pse',
        'nequi',
        'efectivo',
        'otro'
    ) NULL,
    valor DECIMAL(12, 2) NOT NULL,
    estado ENUM(
        'pendiente',
        'aprobado',
        'rechazado',
        'fallido',
        'anulado',
        'reembolsado'
    ) NOT NULL DEFAULT 'pendiente',
    fecha_pago DATETIME NULL,
    PRIMARY KEY (id),
    KEY idx_pagos_suscripcion (suscripciones_id),
    KEY idx_pagos_usuario (usuario_id),
    KEY idx_pagos_estado (estado),
    CONSTRAINT fk_pagos_suscripcion FOREIGN KEY (suscripciones_id) REFERENCES suscripciones (id),
    CONSTRAINT fk_pagos_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id) ON DELETE SET NULL,
    CONSTRAINT chk_pagos_valor CHECK (valor > 0)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COMMENT = 'Transacciones de pago de las suscripciones';