# handover.md — ZMM_PR_LINK_ALV01 운영 이관 묶음

- T-code: 불필요(SE38 실행)
- 권한: SU53 이상 없음 (사용 오브젝트: M_BANF_WRK, ACTVT=03 — SU21/PFCG 등록 시 참조)
- 이송: 미정 / 배치잡: 불필요

## SE93 (해당 없음 — SE38 실행)

## 권한 목록 (SU21/PFCG 등록용)

| 오브젝트 | 필드 | 값 | 비고 |
|---|---|---|---|
| M_BANF_WRK | WERKS / ACTVT | 입력 플랜트 / 03 | 플랜트 미입력 시 체크 건너뜀(코드 참조) |

## TR 초안

- 오브젝트: 프로그램 ZMM_PR_LINK_ALV01 (패키지 ZMM01)
- 이송 순서: 프로그램 단건 (SE91·T-code 없음)
- 검증 T-code: SE38 → 생성일=오늘 → T1~T3

## 운영 주의사항

- 생성일 범위 90일 상한으로 전건 조회 방지됨
- `[확인필요]` DDIC 5곳(EBKN·VBAP·MSEG·RSEG·WBS)은 운영 전 SE11 확정 요망
- 개인정보 미포함, 테스트 코드값만 사용
