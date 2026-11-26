# Tâche 2 — Scaling, `EXPLAIN ANALYZE` & Indexing

Script: [`tache_2_indexing_benchmark.sql`](tache_2_indexing_benchmark.sql) · Schema: `benchmark` (`public` & `dw` untouched)

## 1. Scaling (`dw` ×50, shifted keys)

| Table | `dw` | `benchmark` (×50) | Size |
| :--- | ---: | ---: | ---: |
| `fact_race_results` | 26,759 | 1,337,950 | 194 MB |
| `dim_date` | 1,125 | 56,250 | 6.9 MB |
| `dim_driver` | 861 | 43,050 | 4.6 MB |
| `dim_constructor` | 212 | 10,600 | 1.3 MB |
| `dim_status` | 139 | 6,950 | 688 kB |
| `dim_circuit` | 77 | 3,850 | 624 kB |
| **Total** | **29,173** | **1,458,650** | **~208 MB** |

## 2. Indexes Added

- **Primary Keys:** all 6 tables (`dim_*_pkey`, `fact_race_results_pkey`)
- **Simple B-Tree:** `idx_bench_driver_key (driver_key)` — 9.9 MB
- **Composite B-Tree:** `idx_bench_constructor_circuit (constructor_key, circuit_key)` — 12 MB
- **Partial B-Tree:** `idx_bench_wins_driver (driver_key) WHERE is_win = 1` — **512 kB**
- **Covering B-Tree:** `idx_bench_constructor_cover (constructor_key) INCLUDE (driver_key, date_key, points)` — 52 MB (for query D, the window function)

## 3. Before vs. After (`EXPLAIN (ANALYZE, BUFFERS)`)

Protocol (course method): the `benchmark` schema is rebuilt without any index, each query runs **3 times** and the **median** is kept (warm cache); the indexes and `ANALYZE` are then applied and each query is measured again the same way.

| Query | Before (ms) | Operator before (fact) | Action | After (ms) | Operator after (fact) | Gain |
| :--- | ---: | :--- | :--- | ---: | :--- | :---: |
| **A.** one driver: `driver_key = 1` (`fact ⋈ driver ⋈ constructor`, join + group by) | 33.45 · 19,334 buffers | Seq Scan | `INDEX (driver_key)` | **1.85** · 252 buffers | Index Scan `idx_bench_driver_key` | **×18.1** |
| **B.** one constructor on one circuit: `constructor = 6 & circuit = 14` (`fact ⋈ driver`) | 228.21 · 109,813 buffers | Seq Scan | `INDEX (constructor_key, circuit_key)` | **0.59** · 707 buffers | Index Scan `idx_bench_constructor_circuit` | **×386.8** |
| **C.** wins of one driver: `is_win = 1 & driver = 1` (`fact ⋈ date ⋈ circuit`) | 61.49 · 25,728 buffers | Seq Scan | partial `INDEX (driver_key) WHERE is_win = 1` | **0.25** · 697 buffers | Index Scan `idx_bench_wins_driver` | **×246.0** |
| **D.** window function: rank of a constructor's drivers per season, `RANK() OVER (PARTITION BY year ORDER BY points DESC)` | 59.45 · 21,916 buffers | Seq Scan | covering `INDEX (constructor_key) INCLUDE (driver_key, date_key, points)` | **14.57** · 1,542 buffers | Index Only Scan `idx_bench_constructor_cover` | **×4.1** |

Individual runs (ms) — A: 39.83 / 32.82 / 33.45 → 11.49 / 1.85 / 1.73 · B: 228.21 / 239.00 / 216.94 → 3.44 / 0.56 / 0.59 · C: 58.81 / 61.49 / 66.55 → 1.17 / 0.25 / 0.25 · D: 79.29 / 49.14 / 59.45 → 35.86 / 14.56 / 14.57. The first run after indexing is slower (cold index pages), which is why the median is used.

## 4. Takeaways

- Shifted keys (`key + (copy_num - 1) * 100000`) keep all PKs/FKs unique with zero join fan-out.
- On every query the bottleneck was a **Seq Scan of the 1.34 M-row fact table** that kept only a few rows (*Rows Removed by Filter*); the indexes replace it with an index scan and cut buffer reads by **93–99%**.
- The **partial index** (`WHERE is_win = 1`) is only **512 kB** yet gives **×246** on query C.
- **Query D (window function) gains less (×4.1):** the covering index lets PostgreSQL read the constructor's rows straight from the index (**Index Only Scan**, no table access), but after the scan the query still has to join `dim_date` and `dim_driver`, aggregate per season and sort for `RANK()`. The window function itself cannot use the index, because it runs on the aggregated rows. This is the expected "partial gain" case: the index removes the scan cost, not the sort / window cost.
- **Trade-off:** the covering index is the largest (52 MB, 4× the composite index) because it stores 3 extra columns; it would also slow down writes on the fact table.

## 5. Limits

- Volume is **1.46 M rows** (×50), below the course's ~10 M target: the gains would be larger at 10 M rows, since Seq Scan cost grows with the table while index lookups stay almost flat.
- Timings are from a laptop with a warm cache; absolute values vary between runs, the ratios and the plan operators are what matter.
