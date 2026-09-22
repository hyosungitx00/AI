# 03 — Function Module (재사용 로직)

> 여러 프로그램·배치·RFC에서 호출할 단위 로직. `00-common.md`와 세트로 제출.

## §1 함수 식별 ★

- 함수그룹 ★: [예: ZFGSD01(신규/기존)] / 함수명 ★: [예: Z_SD_GET_SALES]
- 처리 유형 ★: [ ] 조회(Read) [ ] 계산 [ ] 저장(Post+Commit) [ ] BAPI 래퍼
- RFC 허용(Remote-Enabled): [ ] 예(외부 호출) [ ] 아니오(내부 전용)
- 호출 빈도·발신자: [예: 리포트 2곳 + 배치잡(매일), 월 10만 콜]

## §2 Import / Export / Tables / Exceptions ★

| 구분 | 파라미터명 | 타입(DDIC 참조) | 필수 | 설명 |
|---|---|---|---|---|
| Import ★ | IV_VKORG | VKORG | 필수 | 판매조직 |
| Import | IV_ERDAT_FM | DATS range | 선택 | 생성일 From-To |
| Export | EV_NETWR | NETWR | | 합계 |
| Tables | ET_ITEMS | ZSSD_SALES_S01 | | 아이템 목록 |
| Exception | NO_DATA | | | 0건 |
| Exception | NO_AUTH | | | 권한 없음 |

- 테스트값: [예: IV_VKORG=1000 → ET 100행, EV=____]
- 예외 시 동작: [예: NO_DATA → SY-SUBRC=1 + 메시지, 저장형은 ROLLBACK]

## §3 내부 로직 ★

- 조회 테이블·조인: [예: VBAK-VBAP 조인, KNA1 텍스트]
- BAPI 호출 시: [예: BAPI_SALESORDER_GETLIST → BAPI_TRANSACTION_COMMIT 여부]
- 권한 체크: [예: V_VBAK_VKO, ACTVT=03]
- 성능: [예: FOR ALL ENTRIES + 빈 체크, 루프 내 SELECT 금지]

## §4 SE37 테스트 시나리오 ★

- T1: [예: IV_VKORG=1000 → 정상 ET 반환]
- T2: [예: IV_VKORG=9999 → NO_DATA]
