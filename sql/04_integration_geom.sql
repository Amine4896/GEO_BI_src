-- =====================================================================
-- TP1 Geo BI - Partie II.2 Option 2 : recuperation des geometries
-- Jointure sur le code (shp en staging) + corrections geometriques :
--   ST_MakeValid          : repare les polygones invalides (auto-intersections...)
--   ST_CollectionExtract 3: ne garde que les parties surfaciques
--   ST_Multi              : homogeneise en MultiPolygon (type de la colonne)
-- =====================================================================
BEGIN;

-- Plusieurs polygones pour un meme code ? -> on les fusionne (ST_Union).
UPDATE region t
SET geom = g.geom
FROM (
    SELECT code,
           ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Union(ST_MakeValid(geom))), 3)) AS geom
    FROM staging.shp_region
    GROUP BY code
) g
WHERE t.code = g.code;

UPDATE province_prefecture t
SET geom = g.geom
FROM (
    SELECT code,
           ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Union(ST_MakeValid(geom))), 3)) AS geom
    FROM staging.shp_province
    GROUP BY code
) g
WHERE t.code = g.code;

UPDATE commune t
SET geom = g.geom
FROM (
    SELECT code,
           ST_Multi(ST_CollectionExtract(ST_MakeValid(ST_Union(ST_MakeValid(geom))), 3)) AS geom
    FROM staging.shp_commune
    GROUP BY code
) g
WHERE t.code = g.code;

COMMIT;

ANALYZE region;
ANALYZE province_prefecture;
ANALYZE commune;
