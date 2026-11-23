-- =====================================================================
-- TP1 Geo BI - Partie SSIS : geometries WKT (staging) -> tables du modele
-- (Execute SQL Task final du package, apres 03_integration_attributs.sql)
-- =====================================================================
UPDATE region t
SET geom = ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_GeomFromText(s.wkt, 4326)), 3))
FROM staging.shp_region_wkt s
WHERE t.code = s.code;

UPDATE province_prefecture t
SET geom = ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_GeomFromText(s.wkt, 4326)), 3))
FROM staging.shp_province_wkt s
WHERE t.code = s.code;

UPDATE commune t
SET geom = ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_GeomFromText(s.wkt, 4326)), 3))
FROM staging.shp_commune_wkt s
WHERE t.code = s.code;
