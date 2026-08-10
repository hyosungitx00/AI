---
name: abap-clean-oo
description: Write and refactor ABAP using Clean ABAP + OO conventions — interface-first design, small single-responsibility methods, strategy/registry patterns, constants over literals, and proper exception classes.
user-invocable: true
---

# Clean OO ABAP

Use this skill when writing new ABAP classes/interfaces or refactoring existing
report/module logic toward maintainable, extensible OO code.

## Design principles

- **Separation of concerns.** Keep data access, presentation, and control in
  separate classes (providers vs UI vs controller). A report should mostly wire
  things together, not hold business logic.
- **Interface-first / Strategy.** Depend on an interface
  (`ZIF_MON_DATA_PROVIDER`), not concrete classes. The controller iterates a
  **registry** of providers and treats each identically — new behavior = new
  implementer, no changes to callers (Open/Closed).
- **Global classes over local** when reuse/extension matters; local `LCL_*`
  classes only for small, report-private helpers.

## Method & member rules

- One responsibility per method; keep methods short. Prefer returning via a
  single `RETURNING` param where it reads naturally.
- Name intent, not type: `get_data`, `navigate_to_detail`, `build_datetime_range`.
- Prefer importing/returning **typed** structures/table types (`ZMON_S_*`,
  `ZMON_T_*`) over generic `DATA`.
- Guard clauses over deep nesting; `CHECK` / early `RETURN` to reduce arrow code.
- Replace magic values with **class constants** (`c_status_cancelled = 'A'`,
  threshold constants `c_st22_red = 31`, etc.).

## Errors & resources

- Use class-based exceptions (`CX_*` / `ZCX_*`) with `TRY/CATCH`; do not swallow
  exceptions silently — convert to an area-level user message.
- No `IN UPDATE TASK`, no `COMMIT WORK` in read-only code (see
  `abap-read-only-monitoring`).

## i18n & config

- All literals shown to users → **text symbols**; all messages → a **message
  class**. No hardcoded UI strings.
- Tunables (periods, Top-N default, thresholds, max rows) as constants or
  selection-screen parameters, not scattered literals.

## Refactoring recipe (report → OO)

1. Identify data-access blocks → extract into provider class(es) behind the
   interface.
2. Extract screen/ALV/splitter/chart logic → UI class.
3. Move orchestration (loop over areas, aggregate, display) → controller.
4. Replace duplicated period/timezone logic with a single shared utility
   (`build_datetime_range`, `convert_local_to_utc_tstmp`).
5. Replace literals with constants; introduce text symbols/messages.
6. Re-run the review checklist (`abap-code-review`) and confirm read-only
   guardrails still hold.

## Done criteria

- New areas can be added by adding one class + registry entry only.
- No literal thresholds/status codes in logic bodies.
- Each public method has a clear single purpose and typed signature.
