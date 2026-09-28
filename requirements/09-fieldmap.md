# 09 — 필드 연결 정보 + 구현 방식 확인서

> Gate F용 문서이다. `08-demo.md` 화면 컨펌이 완료된 후에만 작성한다.
> 승인(Gate F 통과) 후 기존 유형 템플릿(01~07)으로 구조화 → Gate 2 스펙 확정 → Gate 3 코드.

## §1 화면-필드 연결표 ★ (화면별, 행 추가 가능)

| 화면 | 화면 항목 | SAP 필드(DDIC) ★ | 입/출력 | 필수 | 변환·체크 | 미확정 |
|---|---|---|---|---|---|---|
| S1 | 판매조직 입력 | VBAK-VKORG | 입력 | 필수 | F4(T001) | |
| S1 | 생성일 From-To | VBAK-ERDAT | 입력 | 선택 | From>To 에러 | |
| S1 | ALV 판매문서 | VBAK-VBELN | 출력 | | 핫스팟→VA03 | |
| S1 | ALV 고객명 | KNA1-NAME1 | 출력 | | KUNNR 조인 텍스트 | |
| S1 | ALV 순매출 | VBAP-NETWR | 출력 | | 통화 WAERK 참조, 합계 | |
| ... | | | | | | |

- DDIC 미확정 필드는 비우지 말고 `[모름-SE11 확인 예정]`이라고 적는다. AI가 `ddic-collect` 절차로 바꿔준다.

## §2 테이블·조인·로직 ★

- 조회 테이블·조인 ★: [예: VBAK INNER JOIN VBAP ON VBELN, KNA1 LEFT JOIN ON KUNNR]
- 선택·검증 로직: [예: ERDAT From>To 에러, VKORG 권한 체크 V_VBAK_VKO]
- 집계·정렬: [예: KUNNR 소계, NETWR 합계, ERDAT 내림차순]
- 저장·연동 시(해당 시): [예: BAPI ____ 호출 → COMMIT, 실패 시 ROLLBACK]

## §3 구현 방식 ★ (AI 제안 + 사용자 확정)

- 프로그램 유형 확정 ★: [ ] 01 ALV(SE38) [ ] 02 ModulePool [ ] 03 Function(SE37) [ ] 04 Enhancement [ ] 05 Interface [ ] 06 Batch [ ] 07 Forms
- 오브젝트명(가안) ★: [예: ZSD_SALES_ALV01 / AI 제안 규칙 적용]
- ALV 방식(01 해당 시): [ ] SALV [ ] REUSE [ ] GUI 컨테이너 [ ] 해당 없음
- 메시지 클래스: [ ] 신규 ____ 생성 [ ] 기존 ____ 사용
- 권한 오브젝트: [예: V_VBAK_VKO / 모르면 "모름-SU53 TRACE 예정"]
- 비정상 처리: [예: 0건 → S, 권한 실패 → E, 입력 오류 → E + 커서]

## §4 테스트값 ★ (코드값만, 실데이터 금지)

- T1 정상 ★: [예: VKORG=1000, ERDAT=20240101~20240131 → 100건 내외]
- T2 0건/예외: [예: VKORG=9999 → S 메시지]
- T3 권한·검증: [예: VKORG=2000 → E 메시지]

## §5 컨펌 ★

- 필드·구현 컨펌 ★: [ ] 컨펌(OK → 유형 템플릿 구조화 진행) [ ] 수정 요청(번호로 지시: ____)
