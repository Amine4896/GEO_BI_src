-- =====================================================================
-- TP1 Geo BI - Partie II.1 : integration des donnees attributaires
-- staging.<entite> (codes)  ->  tables du modele (id + cles etrangeres)
-- Rejouable : vide les tables puis recharge dans l'ordre des dependances.
-- =====================================================================
BEGIN;

TRUNCATE stat_centre_urbain, centre_urbain, stat_commune,
         commune, cercle, province_prefecture, region RESTART IDENTITY CASCADE;

-- 1. REGION
INSERT INTO region (code, nom)
SELECT code, nom
FROM staging.region
ORDER BY code;

-- 2. PROVINCE / PREFECTURE  (region_code -> region_id)
INSERT INTO province_prefecture (code, nom, type, region_id)
SELECT s.code, s.nom, s.type, r.id
FROM staging.province_prefecture s
JOIN region r ON r.code = s.region_code
ORDER BY s.code;

-- 3. CERCLE  (province_code -> province_prefecture_id)
INSERT INTO cercle (code, nom, type, province_prefecture_id)
SELECT s.code, s.nom, s.type, p.id
FROM staging.cercle s
JOIN province_prefecture p ON p.code = s.province_code
ORDER BY s.code;

-- 4. COMMUNE  (cercle facultatif -> LEFT JOIN)
INSERT INTO commune (code, nom, type, region_id, province_prefecture_id, cercle_id)
SELECT s.code, s.nom, s.type, r.id, p.id, c.id
FROM staging.commune s
JOIN region r              ON r.code = s.region_code
JOIN province_prefecture p ON p.code = s.province_code
LEFT JOIN cercle c         ON c.code = s.cercle_code
ORDER BY s.code;

-- 5. STAT_COMMUNE
INSERT INTO stat_commune (commune_id, menages, population, etrangers, marocains)
SELECT c.id, s.menages, s.population, s.etrangers, s.marocains
FROM staging.stat_commune s
JOIN commune c ON c.code = s.commune_code;

-- 6. CENTRE_URBAIN
INSERT INTO centre_urbain (code, nom, commune_id)
SELECT s.code, s.nom, c.id
FROM staging.centre_urbain s
JOIN commune c ON c.code = s.commune_code
ORDER BY s.code;

-- 7. STAT_CENTRE_URBAIN
INSERT INTO stat_centre_urbain (centre_urbain_id, menages, population, etrangers, marocains)
SELECT u.id, s.menages, s.population, s.etrangers, s.marocains
FROM staging.stat_centre_urbain s
JOIN centre_urbain u ON u.code = s.centre_urbain_code;

COMMIT;
