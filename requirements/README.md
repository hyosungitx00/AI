# 요구사항 템플릿 라우터 — 어떤 파일을 쓸까?

> 신규 세션 기본값은 **인테이크·데모-퍼스트**: `00-intake` 접수 → Gate U 이해도 확인 →
> `08-demo` 화면 컨펌(Gate D) → `09-fieldmap` 필드·구현 승인(Gate F) → 유형 템플릿(01~07) 구조화.
> 세션마다 기존 요구사항을 참조할 필요가 없으며, 텍스트·파일 중 편한 형식으로 1건 접수한다.
> 구방식(공통 00 + 유형별 1부를 사용자가 직접 채워 시작)도 그대로 유효하다.
> 엄격 게이트 운용: 필수(★) 1개라도 비어 있으면 AI가 코드를 만들지 않는다.
>
> 확정 사항(2번 항목 Q&A, 2026-09-22): 템플릿 범위 `8종 유지(01·03 주력 + 02·04~07 확장)`,
> 필수 엄격도 `엄격 유지(★ 1개라도 비면 코드 금지)`, 테스트 형식 `T1 정상 + T2 0건/예외 + T3 권한·검증 표`,
> 문서 언어 `한국어 표·체크박스 고정(AI 파싱용 형식 유지)`.
> 추가 확정(2026-09-28): 신규 세션 `인테이크·데모-퍼스트` 기본 적용 — Gate U(이해도) → Gate D(화면) → Gate F(필드·구현) 순 승인.

## 신규 세션 접수표 (기본)

| 순서 | 단계 | 템플릿·입력 | 게이트 |
|---|---|---|---|
| 1 | 접수 | `requirements/00-intake.md` + 요구사항 본문(텍스트 붙여넣기 또는 파일: md/txt/xlsx/docx/pdf/이미지/html 데모) | — |
| 2 | 이해도 확인 | AI 작성 **이해도 확인서** (목적·기능·입출력·예외·모호점·데모 분기) | Gate U 승인 전 데모·필드맵·스펙·코드 금지 |
| 3 | 화면 데모 | `requirements/08-demo.md` — 데모 있음→경로A 분석 / 없음→경로B AI 생성 목업 | Gate D 화면 컨펌 전 필드맵·스펙·코드 금지 |
| 4 | 필드·구현 | `requirements/09-fieldmap.md` — 화면-필드 연결표 + 테이블·조인 + 구현 방식 + T1~T3 | Gate F 승인 후 유형 템플릿으로 구조화 |

## 유형 선택표 (Gate F 승인 후 구조화 대상)

| 번호 | 만들고 싶은 프로그램 | 템플릿 파일 | 대표 트랜잭션 | 구분 |
|---|---|---|---|---|
| 공통 | 모든 유형 공통 (목적·네이밍·권한·이송) | `requirements/00-common.md` | — | 필수 |
| 01 | 조회·출력 리포트 (ALV, 선택화면) ★주력 | `requirements/01-alv-report.md` | SE38 | 주력 |
| 03 | 재사용 로직 (Function Module, BAPI 래퍼) ★주력 | `requirements/03-function-module.md` | SE37 | 주력 |
| 02 | 입력·저장 화면 (전표 입력, Module Pool) | `requirements/02-module-pool.md` | SE80/SE51 | 확장 |
| 04 | 표준 강화 (User-Exit, BAdI, Enhancement) | `requirements/04-enhancement.md` | SMOD/CMOD, SE18/SE19, SE80 | 확장 |
| 05 | 연동 (RFC, 파일, IDoc/Proxy) | `requirements/05-interface.md` | SE37, WE31, SM59 | 확장 |
| 06 | 대량 처리 (업로드·BDC·BAPI 배치, 배치잡) | `requirements/06-batch.md` | SE38, SM36 | 확장 |
| 07 | 출력 서식 (SmartForms, Adobe Forms, 라벨) | `requirements/07-forms.md` | SMARTFORMS, SFP | 확장 |

## 작성 규칙

1. **공통(00) + 유형별 1부**를 세트로 작성한다. 공통 없이 유형별만 오면 Gate 1에서 반려된다.
2. `★` 표시는 필수. 비어 있으면 AI가 코드를 만들지 않고 질문 리스트만 반환한다.
3. 모르는 칸은 비우지 말고 `[모름]` 이라고 쓰고 아는 만큼 적는다. AI가 SE11/SE37 확인 절차로 바꿔준다.
4. 표·체크박스는 지우지 말고 값을 채운다. AI가 파싱하기 쉽게 형식을 유지한다.
5. 작성본 파일명 권장: `requirements/filled-ZSD_SALES_ALV01.md` 처럼 프로그램명을 붙인다.

## AI에게 붙여넣는 순서 (신규 기본: 인테이크 방식)

```text
① SKILL 지시 1줄 (AGENTS.md 참조)
② context/system-context.filled.md 1부
③ requirements/00-intake.filled.md 1부 + 요구사항 텍스트/파일
→ Gate U 이해도 확인 → ④ 08-demo 화면 컨펌 → ⑤ 09-fieldmap 승인
→ ⑥ 유형 템플릿(01~07) 구조화본 → Gate 2 스펙 확정
⑦ (있으면) context/ddic-collect.filled.md
```

구방식(템플릿 직접 작성 시작)도 유효하다:

```text
① SKILL 지시 1줄
② context/system-context.filled.md 1부
③ requirements/00-common.filled.md 1부
④ requirements/01(또는 해당 유형).filled.md 1부
⑤ (있으면) context/ddic-collect.filled.md
```
