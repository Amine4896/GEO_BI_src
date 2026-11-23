"""Connexion PostgreSQL commune aux scripts (variables d'environnement PG*)."""
import getpass
import os

import psycopg2


def connect():
    if not os.environ.get("PGPASSWORD"):
        os.environ["PGPASSWORD"] = getpass.getpass("Mot de passe PostgreSQL (postgres) : ")
    return psycopg2.connect(
        host=os.environ.get("PGHOST", "localhost"),
        port=os.environ.get("PGPORT", "5432"),
        user=os.environ.get("PGUSER", "postgres"),
        dbname=os.environ.get("PGDATABASE", "geobi_tp1"),
    )
