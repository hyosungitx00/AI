# AI
AI연구과제 활동 — SAP GUI ABAP 바이브 코딩 사전 준비물 저장소.

## 이 저장소는 무엇인가?

SAP GUI에서 ABAP 바이브 코딩을 시작하기 전에 준비하는 2종 세트이다.

1. **AI 성능 향상 문서 (SKILL + Harness)**
   - `SKILL.md` — AI 행동 규칙 (DDIC 환각 금지·릴리스 게이트·복붙 계약)
   - `HARNESS.md` — 5단계 워크플로우·게이트·덤프 대응표·복붙 프로토콜
   - `AGENTS.md` — 이 저장소를 AI와 함께 쓰는 순서 + AI 필수 준수 2항(자율 축적·설계층 수정 금지)
   - `GOVERNANCE.md` — 사용자가 요청하지 않아도 기록이 쌓이게 하는 규칙 + 설계층 보호 설정(CODEOWNERS·branch protection)과 그 한계
2. **프로그램별 요구사항·프롬프트 문서 (인터뷰 전용: 인테이크·데모-퍼스트 + 세션별 묶음)**
  - `context/` — 시스템 정보 1회성 템플릿 + SE11/SE16N 수집 양식
- `requirements/` — 접수 커버(00-intake) + 화면 데모(08) + 필드맵(09) + 공통(00) + 유형별(01~07) — 접수 입력은 인터뷰(I-0~I-8)만 사용
- `sessions/` — 세션별 묶음 (`YYYYMMDD-프로그램명/` 1건 1폴더). 세션은 **같은 저장소를 공유하며 계속 쌓이고**, 산출물은 세션 폴더로 구분된다. 누적 경로·수정 범위·세션 색인은 `sessions/README.md`
- `practice/` — 오류·교훈 패턴 (`error-patterns.md`) + 사용자 입력 요청 기준 (`user-input-catalog.md`) + GUI 산출물 정의 기준 (`screen-text-detail.md`). **세션 간 지식 전달의 유일한 경로**
  - 작성 견본: `examples/filled/00-intake.filled.md`(접수), `examples/filled/08-demo.filled.md`(AI 생성 데모), `examples/filled/09-fieldmap.filled.md`(필드·구현), `examples/filled/01-alv-report.filled.md`(ALV), `examples/filled/03-function-module.filled.md`(FM)
- `harness/` — 활성화·리뷰 체크리스트 + 그대로 붙여넣는 프롬프트(신규 기본 `intake-demo-prompt.md`)
- `examples/` — AI 출력 형식의 기준 샘플 2종(ALV `ZSD_SALES_ALV01.abap`, FM `Z_SD_GET_SALES.fugr.abap`, 상세 `examples/README.md`)

## 3분 시작 가이드 (신규 세션)

1. `context/system-context.template.md` 1부 작성 (릴리스·패키지·네이밍, 프로젝트당 1회).
2. AI 채팅에 `[신규 프로그램 요구사항 인터뷰 시작 요청]` 한 줄을 보낸다 (인터뷰 전용 — 작성 틀·파일 접수는 받지 않음).
3. AI의 인터뷰(I-0 → I-8) 응답 → Gate U(이해도 확인) → Gate D(08-demo 화면 컨펌) → Gate F(09-fieldmap 승인) → Gate 2(스펙 확정) → Gate 3(코드) 흐름을 따른다.

상세 절차는 `HARNESS.md` 0.5단계, 신규 최초 프롬프트는 `harness/prompts/intake-demo-prompt.md` 참조.
