# Replay Test — 첫 메시지 (복사해서 새 세션에 그대로 붙여넣기)

> 이전 세션의 “첫 질문 = 설계서 제공”과 같은 출발점입니다.
> Brief를 미리 채우지 **마세요** (Skills/Default/Intake가 얼마나 버티는지 측정).

---

아래부터 복사:

```text
@docs/design/integrated-ops-monitor-design.md

위 통합 운영 모니터링 상세 설계서를 기준으로,
읽기 전용(SM37 / ST22 / SXI) 통합 대시보드 ABAP 프로그램을 구현해 주세요.

제약 / 적용 규칙:
1) 프로그램명: Y_OPS_MONITOR_V2 (로컬 리포트, 네임스페이스 Y 허용)
2) .cursor/rules 와 .cursor/skills 를 반드시 적용
   - 모호하면 abap-requirement-intake 를 한 번만 (≤8 선택지)
   - UI는 abap-ops-monitor-ux 품질 바
   - 붙여넣기 전 abap-activation-preflight
3) 기존 구현 파일(src/y_ops_monitor_v2.prog.abap 등)이 워크스페이스에 있어도
   **내용을 복사·참조하지 말고** 설계서+스킬만으로 새로 작성
4) 읽기 전용 불변 유지 (DML/COMMIT/Enqueue/Update Task/재처리 금지)
5) 결과물은 SE38에 붙여넣을 수 있게 소스 파일로 커밋하고,
   마지막에 docs/templates/replay-test-scorecard.md 양식으로
   자가 채점 결과를 docs/report/ 아래 저장

목표: 이전 장기 세션과 유사한 데모 품질을, 사람 추가 질문을 최소화하여 달성.
```
