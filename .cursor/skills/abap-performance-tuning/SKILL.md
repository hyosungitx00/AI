---
name: abap-performance-tuning
description: Diagnose and refactor slow ABAP for SAP monitoring/reporting — bounded and index-friendly SELECTs, no SELECT* / SELECT-in-LOOP, set-based joins/FOR ALL ENTRIES, and efficient internal-table access.
user-invocable: true
---

# ABAP Performance Tuning

Use when a report/query is slow, or proactively during refactoring to keep the
Five Golden Rules of ABAP database access.

## The Five Golden Rules

1. **Keep the result set small** — filter in the `WHERE` clause (period, status),
   never fetch-then-discard. Every query in this project is bounded by the
   selection period; enforce it.
2. **Minimize transferred data** — explicit field list, never `SELECT *`. Use
   aggregates (`COUNT`, `SUM`) in the DB when you only need totals.
3. **Minimize the number of round-trips** — no `SELECT` inside a `LOOP`. Use a
   join, a CDS view, or `FOR ALL ENTRIES` (with a non-empty, de-duplicated driver
   table). Batch ST22 date-by-date FM calls only across the bounded period.
4. **Minimize search effort** — hit an existing index; put the most selective
   indexed fields first in `WHERE`. For `TBTCO`, filter on status + end date; for
   `SXMSPERROR`, gate on `EXETIMEST` first, then join by `MSGGUID`(+`PID`).
5. **Minimize the load on the DB** — do heavy filtering/sorting where cheapest;
   avoid returning huge sets to be trimmed in ABAP (cap ALV rows, but aggregate
   charts on the full bounded set in memory).

## Internal-table hygiene

- Choose the right table kind: `SORTED`/`HASHED` for keyed lookups; avoid linear
  `READ TABLE ... WITH KEY` inside loops on `STANDARD` tables.
- Use `READ TABLE ... BINARY SEARCH` only on sorted data; prefer typed keys.
- Avoid nested loops over large internal tables (O(n²)); pre-index with a hashed
  table or `GROUP BY` (`LOOP AT ... GROUP BY`).
- Move invariant work out of loops.

## Diagnosis workflow

1. Reproduce with a realistic period; note the slow step.
2. Inspect with SQL trace (**ST05**) and runtime analysis (**SAT/SE30**);
   check the DB explain for full-scan vs index range scan.
3. Form a hypothesis (e.g. "SELECT-in-LOOP causes N round-trips"), fix the single
   biggest offender, re-measure. Don't micro-optimize before measuring.
4. Re-run the `abap-code-review` checklist to confirm no read-only or correctness
   regression was introduced by the optimization.

## Done criteria

- No `SELECT *`, no SELECT-in-LOOP, all queries period-bounded and index-friendly.
- Aggregations set-based or single-pass in memory.
- Measured improvement (ST05/SAT) recorded in the PR/design notes.
