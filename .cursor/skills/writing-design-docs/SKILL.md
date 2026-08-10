---
name: writing-design-docs
description: Author and maintain ABAP technical design documents in this repo's style — structured Markdown with numbered sections, requirement/decision tables, mermaid diagrams, an object list, test scenarios, and a tracked Open Issues log with a change history.
user-invocable: true
---

# Writing ABAP Design Docs

Use when creating or updating a technical design document under `docs/design/`.
Match the established structure and Korean writing style of
`integrated-ops-monitor-design.md`.

## Document skeleton

Keep this numbered structure (adapt as needed):

1. 개요 (Overview) — 목적/범위(In/Out-of-Scope)/대상 사용자/용어 정의
2. 요구사항 정의 — 기능(FR-##) / 비기능(NFR-##) tables
3. 전제 및 제약사항 (Assumptions / Constraints)
4. 전체 아키텍처 — 설계 원칙 + **mermaid** 논리 구성도 + 컴포넌트/인터페이스 계약 table
5. 데이터 소스 상세 — per source: 표준 테이블/FM, 에러 판별 기준, 조회 조건, 출력 구조, 드릴다운
6. 화면 설계 — 선택화면/대시보드 레이아웃(ASCII mockup + 이미지), 필드 카탈로그
7. 처리 로직 — **mermaid** sequence diagram + 의사코드
8. 권한 및 보안
9. 성능 설계
10. 예외/에러 처리
11. 개발 표준 및 오브젝트 목록 — naming + object list table
12. 테스트 시나리오 — TC-## table
13. 향후 확장 방안
14. 가정 및 미결 사항 (Open Issues)

Start with a metadata table (문서명/대상 시스템/버전/상태) and a top-of-doc
read-only note when applicable.

## House style

- **Tables** for requirements, decisions, field catalogs, and object lists.
- **Mermaid** for architecture (`flowchart`) and flow (`sequenceDiagram`).
- ASCII box mockups for screens, backed by an image under `docs/design/images/`.
- Stable IDs: `FR-##`, `NFR-##`, `TC-##`, `O-#` (Open Issue). Reference them across
  sections so decisions are traceable.
- Mark confirmed decisions inline, e.g. `✅ 확정(O-4)`; mark pending work with
  `🔶` and a `TODO:` note.

## Open Issues discipline (key technique)

- Maintain an **Open Issues** section split into **Resolved** and **Open** tables.
- Each issue has an ID (`O-#`), the topic, the decision/needed decision, and a
  tentative position.
- When a decision is made: move it to Resolved with the final wording, and reflect
  it in every affected section (data source, screen, logic, object list).
- Anything still open must appear in code as `"TODO: ...` at the relevant spot.

## Change history

Append a row to the 변경 이력 (Change history) table on every substantive edit:
`| 버전 | 일자 | 내용 |`. Bump the version (v0.x Draft) and summarize what changed
(which O-# were resolved, which sections updated).

## Done criteria

- New/changed decisions are reflected consistently across all sections and the
  object/field tables.
- Open Issues log and change history are updated; version bumped.
- Diagrams and mockups render; IDs are consistent and cross-referenced.
