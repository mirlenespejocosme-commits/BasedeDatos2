-- =====================================================================
-- ACTIVIDAD 02 - ENUNCIADO 01: CADENA EDITORIAL
-- Modelo fisico para SQL Server
--
-- Este script crea la base de datos CadenaEditorial desde cero.
-- Si ya existe una con ese nombre, la elimina y la vuelve a crear.
-- =====================================================================

USE master;
GO

IF DB_ID(N'CadenaEditorial') IS NOT NULL
BEGIN
    ALTER DATABASE CadenaEditorial SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CadenaEditorial;
END
GO

CREATE DATABASE CadenaEditorial;
GO

USE CadenaEditorial;
GO

-- ---------------------------------------------------------------------
-- SUCURSAL: la editorial tiene varias sucursales, con domicilio,
-- telefono y un codigo de sucursal.
-- ---------------------------------------------------------------------
CREATE TABLE dbo.Sucursal (
    CodigoSucursal  INT           IDENTITY(1,1) NOT NULL,
    Domicilio       VARCHAR(150)  NOT NULL,
    Telefono        VARCHAR(15)   NOT NULL,

    CONSTRAINT PK_Sucursal PRIMARY KEY (CodigoSucursal)
);
GO

-- ---------------------------------------------------------------------
-- EMPLEADO: cada sucursal tiene varios empleados (nombre, apellidos,
-- NIF y telefono). Un empleado trabaja en una unica sucursal.
-- ---------------------------------------------------------------------
CREATE TABLE dbo.Empleado (
    NIF             VARCHAR(9)    NOT NULL,
    Nombre          VARCHAR(60)   NOT NULL,
    Apellidos       VARCHAR(100)  NOT NULL,
    Telefono        VARCHAR(15)   NULL,
    CodigoSucursal  INT           NOT NULL,

    CONSTRAINT PK_Empleado PRIMARY KEY (NIF),
    CONSTRAINT FK_Empleado_Sucursal
        FOREIGN KEY (CodigoSucursal) REFERENCES dbo.Sucursal(CodigoSucursal),
    CONSTRAINT CHK_Empleado_NIF CHECK (LEN(NIF) >= 8)
);
GO

-- ---------------------------------------------------------------------
-- REVISTA: titulo, numero de registro, periodicidad y tipo.
-- ---------------------------------------------------------------------
CREATE TABLE dbo.Revista (
    NumeroRegistro  VARCHAR(20)   NOT NULL,
    Titulo          VARCHAR(120)  NOT NULL,
    Periodicidad    VARCHAR(15)   NOT NULL,
    Tipo            VARCHAR(50)   NOT NULL,

    CONSTRAINT PK_Revista PRIMARY KEY (NumeroRegistro),
    CONSTRAINT CHK_Revista_Periodicidad CHECK (Periodicidad IN (
        'DIARIA', 'SEMANAL', 'QUINCENAL', 'MENSUAL',
        'BIMESTRAL', 'TRIMESTRAL', 'SEMESTRAL', 'ANUAL'
    ))
);
GO

-- ---------------------------------------------------------------------
-- SUCURSAL_REVISTA: en cada sucursal se publican varias revistas y una
-- revista puede ser publicada por varias sucursales (relacion N:M).
-- ---------------------------------------------------------------------
CREATE TABLE dbo.SucursalRevista (
    CodigoSucursal  INT           NOT NULL,
    NumeroRegistro  VARCHAR(20)   NOT NULL,

    CONSTRAINT PK_SucursalRevista PRIMARY KEY (CodigoSucursal, NumeroRegistro),
    CONSTRAINT FK_SucursalRevista_Sucursal
        FOREIGN KEY (CodigoSucursal) REFERENCES dbo.Sucursal(CodigoSucursal),
    CONSTRAINT FK_SucursalRevista_Revista
        FOREIGN KEY (NumeroRegistro) REFERENCES dbo.Revista(NumeroRegistro)
);
GO

-- ---------------------------------------------------------------------
-- PERIODISTA: mismos datos que los empleados, mas su especialidad.
-- No trabajan en las sucursales.
-- ---------------------------------------------------------------------
CREATE TABLE dbo.Periodista (
    NIF             VARCHAR(9)    NOT NULL,
    Nombre          VARCHAR(60)   NOT NULL,
    Apellidos       VARCHAR(100)  NOT NULL,
    Telefono        VARCHAR(15)   NULL,
    Especialidad    VARCHAR(80)   NOT NULL,

    CONSTRAINT PK_Periodista PRIMARY KEY (NIF),
    CONSTRAINT CHK_Periodista_NIF CHECK (LEN(NIF) >= 8)
);
GO

-- ---------------------------------------------------------------------
-- PERIODISTA_REVISTA: un periodista puede escribir articulos para
-- varias revistas (relacion N:M).
-- ---------------------------------------------------------------------
CREATE TABLE dbo.PeriodistaRevista (
    NIFPeriodista   VARCHAR(9)    NOT NULL,
    NumeroRegistro  VARCHAR(20)   NOT NULL,

    CONSTRAINT PK_PeriodistaRevista PRIMARY KEY (NIFPeriodista, NumeroRegistro),
    CONSTRAINT FK_PeriodistaRevista_Periodista
        FOREIGN KEY (NIFPeriodista) REFERENCES dbo.Periodista(NIF),
    CONSTRAINT FK_PeriodistaRevista_Revista
        FOREIGN KEY (NumeroRegistro) REFERENCES dbo.Revista(NumeroRegistro)
);
GO

-- ---------------------------------------------------------------------
-- SECCION_REVISTA: secciones fijas de cada revista (titulo y extension).
-- La extension se mide en paginas.
-- ---------------------------------------------------------------------
CREATE TABLE dbo.SeccionRevista (
    IdSeccion         INT           IDENTITY(1,1) NOT NULL,
    NumeroRegistro    VARCHAR(20)   NOT NULL,
    Titulo            VARCHAR(100)  NOT NULL,
    ExtensionPaginas  SMALLINT      NOT NULL,

    CONSTRAINT PK_SeccionRevista PRIMARY KEY (IdSeccion),
    CONSTRAINT FK_SeccionRevista_Revista
        FOREIGN KEY (NumeroRegistro) REFERENCES dbo.Revista(NumeroRegistro),
    CONSTRAINT UQ_SeccionRevista_Titulo UNIQUE (NumeroRegistro, Titulo),
    CONSTRAINT CHK_SeccionRevista_Extension CHECK (ExtensionPaginas > 0)
);
GO

-- ---------------------------------------------------------------------
-- EJEMPLAR: informacion de cada ejemplar de una revista (fecha, numero
-- de paginas y numero de ejemplares vendidos).
-- ---------------------------------------------------------------------
CREATE TABLE dbo.Ejemplar (
    IdEjemplar          INT          IDENTITY(1,1) NOT NULL,
    NumeroRegistro      VARCHAR(20)  NOT NULL,
    FechaPublicacion    DATE         NOT NULL,
    NumeroPaginas       SMALLINT     NOT NULL,
    EjemplaresVendidos  INT          NOT NULL DEFAULT 0,

    CONSTRAINT PK_Ejemplar PRIMARY KEY (IdEjemplar),
    CONSTRAINT FK_Ejemplar_Revista
        FOREIGN KEY (NumeroRegistro) REFERENCES dbo.Revista(NumeroRegistro),
    CONSTRAINT UQ_Ejemplar_Revista_Fecha UNIQUE (NumeroRegistro, FechaPublicacion),
    CONSTRAINT CHK_Ejemplar_Paginas CHECK (NumeroPaginas > 0),
    CONSTRAINT CHK_Ejemplar_Vendidos CHECK (EjemplaresVendidos >= 0)
);
GO

-- =====================================================================
-- DATOS DE EJEMPLO (para poder visualizar la base de datos)
-- =====================================================================

INSERT INTO dbo.Sucursal (Domicilio, Telefono) VALUES
('Calle Mayor 10, Madrid',          '911111111'),
('Avenida del Puerto 25, Valencia', '963333333'),
('Calle Sierpes 5, Sevilla',        '955555555');
GO

INSERT INTO dbo.Empleado (NIF, Nombre, Apellidos, Telefono, CodigoSucursal) VALUES
('11111111A', 'Ana',   'Lopez Garcia', '600111111', 1),
('22222222B', 'Luis',  'Perez Ruiz',   '600222222', 1),
('33333333C', 'Marta', 'Sanchez Gil',  '600333333', 2),
('44444444D', 'Pablo', 'Diaz Torres',  NULL,        3);
GO

INSERT INTO dbo.Revista (NumeroRegistro, Titulo, Periodicidad, Tipo) VALUES
('REG-0001', 'Mundo Ciencia',  'MENSUAL',   'CIENTIFICA'),
('REG-0002', 'Deporte Total',  'SEMANAL',   'DEPORTIVA'),
('REG-0003', 'Hogar y Jardin', 'QUINCENAL', 'DECORACION');
GO

INSERT INTO dbo.SucursalRevista (CodigoSucursal, NumeroRegistro) VALUES
(1, 'REG-0001'),
(1, 'REG-0002'),
(2, 'REG-0001'),
(2, 'REG-0003'),
(3, 'REG-0002');
GO

INSERT INTO dbo.Periodista (NIF, Nombre, Apellidos, Telefono, Especialidad) VALUES
('55555555E', 'Carlos', 'Romero Vega', '600555555', 'Ciencia'),
('66666666F', 'Laura',  'Navarro Sola', '600666666', 'Deportes'),
('77777777G', 'Elena',  'Mora Cruz',    NULL,        'Decoracion');
GO

INSERT INTO dbo.PeriodistaRevista (NIFPeriodista, NumeroRegistro) VALUES
('55555555E', 'REG-0001'),
('66666666F', 'REG-0001'),
('66666666F', 'REG-0002'),
('77777777G', 'REG-0003');
GO

INSERT INTO dbo.SeccionRevista (NumeroRegistro, Titulo, ExtensionPaginas) VALUES
('REG-0001', 'Novedades cientificas',   6),
('REG-0001', 'Entrevista del mes',      4),
('REG-0002', 'Resultados de la semana', 8),
('REG-0003', 'Trucos de jardineria',    5);
GO

INSERT INTO dbo.Ejemplar (NumeroRegistro, FechaPublicacion, NumeroPaginas, EjemplaresVendidos) VALUES
('REG-0001', '2026-01-01', 64, 1500),
('REG-0001', '2026-02-01', 64, 1720),
('REG-0002', '2026-01-07', 48, 3200),
('REG-0003', '2026-01-15', 52,  900);
GO

-- =====================================================================
-- CONSULTAS DE COMPROBACION
-- =====================================================================

-- Revistas que publica cada sucursal
SELECT s.CodigoSucursal, s.Domicilio, r.Titulo AS Revista
FROM dbo.Sucursal s
JOIN dbo.SucursalRevista sr ON sr.CodigoSucursal = s.CodigoSucursal
JOIN dbo.Revista r          ON r.NumeroRegistro = sr.NumeroRegistro
ORDER BY s.CodigoSucursal, r.Titulo;
GO

-- Ejemplares de cada revista
SELECT r.Titulo AS Revista, e.FechaPublicacion, e.NumeroPaginas, e.EjemplaresVendidos
FROM dbo.Revista r
JOIN dbo.Ejemplar e ON e.NumeroRegistro = r.NumeroRegistro
ORDER BY r.Titulo, e.FechaPublicacion;
GO

PRINT 'BASE DE DATOS CadenaEditorial CREADA CORRECTAMENTE.';
GO
