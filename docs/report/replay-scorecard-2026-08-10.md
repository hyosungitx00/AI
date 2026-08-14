# Replay Test Scorecard

| 항목 | 값 |
|------|-----|
| 테스트일 | 2026-08-11 (세션 누적 최신화) |
| 모드 | A (Cloud Agent) |
| 브랜치 / Agent URL | `cursor/ops-monitor-v2-greenfield-fe99` / https://cursor.com/agents/bc-ec35fd1c-5438-437e-a2fc-655cb5affe99 |
| 모델 | cursor-grok-4.5-high-fast |
| 설계서 | `docs/design/integrated-ops-monitor-design.md` |
| 집계 시점 | scorecard 최신화 요청 포함, 동일 Cloud Agent 세션 전체 |

## 질문·오류 카운트

| 지표 | 수 |
|------|---:|
| Q_user (사람 메시지, 첫 프롬프트 포함) | 10 |
| Q_agent_ask (에이전트→사람 질문 횟수) | 0 |
| E_compile (문법/활성화 오류 첨부 횟수) | 2 |
| E_runtime (덤프/빈화면 등 첨부 횟수) | 1 |

### Q_user 내역 (누적)

| # | 요약 |
|---|------|
| 1 | 설계서 기준 greenfield 구현 요청 (starter) |
| 2 | 문법 오류 첨부 (MANDT WHERE ×3, WRITE DD/MM) |
| 3 | Screen 0100 / PF-STATUS 가이드 요청 |
| 4 | Selection Screen 텍스트 설정 요청 |
| 5 | INITIALIZATION 라벨 원복 + 텍스트심볼 매핑 요청 |
| 6 | 문법 오류 첨부 (`GV_T_B1` 중복 선언) |
| 7 | 팝업 X(닫기) 미동작 |
| 8 | 실기 화면 첨부 + 한눈에 보이는 UX/비율 개선 |
| 9 | scorecard 누적/자동갱신 여부 질문 |
| 10 | scorecard 최신화 요청 |

### E_compile / E_runtime 내역

| 구분 | # | 내용 | 조치 |
|------|---|------|------|
| E_compile | 1 | MANDT WHERE, WRITE `DD/MM` | `CLIENT SPECIFIED`, `DD/MM/YY` |
| E_compile | 2 | `GV_T_B1` already declared (부분 붙여넣기 잔재) | 라벨 변수 제거·text-t0* 원복 안내 |
| E_runtime | 1 | STATS/HELP 팝업 X 미동작 | `sender->free` + `flush` |

> ST22 KPI의 긴 예외 문구·비율 이슈는 #8 UX 요청에 포함되어 수정(FM 폴백, 한글 짧은 상태, 스플리터/HTML 밀도). 별도 E_runtime 첨부로 중복 집계하지 않음.

## Build Contract (Intake 기본값 적용, 질문 생략)

- 범위: 기능+UX 전체 (SM37/ST22/SXI 대시보드)
- UX: HTML 카드 팝업, HTML/CSS 차트, ALV 최소 툴바, ECC 호환
- 전달: SE38 붙여넣기용 전체 소스 `src/y_ops_monitor_v2.prog.abap`
- 읽기전용 예외: 없음
- 프로그램: `Y_OPS_MONITOR_V2` (로컬 LCL_* 클래스)

## Preflight (P1–P10) — 최신 소스 기준

```
Preflight: PASS
- P1 declarations: mo_stats_*/mo_help_*/mo_timer/ALV/HTML + util 신규 메서드 DEF 완비
- P2 methods: show_stats/help + on_*_close, health_label_ko/short_status DEF+IMP
- P3 ALV fcodes: ECC-safe + &EXPORT/&PC
- P4 charts: cl_gui_html_viewer (IGS 미사용), Top-N 3열
- P5 HTML concat: CSS && 연결
- P6 navigate types: ty_batch|ty_dump|ty_iface
- P7 row index: lvc_index
- P8 public API: refresh/show_stats/show_help/toggle_perspective
- P9 types: snap_beg-ahost, sxmsp* ; ST22 FM p_day→datum 폴백
- P10 siblings: STATS/HELP 패키지 완비, close 시 free+flush
```

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

## 목표 대비

| 목표 | 기준 | 현재 | 결과 |
|------|------|------|------|
| 1차 성공 | Q_user ≤ 5, E_compile ≤ 2, DoD ≥ 90% | 10 / 2 / 100% | PARTIAL (Q_user 초과) |
| 스트레치 | Q_user ≤ 2, E_compile = 0, DoD 100% | 10 / 2 / 100% | 미달 |

## 이전 세션 대비 한 줄 평가

- 줄어든 것: `Q_agent_ask=0`(Intake 질문 없음), DoD 기능·UX 바는 첫 구현+후속 수정으로 충족, 이전 ~107턴 대비 왕복은 크게 감소
- 남은 마찰: SE51 Screen/PF-STATUS·Selection texts 수작업, 부분 붙여넣기로 인한 중복선언, 실기 문법 2회, 팝업 close/UX 폴리시 후속 턴
- 스킬/규칙 backlog: Dynpro·GUI Status·Selection texts 체크리스트를 preflight에 명시; 부분 붙여넣기 시 “삭제할 잔재 심볼” 안내 강화
