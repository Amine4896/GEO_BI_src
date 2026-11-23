-- =====================================================================
-- TP1 Geo BI - Partie SSIS (SQL Server) : creation de la base
--   sqlcmd -S .\SQLEXPRESS -E -C -i sql\sqlserver\01_create_database.sql
-- La base GeoBI_RGPH existante n'est pas touchee.
-- =====================================================================
USE master;
GO
IF DB_ID(N'GeoBI_SSIS') IS NOT NULL
BEGIN
    ALTER DATABASE GeoBI_SSIS SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE GeoBI_SSIS;
END
GO
CREATE DATABASE GeoBI_SSIS COLLATE French_CI_AS;
GO
