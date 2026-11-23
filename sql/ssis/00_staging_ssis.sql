-- =====================================================================
-- TP1 Geo BI - Partie SSIS : tables de transit alimentees par SSIS
-- (Execute SQL Task n°1 du package). Toutes les colonnes "code" sont en
-- texte pour conserver les zeros de tete ('01', '066').
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS staging;

DROP TABLE IF EXISTS staging.region, staging.province_prefecture, staging.cercle,
                     staging.commune, staging.stat_commune, staging.centre_urbain,
                     staging.stat_centre_urbain,
                     staging.shp_region_wkt, staging.shp_province_wkt, staging.shp_commune_wkt;

CREATE TABLE staging.region              (code text, nom text);
CREATE TABLE staging.province_prefecture (code text, nom text, type text, region_code text);
CREATE TABLE staging.cercle              (code text, nom text, type text, province_code text);
CREATE TABLE staging.commune             (code text, nom text, type text, region_code text,
                                          province_code text, cercle_code text);
CREATE TABLE staging.stat_commune        (commune_code text, menages integer, population integer,
                                          etrangers integer, marocains integer);
CREATE TABLE staging.centre_urbain       (code text, nom text, commune_code text);
CREATE TABLE staging.stat_centre_urbain  (centre_urbain_code text, menages integer, population integer,
                                          etrangers integer, marocains integer);

CREATE TABLE staging.shp_region_wkt      (code text, wkt text);
CREATE TABLE staging.shp_province_wkt    (code text, wkt text);
CREATE TABLE staging.shp_commune_wkt     (code text, wkt text);
