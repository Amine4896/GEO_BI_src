-- =====================================================================
-- TP1 Geo BI - SSIS (SQL Server) : WKT (staging) -> colonnes geom
-- Execute SQL Task final du package (apres les Data Flows).
--   STGeomFromText : WKT -> geometry (SRID 4326)
--   MakeValid()    : corrige les polygones invalides (2 communes, 6 provinces)
-- =====================================================================
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

UPDATE t
SET geom = geometry::STGeomFromText(s.wkt, 4326).MakeValid()
FROM dbo.region t
JOIN staging.shp_region_wkt s ON s.code = t.code;

UPDATE t
SET geom = geometry::STGeomFromText(s.wkt, 4326).MakeValid()
FROM dbo.province_prefecture t
JOIN staging.shp_province_wkt s ON s.code = t.code;

UPDATE t
SET geom = geometry::STGeomFromText(s.wkt, 4326).MakeValid()
FROM dbo.commune t
JOIN staging.shp_commune_wkt s ON s.code = t.code;
GO

-- Recreer les index spatiaux une fois les geometries chargees
CREATE SPATIAL INDEX SIX_region_geom   ON dbo.region (geom)
    USING GEOMETRY_AUTO_GRID WITH (BOUNDING_BOX = (-18, 20, 0, 37));
CREATE SPATIAL INDEX SIX_province_geom ON dbo.province_prefecture (geom)
    USING GEOMETRY_AUTO_GRID WITH (BOUNDING_BOX = (-18, 20, 0, 37));
CREATE SPATIAL INDEX SIX_commune_geom  ON dbo.commune (geom)
    USING GEOMETRY_AUTO_GRID WITH (BOUNDING_BOX = (-18, 20, 0, 37));
GO
