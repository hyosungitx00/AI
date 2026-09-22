# 이 저장소를 AI와 함께 쓰는 법

이 저장소는 SAP GUI에서 ABAP 바이브 코딩을 하기 전 **"AI의 성능을 높이는 사전 준비물"** 모음이다.
사용자는 코딩 전에 템플릿 2종만 채우면 되고, AI는 그 값을 그대로 믿고 코드를 만든다.

## 구성

| 경로 | 설명 | 언제 쓰나 |
|---|---|---|
| `SKILL.md` | AI 행동 규칙 (환각 금지·릴리스 게이트·복붙 계약) | AI 대화 맨 앞에 지시문으로 사용 |
| `HARNESS.md` | 5단계 워크플로우 + 게이트 + 오류 대응표 | AI와 사용자 공통 절차서 |
| `context/system-context.template.md` | 시스템 정보 1부 (릴리스·패키지·네이밍) | 프로젝트당 1회 작성 |
| `context/ddic-collect.template.md` | SE11/SE16N 값 수집 양식 | 테이블·필드가 불확실할 때 |
| `requirements/` | 프로그램 유형별 요구사항 템플릿 8종 | 프로그램마다 1부 작성 |
| `harness/checklists/` | 활성화·리뷰 체크리스트 | SE38 활성화 전후 |
| `harness/prompts/` | 그대로 붙여넣는 프롬프트 조각 | AI 대화 시작 시 |
| `examples/` | 최소 동작 샘플 | AI 출력 형식의 기준 |

## 확정 사항 (사용자 답변 반영, 2026-09-22)

- 기준 릴리스: `SAP_BASIS 750 / S/4HANA` — 모던 ABAP 허용, 코드 상단에 기준 명시
- 주력 유형: `01 ALV 리포트(SE38)` + `03 Function Module(SE37)` — 그 외(02, 04~07)는 확장용
- ALV 방식: 건별 유연 선택 (`CL_SALV_TABLE` / `REUSE_ALV_GRID_DISPLAY` / `CL_GUI_ALV_GRID`)
- 워크플로우: 엄격 게이트 — ★ 빈칸 시 코드 금지, 스펙 "OK" 승인 전 코드 금지
- 네이밍: AI 제안 규칙 (`Z+모듈약어`, 예: `ZSD_*`, 함수그룹 `ZFG*`)
- 주석: 한국어+영문 병기 고정
- 사용 도구: Cursor — 아래 등록 절차 참조

## 권장 사용 순서 (최초 1회 → 매 프로그램)

1. `context/system-context.template.md` 복사·작성 (5분).
2. `requirements/README.md` 에서 유형 선택 → 해당 템플릿 1부 작성 (10~15분).
3. AI 채팅에 순서대로 붙여넣기: `SKILL 지시 1줄` + `시스템 컨텍스트` + `요구사항 템플릿`.
   - 원문은 `HARNESS.md` 부록 A에 있다.
4. AI가 Gate 1(빈칸 질문) → Gate 2(스펙 확정안) → Gate 3(코드) 순으로 준다.
5. `harness/checklists/activation-checklist.md` 대로 SE38에 활성화·테스트한다.
6. 오류는 `HARNESS.md` §4.3 양식으로 회수한다.

## AI 모델 공통 지시 1줄

```text
이 저장소의 SKILL.md와 HARNESS.md를 따르십시오. 기준 SAP_BASIS 750/S4 모던 허용, DDIC 환각 금지, 복붙 계약(완전 소스+복사 순서+테스트 절차) 준수, 엄격 게이트(★ 빈칸 시 코드 금지·스펙 OK 전 코드 금지)를 엄수하십시오. 주력은 ALV 리포트와 Function Module입니다.
```

## Cursor 등록 절차 (사용 도구: Cursor)

1. Cursor Settings → Rules / Custom Instructions에 `harness/prompts/system-prompt-fragment.md` 전문을 등록한다.
2. 새 AI 대화 시작 시 `HARNESS.md` 부록 A 블록(시스템 컨텍스트 + 요구사항 01/03 작성본)만 붙여넣는다. SKILL 지시는 Rules에 이미 있으므로 생략 가능.
3. ALV·FM 외 유형(02, 04~07)이 필요해지면 해당 템플릿 1부를 추가로 붙여넣는다.

## 사용 모델별 팁

- **Cursor**: 위 등록 절차대로 하면 매번 SKILL 전문을 붙여넣지 않아도 된다.
- **SAP 용어가 약한 경우**: `context/ddic-collect.template.md` 수집값을 먼저 주고 "이 값만 써라"고 못 박는다.
- **긴 코드가 잘리는 경우**: "파일을 나눠서 ① TOP ② MAIN ③ FORM 순으로 각각 완전한 코드블록으로 달라"고 요청한다 (`HARNESS.md` §3.1).
