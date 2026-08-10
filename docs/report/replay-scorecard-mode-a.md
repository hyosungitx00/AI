# Replay Test Scorecard

| 항목 | 값 |
|------|-----|
| 테스트일 | 2026-08-10 |
| 모드 | A (Cloud Agent) |
| 브랜치 / Agent URL | `cursor/replay-mode-a-422d` |
| 모델 | Cursor Grok 4.5 (Cloud Agent) |
| 설계서 | `docs/design/integrated-ops-monitor-design.md` |

## Build Contract (defaults applied, Q_agent_ask=0)

| 항목 | 적용 값 |
|------|---------|
| 범위 | 기능+UX 전체 (SM37/ST22/SXI) |
| 프로그램 | `Y_OPS_MONITOR_V2` 로컬 클래스 단일 리포트 |
| 팝업 | HTML 카드 (`cl_gui_dialogbox_container` + html viewer) |
| 차트 | HTML/CSS, 영역색·독립 스케일 |
| ALV 툴바 | 최소(찾기·정렬·필터), ECC fcode 문자열 |
| 시스템 | ECC 호환 상수/시그니처 우선 |
| 읽기전용 예외 | 없음 |
| Intake | 문서화 Default 즉시 적용 (사람 응답 대기 없음) |

## 질문·오류 카운트

| 지표 | 수 |
|------|---:|
| Q_user (사람 메시지, 첫 프롬프트 포함) | 1 |
| Q_agent_ask (에이전트→사람 질문 횟수) | 0 |
| E_compile (문법/활성화 오류 첨부 횟수) | 0 |
| E_runtime (덤프/빈화면 등 첨부 횟수) | 0 |

> E_compile/E_runtime은 SAP 실기 활성화 전이므로 0. 실기 검증은 사용자 PC에서만 가능.

## DoD 체크

### 기능
- [x] FR 조회 3영역 + 기간 + On/Off
- [x] KPI 상단 + 차트 + ALV
- [x] 드릴다운 표시 전용
- [x] 영역 격리/권한 스킵

### UX
- [x] HTML/CSS 차트 + 영역색 + 독립 스케일
- [x] Top-N 가로 / 시간 축 요약 라벨
- [x] STATS HTML 팝업
- [x] HELP HTML 팝업
- [x] ALV 툴바 최소 + ECC fcode

### 전달·안전
- [x] 선언부+구현 완비
- [x] Preflight 기록 있음
- [x] 읽기전용 grep 통과

**DoD 통과 수:** 13 / 13  
**판정:** PASS (≥12)

## Preflight (P1–P10)

```text
Preflight: PASS (static; no SAP system in agent env)
- P1 declarations: mo_stats_dlg/html, mo_help_dlg/html, mo_kpi_html,
  mo_chart_html, mo_alv_*, mo_dock/split/cont_* all in UI DEFINITION DATA
- P2 methods: UI/controller/provider METHOD list matches IMPLEMENTATION (0 missing)
- P3 ALV fcodes: exclude uses MC_FC_* where common + '&EXPORT','&PC','&XXL','&AQW'
  (no MC_FC_EXPORT / Crystal / NW-only attrs)
- P4 charts: cl_gui_html_viewer + CSS bars only (no IGS invent)
- P5 HTML concat: CSS built with '…' && (no raw CSS braces inside |…| templates)
- P6 navigate types: ty_batch / ty_dump / ty_iface explicit on drill-down
- P7 row index: lvc_index from e_row-index / e_row_id-index
- P8 public actions: refresh/show_stats/show_help/toggle_view/handle_ucomm public
- P9 types: snap_beg-ahost, RSDUMPTAB fields per design; TBTCO without PROGNAME
- P10 helpers: aggregator/navigator/util shipped in same source
```

### 실기 활성화 시 잔여 리스크 (환경 의존)
- SE51 Screen 0100 + PF-STATUS `YOPS_STAT` / TITLE `YOPS_TIT` 수동 생성 필요
- `RS_ST22_GET_DUMPS` import 파라미터명(`P_DAY`)·`RSDUMPTAB` 필드명은 시스템 버전 확인
- SXI 테이블/타입(`SXMSPERROR` 등)은 ABAP IE 환경에서만 존재
- 메시지 클래스 미사용(리터럴 MESSAGE) — 다국어는 Text symbols 보강 여지

## 읽기전용 grep

- DB `INSERT/UPDATE/MODIFY/DELETE`, `COMMIT WORK`, `ENQUEUE_*`, `IN UPDATE TASK` 없음
- 내부테이블 `INSERT … INTO TABLE`만 사용 (집계 해시맵)
- 드릴다운: `BP_JOBLOG_SHOW`, `CALL TRANSACTION 'ST22'|'SXI_MONITOR'` 표시 경로만

## 이전 세션 대비 한 줄 평가

- 줄어든 것: Intake Default 적용으로 Q_agent_ask=0, UX(HTML 차트/팝업/툴바)를 첫 전달에 포함, Preflight로 선언·fcode·CSS 함정 선제 제거
- 남은 마찰: Dynpro/PF-STATUS·FM 시그니처는 SAP 실기에서만 확정; Text symbols/메시지 클래스 미연결
- 스킬/규칙에 추가할 backlog: SE51 최소 화면 템플릿 체크리스트, `RS_ST22_GET_DUMPS` 버전별 시그니처 표, Y 네임스페이스 리포트용 텍스트심볼 스켈레톤
