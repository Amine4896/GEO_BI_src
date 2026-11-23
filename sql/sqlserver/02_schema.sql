-- =====================================================================
-- TP1 Geo BI - Partie SSIS (SQL Server) : modele physique (tables vides)
--   sqlcmd -S .\SQLEXPRESS -E -C -d GeoBI_SSIS -i sql\sqlserver\02_schema.sql
-- Meme modele que PostgreSQL ; geom en type geometry (SRID 4326).
-- =====================================================================
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- ---------------------------------------------------------------------
-- REGION
-- ---------------------------------------------------------------------
CREATE TABLE dbo.region (
    id    int IDENTITY(1,1) CONSTRAINT PK_region PRIMARY KEY,
    code  nvarchar(10)  NOT NULL CONSTRAINT UQ_region_code UNIQUE,
    nom   nvarchar(100) NOT NULL,
    geom  geometry      NULL
);

-- ---------------------------------------------------------------------
-- PROVINCE / PREFECTURE
-- ---------------------------------------------------------------------
CREATE TABLE dbo.province_prefecture (
    id         int IDENTITY(1,1) CONSTRAINT PK_province_prefecture PRIMARY KEY,
    code       nvarchar(15)  NOT NULL CONSTRAINT UQ_province_code UNIQUE,
    nom        nvarchar(100) NOT NULL,
    type       nvarchar(20)  NOT NULL
               CONSTRAINT CK_province_type CHECK (type IN (N'Province', N'Préfecture')),
    region_id  int           NOT NULL CONSTRAINT FK_province_region REFERENCES dbo.region(id),
    geom       geometry      NULL
);

-- ---------------------------------------------------------------------
-- CERCLE (+ prefectures d'arrondissements de Casablanca)
-- ---------------------------------------------------------------------
CREATE TABLE dbo.cercle (
    id                      int IDENTITY(1,1) CONSTRAINT PK_cercle PRIMARY KEY,
    code                    nvarchar(20)  NOT NULL CONSTRAINT UQ_cercle_code UNIQUE,
    nom                     nvarchar(100) NOT NULL,
    type                    nvarchar(40)  NOT NULL
                            CONSTRAINT CK_cercle_type CHECK (type IN (N'Cercle', N'Préfecture d''arrondissements')),
    province_prefecture_id  int           NOT NULL
                            CONSTRAINT FK_cercle_province REFERENCES dbo.province_prefecture(id)
);

-- ---------------------------------------------------------------------
-- COMMUNE (cercle_id NULL pour les municipalites hors cercle)
-- ---------------------------------------------------------------------
CREATE TABLE dbo.commune (
    id                      int IDENTITY(1,1) CONSTRAINT PK_commune PRIMARY KEY,
    code                    nvarchar(25)  NOT NULL CONSTRAINT UQ_commune_code UNIQUE,
    nom                     nvarchar(150) NOT NULL,
    type                    nvarchar(20)  NOT NULL
                            CONSTRAINT CK_commune_type CHECK (type IN (N'Commune rurale', N'Municipalité', N'Arrondissement')),
    region_id               int NOT NULL CONSTRAINT FK_commune_region   REFERENCES dbo.region(id),
    province_prefecture_id  int NOT NULL CONSTRAINT FK_commune_province REFERENCES dbo.province_prefecture(id),
    cercle_id               int NULL     CONSTRAINT FK_commune_cercle   REFERENCES dbo.cercle(id),
    geom                    geometry NULL
);

-- ---------------------------------------------------------------------
-- STAT_COMMUNE (1-1)
-- ---------------------------------------------------------------------
CREATE TABLE dbo.stat_commune (
    id          int IDENTITY(1,1) CONSTRAINT PK_stat_commune PRIMARY KEY,
    commune_id  int NOT NULL CONSTRAINT UQ_stat_commune UNIQUE
                CONSTRAINT FK_stat_commune REFERENCES dbo.commune(id) ON DELETE CASCADE,
    menages     int NULL CHECK (menages    >= 0),
    population  int NULL CHECK (population >= 0),
    etrangers   int NULL CHECK (etrangers  >= 0),
    marocains   int NULL CHECK (marocains  >= 0)
);

-- ---------------------------------------------------------------------
-- CENTRE_URBAIN
-- ---------------------------------------------------------------------
CREATE TABLE dbo.centre_urbain (
    id          int IDENTITY(1,1) CONSTRAINT PK_centre_urbain PRIMARY KEY,
    code        nvarchar(30)  NOT NULL CONSTRAINT UQ_centre_code UNIQUE,
    nom         nvarchar(150) NOT NULL,
    commune_id  int NOT NULL CONSTRAINT FK_centre_commune REFERENCES dbo.commune(id)
);

-- ---------------------------------------------------------------------
-- STAT_CENTRE_URBAIN (1-1)
-- ---------------------------------------------------------------------
CREATE TABLE dbo.stat_centre_urbain (
    id                int IDENTITY(1,1) CONSTRAINT PK_stat_centre_urbain PRIMARY KEY,
    centre_urbain_id  int NOT NULL CONSTRAINT UQ_stat_centre UNIQUE
                      CONSTRAINT FK_stat_centre REFERENCES dbo.centre_urbain(id) ON DELETE CASCADE,
    menages           int NULL CHECK (menages    >= 0),
    population        int NULL CHECK (population >= 0),
    etrangers         int NULL CHECK (etrangers  >= 0),
    marocains         int NULL CHECK (marocains  >= 0)
);
GO

-- ---------------------------------------------------------------------
-- Index FK + index spatiaux (emprise du Maroc, Sahara inclus)
-- ---------------------------------------------------------------------
CREATE INDEX IX_province_region  ON dbo.province_prefecture (region_id);
CREATE INDEX IX_cercle_province  ON dbo.cercle (province_prefecture_id);
CREATE INDEX IX_commune_region   ON dbo.commune (region_id);
CREATE INDEX IX_commune_province ON dbo.commune (province_prefecture_id);
CREATE INDEX IX_commune_cercle   ON dbo.commune (cercle_id);
CREATE INDEX IX_centre_commune   ON dbo.centre_urbain (commune_id);

CREATE SPATIAL INDEX SIX_region_geom   ON dbo.region (geom)
    USING GEOMETRY_AUTO_GRID WITH (BOUNDING_BOX = (-18, 20, 0, 37));
CREATE SPATIAL INDEX SIX_province_geom ON dbo.province_prefecture (geom)
    USING GEOMETRY_AUTO_GRID WITH (BOUNDING_BOX = (-18, 20, 0, 37));
CREATE SPATIAL INDEX SIX_commune_geom  ON dbo.commune (geom)
    USING GEOMETRY_AUTO_GRID WITH (BOUNDING_BOX = (-18, 20, 0, 37));
GO

-- ---------------------------------------------------------------------
-- Schema de transit : geometries WKT chargees par SSIS (Flat File)
-- ---------------------------------------------------------------------
CREATE SCHEMA staging;
GO
CREATE TABLE staging.shp_region_wkt   (code nvarchar(10), wkt nvarchar(max));
CREATE TABLE staging.shp_province_wkt (code nvarchar(15), wkt nvarchar(max));
CREATE TABLE staging.shp_commune_wkt  (code nvarchar(25), wkt nvarchar(max));
GO
