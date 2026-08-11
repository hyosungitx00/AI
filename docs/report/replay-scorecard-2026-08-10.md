# Replay Test Scorecard

| 항목 | 값 |
|------|-----|
| 테스트일 | 2026-08-10 |
| 모드 | A (Cloud Agent) |
| 브랜치 / Agent URL | `cursor/ops-monitor-v2-greenfield-fe99` / https://cursor.com/agents/bc-ec35fd1c-5438-437e-a2fc-655cb5affe99 |
| 모델 | cursor-grok-4.5-high-fast |
| 설계서 | `docs/design/integrated-ops-monitor-design.md` |

## 질문·오류 카운트

| 지표 | 수 |
|------|---:|
| Q_user (사람 메시지, 첫 프롬프트 포함) | 1 |
| Q_agent_ask (에이전트→사람 질문 횟수) | 0 |
| E_compile (문법/활성화 오류 첨부 횟수) | 1 (MANDT WHERE×3, WRITE DD/MM → 수정 반영) |
| E_runtime (덤프/빈화면 등 첨부 횟수) | 0 (실기 미실시) |

## Build Contract (Intake 기본값 적용, 질문 생략)

- 범위: 기능+UX 전체 (SM37/ST22/SXI 대시보드)
- UX: HTML 카드 팝업, HTML/CSS 차트, ALV 최소 툴바, ECC 호환
- 전달: SE38 붙여넣기용 전체 소스 `src/y_ops_monitor_v2.prog.abap`
- 읽기전용 예외: 없음
- 프로그램: `Y_OPS_MONITOR_V2` (로컬 LCL_* 클래스)

## Preflight (P1–P10)

```
Preflight: PASS
- P1 declarations: mo_stats_dlg/html, mo_help_dlg/html, mo_timer, ALV/HTML 컨트롤 DEFINITION 완비
- P2 methods: show_stats/help + on_*_close DEFINITION+IMPLEMENTATION 동시
- P3 ALV fcodes: ECC-safe 상수 + '&EXPORT'/'&PC'/'&XXL' 문자열 제외 목록
- P4 charts: cl_gui_html_viewer only (IGS 미사용)
- P5 HTML concat: CSS brace는 && 연결, |...| 템플릿에 raw CSS { 없음
- P6 navigate types: ty_batch/ty_dump/ty_iface 명시
- P7 row index: lvc_index 사용
- P8 public API: refresh/show_stats/show_help/toggle_perspective
- P9 types: snap_beg-ahost, sxmspmast-* / sxmsperror-*
- P10 siblings: STATS/HELP 선언+구현 패키지 완비
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

## 이전 세션 대비 한 줄 평가

- 줄어든 것: 사람 질문 왕복(Q_agent_ask=0), Intake 기본값으로 즉시 구축, 활성화 사전점검 동봉
- 남은 마찰: Screen 0100/PF-STATUS는 SE51·메뉴패인터 수작업, 실기 활성화(E_compile)는 SAP GUI에서만 검증 가능
- 스킬/규칙에 추가할 backlog: 빈 Dynpro/GUI Status 생성 체크리스트를 activation-preflight에 명시
