# YNOV-SQL-F1 — Formula 1 World Championship PostgreSQL Database (1950–2024)

A normalized, production-style **PostgreSQL** database built from the **Formula 1 World Championship (1950–2024)** dataset (Ergast F1 / Kaggle), created for the **YNOV SQL & Data Engineering** project.

- **14 normalized tables** linked by **23 enforced foreign keys**
- **701,433 total rows** across **75 seasons** (`1950-05-13` to `2024-12-08`)
- **27 indexes** (14 primary keys + 13 analytical B-Tree indexes)
- **Open license:** CC0 Public Domain (sourced from [Kaggle / Ergast F1](https://www.kaggle.com/datasets/rohanrao/formula-1-world-championship-1950-2020))

---

## Repository Structure

```text
YNOV-SQL-F1/
├── README.md                     # Project overview and quickstart guide
├── data/
│   └── csv/                      # All 14 raw source CSV files (21 MB total)
├── dump/
│   └── f1.dump                   # Portable compressed PostgreSQL dump (6.2 MB)
├── sql/
│   ├── schema.sql                # Full PostgreSQL DDL (tables, PKs, FKs, indexes)
│   └── queries.sql               # Window functions & CTEs exercises (beginner-friendly, lowercase)
├── docs/
│   ├── f1_er_diagram.drawio      # Editable Draw.io ER diagram (14 tables, 23 FKs)
│   ├── f1_star_schema.drawio     # Editable Draw.io Star Schema diagram (1 fact, 5 dims)
│   ├── validation_report.md      # Verification against all 6 course criteria + row parity
│   └── db_choices_defense.md     # Architectural defense & Q&A prep for database choices
```

---

## Quick Start — Restore the Database

### Option 1: Restore from `dump/f1.dump` (Fastest — ~2 seconds)

```bash
createdb f1
pg_restore -d f1 --no-owner --no-privileges dump/f1.dump
```

*(Add `-U postgres` or `-p <port>` if your local PostgreSQL uses a non-default user or port.)*

### Option 2: Restore via pgAdmin 4

1. Create an empty database named `f1`.
2. Right-click **`f1`** → **Restore...**
3. Select `dump/f1.dump` and click **Restore**.

---

## Dataset Overview

| Table | Rows | Description |
| :--- | ---: | :--- |
| `seasons` | 75 | F1 World Championship seasons (1950–2024) |
| `circuits` | 77 | Race circuits with city, country, coordinates, altitude |
| `constructors` | 212 | Racing teams / constructors and nationalities |
| `drivers` | 861 | Drivers with code, number, DOB, nationality |
| `status` | 139 | Race finish & retirement status categories |
| `races` | 1,125 | Grand Prix events, rounds, dates, session schedules |
| `constructor_results` | 12,625 | Per-race points scored by each constructor |
| `constructor_standings` | 13,391 | Cumulative constructor championship standings per race |
| `driver_standings` | 34,863 | Cumulative driver championship standings per race |
| `qualifying` | 10,494 | Qualifying positions and Q1/Q2/Q3 lap times |
| `results` | 26,759 | Grand Prix race results, grid, points, fastest lap, status |
| `sprint_results` | 360 | Sprint race results (introduced in 2021) |
| `pit_stops` | 11,371 | Pit stop lap, timestamp, and duration (2011+) |
| `lap_times` | 589,081 | Lap-by-lap positions and times in milliseconds (1996+) |
| **Total** | **701,433** | **89 MB in PostgreSQL (including indexes)** |

---

## Documentation

- **[ER Diagram — Snowflake / 3NF (Draw.io)](docs/f1_er_diagram.drawio)** — Full visual schema with all 14 tables, column types, `PK`/`FK` badges, and 23 crow's-foot relationships ([Open directly in draw.io](https://app.diagrams.net/#Uhttps%3A%2F%2Fraw.githubusercontent.com%2Fganpat-patel-012%2FYNOV-SQL-F1%2Fmain%2Fdocs%2Ff1_er_diagram.drawio)).
- **[Star Schema ER Diagram (Draw.io)](docs/f1_star_schema.drawio)** — Analytics/BI Star Schema with 1 central fact table (`fact_race_results`) and 5 denormalized dimensions ([Open directly in draw.io](https://app.diagrams.net/#Uhttps%3A%2F%2Fraw.githubusercontent.com%2Fganpat-patel-012%2FYNOV-SQL-F1%2Fmain%2Fdocs%2Ff1_star_schema.drawio)).
- **[Validation Report](docs/validation_report.md)** — Proof that all 6 course criteria (*Les critères d'une base valide*) and 100% CSV-to-DB row parity are satisfied.
- **[Database Choices Defense](docs/db_choices_defense.md)** — Justification of dataset selection, PostgreSQL engine, 3NF schema modeling, data typing, indexing strategy, data quirks, and anticipated Q&A for project defense.

---

## Sample Query

Top 5 Grand Prix race winners of all time:

```sql
SELECT
    d.forename || ' ' || d.surname AS driver,
    COUNT(*) AS wins
FROM results r
JOIN drivers d ON d.driver_id = r.driver_id
WHERE r.position = 1
GROUP BY d.driver_id, d.forename, d.surname
ORDER BY wins DESC
LIMIT 5;
```

## License & Attribution

- Dataset: [Formula 1 World Championship (1950–2020)](https://www.kaggle.com/datasets/rohanrao/formula-1-world-championship-1950-2020) by Vopani (rohanrao), sourced from the **Ergast Developer API** — **CC0: Public Domain**.
