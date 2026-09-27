# 예시 모음 — AI 출력 형식의 기준 + 작성본 견본

> 이 폴더는 두 종류의 예시를 둔다. 모두 복붙 기준이다.
> 기준 릴리스: `SAP_BASIS 750 / S/4HANA, 모던 ABAP 허용` — 코드 상단에 기준 명시, 호스트변수 `@` 사용.

## 1. AI 출력 형식 기준 (복붙 계약 준수 코드)

| 파일 | 용도 | 복사 대상 |
|---|---|---|
| `ZSD_SALES_ALV01.abap` | ALV 리포트(SE38) 최소 동작 샘플 — `CL_SALV_TABLE`, `@` 호스트변수, DDIC·메시지·테스트 부록 포함 | SE38 |
| `Z_SD_GET_SALES.fugr.abap` | Function Module(SE37) 최소 동작 샘플 — `V_VBAK_VKO` 권한 체크, `NO_DATA`/`NO_AUTH` 예외, SE37 테스트 표 포함 | SE37 (함수그룹 `ZFGSD01`) |

## 2. 작성본 견본 (사용자가 채워서 AI에 붙여넣는 입력 예시)

| 파일 | 원본 템플릿 | 용도 |
|---|---|---|
| `filled/system-context.filled.md` | `context/system-context.template.md` | 시스템 정보 작성본 — 모든 대화 맨 앞에 붙여넣기 |
| `filled/01-alv-report.filled.md` | `requirements/00-common.md` + `01-alv-report.md` | ALV 1건 완성 입력 — 붙여넣으면 Gate 2 진입 |
| `filled/03-function-module.filled.md` | `requirements/00-common.md` + `03-function-module.md` | FM 1건 완성 입력 — 붙여넣으면 Gate 2 진입 |
| `filled/ddic-collect.filled.md` | `context/ddic-collect.template.md` | SE11/SE16N 수집값 작성본 — DDIC 그라운딩용 |

## 3. 붙여넣는 순서 (최초 1회 확인용 데모)

```text
① AGENTS.md의 지시 1줄
② filled/system-context.filled.md
③ filled/01-alv-report.filled.md (또는 03 FM)
④ filled/ddic-collect.filled.md (있으면)
→ Gate 1 통과 → 스펙 확정안(Gate 2) → "OK" → Gate 3 코드 (examples/*.abap 형식)
```
