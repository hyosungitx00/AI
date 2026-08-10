---
name: abap-code-review
description: Review ABAP changes for read-only safety, correctness, performance, security/authorization, and Clean ABAP maintainability. Reports findings by severity with file/line and a suggested fix.
user-invocable: true
---

# ABAP Code Review

Use when reviewing ABAP code or a change set. Organize findings by severity and
always give an actionable fix.

## 1. Understand the change

Read the diff/objects and identify scope (new provider, UI change, bug fix,
refactor). Note which monitoring area(s) and standard objects are touched.

## 2. Read-only safety (blocking)

- Scan for forbidden statements: `INSERT/UPDATE/MODIFY/DELETE`, `COMMIT WORK`,
  `ROLLBACK WORK`, `ENQUEUE_*/DEQUEUE_*`, `IN UPDATE TASK`, state-changing
  BAPIs/FMs, edit-mode `CALL TRANSACTION`. Any occurrence = **Must fix**.
- Confirm drill-downs go through `ZCL_MON_NAVIGATOR` in display mode only.

## 3. Correctness

- Period filtering handles the **day/midnight boundary** (composite date+time or
  timestamp compare), not a bare `DATUM BETWEEN`.
- Timestamps (`*TIMEST`) are treated as **UTC**: local→UTC on input, UTC→local on
  display. No direct comparison of screen-local values to UTC columns.
- Error-detection criteria match spec (`TBTCO-STATUS = 'A'`; `SXMSPERROR` presence
  for SXI; `RS_ST22_GET_DUMPS` results for ST22).
- `SY-SUBRC` checked after every SELECT / FM call; empty results handled.
- Off-by-one / boundary issues in loops, Top-N, and row caps.

## 4. Performance

- Every `SELECT` is period-bounded; no unbounded full scans.
- Explicit field lists, no `SELECT *`.
- No SELECT inside a LOOP (use `FOR ALL ENTRIES` with a non-empty/duplicate-safe
  driver, or a join/CDS). Watch nested loops on internal tables (use sorted/hashed
  tables or keys).
- ST22 date-by-date FM calls are bounded by the period; long ranges flagged.
- Aggregation happens on in-memory result rows, not via extra DB round-trips.

## 5. Security / authorization

- `AUTHORITY-CHECK` performed **per area** before its query; missing rights →
  skip that area (not a hard dump), other areas continue.
- Candidate auth objects present with `"TODO: SU24/STAUTHTRACE 검증` where the
  exact object/field/value is unverified.

## 6. Maintainability (Clean ABAP)

- Interface-first: new area = new implementer + registry, no caller changes.
- Small single-responsibility methods; typed signatures (`ZMON_S_*`/`ZMON_T_*`).
- Constants over magic literals (status codes, thresholds, defaults).
- User text via text symbols; messages via message class (i18n).
- Duplicated period/timezone logic consolidated into shared utilities.

## 7. Activation readiness

Before finishing, run `abap-activation-preflight` (P1–P10). Treat undeclared
members, ECC-incompatible ALV constants, string-template/CSS clashes, and
untyped navigate structures as **Must fix** — they caused repeated compile
loops in prior sessions.

## 8. Report findings

Group by severity, each with **file:line**, the issue, the *why*, and a fix:

- **Must fix** — read-only violations, wrong error criteria, timezone/boundary
  bugs, unbounded queries, missing authority check, `SY-SUBRC` unchecked.
- **Should fix** — `SELECT *`, SELECT-in-LOOP, magic literals, missing i18n,
  weak exception handling.
- **Nit** — naming, ordering, comments that a formatter/pretty-printer handles.

Acknowledge what's done well. Don't bikeshed style the Pretty Printer covers.
