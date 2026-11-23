"""
TP1 Geo BI - Preparation des sources SSIS : export des shapefiles en CSV (code;wkt).

SSIS ne lit pas les shapefiles nativement : on les convertit en CSV dont la
geometrie est en WKT. SSIS charge ce texte dans staging puis PostGIS le
convertit (ST_GeomFromText).

    output/csv/shp_region_wkt.csv, shp_province_wkt.csv, shp_commune_wkt.csv

Equivalent avec l'ogr2ogr de QGIS :
    ogr2ogr -f CSV output/csv/shp_commune_wkt.csv shp_sources/commune.shp
            -lco GEOMETRY=AS_WKT -lco SEPARATOR=SEMICOLON
"""
from pathlib import Path

import geopandas as gpd

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output" / "csv"
SOURCES = {"region": "code_regio", "province": "code_provi", "commune": "code_commu"}


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, code_col in SOURCES.items():
        gdf = gpd.read_file(ROOT / "shp_sources" / f"{name}.shp")
        df = gdf[[code_col]].rename(columns={code_col: "code"})
        df["wkt"] = gdf.geometry.to_wkt()
        path = OUT / f"shp_{name}_wkt.csv"
        df.to_csv(path, sep=";", index=False, encoding="utf-8")
        print(f"  {path.name:<24} {len(df):>5} lignes")


if __name__ == "__main__":
    main()
