# 요구사항 템플릿 라우터 — 어떤 파일을 쓸까?

> 신규 세션 접수 방식은 **인터뷰 전용**: `[신규 프로그램 요구사항 인터뷰 시작 요청]` 한 줄 → AI가 `interview-script.md` 순서로 질문(I-0~I-8) →
> Gate U 이해도 확인 → `08-demo` 화면 컨펌(Gate D) → `09-fieldmap` 필드·구현 승인(Gate F) → 유형 템플릿(01~07) 구조화.
> 작성 틀 한 번에 입력·자유 텍스트·파일 첨부·구방식 직접 작성 시작은 접수하지 않으며, 해당 입력이 오면 인터뷰로 전환한다.
> 엄격 게이트 운용: 필수(★) 1개라도 비어 있으면 AI가 코드를 만들지 않는다.
>
> 확정 사항(2번 항목 Q&A, 2026-09-22): 템플릿 범위 `8종 유지(01·03 주력 + 02·04~07 확장)`,
> 필수 엄격도 `엄격 유지(★ 1개라도 비면 코드 금지)`, 테스트 형식 `T1 정상 + T2 0건/예외 + T3 권한·검증 표`,
> 문서 언어 `한국어 표·체크박스 고정(AI 파싱용 형식 유지)`.
> 추가 확정(2026-09-28): 신규 세션 `인테이크·데모-퍼스트` 기본 적용 — Gate U(이해도) → Gate D(화면) → Gate F(필드·구현) 순 승인.

## 신규 세션 접수표 (인터뷰 전용)

| 순서 | 단계 | 템플릿·입력 | 게이트 |
|---|---|---|---|
| 1 | 접수 | 인터뷰 시작 1줄(`[신규 프로그램 요구사항 인터뷰 시작 요청]`) → AI가 `interview-script.md` 순서로 질문(I-0~I-8) | — |
| 2 | 이해도 확인 | AI 작성 **이해도 확인서** (목적·기능·입출력·예외·모호점·데모 분기) | Gate U 승인 전 데모·필드맵·스펙·코드 금지 |
| 3 | 화면 데모 | `requirements/08-demo.md` — 데모 있음→경로A 분석 / 없음→경로B AI 생성 목업 | Gate D 화면 컨펌 전 필드맵·스펙·코드 금지 |
| 4 | 필드·구현 | `requirements/09-fieldmap.md` — 화면-필드 연결표 + 테이블·조인 + 구현 방식 + T1~T3 | Gate F 승인 후 유형 템플릿으로 구조화 |

## 기존 프로그램 개선 세션 접수표

신규 개발과 입력이 다르다. **AS-IS 자산이 먼저 저장되어 있어야** 개선 설계에 들어간다.

| 순서 | 단계 | 입력·위치 | 게이트 |
|---|---|---|---|
| 0 | AS-IS 자산 확인 | `legacy/<프로그램>/README.md` — 로직·화면 정보 수령 범위와 미수령분 | 개선 범위에 걸린 미수령분이 있으면 코드 금지 |
| 1 | 기준선 진단 | `python3 tools/abap_check.py legacy/<프로그램>/source` | — |
| 2 | 개선 요구사항 접수 | 인터뷰 (유지해야 할 동작 / 바꿀 동작을 분리 질문) | Gate U 승인 |
| 3 | 화면 변경 컨펌 | 기존 화면(`legacy/.../screen-info.md`) 대비 변경 전·후 제시 | Gate D 컨펌 |
| 4 | 이후 단계 | 신규와 동일 (Gate F → 1 → 2 → 3 → 4) | — |

자산 수집은 **별도 세션에서 저장까지만** 수행한다 (`legacy/README.md` 접수 절차).
개선 결과물은 `sessions/<날짜-프로그램>/code.abap` 에 쓰고 `legacy/` 를 덮어쓰지 않는다.

## 유형 선택표 (Gate F 승인 후 구조화 대상)

| 번호 | 만들고 싶은 프로그램 | 템플릿 파일 | 코드 골격 (Gate 3) | 대표 트랜잭션 | 구분 |
|---|---|---|---|---|---|
| 공통 | 모든 유형 공통 (목적·네이밍·권한·이송) | `requirements/00-common.md` | — | — | 필수 |
| 01 | 조회·출력 리포트 (ALV, 선택화면) ★주력 | `requirements/01-alv-report.md` | `templates/abap/01-alv-salv.abap` 또는 `01-alv-reuse.abap` | SE38 | 주력 |
| 03 | 재사용 로직 (Function Module, BAPI 래퍼) ★주력 | `requirements/03-function-module.md` | `templates/abap/03-function-module.abap` | SE37 | 주력 |
| 02 | 입력·저장 화면 (전표 입력, Module Pool) | `requirements/02-module-pool.md` | 골격 없음 (화면 설계 선행) | SE80/SE51 | 확장 |
| 04 | 표준 강화 (User-Exit, BAdI, Enhancement) | `requirements/04-enhancement.md` | 골격 없음 (확장점 분석 선행) | SMOD/CMOD, SE18/SE19, SE80 | 확장 |
| 05 | 연동 (RFC, 파일, IDoc/Proxy) | `requirements/05-interface.md` | `templates/abap/03-function-module.abap` 응용 | SE37, WE31, SM59 | 확장 |
| 06 | 대량 처리 (업로드·BDC·BAPI 배치, 배치잡) | `requirements/06-batch.md` | `templates/abap/01-alv-salv.abap` 응용 | SE38, SM36 | 확장 |
| 07 | 출력 서식 (SmartForms, Adobe Forms, 라벨) | `requirements/07-forms.md` | 골격 없음 (서식 도구 작업) | SMARTFORMS, SFP | 확장 |

## 작성 규칙

1. **공통(00) + 유형별 1부**를 세트로 작성한다. 공통 없이 유형별만 오면 Gate 1에서 반려된다.
2. `★` 표시는 필수. 비어 있으면 AI가 코드를 만들지 않고 질문 리스트만 반환한다.
3. 모르는 칸은 비우지 말고 `[모름]` 이라고 쓰고 아는 만큼 적는다. AI가 SE11/SE37 확인 절차로 바꿔준다.
4. 표·체크박스는 지우지 말고 값을 채운다. AI가 파싱하기 쉽게 형식을 유지한다.
5. 작성본 파일명 권장: `requirements/filled-ZSD_SALES_ALV01.md` 처럼 프로그램명을 붙인다.

## AI에게 붙여넣는 순서 (인터뷰 전용)

```text
① SKILL 지시 1줄 (AGENTS.md 참조)
② context/system-context.filled.md 1부
③ [신규 프로그램 요구사항 인터뷰 시작 요청] 1줄
→ 인터뷰(I-0~I-8) → Gate U 이해도 확인 → ④ 08-demo 화면 컨펌 → ⑤ 09-fieldmap 승인
→ ⑥ 유형 템플릿(01~07) 구조화본 → Gate 2 스펙 확정
⑦ (있으면) context/ddic-collect.filled.md
```

작성 틀 직접 작성 시작(00-common + 01~07)·자유 텍스트·파일 첨부는 접수하지 않는다. 해당 입력이 오면 인터뷰로 전환한다. (아래 구방식 블록은 참고용으로만 보관한다.)

```text
① SKILL 지시 1줄
② context/system-context.filled.md 1부
③ requirements/00-common.filled.md 1부
④ requirements/01(또는 해당 유형).filled.md 1부
⑤ (있으면) context/ddic-collect.filled.md
```
