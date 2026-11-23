-- =====================================================================
-- TP1 Geo BI - SSIS (SQL Server) : controles apres execution du package
--   sqlcmd -S .\SQLEXPRESS -E -C -d GeoBI_SSIS -i sql\sqlserver\05_controles.sql -W
-- =====================================================================
SET NOCOUNT ON;

PRINT '--- 1. Volumetrie (attendu : 16 / 75 / 204 / 1538 / 1538 / 149 / 149)';
SELECT 'region' AS table_, COUNT(*) AS nb FROM dbo.region
UNION ALL SELECT 'province_prefecture', COUNT(*) FROM dbo.province_prefecture
UNION ALL SELECT 'cercle',              COUNT(*) FROM dbo.cercle
UNION ALL SELECT 'commune',             COUNT(*) FROM dbo.commune
UNION ALL SELECT 'stat_commune',        COUNT(*) FROM dbo.stat_commune
UNION ALL SELECT 'centre_urbain',       COUNT(*) FROM dbo.centre_urbain
UNION ALL SELECT 'stat_centre_urbain',  COUNT(*) FROM dbo.stat_centre_urbain;

PRINT '--- 2. Communes par type (attendu : 41 arrond. dont 16 avec cercle, 1282 rurales, 215 mun.)';
SELECT type, COUNT(*) AS nb, COUNT(cercle_id) AS avec_cercle
FROM dbo.commune GROUP BY type ORDER BY type;

PRINT '--- 3. Geometries manquantes / invalides (attendu : 0)';
SELECT 'region' AS table_,
       SUM(CASE WHEN geom IS NULL THEN 1 ELSE 0 END) AS sans_geom,
       SUM(CASE WHEN geom.STIsValid() = 0 THEN 1 ELSE 0 END) AS invalides
FROM dbo.region
UNION ALL
SELECT 'province_prefecture',
       SUM(CASE WHEN geom IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN geom.STIsValid() = 0 THEN 1 ELSE 0 END)
FROM dbo.province_prefecture
UNION ALL
SELECT 'commune',
       SUM(CASE WHEN geom IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN geom.STIsValid() = 0 THEN 1 ELSE 0 END)
FROM dbo.commune;

PRINT '--- 4. Coherence : region de la commune = region de sa province (attendu : 0)';
SELECT COUNT(*) AS incoherences
FROM dbo.commune c JOIN dbo.province_prefecture p ON p.id = c.province_prefecture_id
WHERE c.region_id <> p.region_id;

PRINT '--- 5. Population par region';
SELECT r.code, r.nom, SUM(s.population) AS population, SUM(s.menages) AS menages
FROM dbo.region r
JOIN dbo.commune c      ON c.region_id = r.id
JOIN dbo.stat_commune s ON s.commune_id = c.id
GROUP BY r.code, r.nom ORDER BY r.code;

PRINT '--- 6. Superficie (km2, geography) et densite : 10 communes les plus denses';
WITH g AS (
    SELECT c.id, geography::STGeomFromWKB(c.geom.STAsBinary(), 4326) AS geo
    FROM dbo.commune c
), a AS (
    -- geography impose l'orientation des anneaux : on la corrige si besoin
    SELECT id, (CASE WHEN geo.EnvelopeAngle() > 90 THEN geo.ReorientObject() ELSE geo END).STArea() / 1e6 AS km2
    FROM g
)
SELECT TOP 10 c.code, c.nom, c.type,
       CAST(a.km2 AS decimal(12, 2)) AS superficie_km2,
       s.population,
       CAST(s.population / NULLIF(a.km2, 0) AS decimal(12, 0)) AS densite
FROM dbo.commune c
JOIN a              ON a.id = c.id
JOIN dbo.stat_commune s ON s.commune_id = c.id
ORDER BY densite DESC;
