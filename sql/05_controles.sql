-- =====================================================================
-- TP1 Geo BI - Controles de l'integration
-- =====================================================================

\echo '--- 1. Volumetrie (attendu : 16 / 75 / 204 / 1538 / 1538 / 149 / 149)'
SELECT 'region' AS table_, count(*) FROM region
UNION ALL SELECT 'province_prefecture', count(*) FROM province_prefecture
UNION ALL SELECT 'cercle',              count(*) FROM cercle
UNION ALL SELECT 'commune',             count(*) FROM commune
UNION ALL SELECT 'stat_commune',        count(*) FROM stat_commune
UNION ALL SELECT 'centre_urbain',       count(*) FROM centre_urbain
UNION ALL SELECT 'stat_centre_urbain',  count(*) FROM stat_centre_urbain;

\echo '--- 2. Communes par type et rattachement a un cercle'
SELECT type, count(*) AS nb, count(cercle_id) AS avec_cercle
FROM commune GROUP BY type ORDER BY type;

\echo '--- 3. Geometries manquantes (attendu : 0 partout)'
SELECT 'region' AS table_, count(*) FILTER (WHERE geom IS NULL) AS sans_geom FROM region
UNION ALL SELECT 'province_prefecture', count(*) FILTER (WHERE geom IS NULL) FROM province_prefecture
UNION ALL SELECT 'commune', count(*) FILTER (WHERE geom IS NULL) FROM commune;

\echo '--- 4. Geometries invalides apres correction (attendu : 0)'
SELECT 'region' AS table_, count(*) FILTER (WHERE NOT ST_IsValid(geom)) AS invalides FROM region
UNION ALL SELECT 'province_prefecture', count(*) FILTER (WHERE NOT ST_IsValid(geom)) FROM province_prefecture
UNION ALL SELECT 'commune', count(*) FILTER (WHERE NOT ST_IsValid(geom)) FROM commune;

\echo '--- 5. Codes shp sans correspondance dans la BDD (attendu : 0 ligne)'
SELECT 'commune' AS niveau, s.code FROM staging.shp_commune s
LEFT JOIN commune c ON c.code = s.code WHERE c.id IS NULL
UNION ALL
SELECT 'province', s.code FROM staging.shp_province s
LEFT JOIN province_prefecture p ON p.code = s.code WHERE p.id IS NULL
UNION ALL
SELECT 'region', s.code FROM staging.shp_region s
LEFT JOIN region r ON r.code = s.code WHERE r.id IS NULL;

\echo '--- 6. Coherence hierarchique : region de la commune = region de sa province'
SELECT count(*) AS incoherences
FROM commune c JOIN province_prefecture p ON p.id = c.province_prefecture_id
WHERE c.region_id <> p.region_id;

\echo '--- 7. Population par region (somme des communes)'
SELECT r.code, r.nom, sum(s.population) AS population, sum(s.menages) AS menages
FROM region r
JOIN commune c      ON c.region_id = r.id
JOIN stat_commune s ON s.commune_id = c.id
GROUP BY r.code, r.nom ORDER BY r.code;

\echo '--- 8. Superficie (km2) et densite des 10 communes les plus denses'
SELECT c.code, c.nom, c.type,
       round((ST_Area(c.geom::geography) / 1e6)::numeric, 2) AS superficie_km2,
       s.population,
       round((s.population / NULLIF(ST_Area(c.geom::geography) / 1e6, 0))::numeric, 0) AS densite
FROM commune c JOIN stat_commune s ON s.commune_id = c.id
ORDER BY densite DESC NULLS LAST
LIMIT 10;
