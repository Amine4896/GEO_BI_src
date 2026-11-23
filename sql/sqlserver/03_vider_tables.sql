-- =====================================================================
-- TP1 Geo BI - SSIS (SQL Server) : vidage avant (re)chargement
-- Execute SQL Task n°1 du package (connexion OLE DB GeoBI_SSIS).
-- TRUNCATE est interdit sur les tables referencees par une FK :
-- on fait DELETE puis on remet les compteurs IDENTITY a zero.
-- =====================================================================
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

DELETE FROM dbo.stat_centre_urbain;
DELETE FROM dbo.centre_urbain;
DELETE FROM dbo.stat_commune;
DELETE FROM dbo.commune;
DELETE FROM dbo.cercle;
DELETE FROM dbo.province_prefecture;
DELETE FROM dbo.region;

DBCC CHECKIDENT ('dbo.stat_centre_urbain',  RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.centre_urbain',       RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.stat_commune',        RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.commune',             RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.cercle',              RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.province_prefecture', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('dbo.region',              RESEED, 0) WITH NO_INFOMSGS;

TRUNCATE TABLE staging.shp_region_wkt;
TRUNCATE TABLE staging.shp_province_wkt;
TRUNCATE TABLE staging.shp_commune_wkt;
