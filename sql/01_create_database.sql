-- =====================================================================
-- TP1 Geo BI - Etape I : creation de la base de donnees
-- A executer connecte a la base "postgres" :
--   psql -U postgres -h localhost -d postgres -f sql/01_create_database.sql
-- =====================================================================

DROP DATABASE IF EXISTS geobi_tp1;

CREATE DATABASE geobi_tp1
    WITH ENCODING 'UTF8'
         TEMPLATE template0;
