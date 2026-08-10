---
name: abap-ops-monitor-ux
description: Deliver presentation-quality UX for the read-only Ops Monitor (HTML charts, KPI/HELP dialogs, ALV polish, area colors) without multi-turn visual trial-and-error.
user-invocable: true
---

# Ops Monitor UX Quality Bar

Use when changing dashboard UI, charts, ALV, STATS/HELP popups, KPI banners, or
when the user asks for “있어보이게 / 멋지게 / 데모용” polish on
`Y_OPS_MONITOR_V2` (or successor). Apply this bar on the **first** delivery —
do not ship a plain `MESSAGE` and wait to be asked for HTML.

## Non-negotiable UX decisions (learned)

| Area | Do | Don't |
|------|----|-------|
| Charts | `cl_gui_html_viewer` + HTML/CSS bars | Rely on IGS for per-area color/orientation (often ignored) |
| Top-N | Horizontal bars | Vertical when comparing category names |
| Time | Vertical bars; axis labels = **first \| 1칸=단위 \| last** only; `title` tooltip per bar | Every bucket labeled |
| Scale | Reset max **per area** so each chart fills independently | One global max across SM37/ST22/SXI |
| Colors | Match ALV `LINE_COLOR`: SM37 `C400`→`#26A69A`, ST22 `C600`→`#EF5350`, SXI `C700`→`#FFA726` | Same color for all series |
| STATS / HELP | HTML card in `cl_gui_dialogbox_container` | Plain `MESSAGE … TYPE 'I'` walls of text |
| ALV toolbar | Keep Find / Sort / Filter; exclude export/sum/info/etc. via ECC-safe fcodes | Assume NetWeaver-only `MC_FC_*` constants |
| Drill-down | Display-only standard screens/FMs for the **selected row** | Generic tcode menu |
| New popup members | Declare `mo_*_dlg` / `mo_*_html` + `on_*_close` in DEFINITION **with** IMPLEMENTATION | Paste method body only |

## HTML dialog recipe (STATS / HELP)

1. Build UTF-8-safe HTML with **concatenated** CSS (`'body{…}' && …`) — avoid
   string-template `{` clashes with CSS braces.
2. Free previous dialog/viewer if bound; `CREATE` dialogbox + html viewer.
3. Split HTML into `w3html` 255-char lines → `load_data` → `show_url`.
4. `SET HANDLER on_*_close FOR mo_*_dlg` and free both on close.
5. Visual structure:
   - Status-colored header (gradient OK; solid fallback first)
   - One primary number or title
   - Card rows / numbered steps
   - Meta chips (조회시각, 소요, 관점, 자동갱신)
   - Footer: 읽기 전용 · 창 닫기(X)

## KPI / HELP content patterns

- **STATS:** health label (`ALL CLEAR` / `WARNING` / `CRITICAL` / `STABLE`),
  total count, per-area card with left color bar, traffic badge, share %, bar.
- **HELP:** numbered steps with command chips (`REFRESH`, `TOGGLE`, …) +
  yellow read-only note — not a single paragraph.

## ALV polish checklist

- [ ] Zebra + area `LINE_COLOR`
- [ ] Hotspot on key columns; double-click → `navigate` display-only
- [ ] Column set = requested fields only (no unused icon/noise columns unless needed)
- [ ] Toolbar excluding list uses string fcodes where constants missing on ECC
  (e.g. `&EXPORT`, `&PC` — verify against local `CL_GUI_ALV_GRID`)

## First-delivery definition of done

When the user asks for UX polish, the first reply that changes code must include:

1. Declarations (if new controls)
2. Full methods to paste (or clear edit loci)
3. Behavior matching the table above
4. No placeholder “나중에 HTML로” step

If uncertain about one preference only, run `abap-requirement-intake` once —
then deliver at this bar.
