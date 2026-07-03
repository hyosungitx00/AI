---
name: abap-read-only-monitoring
description: Implement or extend read-only SAP monitoring ABAP (SM37/ST22/SXI style) with hard guardrails against any data-changing statement, bounded standard-table queries, and display-only drill-downs.
user-invocable: true
---

# ABAP Read-Only Monitoring

Use this skill when implementing or extending the read-only ops-monitoring program
(or any read-only ABAP reporting). The guiding principle: **observe, never mutate.**

## Guardrails (verify on every change)

Reject / do not emit any of these:

| Forbidden | Why |
|-----------|-----|
| `INSERT` / `UPDATE` / `MODIFY` / `DELETE` (DB) | Data mutation |
| `COMMIT WORK` / `ROLLBACK WORK` (business intent) | Transaction side effects |
| `ENQUEUE_*` / `DEQUEUE_*` | Locking = intent to change |
| `CALL FUNCTION ... IN UPDATE TASK` | Deferred mutation |
| State-changing BAPIs/FMs (job re-run, msg re-send, `*_SAVE`, `*_POST`, `*_CHANGE`) | Mutation |
| `CALL TRANSACTION` in change/edit mode | Could trigger mutation |
| `SUBMIT` of update-capable programs | Uncontrolled side effects |

After editing, grep the touched code for the tokens above and confirm none appear
outside comments.

## Implementation steps

1. **Data source = standard only.** Read from documented standard tables / read
   FMs. For this project:
   - SM37 (batch): `TBTCO` / `TBTCP`, error = `TBTCO-STATUS = 'A'`.
   - ST22 (dumps): FM `RS_ST22_GET_DUMPS` (returns `RSDUMPTAB`); error type = `DUMPID`.
   - SXI (interfaces): `SXMSPERROR` (period gate on `EXETIMEST`) joined to
     `SXMSPMAST` / `SXMSPEMAS` on `MSGGUID` (+`PID`).

2. **Bound every query by the period.** Use the selection-screen FROM/TO. Handle
   the midnight/day-boundary case with a composite `(date, time)` condition or a
   timestamp comparison — never a bare `DATUM BETWEEN`. Timestamp columns
   (`*TIMEST`) are UTC: convert local screen input via `CL_ABAP_TSTMP` before
   comparing, and convert back to local for display.

3. **Select only needed fields.** Explicit field list, no `SELECT *`. Cap the ALV
   display rows (`P_MAXROW`, latest-first) but aggregate charts on the full count.

4. **Per-area isolation.** Wrap each provider call in `TRY/CATCH`; a failing area
   empties its ALV and reports status while other areas render normally.

5. **Authority per area, then skip.** Run `AUTHORITY-CHECK` before each area's
   query; if the user lacks rights, skip that area with a "no authorization"
   notice and continue with the rest. Leave `"TODO: SU24/STAUTHTRACE 검증` where
   the exact object/field/value is not yet verified.

6. **Drill-down is display-only.** Route all navigation through
   `ZCL_MON_NAVIGATOR`, calling display FMs/transactions only
   (e.g. `BP_JOBLOG_SHOW`, `CALL TRANSACTION 'ST22'`,
   `CALL TRANSACTION 'SXI_MONITOR'` in display context).

## Extending with a new area

Implement `ZIF_MON_DATA_PROVIDER` in a new `ZCL_MON_DP_*` class and register it
with the controller. Do **not** modify the controller/UI orchestration logic — the
summary, chart, and layout are driven generically off the provider registry.

## Done criteria

- No forbidden token present in the diff.
- Queries are period-bounded and field-explicit.
- Each area is authority-checked and exception-isolated.
- Drill-downs verified to be display-mode.
