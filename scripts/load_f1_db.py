#!/usr/bin/env python3
"""Download the Ergast Formula 1 dataset via kagglehub and load it into PostgreSQL."""

import argparse
import os
from pathlib import Path

import kagglehub
import psycopg2
from psycopg2 import sql

# Load order respects foreign key dependencies
TABLE_FILES = [
    ("seasons", "seasons.csv"),
    ("circuits", "circuits.csv"),
    ("constructors", "constructors.csv"),
    ("drivers", "drivers.csv"),
    ("status", "status.csv"),
    ("races", "races.csv"),
    ("constructor_results", "constructor_results.csv"),
    ("constructor_standings", "constructor_standings.csv"),
    ("driver_standings", "driver_standings.csv"),
    ("qualifying", "qualifying.csv"),
    ("results", "results.csv"),
    ("sprint_results", "sprint_results.csv"),
    ("pit_stops", "pit_stops.csv"),
    ("lap_times", "lap_times.csv"),
]


def ensure_database(conn_params: dict, dbname: str) -> None:
    admin_params = {**conn_params, "dbname": "postgres"}
    conn = psycopg2.connect(**admin_params)
    conn.autocommit = True
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (dbname,))
            if cur.fetchone() is None:
                cur.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(dbname)))
                print(f"Created database '{dbname}'.")
            else:
                print(f"Database '{dbname}' already exists.")
    finally:
        conn.close()


def load_data(conn_params: dict, dbname: str, dataset_dir: Path, schema_path: Path) -> None:
    db_params = {**conn_params, "dbname": dbname}
    conn = psycopg2.connect(**db_params)
    try:
        with conn.cursor() as cur:
            print(f"Applying schema from {schema_path.name}...")
            cur.execute(schema_path.read_text(encoding="utf-8"))

            for table, filename in TABLE_FILES:
                csv_path = dataset_dir / filename
                copy_sql = (
                    f"COPY {table} FROM STDIN "
                    f"WITH (FORMAT csv, HEADER true, NULL '\\N')"
                )
                with csv_path.open("r", encoding="utf-8") as f:
                    cur.copy_expert(copy_sql, f)
                cur.execute(sql.SQL("SELECT COUNT(*) FROM {}").format(sql.Identifier(table)))
                count = cur.fetchone()[0]
                print(f"  Loaded {table:<22} {count:>7,} rows")

        conn.commit()
        print("\nAll 14 tables loaded successfully.")
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def main() -> None:
    parser = argparse.ArgumentParser(description="Load F1 Kaggle dataset into PostgreSQL.")
    parser.add_argument("--db", default=os.environ.get("PGDATABASE", "f1"), help="Target database name (default: f1)")
    parser.add_argument("--host", default=os.environ.get("PGHOST", "localhost"))
    parser.add_argument("--port", type=int, default=int(os.environ.get("PGPORT", "5432")))
    parser.add_argument("--user", default=os.environ.get("PGUSER", os.environ.get("USER", "postgres")))
    parser.add_argument("--password", default=os.environ.get("PGPASSWORD"))
    parser.add_argument("--from-kaggle", action="store_true", help="Download fresh CSVs via kagglehub instead of using data/csv")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    local_csv_dir = repo_root / "data" / "csv"
    if not args.from_kaggle and local_csv_dir.exists() and any(local_csv_dir.glob("*.csv")):
        dataset_path = local_csv_dir
    else:
        dataset_path = Path(kagglehub.dataset_download("rohanrao/formula-1-world-championship-1950-2020"))
    print(f"Dataset path: {dataset_path}")

    conn_params = {
        "host": args.host,
        "port": args.port,
        "user": args.user,
    }
    if args.password is not None:
        conn_params["password"] = args.password

    ensure_database(conn_params, args.db)
    schema_path = repo_root / "sql" / "schema.sql"
    load_data(conn_params, args.db, dataset_path, schema_path)


if __name__ == "__main__":
    main()
