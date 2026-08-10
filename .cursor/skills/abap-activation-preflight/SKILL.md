---
name: abap-activation-preflight
description: Run a mandatory activation preflight before delivering ABAP paste — catches missing declarations, ECC API mismatches, type errors, and string-template pitfalls that caused multi-turn compile loops.
user-invocable: true
---

# ABAP Activation Preflight

Use **before every ABAP paste/delivery** (and before claiming “활성화하세요”).
This skill exists to cut error-driven user turns (syntax / type / unknown field /
wrong FM signature). No SAP system is available here — preflight is a static
self-check against known ECC pitfalls and the repo’s working patterns.

## When (mandatory)

| Trigger | Required |
|---------|----------|
| New/changed method in chat for SE38 paste | Yes |
| New class members / event handlers | Yes |
| “전체 소스” dump | Yes (spot-check hotspots) |
| Docs-only / Korean explanation only | No |

If preflight finds a **Blocker**, fix it in the same turn — do not ask the user
to activate and report back.

## Session-proven failure modes → checks

| # | Failure seen in session | Preflight check |
|---|-------------------------|-----------------|
| P1 | `Field "MO_STATS_HTML" is unknown` | Every `mo_*` / `mt_*` / `mv_*` used in the paste appears in **DEFINITION DATA** in the same delivery |
| P2 | Event handler / method unknown | `METHODS …` in DEFINITION + `METHOD … ENDMETHOD` in IMPLEMENTATION together |
| P3 | `MC_FC_EXPORT` / Crystal / fix-layout unknown | ALV exclude list uses **ECC-safe** constants or fcode strings (`&EXPORT`, `&PC`, …); no NW-only attrs |
| P4 | `SET_CUSTOMIZING_DATA` / param missing | Prefer **already-working repo pattern** (`cl_gui_html_viewer` charts). Do not invent IGS method names |
| P5 | String template `{` / CSS clash | HTML/CSS built with `'…' &&` concatenation; no raw CSS `{` inside `|…|` templates |
| P6 | `LS-DATUM` / wrong structure | `navigate` / hotspot: explicit `TYPE ty_batch\|ty_dump\|…`, not generic `DATA ls` / untyped field-symbol |
| P7 | `E_ROW-INDEX` type mismatch | Row index typed `lvc_index` / matching formal; map `e_row-index` → importing param carefully |
| P8 | Private method called from outside | UI actions call **public** methods only (`refresh`, `show_stats`, …) |
| P9 | Formal parameter type clash | Match DDIC/types already in program (`snap_beg-ahost`, `ty_dump-datum`, …) |
| P10 | Partial paste omits sibling | If method references helpers, include helper signature or confirm it already exists in user’s program |

## Preflight procedure (agent)

1. List identifiers introduced or relied on by the change.
2. For each identifier: declaration locus (DEFINITION / local DATA / existing).
3. Run the table P1–P10 mentally (or via grep on `src/y_ops_monitor_v2.prog.abap`).
4. Prefer copy-adapt from **existing working methods** in the same report over new APIs.
5. Emit a short block in the reply:

```text
Preflight: PASS | BLOCKERS
- P1 declarations: …
- P3 ALV fcodes: …
- P5 HTML concat: …
- P6 navigate types: …
```

6. On **BLOCKERS**: fix code, re-run, then deliver paste.

## Delivery package shape (reduces activate errors)

Always group paste in this order when anything is new:

1. `CLASS … DEFINITION` deltas (`DATA` + `METHODS`)
2. `METHOD` implementations (new/changed)
3. One-line activate note: “선언부 먼저 → 구현 → 활성화”

Never ship (2) without (1) if (2) references new members.

## Relation to other skills

- Complements `abap-code-review` (design/read-only/perf) with **activate-ability**.
- Complements `abap-ops-monitor-ux` (what to build) with **how to ship without red syntax**.
- Always-on rule `abap-delivery-preferences` requires this preflight before paste.
