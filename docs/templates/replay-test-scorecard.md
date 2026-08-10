# Replay Test Scorecard

| 항목 | 값 |
|------|-----|
| 테스트일 | YYYY-MM-DD |
| 모드 | H (인간) / A (Cloud Agent) |
| 브랜치 / Agent URL | |
| 모델 | |
| 설계서 | `docs/design/integrated-ops-monitor-design.md` |

## 질문·오류 카운트

| 지표 | 수 |
|------|---:|
| Q_user (사람 메시지, 첫 프롬프트 포함) | |
| Q_agent_ask (에이전트→사람 질문 횟수) | |
| E_compile (문법/활성화 오류 첨부 횟수) | |
| E_runtime (덤프/빈화면 등 첨부 횟수) | |

## DoD 체크

### 기능
- [ ] FR 조회 3영역 + 기간 + On/Off
- [ ] KPI 상단 + 차트 + ALV
- [ ] 드릴다운 표시 전용
- [ ] 영역 격리/권한 스킵

### UX
- [ ] HTML/CSS 차트 + 영역색 + 독립 스케일
- [ ] Top-N 가로 / 시간 축 요약 라벨
- [ ] STATS HTML 팝업
- [ ] HELP HTML 팝업
- [ ] ALV 툴바 최소 + ECC fcode

### 전달·안전
- [ ] 선언부+구현 완비
- [ ] Preflight 기록 있음
- [ ] 읽기전용 grep 통과

**DoD 통과 수:** __ / 13  
**판정:** PASS (≥12) / PARTIAL (9–11) / FAIL (≤8)

## 이전 세션 대비 한 줄 평가

- 줄어든 것:
- 남은 마찰:
- 스킬/규칙에 추가할 backlog:
