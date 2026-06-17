# AGENTS.md

## Cursor Cloud specific instructions

### Project nature

This repository is an **SAP ABAP** research/design project (an integrated SM37 / ST22 / SXI_MONITOR operations-monitoring dashboard, report `ZERR_MONITOR_DASHBOARD`). It is **not** a conventional web/backend application.

- The `main` branch contains only `README.md`. The actual artifacts live on unmerged feature branches:
  - `origin/cursor/abap-screen-code-fcd6` → `src/zerr_monitor_dashboard.abap` (ABAP report skeleton)
  - `origin/cursor/ops-monitor-design-doc-435b` → `docs/design/integrated-ops-monitor-design.md` + screen mockups

### There is no local dev environment

- There are **no package managers, lockfiles, build tooling, or dependencies** of any kind (no `package.json`, `requirements.txt`, `Makefile`, etc.). There is nothing to install — the startup update script is intentionally empty.
- ABAP source (release 7.50, namespace `Z`) **cannot be built, linted, tested, or run on a Linux container**. It executes only inside an SAP S/4HANA Application Server, with screen objects (Dynpro 0100/0110–0140, GUI status `MAIN`) created manually in SE51/SE41 and launched through SAP GUI. See the header comments in `src/zerr_monitor_dashboard.abap` for the required SE51/SE41 setup steps.
- Consequently there is no `lint`/`test`/`build`/`run` command to execute in this environment, and no application can be demonstrated here. Do not attempt to provision a generic runtime; validation of the ABAP code requires a real SAP system.
