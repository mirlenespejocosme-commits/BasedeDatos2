/* ============================================================
   BASE DE DATOS: CADENA EDITORIAL
   GESTOR: MICROSOFT SQL SERVER
   ============================================================ */

USE master;
GO

/* ------------------------------------------------------------
   0. LIMPIEZA: borra de master las tablas creadas por error
      en intentos anteriores (si no existen, no hace nada)
   ------------------------------------------------------------ */
DROP TABLE IF EXISTS dbo.Articulo;
DROP TABLE IF EXISTS dbo.Ejemplar;
DROP TABLE IF EXISTS dbo.SeccionFija;
DROP TABLE IF EXISTS dbo.SucursalRevista;
DROP TABLE IF EXISTS dbo.Periodista;
DROP TABLE IF EXISTS dbo.Empleado;
DROP TABLE IF EXISTS dbo.Revista;
DROP TABLE IF EXISTS dbo.Sucursal;
GO

/* ------------------------------------------------------------
   1. CREACION DE LA BASE DE DATOS
   (se crea en la carpeta de datos por defecto del servidor)
   ------------------------------------------------------------ */

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'CadenaEditorial')
BEGIN
    ALTER DATABASE CadenaEditorial SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CadenaEditorial;
END
GO

CREATE DATABASE CadenaEditorial;   -- usa la carpeta por defecto de tu SQL Server
GO

USE CadenaEditorial;
GO

-- Proteccion: si no se pudo entrar a la base, no ejecutar nada mas
IF DB_NAME() <> N'CadenaEditorial' SET NOEXEC ON;
GO

/* ============================================================
   2. TABLA SUCURSAL
   ============================================================ */

CREATE TABLE Sucursal
(
    IdSucursal INT IDENTITY(1,1) NOT NULL,
    CodigoSucursal VARCHAR(10) NOT NULL,
    Domicilio VARCHAR(150) NOT NULL,
    Telefono VARCHAR(20) NOT NULL,

    CONSTRAINT PK_Sucursal
        PRIMARY KEY (IdSucursal),

    CONSTRAINT UQ_Sucursal_Codigo
        UNIQUE (CodigoSucursal)
);
GO

/* ============================================================
   3. TABLA EMPLEADO
   ============================================================ */

CREATE TABLE Empleado
(
    IdEmpleado INT IDENTITY(1,1) NOT NULL,
    Nombre VARCHAR(50) NOT NULL,
    Apellidos VARCHAR(100) NOT NULL,
    NIF VARCHAR(20) NOT NULL,
    Telefono VARCHAR(20) NOT NULL,
    IdSucursal INT NOT NULL,

    CONSTRAINT PK_Empleado
        PRIMARY KEY (IdEmpleado),

    CONSTRAINT UQ_Empleado_NIF
        UNIQUE (NIF),

    CONSTRAINT FK_Empleado_Sucursal
        FOREIGN KEY (IdSucursal)
        REFERENCES Sucursal(IdSucursal)
);
GO

/* ============================================================
   4. TABLA REVISTA
   ============================================================ */

CREATE TABLE Revista
(
    IdRevista INT IDENTITY(1,1) NOT NULL,
    Titulo VARCHAR(150) NOT NULL,
    NumeroRegistro VARCHAR(30) NOT NULL,
    Periodicidad VARCHAR(30) NOT NULL,
    Tipo VARCHAR(50) NOT NULL,

    CONSTRAINT PK_Revista
        PRIMARY KEY (IdRevista),

    CONSTRAINT UQ_Revista_Registro
        UNIQUE (NumeroRegistro)
);
GO

/* ============================================================
   5. TABLA SUCURSAL_REVISTA
   Relacion N:M
   ============================================================ */

CREATE TABLE SucursalRevista
(
    IdSucursal INT NOT NULL,
    IdRevista INT NOT NULL,

    CONSTRAINT PK_SucursalRevista
        PRIMARY KEY (IdSucursal, IdRevista),

    CONSTRAINT FK_SucursalRevista_Sucursal
        FOREIGN KEY (IdSucursal)
        REFERENCES Sucursal(IdSucursal),

    CONSTRAINT FK_SucursalRevista_Revista
        FOREIGN KEY (IdRevista)
        REFERENCES Revista(IdRevista)
);
GO

/* ============================================================
   6. TABLA PERIODISTA
   ============================================================ */

CREATE TABLE Periodista
(
    IdPeriodista INT IDENTITY(1,1) NOT NULL,
    Nombre VARCHAR(50) NOT NULL,
    Apellidos VARCHAR(100) NOT NULL,
    NIF VARCHAR(20) NOT NULL,
    Telefono VARCHAR(20) NOT NULL,
    Especialidad VARCHAR(100) NOT NULL,

    CONSTRAINT PK_Periodista
        PRIMARY KEY (IdPeriodista),

    CONSTRAINT UQ_Periodista_NIF
        UNIQUE (NIF)
);
GO

/* ============================================================
   7. TABLA ARTICULO
   Relacion entre PERIODISTA y REVISTA
   ============================================================ */

CREATE TABLE Articulo
(
    IdArticulo INT IDENTITY(1,1) NOT NULL,
    Titulo VARCHAR(200) NOT NULL,
    FechaPublicacion DATE NOT NULL,
    IdPeriodista INT NOT NULL,
    IdRevista INT NOT NULL,

    CONSTRAINT PK_Articulo
        PRIMARY KEY (IdArticulo),

    CONSTRAINT FK_Articulo_Periodista
        FOREIGN KEY (IdPeriodista)
        REFERENCES Periodista(IdPeriodista),

    CONSTRAINT FK_Articulo_Revista
        FOREIGN KEY (IdRevista)
        REFERENCES Revista(IdRevista)
);
GO

/* ============================================================
   8. TABLA SECCION_FIJA
   ============================================================ */

CREATE TABLE SeccionFija
(
    IdSeccion INT IDENTITY(1,1) NOT NULL,
    Titulo VARCHAR(150) NOT NULL,
    Extension INT NOT NULL,
    IdRevista INT NOT NULL,

    CONSTRAINT PK_SeccionFija
        PRIMARY KEY (IdSeccion),

    CONSTRAINT FK_SeccionFija_Revista
        FOREIGN KEY (IdRevista)
        REFERENCES Revista(IdRevista),

    CONSTRAINT CK_SeccionFija_Extension
        CHECK (Extension > 0)
);
GO

/* ============================================================
   9. TABLA EJEMPLAR
   ============================================================ */

CREATE TABLE Ejemplar
(
    IdEjemplar INT IDENTITY(1,1) NOT NULL,
    Fecha DATE NOT NULL,
    NumeroPaginas INT NOT NULL,
    EjemplaresVendidos INT NOT NULL,
    IdRevista INT NOT NULL,

    CONSTRAINT PK_Ejemplar
        PRIMARY KEY (IdEjemplar),

    CONSTRAINT FK_Ejemplar_Revista
        FOREIGN KEY (IdRevista)
        REFERENCES Revista(IdRevista),

    CONSTRAINT CK_Ejemplar_Paginas
        CHECK (NumeroPaginas > 0),

    CONSTRAINT CK_Ejemplar_Vendidos
        CHECK (EjemplaresVendidos >= 0)
);
GO

/* ============================================================
   INSERCION DE DATOS
   ============================================================ */

USE CadenaEditorial;
GO

INSERT INTO Sucursal
    (CodigoSucursal, Domicilio, Telefono)
VALUES
('SUC001', 'Av. Arequipa 1010, Lima', '01-4101001'),
('SUC002', 'Av. Brasil 1250, Lima', '01-4101002'),
('SUC003', 'Av. Javier Prado 2200, Lima', '01-4101003'),
('SUC004', 'Av. La Marina 1500, Lima', '01-4101004'),
('SUC005', 'Av. Angamos 1800, Lima', '01-4101005'),
('SUC006', 'Av. Colonial 1450, Callao', '01-4101006'),
('SUC007', 'Av. Universitaria 3200, Lima', '01-4101007'),
('SUC008', 'Av. Primavera 450, Lima', '01-4101008'),
('SUC009', 'Av. Benavides 1750, Lima', '01-4101009'),
('SUC010', 'Av. Alfonso Ugarte 950, Lima', '01-4101010'),
('SUC011', 'Av. Grau 850, Lima', '01-4101011'),
('SUC012', 'Av. Tacna 720, Lima', '01-4101012'),
('SUC013', 'Av. Canadá 1250, Lima', '01-4101013'),
('SUC014', 'Av. República de Panamá 3300, Lima', '01-4101014'),
('SUC015', 'Av. Tomás Marsano 1800, Lima', '01-4101015'),
('SUC016', 'Av. Caminos del Inca 650, Lima', '01-4101016'),
('SUC017', 'Av. Petit Thouars 1450, Lima', '01-4101017'),
('SUC018', 'Av. Prolongación Iquitos 900, Lima', '01-4101018'),
('SUC019', 'Av. Nicolás de Piérola 1100, Lima', '01-4101019'),
('SUC020', 'Av. Elmer Faucett 1200, Callao', '01-4101020');
GO

INSERT INTO Empleado
    (Nombre, Apellidos, NIF, Telefono, IdSucursal)
VALUES
('Carlos', 'Ramirez Torres', 'NIF100001', '999100001', 1),
('Ana', 'Flores Mendoza', 'NIF100002', '999100002', 1),
('Luis', 'Gonzales Perez', 'NIF100003', '999100003', 2),
('Maria', 'Quispe Rojas', 'NIF100004', '999100004', 2),
('Jorge', 'Castillo Vargas', 'NIF100005', '999100005', 3),
('Lucia', 'Fernandez Diaz', 'NIF100006', '999100006', 3),
('Pedro', 'Sanchez Leon', 'NIF100007', '999100007', 4),
('Rosa', 'Torres Silva', 'NIF100008', '999100008', 4),
('Miguel', 'Herrera Campos', 'NIF100009', '999100009', 5),
('Carmen', 'Vega Salazar', 'NIF100010', '999100010', 5),
('Jose', 'Mendoza Ruiz', 'NIF100011', '999100011', 6),
('Elena', 'Paredes Soto', 'NIF100012', '999100012', 7),
('Daniel', 'Morales Castro', 'NIF100013', '999100013', 8),
('Patricia', 'Navarro Cruz', 'NIF100014', '999100014', 9),
('Fernando', 'Vargas Medina', 'NIF100015', '999100015', 10),
('Silvia', 'Ramos Ortiz', 'NIF100016', '999100016', 11),
('Ricardo', 'Salinas Peña', 'NIF100017', '999100017', 12),
('Claudia', 'Molina Reyes', 'NIF100018', '999100018', 13),
('Andres', 'Campos Herrera', 'NIF100019', '999100019', 14),
('Gabriela', 'Ruiz Delgado', 'NIF100020', '999100020', 15);
GO

INSERT INTO Revista
    (Titulo, NumeroRegistro, Periodicidad, Tipo)
VALUES
('Tecnologia Hoy', 'REG001', 'Mensual', 'Tecnologia'),
('Mundo Digital', 'REG002', 'Mensual', 'Tecnologia'),
('Ciencia Actual', 'REG003', 'Mensual', 'Ciencia'),
('Economia Global', 'REG004', 'Semanal', 'Economia'),
('Salud y Vida', 'REG005', 'Mensual', 'Salud'),
('Cultura Peruana', 'REG006', 'Mensual', 'Cultura'),
('Actualidad Nacional', 'REG007', 'Semanal', 'Actualidad'),
('Negocios 360', 'REG008', 'Quincenal', 'Negocios'),
('Innovacion Tech', 'REG009', 'Mensual', 'Tecnologia'),
('Educacion Hoy', 'REG010', 'Mensual', 'Educacion'),
('Viajes y Turismo', 'REG011', 'Mensual', 'Turismo'),
('Deportes Total', 'REG012', 'Semanal', 'Deportes'),
('Historia Viva', 'REG013', 'Mensual', 'Historia'),
('Arte y Diseño', 'REG014', 'Mensual', 'Arte'),
('Finanzas Personales', 'REG015', 'Quincenal', 'Finanzas'),
('Cocina Peruana', 'REG016', 'Mensual', 'Gastronomia'),
('Mundo Empresarial', 'REG017', 'Semanal', 'Empresarial'),
('Ciencia y Futuro', 'REG018', 'Mensual', 'Ciencia'),
('Sociedad Hoy', 'REG019', 'Quincenal', 'Sociedad'),
('Programacion Web', 'REG020', 'Mensual', 'Tecnologia');
GO

INSERT INTO SucursalRevista
    (IdSucursal, IdRevista)
VALUES
(1, 1),
(1, 2),
(2, 3),
(2, 4),
(3, 5),
(3, 6),
(4, 7),
(4, 8),
(5, 9),
(5, 10),
(6, 11),
(7, 12),
(8, 13),
(9, 14),
(10, 15),
(11, 16),
(12, 17),
(13, 18),
(14, 19),
(15, 20);
GO

INSERT INTO Periodista
    (Nombre, Apellidos, NIF, Telefono, Especialidad)
VALUES
('Alberto', 'Navarro Ruiz', 'NIF200001', '998200001', 'Tecnologia'),
('Beatriz', 'Castro Leon', 'NIF200002', '998200002', 'Economia'),
('Carlos', 'Mendoza Silva', 'NIF200003', '998200003', 'Politica'),
('Diana', 'Flores Torres', 'NIF200004', '998200004', 'Ciencia'),
('Eduardo', 'Ramirez Soto', 'NIF200005', '998200005', 'Deportes'),
('Fabiola', 'Quispe Ramos', 'NIF200006', '998200006', 'Cultura'),
('Gustavo', 'Herrera Diaz', 'NIF200007', '998200007', 'Salud'),
('Helena', 'Vargas Cruz', 'NIF200008', '998200008', 'Educacion'),
('Ivan', 'Morales Perez', 'NIF200009', '998200009', 'Tecnologia'),
('Julia', 'Salazar Medina', 'NIF200010', '998200010', 'Turismo'),
('Kevin', 'Paredes Leon', 'NIF200011', '998200011', 'Negocios'),
('Laura', 'Sanchez Castro', 'NIF200012', '998200012', 'Arte'),
('Manuel', 'Torres Vargas', 'NIF200013', '998200013', 'Historia'),
('Natalia', 'Rojas Mendoza', 'NIF200014', '998200014', 'Gastronomia'),
('Oscar', 'Vega Campos', 'NIF200015', '998200015', 'Finanzas'),
('Paola', 'Molina Reyes', 'NIF200016', '998200016', 'Sociedad'),
('Rafael', 'Ortega Ruiz', 'NIF200017', '998200017', 'Tecnologia'),
('Sandra', 'Delgado Silva', 'NIF200018', '998200018', 'Ciencia'),
('Tomas', 'Medina Flores', 'NIF200019', '998200019', 'Deportes'),
('Veronica', 'Cruz Navarro', 'NIF200020', '998200020', 'Educacion');
GO

INSERT INTO Articulo
    (Titulo, FechaPublicacion, IdPeriodista, IdRevista)
VALUES
('El futuro de la inteligencia artificial', '2026-01-10', 1, 1),
('Transformacion digital empresarial', '2026-01-15', 2, 4),
('Nuevos avances cientificos', '2026-02-05', 4, 3),
('Tecnologia y sociedad moderna', '2026-02-12', 9, 2),
('Innovacion en las empresas', '2026-02-20', 11, 8),
('El desarrollo de la ciencia peruana', '2026-03-01', 18, 18),
('Educacion digital en el siglo XXI', '2026-03-08', 8, 10),
('Turismo sostenible en el Peru', '2026-03-15', 10, 11),
('Nuevas tendencias deportivas', '2026-03-20', 5, 12),
('La cultura peruana contemporanea', '2026-03-25', 6, 6),
('Historia de Lima moderna', '2026-04-01', 13, 13),
('Diseño y creatividad digital', '2026-04-05', 12, 14),
('Consejos para mejorar las finanzas', '2026-04-10', 15, 15),
('Gastronomia peruana internacional', '2026-04-15', 14, 16),
('Retos de la sociedad actual', '2026-04-20', 16, 19),
('Programacion web moderna', '2026-05-01', 17, 20),
('Salud y tecnologia', '2026-05-10', 7, 5),
('Actualidad nacional', '2026-05-15', 3, 7),
('Nuevos modelos de negocios', '2026-05-20', 2, 17),
('Tecnologias emergentes', '2026-05-25', 20, 9);
GO

SET NOEXEC OFF;
GO
/* ============================================================
   CADENA EDITORIAL - DATOS COMPLEMENTARIOS Y CUESTIONARIO (40 CONSULTAS)
   Ejecutar DESPUES de CadenaEditorial_desde_cero.sql
   ============================================================ */
 
USE CadenaEditorial;
GO
 
/* ------------------------------------------------------------
   DATOS DE EJEMPLO PARA SeccionFija Y Ejemplar
   (el documento no traia datos para estas tablas y varias
    consultas los necesitan)
   ------------------------------------------------------------ */
 
IF NOT EXISTS (SELECT 1 FROM SeccionFija)
INSERT INTO SeccionFija (Titulo, Extension, IdRevista)
VALUES
('Noticias', 5, 1),
('Investigacion', 2, 1),
('Innovacion', 7, 1),
('Investigacion', 8, 2),
('Innovacion', 5, 2),
('Entrevistas', 2, 2),
('Opinion', 7, 2),
('Innovacion', 3, 3),
('Entrevistas', 8, 3),
('Opinion', 5, 3),
('Editorial', 2, 3),
('Noticias', 7, 3),
('Entrevistas', 6, 4),
('Opinion', 3, 4),
('Opinion', 9, 5),
('Editorial', 6, 5),
('Noticias', 3, 5),
('Editorial', 4, 6),
('Noticias', 9, 6),
('Investigacion', 6, 6),
('Innovacion', 3, 6),
('Noticias', 7, 7),
('Investigacion', 4, 7),
('Innovacion', 9, 7),
('Entrevistas', 6, 7),
('Opinion', 3, 7),
('Investigacion', 2, 8),
('Innovacion', 7, 8),
('Innovacion', 5, 9),
('Entrevistas', 2, 9),
('Opinion', 7, 9),
('Entrevistas', 8, 10),
('Opinion', 5, 10),
('Editorial', 2, 10),
('Noticias', 7, 10),
('Opinion', 3, 11),
('Editorial', 8, 11),
('Noticias', 5, 11),
('Investigacion', 2, 11),
('Innovacion', 7, 11),
('Editorial', 6, 12),
('Noticias', 3, 12),
('Noticias', 9, 13),
('Investigacion', 6, 13),
('Innovacion', 3, 13),
('Investigacion', 4, 14),
('Innovacion', 9, 14),
('Entrevistas', 6, 14),
('Opinion', 3, 14),
('Innovacion', 7, 15),
('Entrevistas', 4, 15),
('Opinion', 9, 15),
('Editorial', 6, 15),
('Noticias', 3, 15),
('Entrevistas', 2, 16),
('Opinion', 7, 16),
('Opinion', 5, 17),
('Editorial', 2, 17),
('Noticias', 7, 17),
('Editorial', 8, 18),
('Noticias', 5, 18),
('Investigacion', 2, 18),
('Innovacion', 7, 18),
('Noticias', 3, 19),
('Investigacion', 8, 19),
('Innovacion', 5, 19),
('Entrevistas', 2, 19),
('Opinion', 7, 19),
('Investigacion', 6, 20),
('Innovacion', 3, 20);
GO
 
IF NOT EXISTS (SELECT 1 FROM Ejemplar)
INSERT INTO Ejemplar (Fecha, NumeroPaginas, EjemplaresVendidos, IdRevista)
VALUES
('2026-02-05', 112, 7800, 1),
('2026-03-05', 152, 5400, 1),
('2026-04-05', 88, 3000, 1),
('2026-03-05', 64, 7600, 2),
('2026-04-05', 104, 5200, 2),
('2026-05-05', 144, 2800, 2),
('2026-01-05', 120, 7400, 3),
('2026-02-05', 56, 5000, 3),
('2026-03-05', 96, 2600, 3),
('2026-02-05', 72, 7200, 4),
('2026-03-05', 112, 4800, 4),
('2026-04-05', 152, 7900, 4),
('2026-03-05', 128, 7000, 5),
('2026-04-05', 64, 4600, 5),
('2026-05-05', 104, 7700, 5),
('2026-01-05', 80, 6800, 6),
('2026-02-05', 120, 4400, 6),
('2026-03-05', 56, 7500, 6),
('2026-02-05', 136, 6600, 7),
('2026-03-05', 72, 4200, 7),
('2026-04-05', 112, 7300, 7),
('2026-03-05', 88, 6400, 8),
('2026-04-05', 128, 4000, 8),
('2026-05-05', 64, 7100, 8),
('2026-01-05', 144, 6200, 9),
('2026-02-05', 80, 3800, 9),
('2026-03-05', 120, 6900, 9),
('2026-02-05', 96, 6000, 10),
('2026-03-05', 136, 3600, 10),
('2026-04-05', 72, 6700, 10),
('2026-03-05', 152, 5800, 11),
('2026-04-05', 88, 3400, 11),
('2026-05-05', 128, 6500, 11),
('2026-01-05', 104, 5600, 12),
('2026-02-05', 144, 3200, 12),
('2026-03-05', 80, 6300, 12),
('2026-02-05', 56, 5400, 13),
('2026-03-05', 96, 3000, 13),
('2026-04-05', 136, 6100, 13),
('2026-03-05', 112, 5200, 14),
('2026-04-05', 152, 2800, 14),
('2026-05-05', 88, 5900, 14),
('2026-01-05', 64, 5000, 15),
('2026-02-05', 104, 2600, 15),
('2026-03-05', 144, 5700, 15),
('2026-02-05', 120, 4800, 16),
('2026-03-05', 56, 7900, 16),
('2026-04-05', 96, 5500, 16),
('2026-03-05', 72, 4600, 17),
('2026-04-05', 112, 7700, 17),
('2026-05-05', 152, 5300, 17),
('2026-01-05', 128, 4400, 18),
('2026-02-05', 64, 7500, 18),
('2026-03-05', 104, 5100, 18),
('2026-02-05', 80, 4200, 19),
('2026-03-05', 120, 7300, 19),
('2026-04-05', 56, 4900, 19),
('2026-03-05', 136, 4000, 20),
('2026-04-05', 72, 7100, 20),
('2026-05-05', 112, 4700, 20);
GO