# 작성본 예시 — DDIC 수집 (복붙용)

> `context/ddic-collect.template.md`의 작성본 예시이다.
> SE11/SE16N에서 눈으로 보고 복사한 값을 그대로 둔다. 추측값에는 반드시 [추측] 표시.

```markdown
### DDIC — 테이블 1
- 테이블명: [VBAK]
- 용도: [판매문서 헤더]
- SE11 Fields (복붙):
| Field | Key | Data element | Type | Len | Dec | 설명 |
|---|---|---|---|---|---|---|
| MANDT | X | MANDT | CLNT | 3 | 0 | 클라이언트 |
| VBELN | X | VBELN_VA | CHAR | 10 | 0 | 판매문서번호 |
| VKORG |   | VKORG | CHAR | 4 | 0 | 판매조직 |
| KUNNR |   | KUNNR | CHAR | 10 | 0 | 고객번호 |
| ERDAT |   | ERDAT | DATS | 8 | 0 | 생성일 |
| WAERK |   | WAERK | CUKY | 5 | 0 | 통화 |
- 조인키 후보: [VBAK-VBELN = VBAP-VBELN, VBAK-KUNNR → KNA1-KUNNR]
- 텍스트/체크 테이블: [KUNNR → KNA1-NAME1]
- [추측] 표시 항목: [없음 — 전 필드 SE11 확인 완료]
- 마스킹 샘플 1행: `VBELN=0100000001, VKORG=1000, ERDAT=20240102`

### DDIC — 테이블 2
- 테이블명: [VBAP]
- 용도: [판매문서 아이템]
- SE11 Fields (발췌):
| Field | Key | Data element | Type | Len | Dec | 설명 |
|---|---|---|---|---|---|---|
| VBELN | X | VBELN_VA | CHAR | 10 | 0 | 판매문서번호 |
| POSNR | X | POSNR_VA | NUMC | 6 | 0 | 아이템번호 |
| NETWR |   | NETWR_AP | CURR | 15 | 2 | 순매출 |
```

```text
위 DDIC 값만 사용해서 SELECT 절과 TYPES를 작성하십시오.
목록에 없는 필드를 쓰지 마십시오. 꼭 필요하면 [확인필요] 주석과 함께 Gate 1 질문으로 반환하십시오.
```
