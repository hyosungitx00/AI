# 이 저장소를 AI와 함께 쓰는 법

이 저장소는 SAP GUI에서 ABAP 바이브 코딩을 하기 전 **"AI의 성능을 높이는 사전 준비물"** 모음이다.
사용자는 코딩 전에 템플릿 2종만 채우면 되고, AI는 그 값을 그대로 믿고 코드를 만든다.

## 구성

| 경로 | 설명 | 언제 쓰나 |
|---|---|---|
| `SKILL.md` | AI 행동 규칙 (환각 금지·릴리스 게이트·복붙 계약) | AI 대화 맨 앞에 지시문으로 사용 |
| `HARNESS.md` | 5단계 워크플로우 + 게이트 + 오류 대응표 | AI와 사용자 공통 절차서 |
| `context/system-context.template.md` | 시스템 정보 1부 (릴리스·패키지·네이밍) | 프로젝트당 1회 작성 |
| `context/ddic-collect.template.md` | SE11/SE16N 값 수집 양식 | 테이블·필드가 불확실할 때 |
| `requirements/` | 접수 커버(00-intake) + 화면 데모(08) + 필드맵(09) + 유형별 템플릿 8종(00~07) | 프로그램마다 인터뷰 1건 |
| `harness/checklists/` | 활성화·리뷰 체크리스트 | SE38 활성화 전후 |
| `harness/prompts/` | 그대로 붙여넣는 프롬프트 조각(인터뷰 전용: `intake-demo-prompt.md` + 인터뷰 스크립트 `interview-script.md`) | AI 대화 시작 시 |
| `sessions/` | 세션별 묶음 — 1건당 `YYYYMMDD-프로그램명/` 폴더에 intake·demo·fieldmap·spec·code·verify·handover 기록 (신규 세션은 이전 폴더 참조 금지) | 매 세션 기록 |
| `practice/` | 오류·교훈 패턴 축적 — Gate 3 전 확인용 `error-patterns.md` + 사용 규칙 (V-3에서 신규 패턴 승격) | 코드 생성 전 확인·오류 회수 시 |
| `.cursor/rules/sap-gui-abap-session-start.mdc` | 세션 시작 자동 질문 규칙 (Cursor 자동 적용) | 새 대화 첫 턴 자동 실행 |
| `examples/` | 출력 형식 기준 2종(ALV·FM) + 작성본 견본(`filled/` 4종) | AI 출력 형식·입력 예시 확인 |

## 확정 사항 (사용자 답변 반영, 2026-09-22)

- 기준 릴리스: `SAP_BASIS 750 / S/4HANA` — 모던 ABAP 허용, 코드 상단에 기준 명시
- 주력 유형: `01 ALV 리포트(SE38)` + `03 Function Module(SE37)` — 그 외(02, 04~07)는 확장용
- ALV 방식: 건별 유연 선택 (`CL_SALV_TABLE` / `REUSE_ALV_GRID_DISPLAY` / `CL_GUI_ALV_GRID`)
- 워크플로우: 엄격 게이트 — ★ 빈칸 시 코드 금지, 스펙 "OK" 승인 전 코드 금지
- 네이밍: AI 제안 규칙 (`Z+모듈약어`, 예: `ZSD_*`, 함수그룹 `ZFG*`)
- 주석: 한국어+영문 병기 고정
- 사용 도구: Cursor — 아래 등록 절차 참조

## 권장 사용 순서 (최초 1회 → 매 프로그램, 인터뷰 전용)

1. `context/system-context.template.md` 복사·작성 (5분, 프로젝트당 1회).
2. AI 채팅에 순서대로 붙여넣기: `SKILL 지시 1줄` + `시스템 컨텍스트` + `[신규 프로그램 요구사항 인터뷰 시작 요청]` 한 줄.
   - 인터뷰 전용: 작성 틀 한 번에 입력·자유 텍스트·파일 첨부는 접수하지 않는다. 해당 형식으로 보내주셔도 인터뷰(I-0)부터 다시 진행한다.
   - 원문은 `harness/prompts/intake-demo-prompt.md`에 있다.
4. AI가 Gate U(이해도 확인서) → Gate D(08-demo 화면 컨펌, 데모 없음이면 AI 목업 생성) → Gate F(09-fieldmap 필드·구현 승인) → Gate 2(스펙 확정안) → Gate 3(코드) 순으로 준다. 각 게이트 승인 전에는 다음 산출물을 만들지 않는다.
5. `harness/checklists/activation-checklist.md` 대로 SE38에 활성화·테스트한다.
6. 오류는 `HARNESS.md` §4.3 양식으로 회수한다.

## AI 모델 공통 지시 1줄

```text
이 저장소의 SKILL.md와 HARNESS.md를 따르십시오. 기준 SAP_BASIS 750/S4 모던 허용, DDIC 환각 금지, 복붙 계약(완전 소스+복사 순서+테스트 절차) 준수, 엄격 게이트(★ 빈칸 시 코드 금지·스펙 OK 전 코드 금지)를 엄수하십시오. 주력은 ALV 리포트와 Function Module입니다. 신규 접수 방식은 인터뷰 전용입니다(작성 틀·자유 텍스트·파일 접수는 받지 않고 인터뷰 I-0으로 전환).
```

## Cursor 등록 절차 (사용 도구: Cursor)

1. 이 저장소의 세션은 선택형 질문을 위해 ACP로 시작한다. Cursor CLI 설치·로그인 후 저장소 루트에서 `node tools/cursor-acp-client.mjs`를 실행한다. 일반 Cloud/웹 세션처럼 `cursor/ask_question`이 없는 환경에서는 텍스트 질문으로 대체하지 않고 진행을 중단한다.
2. `harness/prompts/system-prompt-fragment.md` 전문을 Cursor Settings → Rules / Custom Instructions에 등록한다.
3. `.cursor/rules/sap-gui-abap-session-start.mdc` 는 `alwaysApply: true` 로 저장소에 포함되어 있어, ACP 새 대화의 첫 턴에 1번 항목 맞춤 질문(8문항)이 `cursor/ask_question`으로 자동 진행된다. 별도 붙여넣기가 필요 없다.
4. Cursor를 쓰지 않는 도구에서는 `cursor/ask_question`을 제공할 수 없으므로 이 저장소의 대화형 세션을 진행하지 않는다.
5. 세션 적용값이 확정되면 인터뷰 전용 흐름으로 진행한다: `harness/prompts/intake-demo-prompt.md` 블록(시스템 컨텍스트 + 인터뷰 시작 요청 한 줄)을 붙여넣고 인터뷰(I-0 → I-8) → Gate U → Gate D → Gate F → Gate 2 순으로 진입한다. 작성 틀 직접 작성 시작(00-common + 01/03)·자유 텍스트·파일 첨부 접수는 받지 않는다.
6. ALV·FM 외 유형(02, 04~07)이 필요해지면 해당 템플릿 1부를 추가로 붙여넣는다.

## 사용 모델별 팁

- **Cursor**: 위 등록 절차대로 하면 매번 SKILL 전문을 붙여넣지 않아도 된다.
- **SAP 용어가 약한 경우**: `context/ddic-collect.template.md` 수집값을 먼저 주고 "이 값만 써라"고 못 박는다.
- **긴 코드가 잘리는 경우**: "파일을 나눠서 ① TOP ② MAIN ③ FORM 순으로 각각 완전한 코드블록으로 달라"고 요청한다 (`HARNESS.md` §3.1).
