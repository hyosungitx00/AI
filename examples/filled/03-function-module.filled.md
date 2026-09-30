# 작성본 예시 — 00 공통 + 03 Function Module (복붙용)

> `requirements/00-common.md` + `requirements/03-function-module.md`의 작성본 예시이다.
> ALV 예시와 같은 판매 집계 로직을 함수로 재사용하는 케이스이다.

```markdown
## 00 §0 프로그램 식별
- 프로그램/오브젝트명: [Z_SD_GET_SALES (함수그룹 ZFGSD01)]
- 프로그램 유형: [ ] 01 [ ] 02 [x] 03 Function [ ] 04 [ ] 05 [ ] 06 [ ] 07
- 제목(40자): [판매조직별 판매 집계 조회 함수]
- 패키지: [ZSD01]
- 요청번호(TR): [DEVK900123]
- 신규/변경: [x] 신규 [ ] 변경

## 00 §1 목적·사용자
- 목적: [ALV 리포트 2곳 + 배치잡에서 공통 호출할 판매 집계 로직]
- 사용자·빈도: [리포트 2곳 + 매일 배치, 월 10만 콜]
- 기존 대체: [없음]

## 03 §1 함수 식별
- 함수그룹 / 함수명: [ZFGSD01(신규)] / [Z_SD_GET_SALES]
- 처리 유형: [x] 조회(Read) [ ] 계산 [ ] 저장 [ ] BAPI 래퍼
- RFC 허용: [ ] 예 [x] 아니오(내부 전용)
- 호출 빈도·발신자: [리포트 2곳 + 배치잡(매일), 월 10만 콜]

## 03 §2 파라미터
| 구분 | 파라미터명 | 타입 | 필수 | 설명 |
|---|---|---|---|---|
| Import | IV_VKORG | VKORG | 필수 | 판매조직 |
| Import | IV_ERDAT_FM | DATS | 선택 | 생성일 From |
| Import | IV_ERDAT_TO | DATS | 선택 | 생성일 To |
| Export | EV_NETWR | NETWR | | 합계 |
| Tables | ET_ITEMS | ZSSD_SALES_S01 | | 아이템 목록 |
| Exception | NO_DATA | | | 0건 |
| Exception | NO_AUTH | | | 권한 없음 |
- 테스트값: [IV_VKORG=1000 → ET 100행 내외]
- 예외 시: [NO_DATA → SY-SUBRC=1, NO_AUTH → SY-SUBRC=2]

## 03 §3 내부 로직
- 조회·조인: [VBAK-VBAP 조인, KNA1 텍스트]
- 권한 체크: [V_VBAK_VKO, ACTVT=03]
- 성능: [FOR ALL ENTRIES 사용 시 빈 체크, 루프 내 SELECT 금지]

## 03 §4 테스트 시나리오
- T1: [IV_VKORG=1000 → 정상 ET 반환]
- T2: [IV_VKORG=9999 → NO_DATA]
- T3: [권한 없는 유저 → NO_AUTH]
```
