---
name: sap-gui-abap-vibe-coding
description: SAP GUI(SE38/SE37) 환경에서 ABAP 바이브 코딩을 위한 스킬. AI가 SAP에 직접 접속하지 못하고 사용자가 복사·붙여넣기로 코드를 옮기는 전제 하에, 요구사항 수집·스펙 확정·복붙용 코드 생성·활성화/테스트 안내를 수행할 때 사용한다. 주력 유형은 ALV 리포트(SE38)와 Function Module(SE37)이며, 그 외 유형(02, 04~07)은 확장용으로 유지한다. 기준 릴리스는 SAP_BASIS 750 / S/4HANA, 엄격 게이트(빈칸 시 코드 금지·스펙 승인 후 코드) 운용이다.
license: MIT
---

# SAP GUI ABAP Vibe Coding SKILL

> 확정 사항(사용자 답변 반영, 2026-09-22): 기준 릴리스 `SAP_BASIS 750 / S/4HANA(모던 문법 허용)`, 주력 유형 `ALV 리포트 + Function Module`, ALV 방식 `유형별 유연 선택`, 워크플로우 `엄격 게이트`, 네이밍 `AI 제안 규칙(Z+모듈약어)`, 주석 `한국어+영문 병기`, 사용 도구 `Cursor(Custom Instructions 등록)`.

## 1. 이 스킬의 목적

SAP GUI 기반 ABAP 개발은 일반 바이브 코딩과 전제가 다르다.

- AI는 SAP 시스템에 **직접 접속·실행·디버깅할 수 없다.**
- 사용자는 AI가 만든 코드를 **SE38 / SE80 / SE24 / SE37 / SM30 / SPRO / SE91 등 트랜잭션에 손으로 옮겨 활성화**해야 한다.
- SAP 릴리스(ECC 6.0, NetWeaver 7.40/7.50, S/4HANA)에 따라 **사용 가능한 ABAP 문법이 다르다.**
- 테이블·필드명을 하나라도 환각(hallucination)하면 **활성화 실패 → 전량 재작업**이 된다.

이 스킬은 위 리스크를 제거하고, 이 저장소의 `HARNESS.md` + `requirements/` 템플릿과 함께
**"한 번에 제대로 된 요구사항 → 한 번에 활성화되는 코드"** 흐름을 만드는 것이 목적이다.

## 2. 언제 이 스킬을 사용할 것인가

사용자가 다음 중 하나라도 요청하면 이 스킬을 따른다.

- "ALV 리포트 만들어줘", "Function Module 만들어줘" (주력 유형)
- `requirements/01-alv-report.md` 또는 `requirements/03-function-module.md` 템플릿이 붙여넣어졌을 때
- `context/system-context.template.md` 가 제공되었을 때
- SAP 오류 메시지(`Syntax error`, `Dump`, `SY-SUBRC`) 해결을 요청할 때 (SE38/SE37 활성화·실행 결과 회수 시)

## 3. 절대 규칙 (Golden Rules)

### 3.1 환각 금지 — DDIC 우선

1. 테이블·필드·도메인·데이터엘리먼트명은 **사용자가 준 것만 사용**한다.
2. 사용자가 필드명을 안 줬으면 코드를 추측해서 만들지 말고, 먼저 `context/ddic-collect.template.md` 절차로 **SE16N / SE11 확인을 요청**한다.
3. 부득이하게 표준 테이블을 가정해야 하면, 코드 상단에 아래 주석을 강제한다.

```abap
"! [확인필요] 아래 DDIC 가정은 사용자 확인이 필요합니다
"! 가정: VBAK-VBELN(판매문서), KNA1-KUNNR(고객번호)
"! SE16N 또는 SE11에서 실재 여부를 확인 후 활성화하십시오.
```

4. 존재가 불확실한 Function Module(`BAPI_*`, `CONVERSION_EXIT_*`, `REUSE_ALV_*`)은 **"SE37에서 존재 확인" 코멘트**를 단다.

### 3.2 릴리스 적합성 — 문법 게이트 (기준: SAP_BASIS 750 / S/4HANA)

`context/system-context.template.md` 의 `SAP_BASIS 릴리스`와 `문법 상한`을 먼저 확인한다.
이 저장소의 기준값은 **750 / S/4HANA, 모던 ABAP 허용**이다.

| 시스템 | 사용 가능 문법 | 금지 문법 |
|---|---|---|
| ECC 6.0 / NW 7.31 이하 (확장 대응 시) | 클래식 ABAP만 | 인라인 선언(`DATA(...)`), `VALUE #()`, `COND #()`, `FILTER #()` 금지 |
| NW 7.40 | 인라인 선언 일부 허용 | `FILTER`, 테이블 표현식 남용 금지 |
| **NW 7.50 / S/4HANA (기본값)** | **모던 ABAP 허용 (`@` 호스트변수, 인라인 선언, `VALUE #()`, `COND #()`, `FILTER`)** | S/4에서 제거된 구문(구 플로우 로직, 직접 테이블 갱신 등) 금지 |

> 코드 상단에는 `"! 기준: SAP_BASIS 750 / S/4HANA, 모던 ABAP 허용"` 이라고 명시한다.
> 사용자가 "구문 보수적으로"를 요청한 건에 한해서만 ECC 6.0 호환(클래식)으로 폴백한다.

### 3.3 복붙 계약 (Output Contract) — SAP GUI로 그대로 옮길 수 있어야 한다

AI가 생성하는 모든 ABAP 코드는 다음 계약을 만족해야 한다.

1. **완전한 소스 1개**: `*&---...` 헤더부터 마지막 `ENDFORM/ENDCLASS`까지 생략 없이 제공한다. `... 생략`, `"(이하 동일)"` 같은 플레이스홀더 금지.
2. **파일 분리 명시**: Top Include / Main / Subroutine / Class-Include 구조가 필요하면, 각 파일을 `--- 파일 1: ZXXX_TOP ---` 같은 구분자로 나누고 **SE38/SE80에서 만드는 순서**를 번호로 적는다.
3. **주석은 한국어+영문 병기 고정**: 핵심 주석은 `"! 고객별 매출 집계 / Sales total by customer` 형태로 한국어+영문을 함께 쓴다. (Cursor 복붙·SAP GUI 한글 입력 전제)
4. **활성화 순서 포함**: `SE11(DDIC) → SE38(프로그램, ALV) / SE37(함수, FM) → SE93(T allocation) → SU21(권한)` 같은 순서를 코드 뒤에 체크리스트로 붙인다. 상세 양식은 `HARNESS.md` 5단계 참조.
5. **메시지 클래스·번호 약속**: `MESSAGE e001(zmymsg)` 처럼 하드코딩하지 말고, 사용할 메시지 클래스를 먼저 선언한다. 메시지 클래스가 없으면 `MESSAGE ... DISPLAY LIKE 'E'` 임시방편을 쓰고 TODO로 표시한다.
6. **테스트 절차 동봉**: SE38 실행 → 선택화면 입력값 예시 → 기대 ALV 결과 → 비정상계(데이터 0건, 권한 없음)까지 표로 제공한다.
7. **GUI 수작업 오브젝트는 입력값을 표로 전수 제공**: SE51 화면(요소 목록)·SE41 GUI 상태·GUI 타이틀·SE38 텍스트 요소(선택 텍스트)는 소스로 복붙할 수 없다. "SE51에서 화면을 만드십시오" 같은 요약 안내는 계약 위반이다. 필수 목차·서술 규칙은 `practice/screen-text-detail.md` 를 따른다.

### 3.4 성능·운영 규칙 (Code Rules)

- `SELECT *` 금지. 필요한 필드만 `SELECT a b c ... INTO TABLE @DATA(lt_xxx).` (구문법이면 `INTO TABLE lt_xxx`).
- `FOR ALL ENTRIES` 사용 시 **반드시 빈 테이블 체크**(`IF lt_key IS NOT INITIAL.`) 후 사용.
- 루프 내 `SELECT SINGLE` 금지. `READ TABLE ... WITH KEY` + 해시테이블(`HASHED TABLE`) 또는 사전 수집 후 `FOR ALL ENTRIES`로 대체.
- `SY-SUBRC`는 모든 DB I/O 직후 체크하고, 실패 시 메시지 + `RETURN` / `CONTINUE` 처리.
- `COMMIT WORK`는 BAPI 뒤에만, 그것도 `BAPI_TRANSACTION_COMMIT` 권장. 조회용 리포트에서 `COMMIT` 금지.
- 권한 체크는 `AUTHORITY-CHECK OBJECT '...' ID ...` 로 명시. 오브젝트명을 모르면 `TODO: SU21 확인` 표시.
- 하드코딩된 회사코드·플랜트·언어(`SY-LANGU`) 금지. 선택화면 파라미터 또는 `TVARVC` / 커스텀 테이블에서 읽는다.

### 3.5 명명 규칙 (AI 제안 규칙이 기본값)

- 고객 개발 오브젝트는 `Y` / `Z` 로 시작. 템플릿 기본값은 `Z`다.
- 프로그램: `Z + 모듈약어 + _ + 기능` (예: `ZSD_SALES_ALV01`). 함수그룹: `ZFG + 모듈` (예: `ZFGSD01`). 클래스: `ZCL_ + 기능` (예: `ZCL_SD_DOC`). DDIC: `Z + ...` + 접미사(`_T` 테이블, `_S` 구조).
- `ZZZZ`, `ZTEST`, `ZTEMP` 같은 임시명 금지. TADIR 등록 가능한 실명을 쓴다.
- 사용자가 별도 사내 규칙을 주면 그 값이 이 규칙보다 우선한다. 모르면 AI가 위 규칙으로 제안하고 스펙 확정 단계에서 확정한다.

## 4. 표준 워크플로우 (Harness 연동 — 엄격 게이트)

`HARNESS.md` 의 게이트를 따른다. 이 저장소는 **엄격 게이트**로 운용한다. 신규 세션 기본값은 **인테이크·데모-퍼스트(0.5단계)** 이며, 세션마다 기존 요구사항을 참조하지 않는다. 요약:

0.5. **Intake·데모-퍼스트** — `requirements/00-intake.md` 접수 후 Gate U 이해도 확인서("OK" 전 데모·필드맵·스펙·코드 금지) → `08-demo.md` 분기(데모 있음→경로A 분석 / 없음→경로B AI 생성) → Gate D 화면 컨펌(컨펌 전 필드맵·스펙·코드 금지) → `09-fieldmap.md`(필드 연결 + 구현 방식) → Gate F 승인 후 유형 템플릿(01~07)으로 구조화. 접수 방식은 **인터뷰 방식만 허용**한다(AI가 `harness/prompts/interview-script.md` 순서로 한 턴 최대 3문항씩 질문, `[모름]`·`건너뛰기` 허용, 단계별 확인 후 진행). 작성 틀 한 번에 입력·자유 텍스트·파일 첨부로는 접수하지 않으며, 해당 입력이 오면 인터뷰(I-0)로 전환한다.
1. **Context 수집** — `context/system-context.template.md` + `requirements/00-common.md` + 해당 유형 템플릿(주력은 `01-alv-report` / `03-function-module`)이 모두 채워졌는지 확인. 필수(★) 1개라도 비어 있으면 코드 작성 금지, 템플릿 빈칸을 질문 리스트로 반환.
2. **Spec 확정** — 테이블·조인·선택화면·ALV 레이아웃(FM이면 I/E/T 파라미터)·예외처리를 불릿 스펙으로 먼저 확정. 사용자 **"OK" 승인 전에는 코드 생성 금지**. "바로 코드" 요청이 와도 스펙 없이 코드를 주지 않고, 스펙 확정안을 먼저 제시한다.
3. **Code 생성** — Output Contract(3.3) 준수. 릴리스 게이트(3.2, 750/S4 모던) 준수. ALV 방식은 스펙에서 건별로 선택(`CL_SALV_TABLE` / `REUSE_ALV_GRID_DISPLAY` / `CL_GUI_ALV_GRID`).
4. **Verify 안내** — 활성화 체크리스트 + 테스트 케이스 + 예상 덤프 대응표 제공.
5. **Handover** — SE38/SE37 복사 순서, T-code 생성(SE93), 권한(SU21/PFCG), 이송(TR) 요청서 초안까지 제공한다.

각 단계의 상세 프롬프트와 게이트 기준은 `HARNESS.md`를 따른다.

## 5. 금지 행위

- 사용자의 SAP 접속정보(호스트, 클라이언트, ID/PW)를 묻거나 저장하지 않는다.
- 실제 운영 데이터(전표번호, 고객명, 금액)를 예시 이상으로 요구하지 않는다. 테스트값은 마스킹 예시(`10000001` 등)로 충분하다.
- 코드를 이미지·캔버스 전용으로만 주고 텍스트를 생략하지 않는다. **항상 복사 가능한 코드블록**을 제공한다.
- "SAP에서 바로 실행했습니다"처럼 거짓말하지 않는다. AI는 실행할 수 없으므로 "SE38에서 아래 값으로 테스트하십시오" 형태로 안내한다.

## 6. 관련 파일 인덱스

| 파일 | 용도 |
|---|---|
| `HARNESS.md` | 5단계 워크플로우, 게이트, 복붙 프로토콜, 덤프 대응표 |
| `context/system-context.template.md` | 1회만 작성하는 시스템 정보 (릴리스, 클라이언트, 네이밍, 권한) |
| `context/ddic-collect.template.md` | SE11/SE16N에서 테이블·필드 정보를 뽑아오는 절차 + 붙여넣기 양식 |
| `requirements/README.md` | 어떤 템플릿을 고를지 결정하는 라우터 (신규 기본: 인터뷰 → 08-demo → 09-fieldmap → 01~07) |
| `sessions/README.md` | 세션별 묶음 규칙 — 프로그램 1건당 폴더 1개, 게이트별 기록 파일 |
| `practice/error-patterns.md` | 오류·교훈 패턴 — Gate 3 전 대조 필수, V-3에서 신규 승격 |
| `practice/screen-text-detail.md` | SE51 화면·SE41 상태/타이틀·SE38 텍스트 요소 정의서의 필수 목차 — Dynpro·선택화면이 있으면 대조 필수 |
| `practice/user-input-catalog.md` | 사용자에게만 받을 수 있는 입력 전수 (업무 지식·시스템 실측·실행 결과 3구분) + SAP 조회 경로 + 보안 금지 목록 — 요청 전 대조 |
| `requirements/00-intake.md` | 인터뷰 전용 접수 안내 — 시작 1줄 + 인터뷰(I-0~I-8) 순서 고지 |
| `requirements/00-intake-prompt.md` | 참고용 보관(접수 중단) — 인터뷰 문항 설계 근거, §0 접수 → §8 테스트값 9섹션 |
| `requirements/08-demo.md` | 화면 데모 확인서 — 제공 데모 분석(경로A) 또는 AI 생성 데모(경로B) + 화면 컨펌 |
| `requirements/09-fieldmap.md` | 필드 연결 정보 + 구현 방식 확인서 (화면 컨펌 후 작성, Gate F 점검) |
| `requirements/00-common.md` + `01-alv-report.md` + `03-function-module.md` | 주력 요구사항 템플릿 (1건당 공통+유형 1부) |
| `requirements/02, 04~07` | 확장용 템플릿 (Module Pool·Enhancement·Interface·Batch·Forms, 필요 시 사용) |
| `harness/checklists/` | 활성화·코드 리뷰 체크리스트 |
| `harness/prompts/` | 그대로 붙여넣는 시스템 프롬프트 조각·코드생성 지시문 |
| `examples/` | AI 출력 형식 기준 샘플 2종(`ZSD_SALES_ALV01` ALV · `Z_SD_GET_SALES` FM) + 작성본 견본(`filled/`) |

## 7. 응답 템플릿 (AI가 사용자에게 말할 때)

질문 UI: 세션에 `AskQuestion`(선택형 질문 UI) 도구가 있으면 모든 사용자 질문에 텍스트 나열 대신 반드시 그 도구를 사용한다(타이핑 없이 선택). 도구가 없으면 텍스트 방식(a/b/c 기호 답변)으로 묻고 사유를 한 줄로 밝힌다.

신규 세션 접수 직후 (인터뷰 시작 — 유일한 접수 방식):

> 신규 프로그램 설계를 인터뷰로 진행합니다. 한 번에 최대 3개씩 질문드리고, 모르는 것은 `[모름]`·`건너뛰기`라고 답하시면 제가 제안으로 메우고 넘어갑니다.
> 먼저 I-0 접수 3문항입니다.
> ① 신규 vs 변경 (변경이면 기존명 + 변경점 한 줄) ② 화면 데모 [있음 / 없음-AI 생성] ③ 희망 유형 [01 ALV / 02 / 03 / 04 / 05 / 06 / 07 / 모름]
>
> 참고: 작성 틀 한 번에 입력·자유 텍스트·파일 첨부 접수는 받지 않습니다. 해당 형식으로 보내주셔도 인터뷰 I-0부터 다시 진행합니다.

화면 단계 (Gate D):

> 화면 데모 확인서(`08-demo.md`)를 준비했습니다. (제공 데모 분석본 / AI 생성 목업)
> 화면 구성·버튼·이벤트 중 틀린 곳을 번호로 지시해 주세요. "컨펌(OK)"을 답하면 필드 연결 정보 + 구현 방식(`09-fieldmap.md`)을 작성합니다.
> 화면 컨펌 전에는 필드맵·스펙·코드를 만들지 않습니다.

필드맵 단계 (Gate F):

> 필드 연결 정보 + 구현 방식(`09-fieldmap.md`)을 준비했습니다. 화면-필드 연결표·조인·구현 방식·T1~T3를 점검해 주세요.
> "컨펌(OK)"을 답하면 해당 유형 템플릿으로 구조화해 스펙 확정안(Gate 2)을 제시합니다.

요구사항이 비어 있을 때:

> `requirements/01-alv-report.md` 템플릿의 빈칸(§2 선택화면, §3 ALV 컬럼, §4 조인 조건)이 비어 있어 코드를 만들 수 없습니다.
> 아래 3가지만 채워서 다시 붙여넣어 주세요: ① 조회 테이블·조인키 ② 선택화면 필드 ③ ALV에 보일 컬럼 10개 이내.
> 기준 릴리스는 SAP_BASIS 750 / S/4HANA(모던 허용)이며, ALV 방식은 스펙에서 건별로 정합니다.
> 스펙 확정안에 "OK"라고 답하면 코드를 생성합니다. "바로 코드" 요청 시에도 스펙 확정이 선행됩니다(엄격 게이트).

코드를 줄 때:

> 아래를 순서대로 SE38(ALV) / SE37(FM)에 복사하십시오. ① `ZX..._TOP` → ② 메인. 활성화 후 §테스트 절차의 입력값으로 실행하십시오. 오류가 나면 메시지 번호 + `SY-SUBRC` + 덤프명(`ST22`)을 그대로 붙여넣어 주세요.
