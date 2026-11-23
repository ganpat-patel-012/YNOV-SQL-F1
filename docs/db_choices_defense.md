# Defending Our Database Choices — YNOV-SQL-F1

This document explains **why** we chose the Formula 1 (Ergast) dataset, **why** we modeled and implemented it in **PostgreSQL** the way we did, and how to answer likely questions during a project review or *soutenance*.

---

## 1. Why This Dataset? (Meeting & Exceeding Every Criterion)

| Requirement | Why Formula 1 (Ergast) Is an Ideal Choice |
| :--- | :--- |
| **4–5+ linked tables** | Provides **14 naturally normalized tables** with **23 foreign keys** — no artificial splitting required. Supports complex multi-hop joins (`seasons` → `races` → `results` → `drivers` / `constructors` / `status` / `circuits`). |
| **Time dimension** | **75 years of real historical data** (`1950-05-13` to `2024-12-08`), spanning multiple granularities: year (`seasons`), race date & session times (`races`), driver birthdates (`drivers.dob`), pit stop clock times (`pit_stops.time`), and millisecond lap telemetry (`lap_times.milliseconds`). |
| **Categories & groups** | Rich categorical slicing: **139** finish/DNF statuses (`status`), **212** constructors, **43** driver nationalities, **24** constructor nationalities, and **35** host countries. |
| **Hierarchies** | Supports drill-down / roll-up analytics across **3 distinct hierarchies**:<br>1. **Time/Event:** `Season → Race (Round) → Lap / Pit Stop / Result`<br>2. **Geography:** `Country → City (location) → Circuit`<br>3. **Organization:** `Constructor → Driver → Race Result` |
| **Volume** | **701,433 rows** (including **589,081** rows in `lap_times`) — large enough that query planning, indexing, and aggregation performance actually matter, yet compact enough (**89 MB** in Postgres, **6.2 MB** `.dump`) to run smoothly on any laptop. |
| **Open license** | **CC0: Public Domain** on Kaggle (sourced from Ergast Developer API) — zero legal or licensing restrictions for academic/educational use. |

---

## 2. Why PostgreSQL?

- **Strict relational integrity:** Enforces all 14 primary keys and 23 foreign keys at write time (preventing orphan records or silent type coercion).
- **Rich analytical SQL:** Full support for CTEs (`WITH`), window functions (`RANK()`, `LAG()`, `SUM() OVER (...)`), `ROLLUP`/`CUBE`, lateral joins, and native `DATE`/`TIME` arithmetic — ideal for championship standings, lap-time deltas, and season-over-season trends.
- **High-speed bulk ingestion:** PostgreSQL `COPY ... FROM STDIN` loaded all **701,433 rows** in under 8 seconds with native `\N` → `NULL` conversion.
- **Portable distribution:** `pg_dump -Fc --no-owner --no-privileges` produces a single **6.2 MB** compressed archive (`dump/f1.dump`) that restores cleanly on any teammate's or instructor's machine.

---

## 3. Schema Design & Modeling Decisions

### 3.1 Third Normal Form (3NF)
- **Entity separation:** Reference entities (`seasons`, `circuits`, `constructors`, `drivers`, `status`) are stored once and referenced by integer surrogate keys (`circuit_id`, `driver_id`, `constructor_id`, `status_id`).
- **Why `status` is its own table:** Instead of repeating strings like `"Finished"`, `"Engine"`, or `"Collision"` 26,759 times in `results` (and 360 times in `sprint_results`), `status_id` references `status(status_id)`. This prevents typos, reduces storage, and simplifies failure-mode grouping.
- **Fact vs. Dimension clarity:** The schema naturally supports both OLTP-style queries and BI/OLAP star/snowflake queries:
  - **Fact tables:** `results`, `sprint_results`, `qualifying`, `lap_times`, `pit_stops`, `driver_standings`, `constructor_standings`, `constructor_results`
  - **Dimension tables:** `seasons`, `races`, `circuits`, `drivers`, `constructors`, `status`

### 3.2 Primary Keys: Surrogate vs. Composite
- **Surrogate integer PKs** (`race_id`, `result_id`, `driver_id`, etc.) are preserved from Ergast so all upstream references remain stable and joins stay compact (4-byte integers).
- **Composite natural PKs** are used where no surrogate ID exists and natural uniqueness is guaranteed:
  - `lap_times`: `PRIMARY KEY (race_id, driver_id, lap)` — a driver can only complete lap *N* of race *R* once.
  - `pit_stops`: `PRIMARY KEY (race_id, driver_id, stop)` — a driver's *K*-th pit stop in race *R* is uniquely identified.

### 3.3 Naming Convention (`snake_case`)
- Source CSV headers use `camelCase` (`circuitId`, `fastestLapSpeed`, `positionOrder`).
- In PostgreSQL, unquoted identifiers fold to lowercase, so `camelCase` either requires awkward double-quoting (`"circuitId"`) or turns into hard-to-read `circuitid`.
- Converting all columns to **`snake_case`** (`circuit_id`, `fastest_lap_speed`, `position_order`) follows PostgreSQL best practices and makes SQL queries clean and readable.

### 3.4 Data Typing & NULL Hygiene
- **Dates and Times:** Stored as native `DATE` and `TIME` (`races.date`, `races.time`, `drivers.dob`, `pit_stops.time`) rather than `TEXT`, enabling direct date filtering (`EXTRACT(YEAR FROM dob)`, interval math).
- **Duration / Lap-Time strings vs. Milliseconds:** Both human-readable strings (`time TEXT`, e.g. `1:27.452` or `+5.478`) and exact integer `milliseconds` are kept — strings for display, `milliseconds` for fast numeric aggregations (`AVG`, `MIN`, `PERCENTILE_CONT`).
- **Explicit `NULL` handling:** The Ergast CSVs encode missing values as `\N`. Our loader converts `\N` into true SQL `NULL` so `COUNT(col)`, `AVG(col)`, and `IS NULL` behave accurately (instead of failing casts or skewing aggregates).

---

## 4. Indexing Strategy

PostgreSQL automatically creates a B-Tree index for every primary key (14 indexes), **but does not automatically index foreign keys**. Because analytical queries frequently filter or join on foreign keys, we added **13 targeted B-Tree indexes**:

- `races(year)`, `races(circuit_id)` — fast season filtering and circuit lookups
- `results(race_id)`, `results(driver_id)`, `results(constructor_id)` — accelerates driver career stats, constructor histories, and race summaries
- `qualifying(race_id)`, `qualifying(driver_id)` — fast grid vs. qualifying comparisons
- `driver_standings(race_id)`, `driver_standings(driver_id)` — championship progression queries
- `constructor_standings(race_id)`, `constructor_results(race_id)` — team standings queries
- `lap_times(driver_id)`, `pit_stops(driver_id)` — speeds up driver-level queries across the 589k-row `lap_times` table (since its composite PK starts with `race_id`, queries filtering by `driver_id` alone benefit directly from a dedicated index)

---

## 5. Known Dataset Limitations & How We Handle Them

Being transparent about real-world data gaps shows strong data engineering rigor:

1. **Historical telemetry coverage:**
   - `lap_times` starts in **1996** (electronic lap timing era).
   - `pit_stops` starts in **2011**.
   - `sprint_results` starts in **2021** (when F1 introduced Sprint races).
   - *Implication:* Queries over `lap_times` or `pit_stops` should explicitly state their era scope (e.g. `WHERE year >= 2011`).
2. **Nullable `results.position` vs. `results.position_order`:**
   - Drivers who DNF/DSQ have `position IS NULL` and `position_text` in `('R', 'D', 'E', 'W', 'F', 'N')`.
   - `position_order` is always populated (`NOT NULL`) for deterministic ranking within a race.
3. **Half-points & fastest-lap bonus points:**
   - `points` is stored as `DOUBLE PRECISION` (not `INTEGER`) because F1 has awarded fractional points (e.g., `0.5` points in shortened races like 2021 Belgian GP or 2009 Malaysian GP).
4. **Driver numbers:**
   - Permanent driver numbers were introduced in 2014; older drivers have `drivers.number IS NULL`, while per-race car numbers are tracked in `results.number`.

---

## 6. Anticipated Defense Q&A (*Soutenance*)

**Q: Why keep both `results` and `driver_standings` if standings can be computed from results?**  
*A:* F1's championship scoring rules changed many times between 1950 and 2024 (e.g. dropped-scores rules where only the best *N* results counted, double points in 2014 Abu Dhabi, shared drives in the 1950s). Storing official `driver_standings` and `constructor_standings` preserves historical accuracy while still allowing us to cross-check modern seasons directly from `results` + `sprint_results`.

**Q: Why isn't `lap_times` partitioned?**  
*A:* At 589,081 rows (~34 MB table data), PostgreSQL handles `lap_times` comfortably in memory with B-Tree indexes. Partitioning by `race_id` or `year` would add operational complexity without meaningful speedups at <1M rows — though it is a natural next step if we later ingest high-frequency car telemetry (e.g. FastF1 10Hz sensor data).

**Q: Why use `pg_dump -Fc` instead of just committing CSVs?**  
*A:* We provide **both**: `data/csv/` gives full transparency and reproducibility for ETL pipelines (`scripts/load_f1_db.py`), while `dump/f1.dump` lets anyone restore the exact typed schema, constraints, indexes, and 701,433 rows in a single `pg_restore` command without needing Python.

**Q: What interesting analytical SQL queries can this database answer?**  
- **Driver dominance & consistency:** Win rate, podium rate, DNF rate by era (`GROUP BY` + `CASE`)
- **Qualifying vs. Race pace:** Average positions gained/lost from grid (`grid - position_order`)
- **Pit stop strategy impact:** Correlation between pit stop duration / stop count and finishing position (`JOIN pit_stops` + `results`)
- **Circuit difficulty:** Retirement rate by circuit and status category (`circuits` → `races` → `results` → `status`)
- **Championship progression:** Cumulative points race-by-race using window functions (`SUM(points) OVER (PARTITION BY year, driver_id ORDER BY round)`)
