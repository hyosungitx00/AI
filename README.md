# AI
AI연구과제 활동

## ABAP ST22 모니터링 리포트

- 소스: `abap/zst22_monitor.abap`
- SAP GUI의 SE38/ADT에서 `ZST22_MONITOR` 리포트로 생성 후 소스를 붙여넣어 활성화합니다.
- 최근 N분 동안 생성된 ST22 short dump를 `SNAP_BEG`에서 조회해 ALV로 표시합니다.
- `p_mail`을 선택하고 `p_rec`에 수신자 이메일을 입력하면 덤프가 발견될 때 SAPconnect를 통해 알림 메일을 보냅니다.
- 지속 모니터링이 필요하면 SM36에서 배치 잡으로 주기 실행하세요.
