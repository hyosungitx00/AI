---
name: abap-requirement-intake
description: Before implementing ABAP features, run a short structured brief (or accept a filled template) so quality preferences are captured once — minimizes mid-session polish loops.
user-invocable: true
---

# ABAP Requirement Intake (ask once, then build)

Use at the **start** of a new feature / UX change / report enhancement when the
user request is incomplete or open-ended. Do **not** drip-feed questions across
many turns. Goal: one compact intake → high-quality first delivery.

## When to run

| Situation | Action |
|-----------|--------|
| New feature, vague “좋게 만들어줘 / 있어보이게” | Run intake (≤8 questions) |
| User pasted a filled brief (`docs/templates/…-brief.md`) | Skip questions; confirm assumptions in 3 bullets; build |
| Pure bugfix with screenshot/error text | Skip intake; fix |
| Follow-up polish on an agreed design | Skip intake; apply `abap-ops-monitor-ux` |

## Intake protocol (one message)

1. Read `docs/design/integrated-ops-monitor-design.md` + existing code for defaults.
2. Post **one** Korean checklist (table). Max **8** questions. Prefer multiple-choice.
3. For each unanswered item after the user’s reply, apply the **Default** column — do not re-ask.
4. Restate a 5-line **Build Contract** (scope / UX bar / delivery format / out-of-scope), then implement.

### Required question slots (adapt; drop if already known)

| # | Topic | Example choices | Default (this project) |
|---|-------|-----------------|------------------------|
| 1 | 변경 범위 | 기능 / UX만 / 둘 다 | 요청 문장에서 추론 |
| 2 | 대상 화면 | 선택화면 / 대시보드 / 팝업 / 드릴다운 | 대시보드 |
| 3 | 팝업 형태 | HTML 카드 다이얼로그 / MESSAGE / ALV | HTML 카드 (`cl_gui_dialogbox_container` + `cl_gui_html_viewer`) |
| 4 | 차트 | HTML/CSS / IGS Chart Engine | HTML/CSS (색·방향 확실) |
| 5 | ALV 툴바 | 최소(찾기·정렬·필터) / 표준 전체 | 최소 |
| 6 | 전달 방식 | 메서드 단위 붙여넣기 / 전체 소스 / PR만 | **메서드(+필요 선언부) 붙여넣기** — 회사망 GitHub 차단 가정 |
| 7 | 시스템 | ECC / S/4 | ECC 호환 상수·시그니처 |
| 8 | 읽기전용 예외 | 없음 / 특정 예외 허용 | 예외 없음 (불변) |

Optional only if relevant: 자동갱신, Top-N 상한, 기간 기본값, 권한 객체.

## Anti-patterns

- Do not ask more than 8 questions.
- Do not ask open essay questions when a choice works.
- Do not ask again for delivery format if the always-on delivery rule already applies.
- Do not start large refactors during intake — capture, contract, then code.

## After intake

Apply in order:

1. `abap-read-only-monitoring` + `abap-clean-oo`
2. `abap-ops-monitor-ux` (if UI/dashboard/popup/chart)
3. Delivery rule: pasteable ABAP; declarations + implementation together
4. `abap-code-review` self-check before claiming done

## Done criteria

- [ ] Build Contract stated once
- [ ] Defaults recorded for skipped items
- [ ] First implementation matches contract (no “일단 MESSAGE로…” half-step when HTML was chosen)
