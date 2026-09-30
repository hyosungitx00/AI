# DDIC 수집 템플릿 (SE11 / SE16N 값 그대로 붙여넣기용)

> AI는 SAP를 볼 수 없으므로, 테이블·필드 정보는 사용자가 눈으로 보고 복사해 와야 한다.
> 아래 절차대로 값을 채워 AI 대화에 붙여넣으십시오. **추측값에는 [추측] 표시**를 강제한다.

## 절차 (SAP GUI)

1. `SE11` → Database table에 테이블명 입력 → Display.
   - `Fields` 탭의 Field / Data element / Data type / Length / Decimals를 복사.
   - `Technical settings`의 Data class / Size category는 생략 가능.
2. 키 확인: `Key` 체크된 필드가 조인키·WHERE 후보이다.
3. 외래키·텍스트테이블이 있으면 `Foreign keys` 탭의 체크테이블명도 복사. (예: KNA1 → ADRC)
4. 샘플 1건이 필요하면 `SE16N` → 테이블명 → 실행 → 1행만 복사 후 **개인정보는 마스킹** (`홍길동 → H***`).

## 붙여넣기 양식

```markdown
### DDIC — 테이블 1
- 테이블명: [예: VBAK]
- 용도(한 줄): [예: 판매문서 헤더]
- SE11 Fields (복붙):
| Field  | Key | Data element | Type | Len | Dec | 설명 |
|--------|-----|--------------|------|-----|-----|------|
| MANDT  | X   | MANDT        | CLNT | 3   | 0   | 클라이언트 |
| VBELN  | X   | VBELN_VA     | CHAR | 10  | 0   | 판매문서번호 |
| ERDAT  |     | ERDAT        | DATS | 8   | 0   | 생성일 |
| ...    |     |              |      |     |     |      |
- 조인키 후보: [예: VBAK-VBELN = VBAP-VBELN]
- 텍스트/체크 테이블: [예: KUNNR → KNA1-NAME1]
- [추측] 표시 항목: [예: WAERK 필드 존재 여부 미확인 — SE11 확인 필요]
- 마스킹 샘플 1행(선택): `VBELN=0100000001, ERDAT=20240102, ...`
```

## AI에게 내리는 지시 (같이 붙여넣기)

```text
위 DDIC 값만 사용해서 SELECT 절과 TYPES를 작성하십시오.
목록에 없는 필드를 쓰지 마십시오. 꼭 필요하면 [확인필요] 주석과 함께 Gate 1 질문으로 반환하십시오.
```
