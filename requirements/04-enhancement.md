# 04 — Enhancement (User-Exit · BAdI · Enhancement Spot)

> 표준 SAP를 깨지 않고 붙이는 강화. **Enhancement ID·BAdI명 확정이 핵심**이다. `00-common.md`와 세트로 제출.

## §1 강화 지점 ★

- 방식 ★: [ ] BAdI(신규) [ ] Enhancement Spot/Section [ ] User-Exit(SMOD/CMOD) [ ] BTE [ ] Validation/Substitution
- BAdI·Spot·Exit명 ★: [예: BAdI LE_SHP_DELIVERY_PROC / 모르면 "모름-후보: 납품 저장 시점"]
- 표준 T-code·시점 ★: [예: VL01N 저장 시, VL02N 변경 시에도 동일 적용]
- 구현 목적(한 줄) ★: [예: 납품 저장 시 고객 등급별 창고 자동 결정]

## §2 입수 가능 변수·테이블 (SE18/SE80에서 확인한 값) ★

- Import 구조·내부테이블: [예: IT_LIPS(납품 아이템), IS_LIKP(헤더)]
- 변경 가능(Changing) 파라미터: [예: CT_LIPS-LGORT(창고)]
- 호출 시점(Before/After/At Save): [예: 저장 직전, DB COMMIT 전]

> 모르면 "[모름]" 표기 후 SE18 → Display → Interface 파라미터 화면값을 `ddic-collect` 양식으로 붙여넣는다.

## §3 커스텀 로직 ★

- 참조 커스텀 테이블: [예: ZSD_CUST_GRADE(고객등급→창고 매핑)]
- 분기 조건: [예: 등급=A→1001, B→1002, 없으면 변경 없음]
- 실패 시: [ ] E 메시지로 저장 중단 [ ] W 로그만(BAL/SLG1) [ ] 변경 없이 통과
- 성능 주의: [예: 저장 시점이라 SELECT 최소화, 1회 SELECT로 버퍼링]

## §4 회귀 테스트 ★

- T1 정상: [예: 등급 A 주문 → VL01N 저장 → LGORT=1001]
- T2 미해당: [예: 등급 없는 고객 → 변경 없음, 저장 성공]
- T3 실패: [예: 매핑 없는 등급 → E/W + 저장 중단/통과 여부]
- 표준 영향: [예: VL02N·VL03N 기존 동작 변화 없음]
