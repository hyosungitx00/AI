---
name: abap-systematic-debugging
description: Debug ABAP methodically — reproduce, isolate, hypothesize, verify — using the ABAP debugger, ST22 dumps, ST05 SQL trace, and SLG1/system logs instead of random edits.
user-invocable: true
---

# Systematic ABAP Debugging

Debug with evidence, not guesses. Especially important here because the code is
read-only: fixes must not introduce mutating statements.

## 1. Reproduce

- Get exact selection-screen inputs (period, area flags, filters) and the
  expected vs actual result.
- Note system/client, user, and whether it is consistent or intermittent.
- If a short dump occurred, open it in **ST22** and read the error type
  (`DUMPID`), source position, and the "What happened / How to correct".

## 2. Isolate

- **By area:** disable area checkboxes to find which provider is at fault (each
  area is exception-isolated, so narrow to one).
- **By layer:** is it data (query result), aggregation, or UI rendering?
  - Data → run the SELECT/FM standalone (SE16/SE37) with the same inputs.
  - Aggregation → inspect the provider's returned internal table.
  - UI → check splitter/ALV/chart wiring.
- **Binary search** a long method with breakpoints; halve the suspect region each
  step.

## 3. Hypothesize

State a specific, testable cause, e.g. "SXI returns 0 rows because local FROM/TO
was compared to the UTC `EXETIMEST` without conversion" — not "the date filter is
off".

## 4. Verify with tools

| Symptom | Tool |
|---------|------|
| Wrong/zero rows | **ST05** SQL trace — inspect the actual WHERE and returned count |
| Runtime error | **ST22** short dump analysis |
| Value looks wrong | ABAP debugger: watchpoint on the suspect variable |
| Timezone/boundary suspicion | Log the converted timestamps vs raw column |
| "Works for one client" | Compare `MANDT`/client-dependence of the table |
| Slow, not wrong | **SAT/SE30** runtime analysis |

Set breakpoints/watchpoints; step through the transformation. Confirm or discard
the hypothesis, then iterate.

## 5. Fix and verify

- Apply the **minimal** fix at the root cause (e.g. add the local→UTC conversion),
  not a symptom patch.
- Re-run the original reproduction; confirm it's resolved.
- Check for regressions in the other areas.
- Re-scan the diff for read-only guardrail violations before finishing.

## Rules

- Never guess — verify with ST05/ST22/debugger evidence.
- Fix root cause, not symptom.
- After ~15 min without progress, step back and re-isolate.
- Record what you tried so you don't repeat dead ends.
