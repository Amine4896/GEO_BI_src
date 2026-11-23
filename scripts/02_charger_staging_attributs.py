"""
TP1 Geo BI - Partie II.1 : chargement des feuilles par entite dans staging.

Chaque feuille de output/donnees_par_entite.xlsx est chargee telle quelle
(colonnes texte/entier) dans staging.<entite>. Le passage code -> id et
l'insertion dans les tables du modele se font ensuite en SQL
(sql/03_integration_attributs.sql).
"""
from pathlib import Path

import pandas as pd
from psycopg2.extras import execute_values

from db import connect

ROOT = Path(__file__).resolve().parents[1]
XLSX = ROOT / "output" / "donnees_par_entite.xlsx"
INT_COLS = {"menages", "population", "etrangers", "marocains"}


def main() -> None:
    sheets = pd.read_excel(XLSX, sheet_name=None, dtype=str)
    with connect() as conn, conn.cursor() as cur:
        cur.execute("CREATE SCHEMA IF NOT EXISTS staging")
        for name, df in sheets.items():
            df = df.astype(object).where(df.notna(), None)
            cols = ", ".join(
                f"{c} {'integer' if c in INT_COLS else 'text'}" for c in df.columns
            )
            cur.execute(f"DROP TABLE IF EXISTS staging.{name}")
            cur.execute(f"CREATE TABLE staging.{name} ({cols})")
            execute_values(
                cur,
                f"INSERT INTO staging.{name} ({', '.join(df.columns)}) VALUES %s",
                [tuple(r) for r in df.itertuples(index=False)],
            )
            print(f"  staging.{name:<20} {len(df):>5} lignes")


if __name__ == "__main__":
    main()
