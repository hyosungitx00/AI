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
이 저장소의 SKILL.md와 HARNESS.md를 따르십시오. 릴리스 초과 문법 금지, DDIC 환각 금지, 복붙 계약(완전 소스+복사 순서+테스트 절차) 준수를 엄수하십시오.
```

## 사용 모델별 팁

- **복붙량이 많은 모델(Cursor/ChatGPT/Claude 등)**: `harness/prompts/system-prompt-fragment.md` 전문을 시스템 프롬프트·Custom Instructions에 등록하면 매번 붙여넣지 않아도 된다.
- **SAP 용어가 약한 모델**: `context/ddic-collect.template.md` 수집값을 먼저 주고 "이 값만 써라"고 못 박는다.
- **긴 코드가 잘리는 모델**: "파일을 나눠서 ① TOP ② MAIN ③ FORM 순으로 각각 완전한 코드블록으로 달라"고 요청한다 (`HARNESS.md` §3.1).
