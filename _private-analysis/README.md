# _private-analysis/ — 참조 금지 영역 (DO NOT REFERENCE)

이 폴더는 **하네스(harness)의 일부가 아니다.** 별도 분석 용도로만 보관한다.

## AI 에이전트에 대한 지시

이 폴더 안의 파일은 **다른 세션·다른 작업에서 읽거나 참조하지 않는다.**

- ABAP 프로그램 생성, 요구사항 접수, 코드 리뷰, 패턴 대조 등 **모든 하네스 작업에서 이 폴더를 제외**한다.
- `SKILL.md` · `HARNESS.md` · `AGENTS.md` · `requirements/` · `practice/` · `sessions/` 의 규칙과 **무관하다.** 이 폴더의 내용을 근거로 코드·설계 판단을 하지 않는다.
- 이 폴더의 문서는 과거 세션의 진행 기록을 **분석 목적으로 재구성한 것**이다. 기술 기준(코드 규칙·패턴·템플릿)의 출처로 쓰면 안 된다. 기술 기준의 출처는 `practice/error-patterns.md` 와 `SKILL.md` 다.
- 사용자가 이 폴더를 **명시적으로 지목**했을 때만 열람한다.

## 격리 장치

| 장치 | 내용 |
|---|---|
| `.cursorignore` | 저장소 루트에 `_private-analysis/` 등록 — 인덱싱·AI 접근 제외 |
| `.cursorindexingignore` | 동일 경로 등록 — 코드베이스 인덱스 제외 (이중 장치) |
| 역링크 없음 | `README.md` · `AGENTS.md` · `SKILL.md` · `HARNESS.md` · `requirements/README.md` · `practice/README.md` · `sessions/README.md` 어디에도 이 폴더로 가는 링크를 두지 않았다. 라우터 문서를 따라오는 경로로는 도달할 수 없다 |
| 별도 브랜치 | `cursor/private-analysis-report-f915` — 산출물 PR(#24)에 포함하지 않았고 PR 도 만들지 않았다 |

## 한계 (반드시 인지할 것)

**이것은 접근 통제가 아니다.** 저장소 권한을 가진 사람은 git 이력·GitHub 검색으로 이 폴더를 볼 수 있다. 차단되는 것은 **AI 세션의 자동 인덱싱·자동 참조**이며, 사람의 열람이나 `git log` 추적은 막지 못한다. 기밀 정보는 애초에 넣지 않는다.

또한 `.cursorignore` 에 등록된 뒤에는 **AI 가 이 폴더를 읽지 못하므로, 이 안의 문서를 AI 로 수정하려면 사용자가 경로를 명시해 주거나 `.cursorignore` 에서 일시적으로 제외**해야 한다.

## 내용

| 파일 | 내용 |
|---|---|
| `20261001-session-analysis.md` | 세션 `20260930-ZMM_STOCK_TREE01` 진행 분석 보고서 — 저장소 구조·내역 흐름, 질문·답변 전수, 오류 회수 내역, 수치화, 소요 시간 추정(AI 활용 / 미활용 비교) |
