"""
TP1 Geo BI - Partie II.1 : preparation des donnees attributaires.

Lit population.xlsx (RGPH 2004, feuille "Communes" : hierarchie complete)
et produit une feuille Excel par entite du modele :

    output/donnees_par_entite.xlsx  (feuilles region, province_prefecture,
                                      cercle, commune, stat_commune,
                                      centre_urbain, stat_centre_urbain)
    output/csv/<entite>.csv         (UTF-8, ';' - reutilises par SSIS)

Les cles etrangeres sont exprimees par les CODES (region_code, ...) :
les id techniques sont generes par PostgreSQL, la correspondance
code -> id est faite en SQL (sql/03_integration_attributs.sql).

Regles de decodage du "Code Geographique" (sans le point final) :
    RR                 -> region            (ex : 01)
    RR.PPP             -> province/prefecture (ex : 01.066)
    RR.PPP.CC          -> cercle            (ex : 01.066.03)
    RR.PPP.CC.N        -> prefecture d'arrondissements (Casablanca, ex : 09.141.01.0)
    RR.PPP.CC.NN       -> commune           (ex : 01.066.03.05)
    RR.PPP.CC.NN.3     -> centre urbain ("Dont Centre")
"""
from pathlib import Path
import re

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "population.xlsx"
OUT_DIR = ROOT / "output"
CSV_DIR = OUT_DIR / "csv"

STAT_COLS = ["menages", "population", "etrangers", "marocains"]


def clean(text: str) -> str:
    """Normalise les espaces et l'apostrophe typographique."""
    text = str(text).replace("\u2019", "'").replace("\xa0", " ")
    return re.sub(r"\s+", " ", text).strip()


def strip_prefix(label: str) -> str:
    """Supprime 'Region:', 'Province:', 'Cercle :', 'Dont Centre:' ..."""
    label = re.sub(r"^Pr[ée]fecture d'Arrondissements?\s*", "", label, flags=re.I)
    return clean(re.sub(r"^[^:]{1,20}:\s*", "", label))


def read_source() -> pd.DataFrame:
    df = pd.read_excel(SOURCE, sheet_name="Communes", header=None, skiprows=5)
    df = df.iloc[:, :6]
    df.columns = ["code", "libelle"] + STAT_COLS
    df = df.dropna(subset=["code"])
    df["code"] = df["code"].astype(str).str.strip().str.rstrip(".")
    df = df[df["code"].str.match(r"^\d{2}(\.|$)")]          # retire la ligne Total
    df["libelle"] = df["libelle"].map(clean)
    for c in STAT_COLS:
        df[c] = pd.to_numeric(df[c], errors="coerce").fillna(0).astype(int)
    df["niveau"] = df["code"].str.split(".").map(
        lambda p: {1: "region", 2: "province", 3: "cercle", 5: "centre"}.get(len(p))
        or ("prefecture_arr" if len(p[3]) == 1 else "commune")
    )
    return df.reset_index(drop=True)


def build(df: pd.DataFrame) -> dict[str, pd.DataFrame]:
    seg = df["code"].str.split(".")

    # --- region -------------------------------------------------------
    r = df[df.niveau == "region"]
    region = pd.DataFrame({"code": r.code, "nom": r.libelle.map(strip_prefix)})

    # --- province / prefecture ---------------------------------------
    p = df[df.niveau == "province"]
    province = pd.DataFrame({
        "code": seg[p.index].str[1],                                  # '066'
        "nom": p.libelle.map(strip_prefix),
        "type": p.libelle.str.startswith("Province").map(
            {True: "Province", False: "Préfecture"}),
        "region_code": seg[p.index].str[0],
    })

    # --- cercle (+ prefectures d'arrondissements de Casablanca) -------
    c = df[df.niveau.isin(["cercle", "prefecture_arr"])]
    cercle = pd.DataFrame({
        "code": c.code,
        "nom": c.libelle.map(strip_prefix),
        "type": c.niveau.map({"cercle": "Cercle",
                              "prefecture_arr": "Préfecture d'arrondissements"}),
        "province_code": seg[c.index].str[1],
    })
    cercle_codes = set(cercle.code)

    # --- commune ------------------------------------------------------
    m = df[df.niveau == "commune"]

    def cercle_of(code: str):
        if code[:9] in cercle_codes:                 # commune rurale d'un cercle
            return code[:9]
        if code[:11] in cercle_codes:                # arrondissement de Casablanca
            return code[:11]
        return None                                  # municipalite hors cercle

    def type_of(label: str) -> str:
        if "(Mun.)" in label:
            return "Municipalité"
        if "(Arrond.)" in label:
            return "Arrondissement"
        return "Commune rurale"

    commune = pd.DataFrame({
        "code": m.code,
        "nom": m.libelle.str.replace(r"\((Mun|Arrond)\.\)", "", regex=True).map(clean),
        "type": m.libelle.map(type_of),
        "region_code": seg[m.index].str[0],
        "province_code": seg[m.index].str[1],
        "cercle_code": m.code.map(cercle_of),
    })
    stat_commune = m[["code"] + STAT_COLS].rename(columns={"code": "commune_code"})

    # --- centre urbain ------------------------------------------------
    u = df[df.niveau == "centre"]
    centre = pd.DataFrame({
        "code": u.code,
        "nom": u.libelle.map(strip_prefix),
        "commune_code": u.code.str[:12],
    })
    stat_centre = u[["code"] + STAT_COLS].rename(columns={"code": "centre_urbain_code"})

    return {
        "region": region,
        "province_prefecture": province,
        "cercle": cercle,
        "commune": commune,
        "stat_commune": stat_commune,
        "centre_urbain": centre,
        "stat_centre_urbain": stat_centre,
    }


def check(t: dict[str, pd.DataFrame]) -> None:
    for name, d in t.items():
        key = d.columns[0]
        assert d[key].is_unique, f"doublon de code dans {name}"
        print(f"  {name:<20} {len(d):>5} lignes")
    assert set(t["commune"].code) >= set(t["centre_urbain"].commune_code)
    bad = t["stat_commune"].query("population != etrangers + marocains")
    print(f"  communes avec population != etrangers + marocains : {len(bad)}")


def main() -> None:
    tables = build(read_source())
    check(tables)
    CSV_DIR.mkdir(parents=True, exist_ok=True)
    with pd.ExcelWriter(OUT_DIR / "donnees_par_entite.xlsx") as xw:
        for name, d in tables.items():
            d.to_excel(xw, sheet_name=name, index=False)
            d.to_csv(CSV_DIR / f"{name}.csv", sep=";", index=False, encoding="utf-8")
    print(f"-> {OUT_DIR / 'donnees_par_entite.xlsx'}")
    print(f"-> {CSV_DIR}")


if __name__ == "__main__":
    main()
