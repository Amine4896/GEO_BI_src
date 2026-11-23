"""
TP1 Geo BI - Partie II.2 (Option 2) : chargement des shapefiles dans staging.

    shp_sources/region.shp   (code_regio) -> staging.shp_region
    shp_sources/province.shp (code_provi) -> staging.shp_province
    shp_sources/commune.shp  (code_commu) -> staging.shp_commune

Les geometries sont chargees brutes (WKB, SRID 4326). La correction
(ST_MakeValid, passage en MultiPolygon) et la jointure sur le code sont
faites en SQL (sql/04_integration_geom.sql).
"""
from pathlib import Path

import geopandas as gpd
from psycopg2.extras import execute_values

from db import connect

ROOT = Path(__file__).resolve().parents[1]
SHP_DIR = ROOT / "shp_sources"

SOURCES = {
    "shp_region": ("region.shp", "code_regio"),
    "shp_province": ("province.shp", "code_provi"),
    "shp_commune": ("commune.shp", "code_commu"),
}


def main() -> None:
    with connect() as conn, conn.cursor() as cur:
        cur.execute("CREATE SCHEMA IF NOT EXISTS staging")
        for table, (fname, code_col) in SOURCES.items():
            gdf = gpd.read_file(SHP_DIR / fname)
            if gdf.crs is None or gdf.crs.to_epsg() != 4326:
                gdf = gdf.set_crs(4326, allow_override=True) if gdf.crs is None else gdf.to_crs(4326)
            cur.execute(f"DROP TABLE IF EXISTS staging.{table}")
            cur.execute(f"CREATE TABLE staging.{table} (code text, geom geometry(Geometry, 4326))")
            rows = [(str(c).strip(), g.wkb_hex) for c, g in zip(gdf[code_col], gdf.geometry)]
            execute_values(
                cur,
                f"INSERT INTO staging.{table} (code, geom) VALUES %s",
                rows,
                template="(%s, ST_SetSRID(ST_GeomFromWKB(decode(%s, 'hex')), 4326))",
            )
            print(f"  staging.{table:<14} {len(rows):>5} geometries")


if __name__ == "__main__":
    main()
