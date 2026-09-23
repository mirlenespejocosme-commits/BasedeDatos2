-- =====================================================================
-- BASE DE DATOS: UPLA - GRADOS Y TITULOS DE PREGRADO
-- Normalizacion 3FN - Reglamento General de Grados y Titulos
-- Motor: SQL Server 2021
-- Autor: Ing. Raul Fernandez Bejarano
-- Fecha: 09/08/2026
-- Transcrito desde CODIGOS.docx (capturas de pantalla) para Yuber
-- =====================================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'GradosTitulos')
BEGIN
    ALTER DATABASE GradosTitulos SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GradosTitulos;
END
GO

-- CORRECCION: los archivos se crean en las carpetas por defecto de SQL Server,
-- asi no hace falta que exista la carpeta D:\BaseDatos2026.
DECLARE @RutaDatos NVARCHAR(260) = CONVERT(NVARCHAR(260), SERVERPROPERTY('InstanceDefaultDataPath'));
DECLARE @RutaLog   NVARCHAR(260) = CONVERT(NVARCHAR(260), SERVERPROPERTY('InstanceDefaultLogPath'));
DECLARE @Sql       NVARCHAR(MAX);

SET @Sql = N'
CREATE DATABASE GradosTitulos
ON PRIMARY (
    NAME = GradosTitulos_Data,
    FILENAME = ''' + @RutaDatos + N'GradosTitulos_data.mdf'',
    SIZE = 20MB,
    MAXSIZE = 20GB,
    FILEGROWTH = 5MB
)
LOG ON (
    NAME = GradosTitulos_Log,
    FILENAME = ''' + @RutaLog + N'GradosTitulos_log.ldf'',
    SIZE = 6MB,
    MAXSIZE = 2GB,
    FILEGROWTH = 2MB
);';

EXEC sys.sp_executesql @Sql;
GO

-- =====================================================================
-- ARQUITECTURA GENERAL: la base de datos se divide en seis esquemas
-- GradosTitulos
--  |- Catalogo
--  |- Academico
--  |- Tramite
--  |- Evaluacion
--  |- Documento
--  |- Seguridad
-- Los primeros cinco esquemas corresponden al negocio de Grados y
-- Titulos; Seguridad concentra el control de acceso y seguridad
-- corporativa.
-- =====================================================================

USE GradosTitulos;
GO

-- =====================================================================
-- 2. CREAR ESQUEMAS
-- =====================================================================
CREATE SCHEMA Catalogo;   -- Tablas de parametros y catalogos
GO
CREATE SCHEMA Academico;  -- Entidades academicas principales
GO
CREATE SCHEMA Tramite;    -- Proceso administrativo
GO
CREATE SCHEMA Evaluacion; -- Evaluaciones y sustentacion
GO
CREATE SCHEMA Documento;  -- Resoluciones, diplomas y documentos
GO
CREATE SCHEMA Seguridad;  -- Usuarios, roles y permisos (RBAC)
GO

-- =====================================================================
-- 3. TABLAS DE CATALOGO
-- =====================================================================

-- ---------------------------------------------------------------------
-- T01: TIPO_TRAMITE
-- Catalogo de tipos de tramite disponibles
-- ---------------------------------------------------------------------
CREATE TABLE Catalogo.TipoTramite (
    IdTipoTramite       TINYINT        NOT NULL,
    Descripcion         VARCHAR(60)    NOT NULL,
    RequiereTesis       BIT            NOT NULL DEFAULT 0,
    RequiereSuficiencia BIT            NOT NULL DEFAULT 0,
    RequiereBachiller   BIT            NOT NULL DEFAULT 0, -- prerrequisito obligatorio
    Activo              BIT            NOT NULL DEFAULT 1,

    CONSTRAINT PK_TipoTramite PRIMARY KEY (IdTipoTramite),
    CONSTRAINT UQ_TipoTramite_Descripcion UNIQUE (Descripcion)
);
GO

INSERT INTO Catalogo.TipoTramite VALUES
(1, 'BACHILLER',                 0, 0, 0, 1),
(2, 'TITULO_TESIS_INDIVIDUAL',   1, 0, 1, 1),
(3, 'TITULO_TESIS_GRUPAL',       1, 0, 1, 1),
(4, 'TITULO_SUFICIENCIA_PROF',   0, 1, 1, 1);
GO

-- ---------------------------------------------------------------------
-- T02: ESTADO_TRAMITE
-- Catalogo de estados del flujo administrativo
-- ---------------------------------------------------------------------
CREATE TABLE Catalogo.EstadoTramite (
    IdEstadoTramite TINYINT      NOT NULL,
    Descripcion     VARCHAR(40)  NOT NULL,
    EsTerminal      BIT          NOT NULL DEFAULT 0, -- estado final del flujo

    CONSTRAINT PK_EstadoTramite PRIMARY KEY (IdEstadoTramite),
    CONSTRAINT UQ_EstadoTramite_Descripcion UNIQUE (Descripcion)
);
GO

INSERT INTO Catalogo.EstadoTramite VALUES
(1, 'INICIADO',        0),
(2, 'EN_VERIFICACION', 0),
(3, 'EN_PROCESO',      0),
(4, 'OBSERVADO',       0),
(5, 'APROBADO',        1),
(6, 'IMPROCEDENTE',    1),
(7, 'ARCHIVADO',       1),
(8, 'SUSPENDIDO',      0);
GO

-- ---------------------------------------------------------------------
-- T03: LINEA_INVESTIGACION
-- Lineas de investigacion institucionales aprobadas
-- ---------------------------------------------------------------------
CREATE TABLE Catalogo.LineaInvestigacion (
    IdLinea               SMALLINT      NOT NULL IDENTITY(1,1),
    NombreLinea            VARCHAR(200)  NOT NULL,
    ResolucionAprobacion   VARCHAR(40)   NULL,  -- Ej: Res. 1069-2019-CU-VRINV
    FechaAprobacion        DATE          NULL,
    Activo                 BIT           NOT NULL DEFAULT 1,

    CONSTRAINT PK_LineaInvestigacion PRIMARY KEY (IdLinea),
    CONSTRAINT UQ_LineaInvestigacion_Nombre UNIQUE (NombreLinea)
);
GO

-- =====================================================================
-- 4. TABLAS DE ESTRUCTURA ACADEMICA
-- =====================================================================

-- ---------------------------------------------------------------------
-- T04: FACULTAD
-- ---------------------------------------------------------------------
CREATE TABLE Academico.Facultad (
    IdFacultad      TINYINT       NOT NULL IDENTITY(1,1),
    NombreFacultad  VARCHAR(100)  NOT NULL,
    NombreDecano    VARCHAR(150)  NULL,
    Activo          BIT           NOT NULL DEFAULT 1,

    CONSTRAINT PK_Facultad PRIMARY KEY (IdFacultad),
    CONSTRAINT UQ_Facultad_Nombre UNIQUE (NombreFacultad)
);
GO

INSERT INTO Academico.Facultad (NombreFacultad) VALUES
('Ciencias Administrativas y Contables'),
('Derecho y Ciencias Politicas'),
('Ingenieria'),
('Ciencias de la Salud'),
('Educacion y Ciencias Humanas'),
('Medicina Humana');
GO

-- ---------------------------------------------------------------------
-- T05: PROGRAMA_ESTUDIOS
-- ---------------------------------------------------------------------
CREATE TABLE Academico.ProgramaEstudios (
    IdPrograma      SMALLINT      NOT NULL IDENTITY(1,1),
    IdFacultad      TINYINT       NOT NULL,
    NombrePrograma  VARCHAR(150)  NOT NULL,
    NumSemestres    TINYINT       NOT NULL, -- 10, 12 o 14
    Modalidad       VARCHAR(15)   NOT NULL, -- PRESENCIAL, SEMIPRESENCIAL
    Activo          BIT           NOT NULL DEFAULT 1,

    CONSTRAINT PK_ProgramaEstudios PRIMARY KEY (IdPrograma),
    CONSTRAINT FK_Programa_Facultad
        FOREIGN KEY (IdFacultad) REFERENCES Academico.Facultad(IdFacultad),
    CONSTRAINT CHK_Programa_Semestres
        CHECK (NumSemestres IN (10, 12, 14)),
    CONSTRAINT CHK_Programa_Modalidad
        CHECK (Modalidad IN ('PRESENCIAL', 'SEMIPRESENCIAL')),
    CONSTRAINT UQ_Programa_Nombre_Modalidad
        UNIQUE (NombrePrograma, Modalidad)
);
GO

-- ---------------------------------------------------------------------
-- T06: GRADO_TITULO_CATALOGO
-- Denominaciones oficiales de grado y titulo por programa
-- ---------------------------------------------------------------------
CREATE TABLE Academico.GradoTituloCatalogo (
    IdGradoTitulo       SMALLINT      NOT NULL IDENTITY(1,1),
    IdPrograma          SMALLINT      NOT NULL,
    DenominacionGrado   VARCHAR(150)  NOT NULL,
    DenominacionTitulo  VARCHAR(150)  NOT NULL,
    Activo              BIT           NOT NULL DEFAULT 1,

    CONSTRAINT PK_GradoTituloCatalogo PRIMARY KEY (IdGradoTitulo),
    CONSTRAINT FK_GradoTitulo_Programa
        FOREIGN KEY (IdPrograma) REFERENCES Academico.ProgramaEstudios(IdPrograma)
);
GO

-- =====================================================================
-- 5. TABLAS DE PERSONAS Y ROLES
-- =====================================================================

-- ---------------------------------------------------------------------
-- T07: PERSONA
-- Base comun para estudiantes y docentes
-- ---------------------------------------------------------------------
CREATE TABLE Academico.Persona (
    IdPersona         INT           NOT NULL IDENTITY(1,1),
    DNI               CHAR(8)       NOT NULL,
    Nombres           VARCHAR(80)   NOT NULL,
    ApellidoPaterno   VARCHAR(60)   NOT NULL,
    ApellidoMaterno   VARCHAR(60)   NULL,
    Correo            VARCHAR(120)  NULL,
    Telefono          VARCHAR(15)   NULL,
    TipoPersona       VARCHAR(15)   NOT NULL, -- ESTUDIANTE, DOCENTE
    FechaRegistro     DATETIME2     NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Persona PRIMARY KEY (IdPersona),
    CONSTRAINT UQ_Persona_DNI UNIQUE (DNI),
    CONSTRAINT CHK_Persona_DNI CHECK (DNI LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
    CONSTRAINT CHK_Persona_Tipo CHECK (TipoPersona IN ('ESTUDIANTE', 'DOCENTE'))
);
GO

-- ---------------------------------------------------------------------
-- T08: DOCENTE
-- Especializacion de Persona para asesores y jurados
-- ---------------------------------------------------------------------
CREATE TABLE Academico.Docente (
    IdDocente       INT           NOT NULL IDENTITY(1,1),
    IdPersona       INT           NOT NULL,
    GradoAcademico  VARCHAR(10)   NOT NULL, -- MAESTRO, DOCTOR
    CodigoORCID     VARCHAR(25)   NULL,
    TipoContrato    VARCHAR(12)   NOT NULL, -- ORDINARIO, CONTRATADO
    IdFacultad      TINYINT       NOT NULL,
    EstadoActivo    BIT           NOT NULL DEFAULT 1,

    CONSTRAINT PK_Docente PRIMARY KEY (IdDocente),
    CONSTRAINT UQ_Docente_Persona UNIQUE (IdPersona),
    CONSTRAINT FK_Docente_Persona
        FOREIGN KEY (IdPersona) REFERENCES Academico.Persona(IdPersona),
    CONSTRAINT FK_Docente_Facultad
        FOREIGN KEY (IdFacultad) REFERENCES Academico.Facultad(IdFacultad),
    CONSTRAINT CHK_Docente_Grado
        CHECK (GradoAcademico IN ('MAESTRO', 'DOCTOR')),
    CONSTRAINT CHK_Docente_Contrato
        CHECK (TipoContrato IN ('ORDINARIO', 'CONTRATADO'))
);
GO

-- =====================================================================
-- 6. TABLAS DE COORDINACION
-- =====================================================================

-- ---------------------------------------------------------------------
-- T09: COORDINACION_GT
-- Coordinacion de Grados y Titulos por facultad
-- ---------------------------------------------------------------------
CREATE TABLE Tramite.CoordinacionGT (
    IdCoordinacion    TINYINT       NOT NULL IDENTITY(1,1),
    IdFacultad        TINYINT       NOT NULL,
    NombreCoordinador VARCHAR(150)  NULL,
    FechaCreacion     DATE          NULL,
    Activo            BIT           NOT NULL DEFAULT 1,

    CONSTRAINT PK_CoordinacionGT PRIMARY KEY (IdCoordinacion),
    CONSTRAINT FK_CoordGT_Facultad
        FOREIGN KEY (IdFacultad) REFERENCES Academico.Facultad(IdFacultad)
);
GO

-- =====================================================================
-- 7. TABLAS DEL PROCESO DE MATRICULA Y TRAMITE
-- =====================================================================

-- ---------------------------------------------------------------------
-- T10: MATRICULA
-- Vinculo estudiante-programa, condicion de egresado
-- ---------------------------------------------------------------------
CREATE TABLE Academico.Matricula (
    IdMatricula          INT        NOT NULL IDENTITY(1,1),
    IdEstudiante         INT        NOT NULL,
    IdPrograma           SMALLINT   NOT NULL,
    FechaMatricula       DATE       NOT NULL,
    CreditosAprobados    SMALLINT   NULL,
    AsignaturasAprobadas BIT        NOT NULL DEFAULT 0,
    PracticasCompletadas BIT        NOT NULL DEFAULT 0,
    IdiomaAprobado       BIT        NOT NULL DEFAULT 0,
    ProyeccionSocial     BIT        NOT NULL DEFAULT 0,
    TieneDeuda           BIT        NOT NULL DEFAULT 0,
    FechaEgreso          DATE       NULL,

    CONSTRAINT PK_Matricula PRIMARY KEY (IdMatricula),
    CONSTRAINT FK_Matricula_Estudiante
        FOREIGN KEY (IdEstudiante) REFERENCES Academico.Persona(IdPersona),
    CONSTRAINT FK_Matricula_Programa
        FOREIGN KEY (IdPrograma) REFERENCES Academico.ProgramaEstudios(IdPrograma)
);
GO

-- ---------------------------------------------------------------------
-- T11: TRAMITE
-- Proceso administrativo principal
-- ---------------------------------------------------------------------
CREATE TABLE Tramite.Tramite (
    IdTramite        INT           NOT NULL IDENTITY(1,1),
    IdMatricula      INT           NOT NULL,
    IdTipoTramite    TINYINT       NOT NULL,
    IdEstadoTramite  TINYINT       NOT NULL DEFAULT 1,
    IdCoordinacion   TINYINT       NOT NULL,
    FechaInicio      DATE          NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    FechaUltMod      DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    Observaciones    VARCHAR(500)  NULL,

    CONSTRAINT PK_Tramite PRIMARY KEY (IdTramite),
    CONSTRAINT FK_Tramite_Matricula
        FOREIGN KEY (IdMatricula) REFERENCES Academico.Matricula(IdMatricula),
    CONSTRAINT FK_Tramite_TipoTramite
        FOREIGN KEY (IdTipoTramite) REFERENCES Catalogo.TipoTramite(IdTipoTramite),
    CONSTRAINT FK_Tramite_EstadoTramite
        FOREIGN KEY (IdEstadoTramite) REFERENCES Catalogo.EstadoTramite(IdEstadoTramite),
    CONSTRAINT FK_Tramite_Coordinacion
        FOREIGN KEY (IdCoordinacion) REFERENCES Tramite.CoordinacionGT(IdCoordinacion)
);
GO

-- ---------------------------------------------------------------------
-- T12: PAGO
-- Pagos asociados al tramite (Art. 23, 49)
-- ---------------------------------------------------------------------
CREATE TABLE Tramite.Pago (
    IdPago       INT             NOT NULL IDENTITY(1,1),
    IdTramite    INT             NOT NULL,
    TipoPago     VARCHAR(25)     NOT NULL,
    -- BACHILLER, TESIS_5PCT, TESIS_40PCT, TESIS_TOTAL,
    -- AMPLIACION, CAMBIO_TITULO, POSTERGACION, NUEVO_PLAN
    Monto        DECIMAL(10,2)   NOT NULL,
    Porcentaje   DECIMAL(5,2)    NULL,  -- 5.00, 40.00, 100.00
    FechaPago    DATE            NOT NULL,
    NroRecibo    VARCHAR(30)     NULL,

    CONSTRAINT PK_Pago PRIMARY KEY (IdPago),
    CONSTRAINT FK_Pago_Tramite
        FOREIGN KEY (IdTramite) REFERENCES Tramite.Tramite(IdTramite),
    CONSTRAINT CHK_Pago_Monto CHECK (Monto > 0),
    CONSTRAINT CHK_Pago_Tipo CHECK (TipoPago IN (
        'BACHILLER', 'TESIS_5PCT', 'TESIS_40PCT', 'TESIS_TOTAL',
        'AMPLIACION', 'CAMBIO_TITULO', 'POSTERGACION', 'NUEVO_PLAN',
        'SUFICIENCIA_40PCT', 'SUFICIENCIA_TOTAL'
    ))
);
GO

-- ---------------------------------------------------------------------
-- T13: FOTOGRAFIA
-- Datos de la fotografia requerida en el tramite (Art. 15)
-- ---------------------------------------------------------------------
CREATE TABLE Tramite.Fotografia (
    IdFoto           INT           NOT NULL IDENTITY(1,1),
    IdTramite        INT           NOT NULL,
    Formato          VARCHAR(5)    NOT NULL DEFAULT 'JPG',
    TamanioKB        SMALLINT      NOT NULL, -- max 70 KB
    ResolucionPPP    SMALLINT      NOT NULL, -- max 300 ppp
    Dimensiones      VARCHAR(15)   NOT NULL DEFAULT '35x43mm',
    RutaArchivo      VARCHAR(300)  NULL,
    FechaCarga       DATETIME2     NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Fotografia PRIMARY KEY (IdFoto),
    CONSTRAINT FK_Foto_Tramite
        FOREIGN KEY (IdTramite) REFERENCES Tramite.Tramite(IdTramite),
    CONSTRAINT CHK_Foto_Formato CHECK (Formato IN ('JPG', 'JPEG')),
    CONSTRAINT CHK_Foto_Tamanio CHECK (TamanioKB BETWEEN 1 AND 70),
    CONSTRAINT CHK_Foto_Resolucion CHECK (ResolucionPPP BETWEEN 72 AND 300)
);
GO

-- =====================================================================
-- 8. TABLAS DEL TRABAJO DE INVESTIGACION
-- =====================================================================

-- ---------------------------------------------------------------------
-- T14: TRABAJO_INVESTIGACION
-- Tesis o Trabajo de Suficiencia Profesional (Art. 31, 47)
-- ---------------------------------------------------------------------
CREATE TABLE Tramite.TrabajoInvestigacion (
    IdTrabajo             INT             NOT NULL IDENTITY(1,1),
    IdTramite             INT             NOT NULL,
    IdLinea               SMALLINT        NOT NULL,
    TipoTrabajo           VARCHAR(25)     NOT NULL,
    -- TESIS_CUANTITATIVA, TESIS_CUALITATIVA,
    -- TESIS_MIXTA, SUFICIENCIA_PROFESIONAL
    Titulo                NVARCHAR(400)   NOT NULL,
    FechaInicio           DATE            NOT NULL,
    FechaFin              DATE            NULL,
    ModalidadAutoria      VARCHAR(12)     NOT NULL DEFAULT 'INDIVIDUAL',
    -- INDIVIDUAL, GRUPAL (solo tesis, max 2)
    PorcentajeSimilitud   DECIMAL(5,2)    NULL, -- resultado final antiplagio
    UrlRepositorio        VARCHAR(500)    NULL,
    FechaRegistro         DATETIME2       NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_TrabajoInvestigacion PRIMARY KEY (IdTrabajo),
    CONSTRAINT FK_Trabajo_Tramite
        FOREIGN KEY (IdTramite) REFERENCES Tramite.Tramite(IdTramite),
    CONSTRAINT FK_Trabajo_Linea
        FOREIGN KEY (IdLinea) REFERENCES Catalogo.LineaInvestigacion(IdLinea),
    CONSTRAINT CHK_Trabajo_Tipo CHECK (TipoTrabajo IN (
        'TESIS_CUANTITATIVA', 'TESIS_CUALITATIVA',
        'TESIS_MIXTA', 'SUFICIENCIA_PROFESIONAL'
    )),
    CONSTRAINT CHK_Trabajo_Autoria
        CHECK (ModalidadAutoria IN ('INDIVIDUAL', 'GRUPAL')),
    CONSTRAINT CHK_Trabajo_Similitud
        CHECK (PorcentajeSimilitud IS NULL OR PorcentajeSimilitud BETWEEN 0 AND 100)
);
GO

-- ---------------------------------------------------------------------
-- T15: PLAN_TESIS
-- Plan metodologico previo al desarrollo de la tesis (Art. 20)
-- ---------------------------------------------------------------------
CREATE TABLE Tramite.PlanTesis (
    IdPlan            INT             NOT NULL IDENTITY(1,1),
    IdTrabajo         INT             NOT NULL,
    TituloPlan        NVARCHAR(400)   NOT NULL,
    FechaAprobacion   DATE            NULL,
    FechaInicio       DATE            NOT NULL,
    FechaFin          DATE            NOT NULL,
    EstadoPlan        VARCHAR(15)     NOT NULL DEFAULT 'VIGENTE',
    -- VIGENTE, AMPLIADO, SIN_EFECTO

    CONSTRAINT PK_PlanTesis PRIMARY KEY (IdPlan),
    CONSTRAINT FK_Plan_Trabajo
        FOREIGN KEY (IdTrabajo) REFERENCES Tramite.TrabajoInvestigacion(IdTrabajo),
    CONSTRAINT CHK_Plan_Estado
        CHECK (EstadoPlan IN ('VIGENTE', 'AMPLIADO', 'SIN_EFECTO')),
    CONSTRAINT CHK_Plan_Fechas
        CHECK (FechaFin >= FechaInicio)
);
GO

-- ---------------------------------------------------------------------
-- T16: DESIGNACION_ASESOR
-- Asignacion del asesor al trabajo (Art. 24, 66)
-- ---------------------------------------------------------------------
CREATE TABLE Tramite.DesignacionAsesor (
    IdDesignacion      INT           NOT NULL IDENTITY(1,1),
    IdTrabajo          INT           NOT NULL,
    IdDocente          INT           NOT NULL,
    FechaDesignacion   DATE          NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    NroResolucion      VARCHAR(40)   NOT NULL,
    Estado             VARCHAR(12)   NOT NULL DEFAULT 'ACTIVO',
    -- ACTIVO, SUSTITUIDO, RENUNCIADO
    MotivoRetiro       VARCHAR(200)  NULL,

    CONSTRAINT PK_DesignacionAsesor PRIMARY KEY (IdDesignacion),
    CONSTRAINT FK_DesigAsesor_Trabajo
        FOREIGN KEY (IdTrabajo) REFERENCES Tramite.TrabajoInvestigacion(IdTrabajo),
    CONSTRAINT FK_DesigAsesor_Docente
        FOREIGN KEY (IdDocente) REFERENCES Academico.Docente(IdDocente),
    CONSTRAINT CHK_DesigAsesor_Estado
        CHECK (Estado IN ('ACTIVO', 'SUSTITUIDO', 'RENUNCIADO'))
);
GO

-- ---------------------------------------------------------------------
-- T17: DESIGNACION_JURADO
-- Asignacion de jurados revisores/evaluadores (Art. 34, 72)
-- ---------------------------------------------------------------------
CREATE TABLE Tramite.DesignacionJurado (
    IdDesigJurado      INT           NOT NULL IDENTITY(1,1),
    IdTrabajo          INT           NOT NULL,
    IdDocente          INT           NOT NULL,
    NroResolucion      VARCHAR(40)   NOT NULL,
    RolJurado          VARCHAR(12)   NOT NULL,
    -- TITULAR_1, TITULAR_2, TITULAR_3, SUPLENTE
    Estado             VARCHAR(12)   NOT NULL DEFAULT 'DESIGNADO',
    -- DESIGNADO, REEMPLAZADO, INASISTENTE
    FechaDesignacion   DATE          NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),

    CONSTRAINT PK_DesignacionJurado PRIMARY KEY (IdDesigJurado),
    CONSTRAINT FK_DesigJurado_Trabajo
        FOREIGN KEY (IdTrabajo) REFERENCES Tramite.TrabajoInvestigacion(IdTrabajo),
    CONSTRAINT FK_DesigJurado_Docente
        FOREIGN KEY (IdDocente) REFERENCES Academico.Docente(IdDocente),
    CONSTRAINT CHK_DesigJurado_Rol
        CHECK (RolJurado IN ('TITULAR_1', 'TITULAR_2', 'TITULAR_3', 'SUPLENTE')),
    CONSTRAINT CHK_DesigJurado_Estado
        CHECK (Estado IN ('DESIGNADO', 'REEMPLAZADO', 'INASISTENTE'))
);
GO

-- ---------------------------------------------------------------------
-- T18: EXPERIENCIA_LABORAL
-- Para modalidad suficiencia profesional (Art. 49 inc. c)
-- Minimo 2 anios acumulativos despues del grado de bachiller
-- ---------------------------------------------------------------------
CREATE TABLE Tramite.ExperienciaLaboral (
    IdExperiencia       INT             NOT NULL IDENTITY(1,1),
    IdTramite           INT             NOT NULL,
    NombreEntidad       VARCHAR(200)    NOT NULL,
    TipoEntidad         VARCHAR(8)      NOT NULL, -- PUBLICA, PRIVADA
    Cargo                VARCHAR(150)    NULL,
    FechaInicio          DATE            NOT NULL,
    FechaFin             DATE            NULL,     -- NULL si sigue activo
    AniosAcumulados      DECIMAL(4,2)    NULL,
    NroCertificadoTrab   VARCHAR(60)     NULL,
    TipoDocPago          VARCHAR(20)     NULL,
    -- BOLETA_PAGO, RECIBO_HONORARIOS

    CONSTRAINT PK_ExperienciaLaboral PRIMARY KEY (IdExperiencia),
    CONSTRAINT FK_ExpLaboral_Tramite
        FOREIGN KEY (IdTramite) REFERENCES Tramite.Tramite(IdTramite),
    CONSTRAINT CHK_ExpLaboral_TipoEntidad
        CHECK (TipoEntidad IN ('PUBLICA', 'PRIVADA')),
    CONSTRAINT CHK_ExpLaboral_Fechas
        CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio),
    CONSTRAINT CHK_ExpLaboral_TipoDoc
        CHECK (TipoDocPago IS NULL OR TipoDocPago IN ('BOLETA_PAGO', 'RECIBO_HONORARIOS'))
);
GO

-- =====================================================================
-- 9. TABLAS DE EVALUACION
-- =====================================================================

-- ---------------------------------------------------------------------
-- T19: EVALUACION_TRABAJO
-- Evaluaciones formales del asesor y jurados (Anexos 3-7)
-- ---------------------------------------------------------------------
CREATE TABLE Evaluacion.EvaluacionTrabajo (
    IdEvaluacion       INT             NOT NULL IDENTITY(1,1),
    IdTrabajo          INT             NOT NULL,
    IdEvaluador        INT             NOT NULL, -- FK -> Docente
    TipoEvaluador      VARCHAR(8)      NOT NULL, -- ASESOR, JURADO
    EtapaEvaluacion    VARCHAR(18)     NOT NULL,
    -- PLAN, INFORME_FINAL, SUSTENTACION
    PuntajeObtenido    DECIMAL(5,2)    NULL,
    Condicion          VARCHAR(20)     NULL,
    -- APROBADO, OBS_MENORES, OBS_MAYORES, DESAPROBADO
    FechaEvaluacion    DATE            NULL,
    Observaciones      NVARCHAR(2000)  NULL,

    CONSTRAINT PK_EvaluacionTrabajo PRIMARY KEY (IdEvaluacion),
    CONSTRAINT FK_Eval_Trabajo
        FOREIGN KEY (IdTrabajo) REFERENCES Tramite.TrabajoInvestigacion(IdTrabajo),
    CONSTRAINT FK_Eval_Docente
        FOREIGN KEY (IdEvaluador) REFERENCES Academico.Docente(IdDocente),
    CONSTRAINT CHK_Eval_TipoEval
        CHECK (TipoEvaluador IN ('ASESOR', 'JURADO')),
    CONSTRAINT CHK_Eval_Etapa
        CHECK (EtapaEvaluacion IN ('PLAN', 'INFORME_FINAL', 'SUSTENTACION')),
    CONSTRAINT CHK_Eval_Condicion CHECK (Condicion IS NULL OR Condicion IN (
        'APROBADO', 'OBS_MENORES', 'OBS_MAYORES', 'DESAPROBADO'
    )),
    CONSTRAINT CHK_Eval_Puntaje
        CHECK (PuntajeObtenido IS NULL OR PuntajeObtenido BETWEEN 0 AND 40)
);
GO

-- ---------------------------------------------------------------------
-- T20: DICTAMEN_ETICA
-- Pronunciamiento del Comite de Etica (Art. 24 inc. c, 34)
-- ---------------------------------------------------------------------
CREATE TABLE Evaluacion.DictamenEtica (
    IdDictamen       INT             NOT NULL IDENTITY(1,1),
    IdTrabajo        INT             NOT NULL,
    Etapa            VARCHAR(15)     NOT NULL, -- PLAN, INFORME_FINAL
    Resultado        VARCHAR(10)     NOT NULL, -- CONFORME, OBSERVADO
    Observaciones    NVARCHAR(2000)  NULL,
    FechaDictamen    DATE            NULL,

    CONSTRAINT PK_DictamenEtica PRIMARY KEY (IdDictamen),
    CONSTRAINT FK_Dictamen_Trabajo
        FOREIGN KEY (IdTrabajo) REFERENCES Tramite.TrabajoInvestigacion(IdTrabajo),
    CONSTRAINT CHK_Dictamen_Etapa
        CHECK (Etapa IN ('PLAN', 'INFORME_FINAL')),
    CONSTRAINT CHK_Dictamen_Resultado
        CHECK (Resultado IN ('CONFORME', 'OBSERVADO'))
);
GO

-- ---------------------------------------------------------------------
-- T21: CONTROL_SIMILITUD
-- Control antiplagio - maximo 3 intentos (Art. 7, Art. 35 inc. e)
-- ---------------------------------------------------------------------
CREATE TABLE Evaluacion.ControlSimilitud (
    IdControl       INT             NOT NULL IDENTITY(1,1),
    IdTrabajo       INT             NOT NULL,
    NroIntento      TINYINT         NOT NULL, -- 1, 2 o 3 (maximo)
    Porcentaje      DECIMAL(5,2)    NOT NULL,
    Resultado       VARCHAR(10)     NOT NULL, -- CONFORME, OBSERVADO
    FechaRevision   DATE            NOT NULL,
    NroConstancia   VARCHAR(60)     NULL,

    CONSTRAINT PK_ControlSimilitud PRIMARY KEY (IdControl),
    CONSTRAINT FK_CtrlSim_Trabajo
        FOREIGN KEY (IdTrabajo) REFERENCES Tramite.TrabajoInvestigacion(IdTrabajo),
    CONSTRAINT CHK_CtrlSim_Intento
        CHECK (NroIntento BETWEEN 1 AND 3),
    CONSTRAINT CHK_CtrlSim_Porcentaje
        CHECK (Porcentaje BETWEEN 0 AND 100),
    CONSTRAINT CHK_CtrlSim_Resultado
        CHECK (Resultado IN ('CONFORME', 'OBSERVADO')),
    CONSTRAINT UQ_CtrlSim_Trabajo_Intento
        UNIQUE (IdTrabajo, NroIntento)
);
GO

-- ---------------------------------------------------------------------
-- T22: SUSTENTACION
-- Acto de sustentacion y calificacion (Art. 37, 55, 60)
-- Maximo 2 intentos por trabajo
-- ---------------------------------------------------------------------
CREATE TABLE Evaluacion.Sustentacion (
    IdSustentacion       INT             NOT NULL IDENTITY(1,1),
    IdTrabajo            INT             NOT NULL,
    NroIntento           TINYINT         NOT NULL DEFAULT 1, -- max 2
    FechaHora            DATETIME2       NOT NULL,
    Modalidad            VARCHAR(14)     NOT NULL DEFAULT 'PRESENCIAL',
    -- PRESENCIAL, NO_PRESENCIAL
    DuracionMinutos      TINYINT         NULL, -- max 45
    NotaExposicion       DECIMAL(4,2)    NULL,
    NotaDefensa          DECIMAL(4,2)    NULL,
    NotaConocimientos    DECIMAL(4,2)    NULL, -- solo suficiencia profesional
    Condicion            VARCHAR(12)     NULL, -- APROBADO, DESAPROBADO
    AprobacionTipo       VARCHAR(12)     NULL, -- UNANIMIDAD, MAYORIA
    NroActa              VARCHAR(40)     NULL,

    CONSTRAINT PK_Sustentacion PRIMARY KEY (IdSustentacion),
    CONSTRAINT FK_Sust_Trabajo
        FOREIGN KEY (IdTrabajo) REFERENCES Tramite.TrabajoInvestigacion(IdTrabajo),
    CONSTRAINT CHK_Sust_Intento
        CHECK (NroIntento BETWEEN 1 AND 2),
    CONSTRAINT CHK_Sust_Modalidad
        CHECK (Modalidad IN ('PRESENCIAL', 'NO_PRESENCIAL')),
    CONSTRAINT CHK_Sust_Duracion
        CHECK (DuracionMinutos IS NULL OR DuracionMinutos <= 45),
    CONSTRAINT CHK_Sust_Notas CHECK (
        (NotaExposicion IS NULL OR NotaExposicion BETWEEN 0 AND 20) AND
        (NotaDefensa IS NULL OR NotaDefensa BETWEEN 0 AND 20) AND
        (NotaConocimientos IS NULL OR NotaConocimientos BETWEEN 0 AND 20)
    ),
    CONSTRAINT CHK_Sust_Condicion
        CHECK (Condicion IS NULL OR Condicion IN ('APROBADO', 'DESAPROBADO')),
    CONSTRAINT CHK_Sust_Aprobacion
        CHECK (AprobacionTipo IS NULL OR AprobacionTipo IN ('UNANIMIDAD', 'MAYORIA')),
    CONSTRAINT UQ_Sust_Trabajo_Intento
        UNIQUE (IdTrabajo, NroIntento)
);
GO

-- =====================================================================
-- 10. TABLAS DE DOCUMENTOS
-- =====================================================================

-- ---------------------------------------------------------------------
-- T23: RESOLUCION
-- Resoluciones emitidas durante el proceso (Art. 24, 34, 36)
-- ---------------------------------------------------------------------
CREATE TABLE Documento.Resolucion (
    IdResolucion     INT            NOT NULL IDENTITY(1,1),
    IdTramite        INT            NOT NULL,
    TipoResolucion   VARCHAR(30)    NOT NULL,
    -- APROBACION_PLAN, DESIGNACION_ASESOR, DESIGNACION_JURADO,
    -- EXPEDITO, APROBACION_BACHILLER, APROBACION_TITULO,
    -- CAMBIO_TITULO, CAMBIO_ASESOR, CAMBIO_JURADO, AMPLIACION_PLAZO
    NroResolucion    VARCHAR(50)    NOT NULL,
    FechaEmision     DATE           NOT NULL,
    OrganoEmisor     VARCHAR(25)    NOT NULL,
    -- DECANO, CONSEJO_FACULTAD, CONSEJO_UNIVERSITARIO
    Descripcion      VARCHAR(500)   NULL,

    CONSTRAINT PK_Resolucion PRIMARY KEY (IdResolucion),
    CONSTRAINT FK_Resolucion_Tramite
        FOREIGN KEY (IdTramite) REFERENCES Tramite.Tramite(IdTramite),
    CONSTRAINT UQ_Resolucion_Nro UNIQUE (NroResolucion),
    CONSTRAINT CHK_Resolucion_Tipo CHECK (TipoResolucion IN (
        'APROBACION_PLAN', 'DESIGNACION_ASESOR',
        'DESIGNACION_JURADO', 'EXPEDITO',
        'APROBACION_BACHILLER', 'APROBACION_TITULO',
        'CAMBIO_TITULO', 'CAMBIO_ASESOR',
        'CAMBIO_JURADO', 'AMPLIACION_PLAZO'
    )),
    CONSTRAINT CHK_Resolucion_Organo CHECK (OrganoEmisor IN (
        'DECANO', 'CONSEJO_FACULTAD', 'CONSEJO_UNIVERSITARIO'
    ))
);
GO

-- ---------------------------------------------------------------------
-- T24: DIPLOMA
-- Diploma de bachiller o titulo profesional (Art. 9, 11)
-- ---------------------------------------------------------------------
CREATE TABLE Documento.Diploma (
    IdDiploma             INT           NOT NULL IDENTITY(1,1),
    IdTramite             INT           NOT NULL,
    TipoDiploma           VARCHAR(20)   NOT NULL, -- BACHILLER, TITULO_PROFESIONAL
    NroDiploma            VARCHAR(40)   NULL,
    FechaExpedicion       DATE          NULL,
    FechaRegistroSunedu   DATE          NULL,
    FirmanteRector        VARCHAR(150)  NULL,
    FirmanteDecano        VARCHAR(150)  NULL,
    FirmanteSecretario    VARCHAR(150)  NULL,
    EsDuplicado           BIT           NOT NULL DEFAULT 0,
    FechaDuplicado        DATE          NULL,
    MotivosDuplicado      VARCHAR(200)  NULL, -- PERDIDA, DETERIORO

    CONSTRAINT PK_Diploma PRIMARY KEY (IdDiploma),
    CONSTRAINT FK_Diploma_Tramite
        FOREIGN KEY (IdTramite) REFERENCES Tramite.Tramite(IdTramite),
    CONSTRAINT UQ_Diploma_Nro UNIQUE (NroDiploma),
    CONSTRAINT CHK_Diploma_Tipo
        CHECK (TipoDiploma IN ('BACHILLER', 'TITULO_PROFESIONAL')),
    CONSTRAINT CHK_Diploma_Duplicado
        CHECK (EsDuplicado = 0 OR MotivosDuplicado IS NOT NULL)
);
GO

-- ---------------------------------------------------------------------
-- T25: OBSERVACION_TRAMITE
-- Observaciones y subsanaciones durante el proceso (Art. 15, 35)
-- ---------------------------------------------------------------------
CREATE TABLE Tramite.ObservacionTramite (
    IdObservacion          INT             NOT NULL IDENTITY(1,1),
    IdTramite              INT             NOT NULL,
    TipoObservacion        VARCHAR(15)     NOT NULL,
    -- FORMATO, METODOLOGIA, ETICA, SIMILITUD, ADMINISTRATIVA
    Descripcion            NVARCHAR(2000)  NOT NULL,
    FechaObservacion       DATE            NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    PlazoSubsanacionDias   SMALLINT        NULL,
    FechaSubsanacion       DATE            NULL,
    Estado                 VARCHAR(12)     NOT NULL DEFAULT 'PENDIENTE',
    -- PENDIENTE, SUBSANADO, ARCHIVADO

    CONSTRAINT PK_ObservacionTramite PRIMARY KEY (IdObservacion),
    CONSTRAINT FK_Obs_Tramite
        FOREIGN KEY (IdTramite) REFERENCES Tramite.Tramite(IdTramite),
    CONSTRAINT CHK_Obs_Tipo CHECK (TipoObservacion IN (
        'FORMATO', 'METODOLOGIA', 'ETICA', 'SIMILITUD', 'ADMINISTRATIVA'
    )),
    CONSTRAINT CHK_Obs_Estado
        CHECK (Estado IN ('PENDIENTE', 'SUBSANADO', 'ARCHIVADO')),
    CONSTRAINT CHK_Obs_Plazo
        CHECK (PlazoSubsanacionDias IS NULL OR PlazoSubsanacionDias > 0)
);
GO

-- =====================================================================
-- 10B. TABLAS DE SEGURIDAD Y GESTION DE ROLES (RBAC)
-- Persona = identidad academica/institucional
-- Usuario = cuenta de acceso al sistema
-- Rol = funcion de acceso; Permiso = operacion autorizada
-- =====================================================================

CREATE TABLE Seguridad.Rol (
    IdRol           SMALLINT      NOT NULL IDENTITY(1,1),
    NombreRol       VARCHAR(50)   NOT NULL,
    Descripcion     VARCHAR(250)  NULL,
    EsSistema       BIT           NOT NULL DEFAULT 0,
    Activo          BIT           NOT NULL DEFAULT 1,
    FechaCreacion   DATETIME2     NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_Rol PRIMARY KEY (IdRol),
    CONSTRAINT UQ_Rol_Nombre UNIQUE (NombreRol)
);
GO

INSERT INTO Seguridad.Rol (NombreRol, Descripcion, EsSistema) VALUES
('ADMINISTRADOR', 'Administracion integral del sistema y gestion de usuarios.', 1),
('SECRETARIA', 'Gestion administrativa de expedientes y tramites.', 0),
('COORDINADOR', 'Gestion y seguimiento de tramites de grados y titulos.', 0),
('DOCENTE', 'Funciones academicas dentro del sistema.', 0),
('ASESOR', 'Asesoramiento de trabajos de investigacion.', 0),
('JURADO', 'Evaluacion y participacion en sustentaciones.', 0),
('ESTUDIANTE', 'Gestion y consulta del propio tramite academico.', 0),
('DECANO', 'Gestion y aprobacion de procesos de autoridad academica.', 0),
('CONSULTA', 'Acceso limitado a informacion autorizada.', 0);
GO

CREATE TABLE Seguridad.Permiso (
    IdPermiso        INT           NOT NULL IDENTITY(1,1),
    CodigoPermiso    VARCHAR(80)   NOT NULL,
    NombrePermiso    VARCHAR(100)  NOT NULL,
    Descripcion      VARCHAR(250)  NULL,
    Modulo           VARCHAR(50)   NOT NULL,
    Activo           BIT           NOT NULL DEFAULT 1,

    CONSTRAINT PK_Permiso PRIMARY KEY (IdPermiso),
    CONSTRAINT UQ_Permiso_Codigo UNIQUE (CodigoPermiso)
);
GO

INSERT INTO Seguridad.Permiso (CodigoPermiso, NombrePermiso, Descripcion, Modulo) VALUES
('PERSONA.CONSULTAR', 'Consultar personas', 'Permite consultar informacion de personas.', 'PERSONAS'),
('PERSONA.REGISTRAR', 'Registrar personas', 'Permite registrar nuevas personas.', 'PERSONAS'),
('PERSONA.MODIFICAR', 'Modificar personas', 'Permite modificar informacion de personas.', 'PERSONAS'),
('TRAMITE.CONSULTAR', 'Consultar tramites', 'Permite consultar tramites.', 'TRAMITES'),
('TRAMITE.REGISTRAR', 'Registrar tramites', 'Permite registrar tramites.', 'TRAMITES'),
('TRAMITE.MODIFICAR', 'Modificar tramites', 'Permite modificar tramites.', 'TRAMITES'),
('TRABAJO.CONSULTAR', 'Consultar trabajos', 'Permite consultar trabajos de investigacion.', 'INVESTIGACION'),
('TRABAJO.REGISTRAR', 'Registrar trabajos', 'Permite registrar trabajos de investigacion.', 'INVESTIGACION'),
('TRABAJO.MODIFICAR', 'Modificar trabajos', 'Permite modificar trabajos de investigacion.', 'INVESTIGACION'),
('EVALUACION.CONSULTAR', 'Consultar evaluaciones', 'Permite consultar evaluaciones.', 'EVALUACION'),
('EVALUACION.REGISTRAR', 'Registrar evaluaciones', 'Permite registrar evaluaciones.', 'EVALUACION'),
('EVALUACION.MODIFICAR', 'Modificar evaluaciones', 'Permite modificar evaluaciones.', 'EVALUACION'),
('DOCUMENTO.CONSULTAR', 'Consultar documentos', 'Permite consultar documentos.', 'DOCUMENTOS'),
('DOCUMENTO.REGISTRAR', 'Registrar documentos', 'Permite registrar documentos.', 'DOCUMENTOS'),
('USUARIO.CONSULTAR', 'Consultar usuarios', 'Permite consultar usuarios.', 'SEGURIDAD'),
('USUARIO.REGISTRAR', 'Registrar usuarios', 'Permite registrar usuarios.', 'SEGURIDAD'),
('USUARIO.MODIFICAR', 'Modificar usuarios', 'Permite modificar usuarios.', 'SEGURIDAD'),
('ROL.GESTIONAR', 'Gestionar roles', 'Permite administrar roles del sistema.', 'SEGURIDAD');
GO

CREATE TABLE Seguridad.Usuario (
    IdUsuario               INT              NOT NULL IDENTITY(1,1),
    IdPersona               INT              NULL,
    NombreUsuario            VARCHAR(60)      NOT NULL,
    PasswordHash             VARBINARY(256)   NOT NULL,
    PasswordSalt             VARBINARY(128)   NOT NULL,
    CorreoInstitucional      VARCHAR(150)     NULL,
    Estado                   VARCHAR(15)      NOT NULL DEFAULT 'ACTIVO',
    IntentosFallidos         TINYINT          NOT NULL DEFAULT 0,
    Bloqueado                BIT              NOT NULL DEFAULT 0,
    FechaUltimoAcceso        DATETIME2        NULL,
    FechaCreacion            DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    FechaModificacion        DATETIME2        NULL,

    CONSTRAINT PK_Usuario PRIMARY KEY (IdUsuario),
    CONSTRAINT UQ_Usuario_Persona UNIQUE (IdPersona),
    CONSTRAINT UQ_Usuario_Nombre UNIQUE (NombreUsuario),
    CONSTRAINT UQ_Usuario_Correo UNIQUE (CorreoInstitucional),
    CONSTRAINT FK_Usuario_Persona FOREIGN KEY (IdPersona) REFERENCES Academico.Persona(IdPersona),
    CONSTRAINT CHK_Usuario_Estado CHECK (Estado IN ('ACTIVO', 'INACTIVO', 'BLOQUEADO', 'PENDIENTE')),
    CONSTRAINT CHK_Usuario_Intentos CHECK (IntentosFallidos BETWEEN 0 AND 10),
    CONSTRAINT CHK_Usuario_Bloqueo CHECK (Bloqueado = 0 OR Estado = 'BLOQUEADO')
);
GO

CREATE TABLE Seguridad.UsuarioRol (
    IdUsuarioRol       BIGINT       NOT NULL IDENTITY(1,1),
    IdUsuario          INT          NOT NULL,
    IdRol              SMALLINT     NOT NULL,
    FechaAsignacion    DATETIME2    NOT NULL DEFAULT SYSDATETIME(),
    FechaInicio        DATE         NOT NULL DEFAULT CAST(SYSDATETIME() AS DATE),
    FechaFin           DATE         NULL,
    Activo             BIT          NOT NULL DEFAULT 1,
    Observacion        VARCHAR(250) NULL,

    CONSTRAINT PK_UsuarioRol PRIMARY KEY (IdUsuarioRol),
    CONSTRAINT FK_UsuarioRol_Usuario FOREIGN KEY (IdUsuario) REFERENCES Seguridad.Usuario(IdUsuario),
    CONSTRAINT FK_UsuarioRol_Rol FOREIGN KEY (IdRol) REFERENCES Seguridad.Rol(IdRol),
    CONSTRAINT UQ_UsuarioRol UNIQUE (IdUsuario, IdRol),
    CONSTRAINT CHK_UsuarioRol_Fechas CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio)
);
GO

CREATE TABLE Seguridad.RolPermiso (
    IdRolPermiso       BIGINT      NOT NULL IDENTITY(1,1),
    IdRol              SMALLINT    NOT NULL,
    IdPermiso          INT         NOT NULL,
    FechaAsignacion    DATETIME2   NOT NULL DEFAULT SYSDATETIME(),
    Activo             BIT         NOT NULL DEFAULT 1,

    CONSTRAINT PK_RolPermiso PRIMARY KEY (IdRolPermiso),
    CONSTRAINT FK_RolPermiso_Rol FOREIGN KEY (IdRol) REFERENCES Seguridad.Rol(IdRol),
    CONSTRAINT FK_RolPermiso_Permiso FOREIGN KEY (IdPermiso) REFERENCES Seguridad.Permiso(IdPermiso),
    CONSTRAINT UQ_RolPermiso UNIQUE (IdRol, IdPermiso)
);
GO

-- Permisos por rol
INSERT INTO Seguridad.RolPermiso(IdRol,IdPermiso)
SELECT r.IdRol,p.IdPermiso FROM Seguridad.Rol r CROSS JOIN Seguridad.Permiso p
WHERE r.NombreRol='ADMINISTRADOR';
GO

INSERT INTO Seguridad.RolPermiso(IdRol,IdPermiso)
SELECT r.IdRol,p.IdPermiso FROM Seguridad.Rol r CROSS JOIN Seguridad.Permiso p
WHERE r.NombreRol='SECRETARIA' AND p.CodigoPermiso IN
('PERSONA.CONSULTAR','PERSONA.REGISTRAR','PERSONA.MODIFICAR','TRAMITE.CONSULTAR',
 'TRAMITE.REGISTRAR','TRAMITE.MODIFICAR','DOCUMENTO.CONSULTAR','DOCUMENTO.REGISTRAR');
GO

INSERT INTO Seguridad.RolPermiso(IdRol,IdPermiso)
SELECT r.IdRol,p.IdPermiso FROM Seguridad.Rol r CROSS JOIN Seguridad.Permiso p
WHERE r.NombreRol='COORDINADOR' AND p.CodigoPermiso IN
('PERSONA.CONSULTAR','TRAMITE.CONSULTAR','TRAMITE.REGISTRAR','TRAMITE.MODIFICAR',
 'TRABAJO.CONSULTAR','DOCUMENTO.CONSULTAR');
GO

INSERT INTO Seguridad.RolPermiso(IdRol,IdPermiso)
SELECT r.IdRol,p.IdPermiso FROM Seguridad.Rol r CROSS JOIN Seguridad.Permiso p
WHERE r.NombreRol='DOCENTE' AND p.CodigoPermiso IN
('PERSONA.CONSULTAR','TRABAJO.CONSULTAR','EVALUACION.CONSULTAR');
GO

INSERT INTO Seguridad.RolPermiso(IdRol,IdPermiso)
SELECT r.IdRol,p.IdPermiso FROM Seguridad.Rol r CROSS JOIN Seguridad.Permiso p
WHERE r.NombreRol='ASESOR' AND p.CodigoPermiso IN
('TRAMITE.CONSULTAR','TRABAJO.CONSULTAR','TRABAJO.MODIFICAR','EVALUACION.CONSULTAR',
 'EVALUACION.REGISTRAR');
GO

INSERT INTO Seguridad.RolPermiso(IdRol,IdPermiso)
SELECT r.IdRol,p.IdPermiso FROM Seguridad.Rol r CROSS JOIN Seguridad.Permiso p
WHERE r.NombreRol='JURADO' AND p.CodigoPermiso IN
('TRAMITE.CONSULTAR','TRABAJO.CONSULTAR','EVALUACION.CONSULTAR','EVALUACION.REGISTRAR',
 'EVALUACION.MODIFICAR');
GO

INSERT INTO Seguridad.RolPermiso(IdRol,IdPermiso)
SELECT r.IdRol,p.IdPermiso FROM Seguridad.Rol r CROSS JOIN Seguridad.Permiso p
WHERE r.NombreRol='ESTUDIANTE' AND p.CodigoPermiso IN
('TRAMITE.CONSULTAR','TRABAJO.CONSULTAR','EVALUACION.CONSULTAR','DOCUMENTO.CONSULTAR');
GO

INSERT INTO Seguridad.RolPermiso(IdRol,IdPermiso)
SELECT r.IdRol,p.IdPermiso FROM Seguridad.Rol r CROSS JOIN Seguridad.Permiso p
WHERE r.NombreRol='DECANO' AND p.CodigoPermiso IN
('PERSONA.CONSULTAR','TRAMITE.CONSULTAR','TRAMITE.MODIFICAR','TRABAJO.CONSULTAR',
 'EVALUACION.CONSULTAR','DOCUMENTO.CONSULTAR','DOCUMENTO.REGISTRAR');
GO

INSERT INTO Seguridad.RolPermiso(IdRol,IdPermiso)
SELECT r.IdRol,p.IdPermiso FROM Seguridad.Rol r CROSS JOIN Seguridad.Permiso p
WHERE r.NombreRol='CONSULTA' AND p.CodigoPermiso IN
('PERSONA.CONSULTAR','TRAMITE.CONSULTAR','TRABAJO.CONSULTAR','EVALUACION.CONSULTAR',
 'DOCUMENTO.CONSULTAR');
GO

-- =====================================================================
-- 10C. SEGURIDAD AVANZADA
-- Auditoria + autenticacion + politicas de acceso
-- + sesiones + MFA + seguridad del DBMS
-- =====================================================================

CREATE TABLE Seguridad.PoliticaPassword (
    IdPoliticaPassword    TINYINT      IDENTITY(1,1) NOT NULL,
    NombrePolitica        VARCHAR(80)  NOT NULL,
    LongitudMinima        TINYINT      NOT NULL DEFAULT 12,
    RequiereMayuscula     BIT          NOT NULL DEFAULT 1,
    RequiereMinuscula     BIT          NOT NULL DEFAULT 1,
    RequiereNumero        BIT          NOT NULL DEFAULT 1,
    RequiereEspecial      BIT          NOT NULL DEFAULT 1,
    MaximoIntentos        TINYINT      NOT NULL DEFAULT 5,
    DuracionDias          SMALLINT     NULL,
    HistorialPasswords    TINYINT      NOT NULL DEFAULT 5,
    BloqueoMinutos        SMALLINT     NOT NULL DEFAULT 15,
    Activa                BIT          NOT NULL DEFAULT 1,
    FechaCreacion         DATETIME2    NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_PoliticaPassword PRIMARY KEY (IdPoliticaPassword),
    CONSTRAINT UQ_PoliticaPassword_Nombre UNIQUE (NombrePolitica),
    CONSTRAINT CHK_PoliticaPassword_Longitud CHECK (LongitudMinima BETWEEN 8 AND 128),
    CONSTRAINT CHK_PoliticaPassword_Intentos CHECK (MaximoIntentos BETWEEN 1 AND 20),
    CONSTRAINT CHK_PoliticaPassword_Duracion CHECK (DuracionDias IS NULL OR DuracionDias BETWEEN 1 AND 365),
    CONSTRAINT CHK_PoliticaPassword_Historial CHECK (HistorialPasswords BETWEEN 0 AND 24),
    CONSTRAINT CHK_PoliticaPassword_Bloqueo CHECK (BloqueoMinutos BETWEEN 1 AND 1440)
);
GO

INSERT INTO Seguridad.PoliticaPassword
(NombrePolitica,LongitudMinima,RequiereMayuscula,RequiereMinuscula,
 RequiereNumero,RequiereEspecial,MaximoIntentos,DuracionDias,
 HistorialPasswords,BloqueoMinutos)
VALUES
('POLITICA_INSTITUCIONAL',12,1,1,1,1,5,90,5,15);
GO

CREATE TABLE Seguridad.PasswordHistorial (
    IdPasswordHistorial   BIGINT IDENTITY(1,1) NOT NULL,
    IdUsuario             INT NOT NULL,
    PasswordHash          VARBINARY(512) NOT NULL,
    Algoritmo             VARCHAR(30) NOT NULL,
    FechaCreacion          DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FechaExpiracion        DATETIME2 NULL,
    Activa                 BIT NOT NULL DEFAULT 1,

    CONSTRAINT PK_PasswordHistorial PRIMARY KEY (IdPasswordHistorial),
    CONSTRAINT FK_PasswordHistorial_Usuario FOREIGN KEY (IdUsuario) REFERENCES Seguridad.Usuario(IdUsuario),
    CONSTRAINT CHK_PasswordHistorial_Algoritmo CHECK (Algoritmo IN ('ARGON2ID','BCRYPT','PBKDF2','OTRO'))
);
GO

CREATE TABLE Seguridad.Sesion (
    IdSesion                 UNIQUEIDENTIFIER NOT NULL DEFAULT NEWSEQUENTIALID(),
    IdUsuario                INT NOT NULL,
    FechaInicio               DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FechaUltimaActividad      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FechaExpiracion           DATETIME2 NOT NULL,
    FechaCierre               DATETIME2 NULL,
    Estado                    VARCHAR(15) NOT NULL DEFAULT 'ACTIVA',
    DireccionIP               VARCHAR(45) NULL,
    UserAgent                 NVARCHAR(500) NULL,
    Dispositivo               VARCHAR(150) NULL,
    Revocada                  BIT NOT NULL DEFAULT 0,

    CONSTRAINT PK_Sesion PRIMARY KEY (IdSesion),
    CONSTRAINT FK_Sesion_Usuario FOREIGN KEY (IdUsuario) REFERENCES Seguridad.Usuario(IdUsuario),
    CONSTRAINT CHK_Sesion_Estado CHECK (Estado IN ('ACTIVA','CERRADA','EXPIRADA','REVOCADA')),
    CONSTRAINT CHK_Sesion_Fechas CHECK (FechaExpiracion > FechaInicio)
);
GO

CREATE TABLE Seguridad.PoliticaAcceso (
    IdPoliticaAcceso   INT IDENTITY(1,1) NOT NULL,
    NombrePolitica     VARCHAR(100) NOT NULL,
    Descripcion        VARCHAR(300) NULL,
    IdRol              SMALLINT NULL,
    HoraInicio         TIME(0) NULL,
    HoraFin            TIME(0) NULL,
    DiasSemana         VARCHAR(20) NULL,
    CIDRPermitido      VARCHAR(100) NULL,
    RequiereMFA        BIT NOT NULL DEFAULT 0,
    PermitirAcceso     BIT NOT NULL DEFAULT 1,
    Prioridad          SMALLINT NOT NULL DEFAULT 100,
    Activa             BIT NOT NULL DEFAULT 1,
    FechaCreacion      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_PoliticaAcceso PRIMARY KEY (IdPoliticaAcceso),
    CONSTRAINT UQ_PoliticaAcceso_Nombre UNIQUE (NombrePolitica),
    CONSTRAINT FK_PoliticaAcceso_Rol FOREIGN KEY (IdRol) REFERENCES Seguridad.Rol(IdRol),
    CONSTRAINT CHK_PoliticaAcceso_Prioridad CHECK (Prioridad BETWEEN 1 AND 1000)
);
GO

CREATE TABLE Seguridad.UsuarioPoliticaAcceso (
    IdUsuarioPolitica   BIGINT IDENTITY(1,1) NOT NULL,
    IdUsuario           INT NOT NULL,
    IdPoliticaAcceso    INT NOT NULL,
    FechaInicio          DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    FechaFin             DATETIME2 NULL,
    Activa               BIT NOT NULL DEFAULT 1,
    Motivo               VARCHAR(300) NULL,

    CONSTRAINT PK_UsuarioPoliticaAcceso PRIMARY KEY (IdUsuarioPolitica),
    CONSTRAINT FK_UsuarioPolitica_Usuario FOREIGN KEY (IdUsuario) REFERENCES Seguridad.Usuario(IdUsuario),
    CONSTRAINT FK_UsuarioPolitica_Politica FOREIGN KEY (IdPoliticaAcceso) REFERENCES Seguridad.PoliticaAcceso(IdPoliticaAcceso),
    CONSTRAINT CHK_UsuarioPolitica_Fechas CHECK (FechaFin IS NULL OR FechaFin >= FechaInicio)
);
GO

CREATE TABLE Seguridad.AuditoriaSeguridad (
    IdAuditoria     BIGINT IDENTITY(1,1) NOT NULL,
    FechaHora       DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    IdUsuario       INT NULL,
    NombreUsuario   VARCHAR(60) NULL,
    TipoEvento      VARCHAR(35) NOT NULL,
    Resultado       VARCHAR(15) NOT NULL,
    Modulo          VARCHAR(50) NULL,
    Accion          VARCHAR(80) NULL,
    DireccionIP     VARCHAR(45) NULL,
    UserAgent       NVARCHAR(500) NULL,
    IdSesion        UNIQUEIDENTIFIER NULL,
    Objeto          VARCHAR(150) NULL,
    Detalle         NVARCHAR(2000) NULL,
    DatosAntes      NVARCHAR(MAX) NULL,
    DatosDespues    NVARCHAR(MAX) NULL,
    CorrelationId   UNIQUEIDENTIFIER NULL,

    CONSTRAINT PK_AuditoriaSeguridad PRIMARY KEY (IdAuditoria),
    CONSTRAINT FK_AuditoriaSeguridad_Usuario FOREIGN KEY (IdUsuario) REFERENCES Seguridad.Usuario(IdUsuario),
    CONSTRAINT CHK_Auditoria_Evento CHECK (TipoEvento IN (
        'LOGIN','LOGOUT','LOGIN_FALLIDO','PASSWORD_CAMBIO',
        'PASSWORD_RESET','MFA','ACCESO_PERMITIDO','ACCESO_DENEGADO',
        'ROL_ASIGNADO','ROL_REVOCADO','PERMISO_ASIGNADO',
        'PERMISO_REVOCADO','CUENTA_BLOQUEADA','CUENTA_DESBLOQUEADA',
        'SESION_REVOCADA','POLITICA_VIOLADA','DATOS_SENSIBLES',
        'CONFIGURACION'
    )),
    CONSTRAINT CHK_Auditoria_Resultado CHECK (
        Resultado IN ('EXITOSO','FALLIDO','DENEGADO','ERROR','INFORMATIVO'))
);
GO

CREATE TABLE Seguridad.AuditoriaDatos (
    IdAuditoriaDatos   BIGINT IDENTITY(1,1) NOT NULL,
    FechaHora          DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    IdUsuario          INT NULL,
    IdSesion           UNIQUEIDENTIFIER NULL,
    Operacion          CHAR(1) NOT NULL,
    EsquemaObjeto      SYSNAME NOT NULL,
    NombreObjeto       SYSNAME NOT NULL,
    ClaveRegistro      NVARCHAR(500) NULL,
    DatosAntes         NVARCHAR(MAX) NULL,
    DatosDespues       NVARCHAR(MAX) NULL,
    DireccionIP        VARCHAR(45) NULL,
    CorrelationId      UNIQUEIDENTIFIER NULL,

    CONSTRAINT PK_AuditoriaDatos PRIMARY KEY (IdAuditoriaDatos),
    CONSTRAINT FK_AuditoriaDatos_Usuario FOREIGN KEY (IdUsuario) REFERENCES Seguridad.Usuario(IdUsuario),
    CONSTRAINT CHK_AuditoriaDatos_Operacion CHECK (Operacion IN ('I','U','D'))
);
GO

CREATE TABLE Seguridad.HistorialAutorizacion (
    IdHistorial          BIGINT IDENTITY(1,1) NOT NULL,
    FechaHora            DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    IdUsuarioObjetivo    INT NULL,
    IdUsuarioEjecutor    INT NULL,
    TipoCambio           VARCHAR(30) NOT NULL,
    IdRol                SMALLINT NULL,
    IdPermiso            INT NULL,
    Motivo               VARCHAR(500) NULL,
    ActivoAnterior       BIT NULL,
    ActivoNuevo          BIT NULL,

    CONSTRAINT PK_HistorialAutorizacion PRIMARY KEY (IdHistorial),
    CONSTRAINT FK_HistAut_UsuarioObjetivo FOREIGN KEY (IdUsuarioObjetivo) REFERENCES Seguridad.Usuario(IdUsuario),
    CONSTRAINT FK_HistAut_UsuarioEjecutor FOREIGN KEY (IdUsuarioEjecutor) REFERENCES Seguridad.Usuario(IdUsuario),
    CONSTRAINT FK_HistAut_Rol FOREIGN KEY (IdRol) REFERENCES Seguridad.Rol(IdRol),
    CONSTRAINT FK_HistAut_Permiso FOREIGN KEY (IdPermiso) REFERENCES Seguridad.Permiso(IdPermiso),
    CONSTRAINT CHK_HistAut_Tipo CHECK (TipoCambio IN (
        'ROL_ASIGNADO','ROL_REVOCADO','PERMISO_ASIGNADO','PERMISO_REVOCADO'))
);
GO

CREATE TABLE Seguridad.ConfiguracionDBMS (
    IdConfiguracion    INT IDENTITY(1,1) NOT NULL,
    Parametro          VARCHAR(100) NOT NULL,
    ValorConfigurado   VARCHAR(500) NOT NULL,
    ValorRecomendado   VARCHAR(500) NULL,
    Descripcion        VARCHAR(500) NULL,
    Criticidad         VARCHAR(15) NOT NULL DEFAULT 'MEDIA',
    FechaRevision      DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    RevisadoPor        INT NULL,
    Activo             BIT NOT NULL DEFAULT 1,

    CONSTRAINT PK_ConfiguracionDBMS PRIMARY KEY (IdConfiguracion),
    CONSTRAINT UQ_ConfiguracionDBMS_Parametro UNIQUE (Parametro),
    CONSTRAINT FK_ConfiguracionDBMS_Usuario FOREIGN KEY (RevisadoPor) REFERENCES Seguridad.Usuario(IdUsuario),
    CONSTRAINT CHK_ConfiguracionDBMS_Criticidad CHECK (Criticidad IN ('BAJA','MEDIA','ALTA','CRITICA'))
);
GO

INSERT INTO Seguridad.ConfiguracionDBMS
(Parametro,ValorConfigurado,ValorRecomendado,Descripcion,Criticidad)
VALUES
('AUDITORIA_DBMS','IMPLEMENTAR','SQL SERVER AUDIT','Auditar accesos y eventos de seguridad del motor.','ALTA'),
('CIFRADO_EN_REPOSO','PENDIENTE','TDE','Proteger archivos de datos y log mediante TDE.','ALTA'),
('CIFRADO_EN_TRANSITO','PENDIENTE','TLS','Proteger conexiones cliente-servidor.','ALTA'),
('BACKUP_CIFRADO','PENDIENTE','SI','Cifrar copias de seguridad.','ALTA'),
('MINIMO_PRIVILEGIO','IMPLEMENTAR','SI','Aplicar minimo privilegio a cuentas y roles.','CRITICA'),
('CUENTA_SA','RESTRINGIR','NO_USO_APLICACION','No utilizar cuentas administrativas desde aplicaciones.','CRITICA');
GO

CREATE TABLE Seguridad.CredencialDBMS (
    IdCredencial            INT IDENTITY(1,1) NOT NULL,
    NombreCredencial        VARCHAR(120) NOT NULL,
    TipoCredencial          VARCHAR(30) NOT NULL,
    IdentificadorExterno    VARCHAR(250) NULL,
    FechaVigenciaInicio     DATETIME2 NULL,
    FechaVigenciaFin        DATETIME2 NULL,
    Estado                  VARCHAR(15) NOT NULL DEFAULT 'ACTIVA',
    Observacion              VARCHAR(500) NULL,
    FechaRegistro            DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_CredencialDBMS PRIMARY KEY (IdCredencial),
    CONSTRAINT UQ_CredencialDBMS_Nombre UNIQUE (NombreCredencial),
    CONSTRAINT CHK_CredencialDBMS_Tipo CHECK (TipoCredencial IN
        ('CERTIFICADO','CLAVE_MAESTRA','CREDENCIAL','LLAVE_ENCRIPTACION','OTRO')),
    CONSTRAINT CHK_CredencialDBMS_Estado CHECK (Estado IN ('ACTIVA','EXPIRADA','REVOCADA','PENDIENTE'))
);
GO

-- Indices
CREATE INDEX IX_PasswordHistorial_Usuario_Fecha
ON Seguridad.PasswordHistorial(IdUsuario,FechaCreacion DESC);
GO

-- NOTA: las dos siguientes hacen referencia a Seguridad.TokenAutenticacion y
-- Seguridad.FactorAutenticacion, tablas de MFA que el script NO llega a crear
-- (quedan "preparadas para configurarse", como advierte la introduccion).
-- Comentalas o crea antes esas dos tablas si vas a ejecutar el script completo.
-- CREATE INDEX IX_TokenAutenticacion_Usuario
-- ON Seguridad.TokenAutenticacion(IdUsuario,Revocado,FechaExpiracion);
-- GO
-- CREATE INDEX IX_FactorAutenticacion_Usuario
-- ON Seguridad.FactorAutenticacion(IdUsuario,Activo);
-- GO

CREATE INDEX IX_Sesion_Usuario_Estado
ON Seguridad.Sesion(IdUsuario,Estado,FechaExpiracion);
GO

CREATE INDEX IX_PoliticaAcceso_Rol
ON Seguridad.PoliticaAcceso(IdRol,Activa,Prioridad);
GO

CREATE INDEX IX_UsuarioPolitica_Usuario
ON Seguridad.UsuarioPoliticaAcceso(IdUsuario,Activa,FechaFin);
GO

CREATE INDEX IX_AuditoriaSeguridad_Fecha
ON Seguridad.AuditoriaSeguridad(FechaHora DESC);
GO

CREATE INDEX IX_AuditoriaSeguridad_Usuario
ON Seguridad.AuditoriaSeguridad(IdUsuario,FechaHora DESC);
GO

CREATE INDEX IX_AuditoriaSeguridad_Tipo
ON Seguridad.AuditoriaSeguridad(TipoEvento,FechaHora DESC);
GO

CREATE INDEX IX_AuditoriaDatos_Fecha
ON Seguridad.AuditoriaDatos(FechaHora DESC);
GO

CREATE INDEX IX_HistorialAutorizacion_Usuario
ON Seguridad.HistorialAutorizacion(IdUsuarioObjetivo,FechaHora DESC);
GO

-- =====================================================================
-- VISTAS
-- =====================================================================

CREATE OR ALTER VIEW Seguridad.V_UsuariosSeguridad
AS
SELECT
    u.IdUsuario,
    u.NombreUsuario,
    u.Estado,
    u.Bloqueado,
    u.IntentosFallidos,
    u.FechaUltimoAcceso,
    u.FechaCreacion,
    CASE
        WHEN u.Bloqueado=1 OR u.Estado='BLOQUEADO' THEN 'BLOQUEADO'
        WHEN u.Estado<>'ACTIVO' THEN u.Estado
        WHEN u.IntentosFallidos>0 THEN 'ACTIVO_CON_INTENTOS'
        ELSE 'ACTIVO'
    END AS EstadoSeguridad,
    COUNT(DISTINCT ur.IdRol) AS RolesActivos
FROM Seguridad.Usuario u
LEFT JOIN Seguridad.UsuarioRol ur
  ON ur.IdUsuario=u.IdUsuario
 AND ur.Activo=1
 AND (ur.FechaFin IS NULL OR ur.FechaFin>=CAST(SYSDATETIME() AS DATE))
GROUP BY
    u.IdUsuario,u.NombreUsuario,u.Estado,u.Bloqueado,
    u.IntentosFallidos,u.FechaUltimoAcceso,u.FechaCreacion;
GO

CREATE OR ALTER VIEW Seguridad.V_SesionesActivas
AS
SELECT
    s.IdSesion,s.IdUsuario,u.NombreUsuario,s.FechaInicio,
    s.FechaUltimaActividad,s.FechaExpiracion,s.DireccionIP,
    s.Dispositivo,s.UserAgent
FROM Seguridad.Sesion s
JOIN Seguridad.Usuario u ON u.IdUsuario=s.IdUsuario
WHERE s.Estado='ACTIVA'
  AND s.Revocada=0
  AND s.FechaExpiracion>SYSDATETIME();
GO

CREATE OR ALTER VIEW Seguridad.V_EventosSeguridadRecientes
AS
SELECT TOP (1000)
    a.IdAuditoria,a.FechaHora,a.IdUsuario,
    COALESCE(a.NombreUsuario,u.NombreUsuario) AS NombreUsuario,
    a.TipoEvento,a.Resultado,a.Modulo,a.Accion,
    a.DireccionIP,a.Objeto,a.Detalle
FROM Seguridad.AuditoriaSeguridad a
LEFT JOIN Seguridad.Usuario u ON u.IdUsuario=a.IdUsuario
ORDER BY a.FechaHora DESC;
GO

-- =====================================================================
-- PROCEDIMIENTOS DE AUDITORIA
-- =====================================================================

CREATE OR ALTER PROCEDURE Seguridad.SP_RegistrarAuditoriaSeguridad
    @IdUsuario INT=NULL,
    @NombreUsuario VARCHAR(60)=NULL,
    @TipoEvento VARCHAR(35),
    @Resultado VARCHAR(15),
    @Modulo VARCHAR(50)=NULL,
    @Accion VARCHAR(80)=NULL,
    @DireccionIP VARCHAR(45)=NULL,
    @UserAgent NVARCHAR(500)=NULL,
    @IdSesion UNIQUEIDENTIFIER=NULL,
    @Objeto VARCHAR(150)=NULL,
    @Detalle NVARCHAR(2000)=NULL,
    @DatosAntes NVARCHAR(MAX)=NULL,
    @DatosDespues NVARCHAR(MAX)=NULL,
    @CorrelationId UNIQUEIDENTIFIER=NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Seguridad.AuditoriaSeguridad
    (IdUsuario,NombreUsuario,TipoEvento,Resultado,Modulo,Accion,
     DireccionIP,UserAgent,IdSesion,Objeto,Detalle,DatosAntes,
     DatosDespues,CorrelationId)
    VALUES
    (@IdUsuario,@NombreUsuario,@TipoEvento,@Resultado,@Modulo,@Accion,
     @DireccionIP,@UserAgent,@IdSesion,@Objeto,@Detalle,@DatosAntes,
     @DatosDespues,@CorrelationId);
END;
GO

CREATE OR ALTER PROCEDURE Seguridad.SP_RegistrarAuditoriaDatos
    @IdUsuario INT=NULL,
    @IdSesion UNIQUEIDENTIFIER=NULL,
    @Operacion CHAR(1),
    @EsquemaObjeto SYSNAME,
    @NombreObjeto SYSNAME,
    @ClaveRegistro NVARCHAR(500)=NULL,
    @DatosAntes NVARCHAR(MAX)=NULL,
    @DatosDespues NVARCHAR(MAX)=NULL,
    @DireccionIP VARCHAR(45)=NULL,
    @CorrelationId UNIQUEIDENTIFIER=NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Seguridad.AuditoriaDatos
    (IdUsuario,IdSesion,Operacion,EsquemaObjeto,NombreObjeto,
     ClaveRegistro,DatosAntes,DatosDespues,DireccionIP,CorrelationId)
    VALUES
    (@IdUsuario,@IdSesion,@Operacion,@EsquemaObjeto,@NombreObjeto,
     @ClaveRegistro,@DatosAntes,@DatosDespues,@DireccionIP,@CorrelationId);
END;
GO

-- ---------------------------------------------------------------------
-- CONTEXTO DE SESION PARA IDENTIFICAR AL USUARIO DE LA APP
--
-- La aplicacion debe ejecutar al iniciar una sesion:
-- EXEC sys.sp_set_session_context
--      @key=N'IdUsuario', @value=<IdUsuario>;
-- ---------------------------------------------------------------------

PRINT '==========================================================';
PRINT ' SEGURIDAD AVANZADA IMPLEMENTADA';
PRINT ' Auditoria, autenticacion, MFA, sesiones y politicas';
PRINT ' de acceso agregadas sin modificar el modelo RBAC.';
PRINT '==========================================================';
GO

/* ===== SEGURIDAD CORPORATIVA V2: EXTENSIONES ===== */

/* 1. Dispositivos confiables */
IF OBJECT_ID('Seguridad.Dispositivo','U') IS NULL
BEGIN
 CREATE TABLE Seguridad.Dispositivo(
  IdDispositivo BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Dispositivo PRIMARY KEY,
  NombreDispositivo VARCHAR(150) NULL, HuellaDispositivo VARBINARY(256) NULL,
  TipoDispositivo VARCHAR(30) NULL, SistemaOperativo VARCHAR(100) NULL,
  Navegador VARCHAR(150) NULL, FechaRegistro DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
  UltimoAcceso DATETIME2 NULL,
  Confiable BIT NOT NULL DEFAULT 0,
  Activo BIT NOT NULL DEFAULT 1, Revocado BIT NOT NULL DEFAULT 0, FechaRevocacion DATETIME2 NULL,
  CONSTRAINT CHK_Dispositivo_Tipo CHECK(TipoDispositivo IS NULL OR TipoDispositivo
    IN('DESKTOP','LAPTOP','TABLET','MOVIL','SERVIDOR','OTRO'))
 );
END;
GO

IF OBJECT_ID('Seguridad.UsuarioDispositivo','U') IS NULL
BEGIN
 CREATE TABLE Seguridad.UsuarioDispositivo(
  IdUsuarioDispositivo BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_UsuarioDispositivo PRIMARY KEY,
  IdUsuario INT NOT NULL, IdDispositivo BIGINT NOT NULL,
  FechaVinculacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(), UltimaActividad DATETIME2 NULL,
  Activo BIT NOT NULL DEFAULT 1,
  CONSTRAINT UQ_UsuarioDispositivo UNIQUE(IdUsuario,IdDispositivo),
  CONSTRAINT FK_UsuarioDispositivo_Usuario FOREIGN KEY(IdUsuario) REFERENCES Seguridad.Usuario(IdUsuario),
  CONSTRAINT FK_UsuarioDispositivo_Dispositivo FOREIGN KEY(IdDispositivo) REFERENCES Seguridad.Dispositivo(IdDispositivo)
 );
END;
GO

/* 2. Intentos de autenticacion */
IF OBJECT_ID('Seguridad.IntentoAutenticacion','U') IS NULL
BEGIN
 CREATE TABLE Seguridad.IntentoAutenticacion(
  IdIntento BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_IntentoAutenticacion PRIMARY KEY,
  IdUsuario INT NULL, NombreUsuario VARCHAR(60) NULL, FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
  Resultado VARCHAR(20) NOT NULL, Motivo VARCHAR(300) NULL, DireccionIP VARCHAR(45) NULL,
  UserAgent NVARCHAR(500) NULL, IdSesion UNIQUEIDENTIFIER NULL, CorrelationId UNIQUEIDENTIFIER NULL,
  CONSTRAINT FK_IntentoAutenticacion_Usuario FOREIGN KEY(IdUsuario) REFERENCES Seguridad.Usuario(IdUsuario),
  CONSTRAINT CHK_IntentoAutenticacion_Resultado CHECK(Resultado
    IN('EXITOSO','FALLIDO','BLOQUEADO','MFA_FALLIDO','MFA_EXITOSO'))
 );
END;
GO

/* 3. ABAC: alcances contextuales */
IF OBJECT_ID('Seguridad.AlcanceAcceso','U') IS NULL
BEGIN
 CREATE TABLE Seguridad.AlcanceAcceso(
  IdAlcance INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_AlcanceAcceso PRIMARY KEY,
  NombreAlcance VARCHAR(100) NOT NULL CONSTRAINT UQ_AlcanceAcceso_Nombre UNIQUE,
  TipoAlcance VARCHAR(30) NOT NULL, Descripcion VARCHAR(500) NULL,
  Recurso VARCHAR(150) NULL, ExpresionCondicion NVARCHAR(2000) NULL,
  Activo BIT NOT NULL DEFAULT 1, FechaCreacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
  CONSTRAINT CHK_AlcanceAcceso_Tipo CHECK(TipoAlcance
    IN('PROPIO','PROGRAMA','FACULTAD','ASESORADO','ASIGNADO','INSTITUCIONAL','PERSONALIZADO'))
 );
END;
GO

IF OBJECT_ID('Seguridad.RolAlcance','U') IS NULL
BEGIN
 CREATE TABLE Seguridad.RolAlcance(
  IdRolAlcance BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_RolAlcance PRIMARY KEY,
  IdRol SMALLINT NOT NULL, IdAlcance INT NOT NULL, FechaInicio DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
  FechaFin DATETIME2 NULL, Activo BIT NOT NULL DEFAULT 1,
  CONSTRAINT UQ_RolAlcance UNIQUE(IdRol,IdAlcance),
  CONSTRAINT FK_RolAlcance_Rol FOREIGN KEY(IdRol) REFERENCES Seguridad.Rol(IdRol),
  CONSTRAINT FK_RolAlcance_Alcance FOREIGN KEY(IdAlcance) REFERENCES Seguridad.AlcanceAcceso(IdAlcance),
  CONSTRAINT CHK_RolAlcance_Fechas CHECK(FechaFin IS NULL OR FechaFin>=FechaInicio)
 );
END;
GO

IF OBJECT_ID('Seguridad.UsuarioAlcance','U') IS NULL
BEGIN
 CREATE TABLE Seguridad.UsuarioAlcance(
  IdUsuarioAlcance BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_UsuarioAlcance PRIMARY KEY,
  IdUsuario INT NOT NULL, IdAlcance INT NOT NULL, FechaInicio DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
  FechaFin DATETIME2 NULL, Activo BIT NOT NULL DEFAULT 1, Motivo VARCHAR(500) NULL,
  CONSTRAINT UQ_UsuarioAlcance UNIQUE(IdUsuario,IdAlcance),
  CONSTRAINT FK_UsuarioAlcance_Usuario FOREIGN KEY(IdUsuario) REFERENCES Seguridad.Usuario(IdUsuario),
  CONSTRAINT FK_UsuarioAlcance_Alcance FOREIGN KEY(IdAlcance) REFERENCES Seguridad.AlcanceAcceso(IdAlcance),
  CONSTRAINT CHK_UsuarioAlcance_Fechas CHECK(FechaFin IS NULL OR FechaFin>=FechaInicio)
 );
END;
GO

/* 4. Segregacion de funciones */
IF OBJECT_ID('Seguridad.ReglaSegregacion','U') IS NULL
BEGIN
 CREATE TABLE Seguridad.ReglaSegregacion(
  IdReglaSegregacion INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ReglaSegregacion PRIMARY KEY,
  NombreRegla VARCHAR(150) NOT NULL CONSTRAINT UQ_ReglaSegregacion_Nombre UNIQUE,
  Descripcion VARCHAR(500) NULL, Severidad VARCHAR(15) NOT NULL DEFAULT 'ALTA',
  Activa BIT NOT NULL DEFAULT 1, FechaCreacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
  CONSTRAINT CHK_ReglaSegregacion_Severidad CHECK(Severidad IN('BAJA','MEDIA','ALTA','CRITICA'))
 );
END;
GO

IF OBJECT_ID('Seguridad.ReglaSegregacionRol','U') IS NULL
BEGIN
 CREATE TABLE Seguridad.ReglaSegregacionRol(
  IdReglaSegregacionRol BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ReglaSegregacionRol PRIMARY KEY,
  IdReglaSegregacion INT NOT NULL, IdRol SMALLINT NOT NULL, TipoRol VARCHAR(15) NOT NULL,
  CONSTRAINT UQ_ReglaSegregacionRol UNIQUE(IdReglaSegregacion,IdRol,TipoRol),
  CONSTRAINT FK_ReglaSegregacionRol_Regla FOREIGN KEY(IdReglaSegregacion)
    REFERENCES Seguridad.ReglaSegregacion(IdReglaSegregacion),
  CONSTRAINT FK_ReglaSegregacionRol_Rol FOREIGN KEY(IdRol) REFERENCES Seguridad.Rol(IdRol),
  CONSTRAINT CHK_ReglaSegregacionRol_Tipo CHECK(TipoRol IN('ORIGEN','CONFLICTO'))
 );
END;
GO

/* 5. Clasificacion de datos */
IF OBJECT_ID('Seguridad.ClasificacionDato','U') IS NULL
BEGIN
 CREATE TABLE Seguridad.ClasificacionDato(
  IdClasificacion TINYINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ClasificacionDato PRIMARY KEY,
  NombreClasificacion VARCHAR(30) NOT NULL CONSTRAINT UQ_ClasificacionDato_Nombre UNIQUE,
  Nivel TINYINT NOT NULL CONSTRAINT UQ_ClasificacionDato_Nivel UNIQUE,
  Descripcion VARCHAR(500) NULL, RequiereCifrado BIT NOT NULL DEFAULT 0,
  RequiereAuditoria BIT NOT NULL DEFAULT 0, Activo BIT NOT NULL DEFAULT 1,
  CONSTRAINT CHK_ClasificacionDato_Nivel CHECK(Nivel BETWEEN 1 AND 5)
 );
END;
GO
IF NOT EXISTS (SELECT 1 FROM Seguridad.ClasificacionDato)
INSERT INTO Seguridad.ClasificacionDato(NombreClasificacion,Nivel,Descripcion,RequiereCifrado,RequiereAuditoria) VALUES
('PUBLICO',1,'Informacion de libre consulta.',0,0),
('INTERNO',2,'Informacion de uso institucional.',0,1),
('CONFIDENCIAL',3,'Informacion academica o administrativa restringida.',1,1),
('RESTRINGIDO',4,'Informacion personal o sensible.',1,1),
('CRITICO',5,'Informacion critica para seguridad o continuidad.',1,1);
GO

IF OBJECT_ID('Seguridad.ObjetoClasificado','U') IS NULL
BEGIN
 CREATE TABLE Seguridad.ObjetoClasificado(
  IdObjetoClasificado BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ObjetoClasificado PRIMARY KEY,
  IdClasificacion TINYINT NOT NULL, EsquemaObjeto SYSNAME NOT NULL, NombreObjeto SYSNAME NOT NULL,
  NombreColumna SYSNAME NULL, Descripcion VARCHAR(500) NULL, Activo BIT NOT NULL DEFAULT 1,
  CONSTRAINT UQ_ObjetoClasificado UNIQUE(EsquemaObjeto,NombreObjeto,NombreColumna),
  CONSTRAINT FK_ObjetoClasificado_Clasificacion FOREIGN KEY(IdClasificacion)
    REFERENCES Seguridad.ClasificacionDato(IdClasificacion)
 );
END;
GO

/* 6. Retencion */
IF OBJECT_ID('Seguridad.PoliticaRetencion','U') IS NULL
BEGIN
 CREATE TABLE Seguridad.PoliticaRetencion(
  IdPoliticaRetencion INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_PoliticaRetencion PRIMARY KEY,
  TipoAuditoria VARCHAR(40) NOT NULL CONSTRAINT UQ_PoliticaRetencion_Tipo UNIQUE,
  DiasRetencion INT NOT NULL, DiasArchivado INT NULL,
  EliminacionPermitida BIT NOT NULL DEFAULT 0,
  Descripcion VARCHAR(500) NULL, Activa BIT NOT NULL DEFAULT 1,
  FechaCreacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
  CONSTRAINT CHK_PoliticaRetencion_Dias CHECK(DiasRetencion>=1),
  CONSTRAINT CHK_PoliticaRetencion_Archivado CHECK(DiasArchivado IS NULL OR DiasArchivado>=DiasRetencion)
 );
END;
GO
IF NOT EXISTS (SELECT 1 FROM Seguridad.PoliticaRetencion)
INSERT INTO Seguridad.PoliticaRetencion(TipoAuditoria,DiasRetencion,DiasArchivado,EliminacionPermitida,Descripcion) VALUES
('AUDITORIA_SEGURIDAD',365,1825,0,'Eventos de autenticacion y autorizacion.'),
('AUDITORIA_DATOS',730,1825,0,'Cambios de datos criticos.'),
('AUTENTICACION',365,1095,0,'Intentos de autenticacion.'),
('AUTORIZACION',730,1825,0,'Cambios de roles y permisos.');
GO

/* 7. Objetos criticos e integridad */
IF OBJECT_ID('Seguridad.ObjetoCritico','U') IS NULL
BEGIN
 CREATE TABLE Seguridad.ObjetoCritico(
  IdObjetoCritico INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_ObjetoCritico PRIMARY KEY,
  EsquemaObjeto SYSNAME NOT NULL, NombreObjeto SYSNAME NOT NULL, TipoObjeto VARCHAR(30) NOT NULL,
  NivelCriticidad VARCHAR(15) NOT NULL DEFAULT 'ALTA',
  RequiereAuditoria BIT NOT NULL DEFAULT 1, RequiereAprobacion BIT NOT NULL DEFAULT 0,
  Activo BIT NOT NULL DEFAULT 1,
  CONSTRAINT UQ_ObjetoCritico UNIQUE(EsquemaObjeto,NombreObjeto),
  CONSTRAINT CHK_ObjetoCritico_Criticidad CHECK(NivelCriticidad IN('BAJA','MEDIA','ALTA','CRITICA'))
 );
END;
GO

IF OBJECT_ID('Seguridad.MonitoreoIntegridad','U') IS NULL
BEGIN
 CREATE TABLE Seguridad.MonitoreoIntegridad(
  IdMonitoreo BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_MonitoreoIntegridad PRIMARY KEY,
  FechaHora DATETIME2 NOT NULL DEFAULT SYSDATETIME(), EsquemaObjeto SYSNAME NOT NULL, NombreObjeto SYSNAME NOT NULL,
  TipoObjeto VARCHAR(30) NOT NULL, HashDefinicion VARBINARY(64) NULL, Resultado VARCHAR(20) NOT NULL,
  Detalle VARCHAR(1000) NULL, IdUsuario INT NULL,
  CONSTRAINT FK_MonitoreoIntegridad_Usuario FOREIGN KEY(IdUsuario) REFERENCES Seguridad.Usuario(IdUsuario),
  CONSTRAINT CHK_MonitoreoIntegridad_Resultado CHECK(Resultado IN('OK','CAMBIO_DETECTADO','ERROR','NO_VERIFICADO'))
 );
END;
GO

/* 8. Contexto de sesion para RLS */
CREATE OR ALTER PROCEDURE Seguridad.SP_EstablecerContextoSeguridad
 @IdUsuario INT, @IdSesion UNIQUEIDENTIFIER=NULL, @IdDispositivo BIGINT=NULL,
 @Aplicacion NVARCHAR(128)=NULL, @DireccionIP VARCHAR(45)=NULL,
 @CorrelationId UNIQUEIDENTIFIER=NULL
AS
BEGIN
 SET NOCOUNT ON;
 IF NOT EXISTS(SELECT 1 FROM Seguridad.Usuario WHERE IdUsuario=@IdUsuario AND Estado='ACTIVO' AND Bloqueado=0)
   THROW 51001,'Usuario inexistente, inactivo o bloqueado.',1;
 EXEC sys.sp_set_session_context @key=N'IdUsuario',@value=@IdUsuario;
 EXEC sys.sp_set_session_context @key=N'IdSesion',@value=@IdSesion;
 EXEC sys.sp_set_session_context @key=N'IdDispositivo',@value=@IdDispositivo;
 EXEC sys.sp_set_session_context @key=N'Aplicacion',@value=@Aplicacion;
 EXEC sys.sp_set_session_context @key=N'DireccionIP',@value=@DireccionIP;
 EXEC sys.sp_set_session_context @key=N'CorrelationId',@value=@CorrelationId;
END;
GO

CREATE OR ALTER FUNCTION Seguridad.FN_UsuarioContexto()
RETURNS INT
AS
BEGIN RETURN TRY_CONVERT(INT,SESSION_CONTEXT(N'IdUsuario')); END;
GO

/* 9. Validacion SoD */
CREATE OR ALTER PROCEDURE Seguridad.SP_ValidarSegregacionRoles
 @IdUsuario INT, @IdRolNuevo SMALLINT
AS
BEGIN
 SET NOCOUNT ON;
 IF EXISTS(
  SELECT 1 FROM Seguridad.ReglaSegregacion rs
  JOIN Seguridad.ReglaSegregacionRol rso ON rso.IdReglaSegregacion=rs.IdReglaSegregacion AND rso.TipoRol='ORIGEN'
  JOIN Seguridad.ReglaSegregacionRol rsc ON rsc.IdReglaSegregacion=rs.IdReglaSegregacion AND rsc.TipoRol='CONFLICTO'
  JOIN Seguridad.UsuarioRol ur ON ur.IdUsuario=@IdUsuario AND ur.IdRol=rso.IdRol AND ur.Activo=1
  WHERE rs.Activa=1 AND rsc.IdRol=@IdRolNuevo)
  THROW 51002,'Violacion de segregacion de funciones.',1;
END;
GO

/* 10. Health Check */
CREATE OR ALTER PROCEDURE Seguridad.SP_HealthCheck
AS
BEGIN
 SET NOCOUNT ON;
 SELECT DB_NAME() AS BaseDatos,state_desc AS Estado,recovery_model_desc AS RecoveryModel,
        compatibility_level AS CompatibilityLevel,user_access_desc AS UserAccess,is_read_only AS SoloLectura
 FROM sys.databases WHERE name=DB_NAME();
 SELECT name AS Archivo,type_desc AS TipoArchivo,size*8.0/1024 AS TamanioMB,growth,is_percent_growth AS CrecimientoPorcentaje
 FROM sys.database_files;
 SELECT COUNT(*) AS Usuarios,
        SUM(CASE WHEN Estado='ACTIVO' THEN 1 ELSE 0 END) AS Activos,
        SUM(CASE WHEN Bloqueado=1 THEN 1 ELSE 0 END) AS Bloqueados
 FROM Seguridad.Usuario;
 SELECT COUNT(*) AS SesionesActivas FROM Seguridad.Sesion
 WHERE Estado='ACTIVA' AND Revocada=0 AND FechaExpiracion>SYSDATETIME();
 DECLARE @BD SYSNAME = DB_NAME();
 DBCC CHECKDB(@BD) WITH NO_INFOMSGS;
END;
GO

/* 11. Indices */
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_Dispositivo_Huella'
  AND object_id=OBJECT_ID('Seguridad.Dispositivo'))
 CREATE INDEX IX_Dispositivo_Huella ON Seguridad.Dispositivo(HuellaDispositivo) WHERE HuellaDispositivo IS NOT NULL;
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_UsuarioDispositivo_Usuario'
  AND object_id=OBJECT_ID('Seguridad.UsuarioDispositivo'))
 CREATE INDEX IX_UsuarioDispositivo_Usuario ON Seguridad.UsuarioDispositivo(IdUsuario,Activo);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_IntentoAutenticacion_UsuarioFecha'
  AND object_id=OBJECT_ID('Seguridad.IntentoAutenticacion'))
 CREATE INDEX IX_IntentoAutenticacion_UsuarioFecha ON Seguridad.IntentoAutenticacion(IdUsuario,FechaHora DESC);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_IntentoAutenticacion_IPFecha'
  AND object_id=OBJECT_ID('Seguridad.IntentoAutenticacion'))
 CREATE INDEX IX_IntentoAutenticacion_IPFecha ON Seguridad.IntentoAutenticacion(DireccionIP,FechaHora DESC);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_AlcanceAcceso_Recurso'
  AND object_id=OBJECT_ID('Seguridad.AlcanceAcceso'))
 CREATE INDEX IX_AlcanceAcceso_Recurso ON Seguridad.AlcanceAcceso(Recurso,Activo);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_RolAlcance_Rol'
  AND object_id=OBJECT_ID('Seguridad.RolAlcance'))
 CREATE INDEX IX_RolAlcance_Rol ON Seguridad.RolAlcance(IdRol,Activo);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_UsuarioAlcance_Usuario'
  AND object_id=OBJECT_ID('Seguridad.UsuarioAlcance'))
 CREATE INDEX IX_UsuarioAlcance_Usuario ON Seguridad.UsuarioAlcance(IdUsuario,Activo);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_ObjetoClasificado_Objeto'
  AND object_id=OBJECT_ID('Seguridad.ObjetoClasificado'))
 CREATE INDEX IX_ObjetoClasificado_Objeto ON Seguridad.ObjetoClasificado(EsquemaObjeto,NombreObjeto);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_ObjetoCritico_Criticidad'
  AND object_id=OBJECT_ID('Seguridad.ObjetoCritico'))
 CREATE INDEX IX_ObjetoCritico_Criticidad ON Seguridad.ObjetoCritico(NivelCriticidad,Activo);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_MonitoreoIntegridad_Fecha'
  AND object_id=OBJECT_ID('Seguridad.MonitoreoIntegridad'))
 CREATE INDEX IX_MonitoreoIntegridad_Fecha ON Seguridad.MonitoreoIntegridad(FechaHora DESC);
GO

/* 12. Alcances iniciales */
INSERT INTO Seguridad.AlcanceAcceso(NombreAlcance,TipoAlcance,Descripcion,Recurso)
SELECT 'PROPIO','PROPIO','Acceso solamente a informacion perteneciente al usuario.','*'
WHERE NOT EXISTS(SELECT 1 FROM Seguridad.AlcanceAcceso WHERE NombreAlcance='PROPIO');
GO
INSERT INTO Seguridad.AlcanceAcceso(NombreAlcance,TipoAlcance,Descripcion,Recurso)
SELECT 'ASIGNADO','ASIGNADO','Acceso unicamente a recursos asignados al usuario.','*'
WHERE NOT EXISTS(SELECT 1 FROM Seguridad.AlcanceAcceso WHERE NombreAlcance='ASIGNADO');
GO
INSERT INTO Seguridad.AlcanceAcceso(NombreAlcance,TipoAlcance,Descripcion,Recurso)
SELECT 'INSTITUCIONAL','INSTITUCIONAL','Acceso dentro del ambito institucional autorizado.','*'
WHERE NOT EXISTS(SELECT 1 FROM Seguridad.AlcanceAcceso WHERE NombreAlcance='INSTITUCIONAL');
GO

/* 13. Configuracion DBMS: solo si existe la tabla del modelo base */
IF OBJECT_ID('Seguridad.ConfiguracionDBMS','U') IS NOT NULL
BEGIN
 IF NOT EXISTS(SELECT 1 FROM Seguridad.ConfiguracionDBMS WHERE Parametro='SQL_SERVER_AUDIT')
   INSERT INTO Seguridad.ConfiguracionDBMS(Parametro,ValorConfigurado,ValorRecomendado,Descripcion,Criticidad)
   VALUES('SQL_SERVER_AUDIT','PENDIENTE','HABILITADO','Auditoria nativa del DBMS.','ALTA');
 IF NOT EXISTS(SELECT 1 FROM Seguridad.ConfiguracionDBMS WHERE Parametro='ROW_LEVEL_SECURITY')
   INSERT INTO Seguridad.ConfiguracionDBMS(Parametro,ValorConfigurado,ValorRecomendado,Descripcion,Criticidad)
   VALUES('ROW_LEVEL_SECURITY','PREPARADO','IMPLEMENTAR_POR_ENTIDAD','Predicados RLS segun reglas de negocio.','ALTA');
 IF NOT EXISTS(SELECT 1 FROM Seguridad.ConfiguracionDBMS WHERE Parametro='TDE')
   INSERT INTO Seguridad.ConfiguracionDBMS(Parametro,ValorConfigurado,ValorRecomendado,Descripcion,Criticidad)
   VALUES('TDE','PENDIENTE','HABILITADO','Cifrado de datos en reposo.','ALTA');
 IF NOT EXISTS(SELECT 1 FROM Seguridad.ConfiguracionDBMS WHERE Parametro='BACKUP_ENCRYPTION')
   INSERT INTO Seguridad.ConfiguracionDBMS(Parametro,ValorConfigurado,ValorRecomendado,Descripcion,Criticidad)
   VALUES('BACKUP_ENCRYPTION','PENDIENTE','HABILITADO','Cifrado de copias de seguridad.','ALTA');
 IF NOT EXISTS(SELECT 1 FROM Seguridad.ConfiguracionDBMS WHERE Parametro='TLS')
   INSERT INTO Seguridad.ConfiguracionDBMS(Parametro,ValorConfigurado,ValorRecomendado,Descripcion,Criticidad)
   VALUES('TLS','PENDIENTE','REQUERIDO','Cifrado de comunicaciones cliente-servidor.','ALTA');
END;
GO

/* 14. Objetos criticos iniciales */
INSERT INTO Seguridad.ObjetoCritico(EsquemaObjeto,NombreObjeto,TipoObjeto,NivelCriticidad,RequiereAuditoria,RequiereAprobacion)
SELECT 'Seguridad','Usuario','TABLE','CRITICA',1,1
WHERE NOT EXISTS(SELECT 1 FROM Seguridad.ObjetoCritico WHERE EsquemaObjeto='Seguridad' AND NombreObjeto='Usuario');
GO
INSERT INTO Seguridad.ObjetoCritico(EsquemaObjeto,NombreObjeto,TipoObjeto,NivelCriticidad,RequiereAuditoria,RequiereAprobacion)
SELECT 'Seguridad','Rol','TABLE','CRITICA',1,1
WHERE NOT EXISTS(SELECT 1 FROM Seguridad.ObjetoCritico WHERE EsquemaObjeto='Seguridad' AND NombreObjeto='Rol');
GO
INSERT INTO Seguridad.ObjetoCritico(EsquemaObjeto,NombreObjeto,TipoObjeto,NivelCriticidad,RequiereAuditoria,RequiereAprobacion)
SELECT 'Seguridad','Permiso','TABLE','CRITICA',1,1
WHERE NOT EXISTS(SELECT 1 FROM Seguridad.ObjetoCritico WHERE EsquemaObjeto='Seguridad' AND NombreObjeto='Permiso');
GO

/* 15. Panel de seguridad */
CREATE OR ALTER VIEW Seguridad.V_PanelSeguridad
AS
SELECT
 (SELECT COUNT(*) FROM Seguridad.Usuario WHERE Estado='ACTIVO' AND Bloqueado=0) AS UsuariosActivos,
 (SELECT COUNT(*) FROM Seguridad.Usuario WHERE Bloqueado=1 OR Estado='BLOQUEADO') AS UsuariosBloqueados,
 (SELECT COUNT(*) FROM Seguridad.Sesion WHERE Estado='ACTIVA' AND Revocada=0 AND FechaExpiracion>SYSDATETIME()) AS SesionesActivas,
 (SELECT COUNT(*) FROM Seguridad.IntentoAutenticacion WHERE FechaHora>=DATEADD(HOUR,-24,SYSDATETIME())
   AND Resultado IN('FALLIDO','BLOQUEADO','MFA_FALLIDO')) AS FallosAutenticacion24h,
 (SELECT COUNT(*) FROM Seguridad.AuditoriaSeguridad WHERE FechaHora>=DATEADD(HOUR,-24,SYSDATETIME())
   AND Resultado IN('DENEGADO','ERROR')) AS EventosDenegados24h,
 (SELECT COUNT(*) FROM Seguridad.ObjetoCritico WHERE Activo=1 AND NivelCriticidad='CRITICA') AS ObjetosCriticos;
GO

PRINT 'GRADOSTITULOS - SEGURIDAD CORPORATIVA V2 INSTALADA.';
GO
