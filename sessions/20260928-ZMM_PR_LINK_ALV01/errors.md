# errors.md — ZMM_PR_LINK_ALV01 Syntax 오류 목록 (위에서부터 1건씩 순차 수정)

| # | 행번호 | 메시지 전문(복붙) | 원인·처방 | 상태 |
|---|---|---|---|---|
| 1 | 36 | Field "EBAN-BADAT" is unknown. | 1차 오진단(sy-datum 회피) → 근본원인 TABLES eban 미선언. `TABLES eban.` 추가 + FOR eban-badat 복원 (ERR-006 승격) | 수정본 제공, 재검사 대기 |
| 2 | | | | 대기 |
