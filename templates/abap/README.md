# ABAP 스켈레톤 템플릿 (Gate 3 코드 생성 출발점)

> `examples/`는 "완성된 출력 형식의 기준 샘플"이고, 이 폴더는 "새 코드를 시작하는 골격"이다.
> AI는 Gate 2 스펙 승인 후 여기서 해당 골격을 복제해 세션 값으로 교체한다 — 빈 화면에서 쓰지 않는다.
> 세 파일 모두 `python3 tools/abap_check.py templates --fail-on warning` 오류·경고 0건 상태를 유지한다.

## 파일 선택표

| 파일 | 유형 | ALV·호출 방식 | 메시지 방식 | 언제 쓰나 |
|---|---|---|---|---|
| `01-alv-salv.abap` | 01 ALV 리포트(SE38) | `CL_SALV_TABLE` | 메시지 클래스(SE91 ZSD_MSG) | 기본 ALV. 표준 기능(정렬·필터·엑셀)만 필요할 때 |
| `01-alv-reuse.abap` | 01 ALV 리포트(SE38) | `REUSE_ALV_GRID_DISPLAY` | 텍스트 리터럴(SE91 불필요, MSG-002) | 컬럼 텍스트·합계·핫스팟을 필드카탈로그로 직접 제어할 때 |
| `03-function-module.abap` | 03 Function Module(SE37) | SE37 Local Interface | 예외(`RAISE`) | 재사용 로직·배치 호출 대상 |

`CL_GUI_ALV_GRID`(편집 가능 그리드)는 화면(Dynpro)이 필요해 02 Module Pool과 함께 설계한다. 이 폴더에는 골격을 두지 않는다.

## 템플릿에 이미 선반영된 항목

`practice/error-patterns.md`에서 승격된 패턴을 골격 단계에서 미리 막아 둔다.

| 선반영 | 근거 패턴 | 위치 |
|---|---|---|
| `TABLES <테이블>.` 선언 | ERR-006 | 상단 테이블 선언부 |
| 최소 조건·기간 상한 검증 | ERR-005 | `AT SELECTION-SCREEN` (FM은 `RAISE invalid_input`) |
| `SY-SUBRC` 체크 + 메시지 + `RETURN` | PROC-002 | 모든 SELECT·AUTHORITY-CHECK 직후 |
| `AUTHORITY-CHECK` + `TODO(교체)` | MSG-001 | `frm_check_auth` / FM 선두 |
| `FOR ALL ENTRIES` 앞 `IS NOT INITIAL` | SKILL §3.4 | FM 2차 조회 |
| 선택화면(S1)·결과(S2) 분리 | PROC-001 | 리포트 구조 자체 |
| 복사 순서·DDIC·메시지·테스트 부록 | SKILL §3.3 | 헤더 및 하단 주석 |

## 교체 체크리스트 (AI가 코드 제시 전에 전수 확인)

골격의 예시 값(VBAK / VBAP / KNA1 / ZSD_MSG)은 **반드시 세션 값으로 교체**한다. 교체 지점은 `TODO(교체)` 주석으로 표시되어 있다.

- [ ] 오브젝트명·제목·패키지를 `00-common` §0 값으로 교체 (`ZSD_SAMPLE_*` 잔류 금지)
- [ ] `TABLES` 선언을 실제 조회 기준 테이블로 교체
- [ ] 출력 구조(`ty_out` / 구조 `ZSSD_*`)를 Gate F 필드맵 컬럼으로 교체
- [ ] `SELECT` 필드·조인·WHERE를 `ddic-collect` 수집값으로만 교체 (수집값에 없는 필드 금지)
- [ ] 선택화면 조건·기본값·기간 상한을 세션 값으로 교체
- [ ] 권한 오브젝트를 확정값으로 교체하거나 `TODO(GUI): SU53 확인` 유지
- [ ] 메시지 번호·전문을 세션 값으로 교체 (SE91 없이 진행이면 리터럴 방식 골격 사용)
- [ ] 하단 DDIC·메시지·테스트(T1~T3) 부록을 세션 값으로 교체
- [ ] `grep -n "TODO(교체)"` 결과가 0건
- [ ] `python3 tools/abap_check.py sessions/<세션폴더>/code.abap` 오류 0건

## 사용 예

```bash
cp templates/abap/01-alv-salv.abap sessions/20261006-ZSD_XXX_ALV01/code.abap
# TODO(교체) 지점을 세션 값으로 교체한 뒤
python3 tools/abap_check.py sessions/20261006-ZSD_XXX_ALV01/code.abap
grep -n "TODO(교체)" sessions/20261006-ZSD_XXX_ALV01/code.abap   # 0건이어야 한다
```
