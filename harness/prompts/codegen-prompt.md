# 코드생성 지시문 (Gate 2 OK 이후에 붙여넣기)

```text
Gate 2 스펙이 승인되었습니다. Gate 3 코드 생성을 시작하십시오.

- 골격 복제: templates/abap/ 에서 유형·ALV 방식에 맞는 골격을 복제해 시작하고, TODO(교체) 지점을 세션 값으로 전부 교체하십시오 (잔류 0건).
- 자동 점검: 코드를 제시하기 전에 `python3 tools/abap_check.py <파일>`을 실행해 오류 0건을 확인하고, 남긴 경고는 사유를 한 줄로 밝히십시오.
- Output Contract 준수: 완전 소스 1개(생략·플레이스홀더 금지), 복사 순서 번호+트랜잭션, DDIC 정의서·메시지 정의·T-code 표, T1~T3 테스트 표, 오류 회수 양식 포함.
- 메시지 방식: 기본은 메시지 클래스(SE91 정의서 포함). 사용자가 "SE91 없이"를 요청하면 텍스트 리터럴(`MESSAGE '...' TYPE 'E'`)로 작성하고 복사 순서에서 SE91 단계를 뺀다.
- 릴리스 게이트: SAP_BASIS 750 / S/4HANA 모던 문법 ("보수적으로" 지정 건만 ECC 호환으로 폴백).
- ALV 방식: 승인된 스펙에서 정한 방식 1종 (CL_SALV_TABLE / REUSE / CL_GUI_ALV_GRID).
- DDIC 그라운딩: 아래 수집값에 없는 필드를 쓰지 마십시오. (수집값 붙여넣기)
- practice 대조: `practice/error-patterns.md` 전수 대조 후 해당 패턴을 코드에 선반영하십시오 (대조 없이 코드 금지).
- 자가검증: code-review-checklist.md A~C를 통과한 것만 제시하십시오.

[여기에 승인된 스펙 확정안 + DDIC 수집값을 붙여넣기]
```
