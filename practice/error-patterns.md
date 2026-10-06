# 오류·교훈 패턴 (Gate 3 전 확인용)

> AI는 코드 생성 전 이 표를 전수 대조한다. `출처 세션`은 `sessions/` 폴더명.
> `자동 점검` 열에 ID가 있으면 `python3 tools/abap_check.py`가 기계로 잡아 준다 —
> 그래도 **대조는 생략하지 않는다**. 점검기는 코드 형태만 보고 업무 의미는 보지 못한다.

## ERR — 덤프·Syntax·실행 오류

| ID | 증상 | 1순위 원인 | 처방·사전방지 | 자동 점검 | 출처 세션 |
|---|---|---|---|---|---|
| ERR-001 | `SYNTAX_ERROR` 활성화 실패 | 릴리스 문법 초과·오타·DDIC명 오류 | 에러 행 최소 수정본 + 원인 1줄. Gate 3 전 금지문법(`DATA(`·`VALUE #()` 등) 대조 | CHK-010 (`--release classic`) | 공통(HARNESS 대응표) |
| ERR-002 | `DBIF_RSQL_INVALID_RSQL` | 존재하지 않는 필드로 SELECT | SE11 확인 → 필드명 수정. 수집값·`ddic-cache` 확정 행에 없는 필드 사용 금지 | — (사람 대조) | 공통(HARNESS 대응표) |
| ERR-003 | `ITAB_DUPLICATE_KEY` | `INSERT` 중복키 | `READ` 선체크 후 `MODIFY`, 또는 `COLLECT` | — (사람 대조) | 공통(HARNESS 대응표) |
| ERR-004 | `CONVT_NO_NUMBER` | 문자→숫자 변환 실패 | `CONVERSION_EXIT_*` 또는 정규화 루틴 추가 | — (사람 대조) | 공통(HARNESS 대응표) |
| ERR-005 | 조회 리포트 전건 조회로 과부하 | 선택화면 전체 미입력 허용 | 최소 1조건 필수 + 일자 범위 상한(예: 90일) 검증을 `AT SELECTION-SCREEN`에 선반영 | CHK-017 | 20260928-ZMM_PR_LINK_ALV01 |
| ERR-006 | `Field "XXXX-FIELD" is unknown` (SELECT-OPTIONS·PARAMETERS의 사전 참조) | `TABLES` 선언 누락 — SELECT-OPTIONS FOR dict-field는 프로그램에 `TABLES table.` 선언이 필수 | DDIC 참조 선택조건 사용 시 `TABLES` 선언을 코드 상단에 선반영. Gate 3 전 대조 | CHK-005 | 20260928-ZMM_PR_LINK_ALV01 |

## MSG — 메시지·권한 관행

| ID | 증상·요청 | 처방·사전방지 | 자동 점검 | 출처 세션 |
|---|---|---|---|---|
| MSG-001 | `AUTHORITY-CHECK` 실패 | SU53 스크린샷 회수 → 오브젝트 수정. 모르면 `TODO(GUI)` 표시 | CHK-016 (직후 `SY-SUBRC` 분기) | 공통(HARNESS 대응표) |
| MSG-002 | "SE91 없이 메시지" 요청 | 텍스트 리터럴(`MESSAGE '...' TYPE 'E'`)로 작성, 복사 순서에서 SE91 단계 제외 | CHK-014 | 20260928-ZMM_PR_LINK_ALV01 |

## PROC — 데모·설계 관행

| ID | 교훈 | 처방·사전방지 | 자동 점검 | 출처 세션 |
|---|---|---|---|---|
| PROC-001 | SE38 실행 리포트 데모를 선택화면+ALV 합성 1화면으로 제시 → Module Pool로 오인됨 | 데모 이미지는 S1 선택화면 / S2 ALV 결과 분리형으로만 생성 | — (사람 판단) | 20260928-ZMM_PR_LINK_ALV01 |
| PROC-002 | 0건인데 성공처럼 보임 | `SY-SUBRC` 체크 + 메시지 + `RETURN` 누락 없이 포함 | CHK-004 | 공통(HARNESS 대응표) |

## 점검기 미대응 패턴 (사람이 봐야 하는 것)

`자동 점검`이 `—`인 패턴은 코드 형태만으로는 판별할 수 없다 (존재하지 않는 필드·중복키·변환 오류·화면 구조).
이 항목은 Gate 3에서 `harness/checklists/code-review-checklist.md`로 직접 확인한다.
