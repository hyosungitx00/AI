# 작성본 예시 — 09-fieldmap 필드 연결 + 구현 방식 (복붙용)

> `08-demo.filled.md` 화면 컨펌 완료 후 작성하는 예시이다.
> Gate F 승인 후 `01-alv-report` 유형 템플릿으로 구조화된다(값은 `01-alv-report.filled.md`와 일치).

```markdown
## §1 화면-필드 연결표
| 화면 | 화면 항목 | SAP 필드 | 입/출력 | 필수 | 변환·체크 | 미확정 |
|---|---|---|---|---|---|---|
| S1 | 판매조직 입력 | VBAK-VKORG | 입력 | 필수 | F4(T001) | |
| S1 | 생성일 From-To | VBAK-ERDAT | 입력 | 선택 | From>To 에러 | |
| S1 | ALV 판매문서 | VBAK-VBELN | 출력 | | 핫스팟→VA03 | |
| S1 | ALV 고객명 | KNA1-NAME1 | 출력 | | KUNNR 조인 텍스트 | |
| S1 | ALV 순매출 | VBAP-NETWR | 출력 | | 통화 WAERK 참조, 합계 | |

## §2 테이블·조인·로직
- 조회 테이블·조인: [VBAK INNER JOIN VBAP ON VBELN, KNA1 LEFT JOIN ON KUNNR]
- 선택·검증: [ERDAT From>To 에러, VKORG 권한 체크 V_VBAK_VKO]
- 집계·정렬: [KUNNR 소계, NETWR 합계, ERDAT 내림차순]

## §3 구현 방식
- 프로그램 유형 확정: [x] 01 ALV(SE38) [ ] 03 Function [ ] 기타
- 오브젝트명(가안): [ZSD_SALES_ALV01]
- ALV 방식: [x] SALV [ ] REUSE [ ] GUI 컨테이너
- 메시지 클래스: [x] 신규 ZSD_MSG 생성 [ ] 기존 사용
- 권한 오브젝트: [V_VBAK_VKO / SU53 TRACE 예정]
- 비정상: [0건 → S, 권한 실패 → E, 입력 오류 → E]

## §4 테스트값
- T1 정상: [VKORG=1000, ERDAT=20240101~20240131 → 100건 내외]
- T2 0건: [VKORG=9999 → S 메시지]
- T3 권한: [VKORG=2000 → E 메시지]

## §5 컨펌
- 필드·구현 컨펌: [x] 컨펌(OK → 01-alv-report 구조화 진행) [ ] 수정 요청
```
