# sessions/ — 세션별 묶음 (프로그램 1건 = 폴더 1개)

> 공통 파일(루트·`requirements/`·`harness/`·`context/`·`practice/`·`examples/`)은 전 세션이 공유한다.
> 세션 중에 생기는 작성본·산출물은 이 폴더 아래 `세션 폴더 1개`에 모아둔다.
> 폴더가 세션의 단일 진실 공급원(single source of truth)이다 — AI는 새 세션에서 이전 세션 폴더를 참조하지 않는다(신규 기본).

## 폴더 규칙

- 생성: `tools/new_session.sh <프로그램명> [YYYYMMDD]` — 폴더와 `00-intake.filled.md`만 만든다 (빈 파일 금지 규칙 준수)
- 이름: `YYYYMMDD-프로그램명` (예: `20260928-ZMM_PR_LINK_ALV01`)
- 1건당 파일 구성 (해당 단계까지만 채운다, 빈 파일은 만들지 않는다):

| 파일 | 원본 템플릿 | 작성 시점 |
|---|---|---|
| `00-intake.filled.md` | `requirements/00-intake.md` + `00-intake-prompt.md` | 접수 시 (인터뷰면 답변 정리본) |
| `08-demo.filled.md` | `requirements/08-demo.md` | Gate D 텍스트 컨펌 시 |
| `demo-s1.png` / `demo-s2.png` | AI 생성 데모 이미지 | Gate D-2 이미지 재검증 시 |
| `09-fieldmap.filled.md` | `requirements/09-fieldmap.md` | Gate F 승인 시 |
| `spec.md` | Gate 2 스펙 확정안 | Gate 2 승인 시 |
| `code.abap` | Gate 3 산출물 (`templates/abap/` 골격 복제 → 세션 값 교체) | 코드 제공 시 (SE38 복붙본과 동일) |
| `verify.md` | V-1~V-4 답변 정리 | Verify 진행 시 |
| `errors.md` | 다건 Syntax 오류 목록 (V-3b 양식, 위에서부터 1건씩 순차 수정) | 오류 2건 이상 시 |
| `handover.md` | H-1 답변 + 이관 묶음 | Handover 시 |

## 세션 시작 시 (AI용)

1. `tools/new_session.sh`로 세션 폴더를 새로 만든다. 기존 세션 폴더의 요구사항·설계·코드를 새 코드에 끌어오지 않는다.
   (`context/ddic-cache.md`의 `확정` 행은 시스템에서 확인된 사실이므로 예외 — 재수집하지 않고 그대로 쓴다.)
2. 각 게이트 승인마다 해당 파일을 그때그때 기록한다 (마지막에 몰아서 쓰지 않는다).
3. `code.abap`은 제시 전 `python3 tools/abap_check.py sessions/<폴더>/code.abap` 오류 0건을 확인한다.
   골격의 `TODO(교체)` 잔류가 있으면 미완성이다 (CI도 같은 검사를 한다).

## 세션 종료 시 (AI용)

1. 회수된 오류는 `practice/error-patterns.md`에 패턴으로 승격할지 판단한다 (V-3 규칙).
   기계 점검이 가능하면 `tools/abap_check.py` 규칙으로도 추가한다.
2. 활성화가 Syntax 0건으로 통과했으면 그 코드가 참조한 테이블-필드를 `context/ddic-cache.md`에 `확정`으로 승격한다.

## 보관 중인 세션

| 세션 폴더 | 프로그램 | 상태 |
|---|---|---|
| `20260928-ZMM_PR_LINK_ALV01/` | PR 연결정보 일괄 조회 (SE38 ALV) | 완료 (Verify·Handover済) |
