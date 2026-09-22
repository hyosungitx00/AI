# 요구사항 템플릿 라우터 — 어떤 파일을 쓸까?

> 목표: 사용자에게 하나하나 묻지 않고, **프로그램 1건당 템플릿 1부**를 미리 채워 받는다.
> 공통(`00`) + 유형별 중 **1개**를 골라 작성한다. 이 저장소의 주력은 **01 ALV**와 **03 FM**이다.
> 엄격 게이트 운용: 필수(★) 1개라도 비어 있으면 AI가 코드를 만들지 않는다.
>
> 확정 사항(2번 항목 Q&A, 2026-09-22): 템플릿 범위 `8종 유지(01·03 주력 + 02·04~07 확장)`,
> 필수 엄격도 `엄격 유지(★ 1개라도 비면 코드 금지)`, 테스트 형식 `T1 정상 + T2 0건/예외 + T3 권한·검증 표`,
> 문서 언어 `한국어 표·체크박스 고정(AI 파싱용 형식 유지)`.

## 선택표

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

## AI에게 붙여넣는 순서

```text
① SKILL 지시 1줄 (AGENTS.md 참조)
② context/system-context.filled.md 1부
③ requirements/00-common.filled.md 1부
④ requirements/01(또는 해당 유형).filled.md 1부
⑤ (있으면) context/ddic-collect.filled.md
```
