# Y_OPS_MONITOR_V2 빌드/점검 가이드 (로컬 우선)

`src/y_ops_monitor_v2.prog.abap` 를 대상 SAP 시스템에서 **붙여넣기 → 화면/상태/텍스트 생성 → 활성화 → 실행**하는 절차입니다.
소스로 100% 붙여넣기가 안 되는 요소(**Dynpro 화면·GUI 상태·텍스트 요소**)만 이 문서로 생성합니다. **새 저장소 오브젝트(DDIC/글로벌 클래스/메시지 클래스)는 생성하지 않습니다.**

> 읽기 전용 원칙: 데이터 변경/COMMIT/Enqueue/재처리 금지, 드릴다운은 표시 모드만. (설계서 3.2 / 8.1)

---

## 1. 프로그램 생성 & 소스 붙여넣기
1. `SE38` → 프로그램 `Y_OPS_MONITOR_V2` 생성 (Type: **1 실행 프로그램**, Status: 테스트).
2. `src/y_ops_monitor_v2.prog.abap` 전체를 붙여넣고 저장.
3. 아직 활성화하지 말고, 아래 2~4의 화면/상태/텍스트를 먼저 만든 뒤 일괄 활성화.

## 2. Dynpro 화면 0100 (SE51)
- `SE51` (또는 SE80) → 프로그램 `Y_OPS_MONITOR_V2`, 화면 번호 **0100** 생성.
- 화면 속성: **Normal**, 다음 화면(Next screen) = `0` (또는 공란).
- **레이아웃(Layout Editor)**: 화면 전체를 채우는 **Custom Control** 하나 배치.
  - 요소 유형: Custom Control
  - **이름(Name): `CC_DASH`** ← 소스의 `container_name = 'CC_DASH'` 와 반드시 일치
  - Resizing: 세로/가로 모두 체크(화면 크기 따라 확장), 최소 크기 넉넉히.
- **Element list > OK code 필드명 = `GV_OK_CODE`** (소스 전역변수와 동일하게 지정).
- **Flow Logic** (SE51 Flow Logic 탭에 아래 입력):

```abap
PROCESS BEFORE OUTPUT.
  MODULE status_0100.

PROCESS AFTER INPUT.
  MODULE user_command_0100.
```

> 모듈 `status_0100` / `user_command_0100` 본문은 이미 리포트 소스에 있습니다.

## 3. GUI Status `S0100` & Titlebar `T0100` (SE41)
- `SE41` → 프로그램 `Y_OPS_MONITOR_V2`.
- **Status `S0100`** (Type: Screen/Dialog Status) 생성. 앱툴바 버튼:
  - **`REFRESH`** — 화면에서 재조회(새로고침). 아이콘 예: `ICON_REFRESH`.
  - **`TOGGLE`** — 차트 관점(Top-N ↔ 시간대별 추이) 전환. 아이콘 예: `ICON_CHART` / `ICON_TOGGLE`.
  - **`STATS`** — KPI 요약 팝업. 아이콘 예: `ICON_STATISTICS` / `ICON_INFORMATION`.
  - **`HELP`** — 사용법 팝업. 아이콘 예: `ICON_INFORMATION` / `ICON_SYSTEM_HELP`.
  - 기능 키에 **`BACK` / `EXIT` / `CANCEL`** 표준 배치(F3/Shift+F3/F12).
- **Titlebar `T0100`** 생성: 예) "통합 운영 모니터링 — Cursor AI Demo (SM37/ST22/SXI)".

## 4. 텍스트 요소 (SE38 → Goto > Text Elements)
### 4.1 Selection Texts (선택 텍스트) — 확정
| 필드 | 텍스트 |
|------|--------|
| P_FRDAT | 시작 일자 |
| P_FRTIM | 시작 시간 |
| P_TODAT | 종료 일자 |
| P_TOTIM | 종료 시간 |
| P_HOURS | 조회 범위(시간) |
| CB_SM37 | 배치 잡 에러(SM37) |
| CB_ST22 | 런타임 에러(ST22) |
| CB_SXI  | 인터페이스 에러(SXI) |
| SO_JOB  | 잡명 |
| SO_USER | 사용자 |
| SO_IFACE| 인터페이스명 |
| P_MAND  | 클라이언트 |
| P_MAXROW| 영역별 최대 표시 행수 |
| P_TOPN  | 차트 Top-N 개수 |
| P_AUTORF| 자동 새로고침(초) |

### 4.2 Text Symbols (블록 제목)
| 심볼 | 텍스트 |
|------|--------|
| B00 | Cursor AI Ops Monitor |
| B01 | 조회 기간 |
| B02 | 조회 영역 선택 |
| B03 | 추가 필터(옵션) |
| B04 | 표시 옵션 |

## 5. 활성화 & 구문검사
1. 프로그램/화면/상태/텍스트 **일괄 활성화**.
2. `SE38` 에서 `Ctrl+F2`(Check), 이어서 **SLIN**(확장 구문검사), 가능 시 **ATC**(SCI) 실행.
3. 아래 **환경 의존 지점(TODO)** 에서 활성화 오류가 나면 시스템 값으로 1줄 조정:
   - `RS_ST22_GET_DUMPS` 파라미터명/구조(`SE37`에서 확인): 소스의 `p_day`/`p_infotab`/`RSDUMPTAB` 필드명(`SYDATE/SYTIME/SYUSER/SYHOST/DUMPID/PROGRAMNAME/INCLUDENAME/LINENUMBER`).
   - `SXMSPERROR-EXETIMEST` 실제 타입/정밀도(UTC 타임스탬프 변환 정합성).
   - `BP_JOBLOG_SHOW` 파라미터(잡명/잡카운트).

## 6. 실행 & 기능 점검 (설계 12장 TC)
- `SE38` 에서 `F8` 로 실행(트랜잭션 `ZOPSMON` 은 이 단계에서 미생성).
- TC-01 기본 24H, TC-02 `P_HOURS=72`, TC-03 자정 경계, TC-04 영역 해제,
  TC-05 0건(녹색), TC-06 더블클릭 드릴다운, **TC-07 권한 없는 영역 스킵**,
  TC-08 FROM>TO 검증, TC-11~13 차트(관점 토글/Top-N), TC-14 SXI 타임존.

## 7. 읽기 전용 검수 (TC-10)
소스에서 다음이 **주석 외 미존재** 확인:
`INSERT / UPDATE / MODIFY / DELETE / COMMIT WORK / ENQUEUE_ / DEQUEUE_ / IN UPDATE TASK`
및 상태 변경 BAPI·FM, 편집모드 `CALL TRANSACTION`.

## 8. 권한 확정값 (설계 8.2, STAUTHTRACE 확정)
| 영역 | 객체 | 필드/값 |
|------|------|---------|
| SM37 | `S_BTCH_JOB` | `JOBGROUP='*'`, `JOBACTION='SHOW'` |
| ST22 | `S_ABAPDUMP` | `ACTVT='03'`, `DUMP_INFO='FULL'`, `DUMP_CCLNT='ALL'`, `DUMP_CUSER='ALL'` |
| SXI  | `S_XMB_MONI` | `ACTVT='03'` (기타 필드 DUMMY) |

## 9. 대시보드 데모 기능 (v0.6)
- **상단 KPI**: 헬스 배너(ALL CLEAR/주의/장애) + 신호등 영역건수 + 조회기간/조회시각/소요초/자동갱신/차트관점.
- **중간 차트**: `CL_GUI_HTML_VIEWER` HTML/CSS — Top-N=가로막대, 시간추이=세로막대, 영역별 색(SM37적/ST22황/SXI보라). `TOGGLE` 전환.
- **하단 ALV**: 선택 영역 수만큼 **동적 분할**, zebra/핫스팟, 툴바는 **검색·정렬·필터만** 유지(합계/인쇄/엑셀/레이아웃 등 제외), 더블클릭·핫스팟 드릴다운.
- **커맨드**: `REFRESH` / `TOGGLE` / `STATS`(KPI 팝업) / `HELP`(사용법).
- **선택화면**: 배너 문구, `P_HOURS` 변경 시 FROM/TO 자동 재계산.

## 10. 이후 단계 (로컬 검증 통과 후)
- 로컬 타입/클래스를 **DDIC 구조·글로벌 클래스·인터페이스·메시지 클래스**로 분리.
- 트랜잭션 `ZOPSMON`(SE93) 생성, 텍스트를 메시지 클래스로 전환.
- IGS 그래픽 차트로 차트 패널 교체.
