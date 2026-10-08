# tools/ — 자동 점검·스캐폴딩 (수동 체크리스트의 기계 점검판)

> Gate 3 자가검증과 세션 폴더 준비를 사람 눈 대신 스크립트로 처리한다.
> 추가 설치물이 없다 — Python 3.8+ 와 bash만 있으면 된다.

## 1. `abap_check.py` — ABAP 정적 점검기 (Gate 3 필수)

`HARNESS.md` Gate 3 체크리스트와 `practice/error-patterns.md` 패턴을 17개 규칙으로 점검한다.
**AI는 코드를 사용자에게 제시하기 전에 반드시 실행하고 오류 0건을 확인한다.**

```bash
python3 tools/abap_check.py                              # 저장소 전체 *.abap
python3 tools/abap_check.py sessions/20261006-ZXX/code.abap
python3 tools/abap_check.py --release classic             # ECC 호환(보수적) 문법 게이트
python3 tools/abap_check.py --fail-on warning             # 경고도 실패 처리 (템플릿 기준)
python3 tools/abap_check.py --json                        # 기계 판독용
```

종료코드는 오류 1건 이상이면 `1`이다. 경고는 기본값에서 통과시키되 사유를 사용자에게 알린다.
폴더를 훑을 때 `tools/tests/fixtures/`와 `legacy/`는 건너뛴다 — 각각 일부러 규칙을 위반한
테스트 데이터, 현행 표준을 만족하지 않는 것이 정상인 기존 프로그램 원본이다.
**폴더를 인수로 직접 지정하면 제외하지 않는다**: `python3 tools/abap_check.py legacy/<프로그램>/source`
는 개선 과제의 기준선 지적 목록을 뽑는 용도다.
파일을 직접 지정하면 픽스처도 점검한다.

### 규칙표

| ID | 심각도 | 내용 | 근거 |
|---|---|---|---|
| CHK-001 | 오류 | `SELECT *` 사용 | SKILL §3.4 |
| CHK-002 | 오류 | 루프 내부 SELECT | SKILL §3.4 |
| CHK-003 | 오류 | `FOR ALL ENTRIES` 앞 `IS NOT INITIAL` 누락 | SKILL §3.4 |
| CHK-004 | 오류 | SELECT·CALL FUNCTION 직후 `SY-SUBRC` 체크 누락 | SKILL §3.4 |
| CHK-005 | 오류 | 사전 필드 참조 선택조건의 `TABLES` 선언 누락 | ERR-006 |
| CHK-006 | 오류 | `ZTEST`·`ZTEMP`·`ZZZZ` 임시 오브젝트명 | SKILL §3.5 |
| CHK-007 | 오류 | 헤더에 릴리스 기준(`기준: SAP_BASIS ...`) 누락 | SKILL §3.2 |
| CHK-008 | 경고 | 복사 순서·DDIC 정의서·T1 테스트 부록 누락 | SKILL §3.3 |
| CHK-009 | 오류 | `이하 동일`·`생략` 플레이스홀더 | SKILL §3.3 |
| CHK-010 | 오류 | 지정 릴리스 금지 문법 (`--release 740/classic`에서만) | SKILL §3.2 |
| CHK-011 | 경고 | `COMMIT WORK` 직접 호출 | SKILL §3.4 |
| CHK-012 | 경고 | WHERE 절 회사코드·플랜트·언어 하드코딩 | SKILL §3.4 |
| CHK-013 | 경고 | 한국어+영문 병기 주석 없음 | SKILL §3.3 |
| CHK-014 | 경고 | 사용한 메시지 클래스의 SE91 정의서 누락 | MSG-002 |
| CHK-015 | 경고 | `[확인필요]` DDIC 가정 3건 초과 → Gate 1 회귀 검토 | HARNESS §3.2 |
| CHK-016 | 오류 | `AUTHORITY-CHECK` 직후 `SY-SUBRC` 체크 누락 | MSG-001 |
| CHK-017 | 경고 | 선택화면에 `AT SELECTION-SCREEN` 검증 없음 | ERR-005 |

### 파일 단위 예외

정당한 사유가 있을 때만 코드 주석으로 지정한다 (사유를 같은 줄에 남긴다).

```abap
"! abap-check: ignore CHK-012   " 사유: 법인 고정 리포트, 회사코드 상수 합의됨
"! abap-check: release classic  " 사유: ECC 6.0 대상 건
```

### 새 규칙 추가

`practice/error-patterns.md`에 ERR/MSG/PROC 패턴이 승격되고 기계 점검이 가능하면,
`abap_check.py`의 `RULES` 사전에 `CHK-nnn`을 추가하고 `tools/tests/fixtures/bad_report.abap`에
재현 코드를, `tools/tests/test_abap_check.py`에 기대 규칙을 추가한다.

## 2. `new_session.sh` — 세션 폴더 스캐폴딩

`sessions/README.md` 규칙(1건 1폴더, 빈 파일 금지)대로 폴더와 접수 기록 파일만 만든다.

```bash
tools/new_session.sh ZSD_SALES_ALV01            # sessions/<오늘날짜>-ZSD_SALES_ALV01/
tools/new_session.sh ZSD_SALES_ALV01 20261006   # 날짜 지정
```

## 3. 자체 테스트

```bash
python3 tools/tests/test_abap_check.py
```

불량 픽스처에서 15개 규칙이 모두 탐지되는지, 정상 픽스처가 무지적인지,
저장소의 모든 `.abap` 산출물이 오류 0건인지 확인한다. CI(`.github/workflows/abap-check.yml`)가 같은 명령을 돌린다.
