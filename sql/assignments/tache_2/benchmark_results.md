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

## 3. Before vs. After (`EXPLAIN (ANALYZE, BUFFERS)`)

| Query | Before (No Index) | After (Indexed) | Gain |
| :--- | :--- | :--- | :---: |
| **A.** `driver_key = 1` (`fact ⋈ driver ⋈ constructor`) | 247.31 ms · 18,814 buffers | **7.55 ms** · 203 buffers | **32.7×** (−98.9% buffers) |
| **B.** `constructor = 6 & circuit = 14` (`fact ⋈ driver`) | 498.69 ms · 109,810 buffers | **12.64 ms** · 701 buffers | **39.5×** (−99.4% buffers) |
| **C.** `is_win = 1 & driver = 1` (`fact ⋈ date ⋈ circuit`) | 279.41 ms · 20,800 buffers | **0.63 ms** *(0.29 ms warm)* · 697 buffers | **441×** (−96.6% buffers) |

## 4. Takeaways

- Shifted keys (`key + (copy_num - 1) * 100000`) keep all PKs/FKs unique with zero join fan-out.
- Indexes replace `Parallel Seq Scan` with `Index Scan`, cutting buffer reads by **96–99%**.
- Partial index (`WHERE is_win = 1`) uses only **512 kB** while delivering a **441×** speedup.
