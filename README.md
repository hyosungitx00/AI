# AI
AI연구과제 활동 — SAP GUI ABAP 바이브 코딩 사전 준비물 저장소.

## 이 저장소는 무엇인가?

SAP GUI에서 ABAP 바이브 코딩을 시작하기 전에 준비하는 2종 세트이다.

1. **AI 성능 향상 문서 (SKILL + Harness)**
   - `SKILL.md` — AI 행동 규칙 (DDIC 환각 금지·릴리스 게이트·복붙 계약)
   - `HARNESS.md` — 5단계 워크플로우·게이트·덤프 대응표·복붙 프로토콜
   - `AGENTS.md` — 이 저장소를 AI와 함께 쓰는 순서
2. **프로그램별 요구사항·프롬프트 문서 (인터뷰 전용: 인테이크·데모-퍼스트 + 세션별 묶음)**
  - `context/` — 시스템 정보 1회성 템플릿 + SE11/SE16N 수집 양식 + DDIC 확정값 캐시(`ddic-cache.md`)
- `requirements/` — 접수 커버(00-intake) + 화면 데모(08) + 필드맵(09) + 공통(00) + 유형별(01~07) — 접수 입력은 인터뷰(I-0~I-8)만 사용
- `sessions/` — 세션별 묶음 (`YYYYMMDD-프로그램명/` 1건 1폴더, 실전 1호 `20260928-ZMM_PR_LINK_ALV01` 포함)
- `practice/` — 오류·교훈 패턴 (`error-patterns.md`, Gate 3 전 확인·V-3 승격)
  - 작성 견본: `examples/filled/00-intake.filled.md`(접수), `examples/filled/08-demo.filled.md`(AI 생성 데모), `examples/filled/09-fieldmap.filled.md`(필드·구현), `examples/filled/01-alv-report.filled.md`(ALV), `examples/filled/03-function-module.filled.md`(FM)
- `harness/` — 활성화·리뷰 체크리스트 + 그대로 붙여넣는 프롬프트(신규 기본 `intake-demo-prompt.md`)
- `examples/` — AI 출력 형식의 기준 샘플 2종(ALV `ZSD_SALES_ALV01.abap`, FM `Z_SD_GET_SALES.fugr.abap`, 상세 `examples/README.md`)
3. **자동화 (사람 체크리스트의 기계 점검판)**
- `tools/abap_check.py` — Gate 3 자동 점검기. 코드 제시 전 필수 실행 (규칙 `CHK-001`~`CHK-017`)
- `tools/new_session.sh` — 세션 폴더·접수 기록 생성
- `templates/abap/` — 코드 골격 3종(SALV·REUSE·FM). 오류 패턴이 선반영된 Gate 3 출발점
- `.cursor/rules/` — Cursor 자동 적용 규칙 3종 (코어·ABAP 코드 표준·세션 시작)

## 3분 시작 가이드 (신규 세션)

1. `context/system-context.template.md` 1부 작성 (릴리스·패키지·네이밍, 프로젝트당 1회).
2. AI 채팅에 `[신규 프로그램 요구사항 인터뷰 시작 요청]` 한 줄을 보낸다 (인터뷰 전용 — 작성 틀·파일 접수는 받지 않음).
3. AI의 인터뷰(I-0 → I-8) 응답 → Gate U(이해도 확인) → Gate D(08-demo 화면 컨펌) → Gate F(09-fieldmap 승인) → Gate 2(스펙 확정) → Gate 3(코드) 흐름을 따른다.

상세 절차는 `HARNESS.md` 0.5단계, 신규 최초 프롬프트는 `harness/prompts/intake-demo-prompt.md` 참조.

## Cursor로 이 저장소를 열었을 때

`.cursor/rules/`가 자동 적용되므로 **SKILL 전문을 붙여넣을 필요가 없다.** 바로 요청하면 된다.

- 프로그램 개발 요청 → 세션 시작 질문(8문항) → 인터뷰 → 게이트 순으로 자동 진행
- 저장소 문서·도구 정비 요청 → 질문 없이 바로 수행 (`sap-gui-abap-session-start.mdc` 적용 범위 참조)
- `*.abap` 파일을 열거나 만들면 코드 표준 규칙이 자동으로 함께 적용된다

```bash
python3 tools/abap_check.py            # 저장소 전체 ABAP 점검 (오류 0건 유지)
python3 tools/tests/test_abap_check.py # 점검기 자체 테스트
tools/new_session.sh ZSD_SALES_ALV01   # 새 세션 폴더 준비
```

Cursor를 쓰지 않는 도구(ChatGPT·Claude·사내 LLM)에서는 `harness/prompts/system-prompt-fragment.md`를 지침으로 등록한다.
