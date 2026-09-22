# AI
AI연구과제 활동 — SAP GUI ABAP 바이브 코딩 사전 준비물 저장소.

## 이 저장소는 무엇인가?

SAP GUI에서 ABAP 바이브 코딩을 시작하기 전에 준비하는 2종 세트이다.

1. **AI 성능 향상 문서 (SKILL + Harness)**
   - `SKILL.md` — AI 행동 규칙 (DDIC 환각 금지·릴리스 게이트·복붙 계약)
   - `HARNESS.md` — 5단계 워크플로우·게이트·덤프 대응표·복붙 프로토콜
   - `AGENTS.md` — 이 저장소를 AI와 함께 쓰는 순서
2. **프로그램별 요구사항·프롬프트 문서**
   - `context/` — 시스템 정보 1회성 템플릿 + SE11/SE16N 수집 양식
   - `requirements/` — 공통(00) + 유형별(01~07) 1회 입력 템플릿
   - `harness/` — 활성화·리뷰 체크리스트 + 그대로 붙여넣는 프롬프트
   - `examples/` — AI 출력 형식의 기준 샘플

## 3분 시작 가이드

1. `context/system-context.template.md` 1부 작성 (릴리스·패키지·네이밍).
2. `requirements/README.md` 에서 유형 선택 → `00-common.md` + 해당 유형 1부 작성.
3. AI 채팅에 붙여넣기: `AGENTS.md`의 지시 1줄 + 시스템 컨텍스트 + 요구사항 2부.
4. AI의 Gate 1(빈칸 질문) → Gate 2(스펙 확정) → Gate 3(코드) 흐름을 따른다.

상세 절차는 `HARNESS.md`, AI 등록용 문구는 `harness/prompts/system-prompt-fragment.md` 참조.
