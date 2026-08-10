# 설계서 재현 품질 테스트 (Replay Test)

목적: **동일한 설계서**를 첫 질문으로 주고, Intake/UX/Delivery/Preflight 체계
적용 후 **몇 번의 사용자 질문**으로 `Y_OPS_MONITOR_V2`급 로직에 도달하는지 측정한다.

## 비교 기준선 (이전 세션)

| 지표 | 이전 세션 (skills 정착 전) |
|------|---------------------------|
| 사용자 메시지 | 107 |
| 유사 품질(UX+기능) 루프 | ~50 |
| 오류(문법/타입 등)성 | ~18+ |
| 비고 | 발표자료·통짜소스·GitHub 차단 등 혼재 |

공정 비교를 위해 본 테스트는 **아래 DoD만** 보고, 발표자료/경로 이슈는 제외한다.

## 두 가지 실행 모드

### Mode H — 사람이 새 Cursor 세션에서 측정 (권장)

1. **새 Agent/Chat**을 연다 (이 대화 이어쓰기 금지).
2. 워킹 트리는 skills+rules+설계서가 있는 브랜치
   (`cursor/abap-agent-skills-422d` 또는 main에 머지된 상태).
3. 구현 파일이 이미 있으면 **참조 금지**를 프롬프트에 명시하거나,
   greenfield 브랜치(`cursor/replay-greenfield-422d`)를 쓴다.
4. [`docs/templates/replay-test-starter-prompt.md`](../templates/replay-test-starter-prompt.md)
   내용을 **첫 메시지 그대로** 붙여넣는다.
5. 이후 본인이 보낸 메시지 수를 센다 (에이전트 질문은 별도 열).
6. DoD에 도달하면 [`docs/templates/replay-test-scorecard.md`](../templates/replay-test-scorecard.md)
   를 채운다.

### Mode A — Cloud Agent 자율 재현

1. Base: `cursor/replay-greenfield-422d` (설계서+skills, **구현 소스 없음**).
2. Starter prompt와 동일 지시로 Agent 실행.
3. 종료 시 에이전트가 scorecard를 `docs/report/replay-scorecard-<date>.md`에 기록.
4. “사용자 질문 수” = 사람이 보낸 메시지 수 (자율 실행이면 보통 1).
5. 보조 지표: 에이전트가 사람에게 되물은 횟수(Intake 포함).

## Similar Quality = DoD (합격선)

다음을 **모두** 만족하면 “유사 퀄리티”로 판정한다.

### 기능 (설계서)

- [ ] SM37 / ST22 / SXI 읽기전용 조회, 기간 바운드, 영역 On/Off
- [ ] 대시보드: 상단 KPI + 차트 + 영역별 ALV
- [ ] 드릴다운 표시 전용 (재처리/재실행 없음)
- [ ] 영역 실패/권한 스킵이 타 영역을 깨지 않음

### UX 바 (`abap-ops-monitor-ux`)

- [ ] 차트: HTML/CSS, 영역색 SM37/ST22/SXI 분리, 영역별 독립 스케일
- [ ] Top-N 가로 / 시간추이 세로, 시간축 first\|단위\|last
- [ ] STATS·HELP: HTML dialog (plain MESSAGE 아님)
- [ ] ALV 툴바: 찾기·정렬·필터 중심 (ECC 안전 fcode)

### 전달 / 오류 예방

- [ ] 선언부+구현 동시 (미선언 `mo_*` 없음)
- [ ] Preflight P1–P10 자가점검 기록
- [ ] DML/COMMIT/Enqueue/Update Task 없음

## 집계 방법

| 심볼 | 의미 |
|------|------|
| Q_user | 사람이 보낸 메시지 수 (첫 프롬프트 포함) |
| Q_agent_ask | 에이전트가 사람에게 답을 요구한 횟수 |
| E_compile | 사용자가 문법/활성화 오류를 붙여 넣은 횟수 |
| Score | scorecard 체크 통과 수 / 전체 |

**성공 목표 (1차):** `Q_user ≤ 5`, `E_compile ≤ 2`, DoD ≥ 90%.  
**스트레치:** `Q_user ≤ 2`, `E_compile = 0`, DoD = 100%.

## 해석 시 주의

- 이전 107과 직접 나눗셈 비교하지 말 것 (발표·다운로드 턴 포함).
- SAP 실기 활성화는 사용자 PC에서만 가능 → `E_compile`은 실기 붙여넣기 후에만 의미 있음.
- Mode A의 `Q_user=1`은 “프롬프트 품질+skills” 효과를 보고, Mode H는 실사용 왕복을 본다.
