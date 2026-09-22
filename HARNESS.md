# SAP GUI ABAP Vibe Coding Harness

> SKILL.md의 표준 워크플로우를 실행하기 위한 구체 절차서.
> AI(또는 사용자)는 아래 5단계를 순서대로 수행한다. 각 단계에는 **게이트(Gate)** 가 있으며,
> 게이트를 통과하지 못하면 다음 단계로 넘어가지 않는다.
>
> 확정 사항(사용자 답변 반영, 2026-09-22): 기준 `SAP_BASIS 750 / S/4HANA`, 주력 `ALV 리포트(SE38) + Function Module(SE37)`,
> ALV 방식 `건별 유연 선택`, `엄격 게이트(스펙 OK 전 코드 금지)`, 사용 도구 `Cursor`.

## 전체 그림

```text
[0. 사전준비 1회] system-context + 네이밍 확정
        ↓
[1. Context 수집] requirements/00-common + 주력 템플릿(01 ALV / 03 FM) + DDIC 수집 (02, 04~07은 확장용)
        ↓ Gate 1: 빈칸율 체크 (★ 1개라도 비면 코드 금지)
[2. Spec 확정] 테이블·조인·화면·예외 스펙 문서화 → 사용자 OK
        ↓ Gate 2: 스펙 승인
[3. Code 생성] 복붙 계약 준수 코드 + DDIC/메시지/T-code 정의서
        ↓ Gate 3: 정적 체크리스트
[4. Verify 안내] 활성화 순서 + 테스트 케이스 + 덤프 대응
        ↓ Gate 4: SE38 활성화·실행 결과 회수
[5. Handover] 권한·T-code·이송 요청서 → 운영 이관
```

---

## 0단계. 사전준비 (프로젝트당 1회)

1. `context/system-context.template.md` 를 복사해 1부 작성한다.
   - SAP_BASIS 릴리스, ECC/S4 여부, 클라이언트(개발/검증/운영), 로그온 언어, 한글 입력 가능 여부
   - 네이밍 prefix(`ZSD`, `ZMM` …), 패키지(`$TMP` 금지, `Z***` 지정), 요청번호(TR) 규칙
   - 문법 상한(보수적 ECC 호환 vs 모던 허용), ALV 방식(`REUSE_ALV_GRID_DISPLAY` vs `CL_SALV_TABLE` vs `CL_GUI_ALV_GRID`)
2. AI에게 시스템 컨텍스트를 **대화 맨 앞에** 붙여넣는다. 이후 모든 코드 생성에 자동 적용된다.

**Gate 0**: 릴리스 + 패키지 + 네이밍 prefix가 비어 있으면 1단계로 진행 금지.

---

## 1단계. Context 수집

### 1.1 템플릿 선택 (주력: 01 ALV · 03 FM)

`requirements/README.md` 의 라우터 표로 유형을 고른다. 이 저장소의 주력은 **01 ALV 리포트**와 **03 Function Module**이다.

| 만들고 싶은 것 | 템플릿 | 구분 |
|---|---|---|
| 조회·출력 리포트(ALV) ★주력 | `requirements/01-alv-report.md` | 주력 |
| 재사용 로직, 배치 호출 대상 ★주력 | `requirements/03-function-module.md` | 주력 |
| 입력·저장 화면(전표 입력 등) | `requirements/02-module-pool.md` | 확장 |
| 표준 기능 강화, exits/BAdI | `requirements/04-enhancement.md` | 확장 |
| 외부 시스템 연동(RFC/파일/IDoc) | `requirements/05-interface.md` | 확장 |
| 대량 등록·변경(CBO 업로드, 잔재 정리) | `requirements/06-batch.md` | 확장 |
| 출력 서식(청구서, 라벨) | `requirements/07-forms.md` | 확장 |

공통 항목은 `requirements/00-common.md` 에 먼저 기입한다.

### 1.2 DDIC 수집

테이블·필드가 불확실하면 `context/ddic-collect.template.md` 절차대로 SE11/SE16N 화면값을 복사해 온다.
AI는 이 값을 기준으로만 `SELECT` 절과 구조체(`TYPES`)를 만든다.

### Gate 1 — 빈칸율 체크

- 필수(★) 항목이 1개라도 비어 있으면 **코드 작성 금지**.
- 대신 "빈칸 질문 리스트"를 번호 목록으로 반환한다. 예:

```text
[Gate 1 — 추가 정보 필요]
1. §2-① 조회 기준 테이블이 VBAK 단독인가요, VBAP 조인인가요? 조인키를 적어주세요.
2. §3-② ALV 컬럼 중 금액/수량 필드의 참조 테이블·필드(참조용通貨)를 적어주세요.
3. §5-① 테스트용 판매조직(VKORG) 값 1개를 주세요. (실데이터 말고 코드값만)
```

---

## 2단계. Spec 확정

AI는 코드를 만들기 전에 아래 형식의 **미니 스펙**을 먼저 제시한다.

```markdown
### 스펙 확정안 — ZSD_SALES_ALV01
- 소스 테이블: VBAK(헤더) INNER JOIN VBAP(아이템) ON VBELN
- 선택화면: VKORG(필수), VTWEG(선택), ERDAT(레인지), P_ALV(라디오: GRID/SIMPLE)
- ALV 컬럼(8): VBELN, ERDAT, KUNNR+KNA1-NAME1(텍스트), NETWR(합계), WAERK ...
- 집계/정렬: KUNNR 소계, NETWR 합계, ERDAT 내림차순
- 예외: 0건 → s001 메시지, 권한 없음 → AUTHORITY-CHECK 후 e002
- 가정(확인필요): KNA1-NAME1 길이 35 — SE11 확인 요망
[OK] 라고 답하면 코드를 생성합니다. 수정은 번호로 지시해 주세요.
```

### Gate 2 — 스펙 승인 (엄격 게이트)

- 사용자가 **"OK / 진행"이라고 답했을 때만** 3단계로 간다.
- "바로 코드 줘" 요청이 와도 예외 없이 스펙 확정안을 먼저 제시하고, 승인 후에 코드를 생성한다.
- FM 건은 I/E/T 파라미터표, ALV 건은 ALV 방식(`CL_SALV_TABLE` / `REUSE` / `CL_GUI_ALV_GRID` 중 택1)이 스펙에 포함되어야 승인이 유효하다.

---

## 3단계. Code 생성 (복붙 계약)

### 3.1 출력 형식

1. 복사 순서 번호 + 트랜잭션 명시:

```text
[복사 순서]
① SE11 — 구조 ZSSD_SALES_S01 생성 (아래 DDIC 정의 참조)
② SE38 — 프로그램 ZSD_SALES_ALV01 생성, Type=Executable, Status=Test
③ 코드 붙여넣기: TOP → SELECTION-SCREEN → MAIN → SUBROUTINES 순서대로 1개 파일로 합쳐서 저장
④ Extended Check(SLAM/SCI) 실행 → 경고 0건 확인
```

2. 코드블록은 **언어 태그 abap + 완전 소스**로 제공한다. 분량이 길면 파일을 나눠서 여러 코드블록으로 주되, 각 블록에 파일명·순서를 적는다.
3. 코드 뒤에 **DDIC 정의서**(필드·타입·길이 표), **메시지 클래스 정의**(SE91 생성값), **T-code 연결**(SE93 파라미터)을 표로 붙인다.

### 3.2 코드 내 주석 규칙

- 파일 상단 헤더(프로그램명, 작성일, 작성자, TR, 기능, 변경이력) 필수.
- `TODO(GUI)` — 사용자가 SE38에서 해야 할 일. 예: `" TODO(GUI): SE91 ZSD_MSG 001 등록`.
- `확인필요` — DDIC 가정. 3개 초과 시 코드 생성 중단하고 Gate 1로 회귀.

### Gate 3 — 정적 체크 (AI 자가검증, 답변 전에 수행)

- [ ] `SELECT *` 없음?
- [ ] `FOR ALL ENTRIES` 앞 빈 체크 있음?
- [ ] 루프 내 SELECT 없음?
- [ ] `SY-SUBRC` 체크 누락 없음?
- [ ] 릴리스 금지 문법 없음? (기준 750/S4 모던 허용. "보수적으로" 지정 건에 한해 인라인 선언 전수 검사)
- [ ] 메시지·권한 TODO 명시됨?
- [ ] 주석 한국어+영문 병기 확인됨?

---

## 4단계. Verify 안내 (SAP GUI에서 사용자가 수행)

AI는 아래 3종 세트를 답변에 포함한다.

### 4.1 활성화 체크리스트

`harness/checklists/activation-checklist.md` 를 그대로 붙인다(요약):

1. Syntax Check(`Ctrl+F2`) → 에러 0건
2. Extended Check → Error 0건
3. 실행(F8) → 선택화면 표시 확인
4. 테스트값 입력(템플릿 §5) → ALV 표시
5. 0건·권한없음·잘못된 입력 3종 비정상 테스트

### 4.2 테스트 케이스 표

| # | 입력 | 기대 결과 | 실제 결과(사용자 기입) |
|---|---|---|---|
| T1 | VKORG=1000, ERDAT=20240101~20241231 | 100건 내외 ALV, 합계 표시 | |
| T2 | 존재하지 않는 VKORG=9999 | `s001 데이터가 없습니다` | |
| T3 | 권한 없는 유저로 실행 | `e002 권한이 없습니다` | |

### 4.3 덤프·오류 회수 양식

오류가 나면 사용자에게 아래 양식으로 달라고 요청한다.

```text
[오류 회수]
- 트랜잭션/프로그램: SE38 / ZSD_SALES_ALV01
- 입력값: (T1 중 어떤 케이스)
- 메시지 전문(복붙):
- ST22 덤프명(예: ITAB_DUPLICATE_KEY):
- SY-SUBRC(디버깅 /BREAK-POINT 확인값):
- 스크린샷(선택):
```

### Gate 4 — 실행 결과 회수

- "활성화 OK + T1~T3 결과"가 돌아오기 전에는 5단계(Handover)로 가지 않는다.
- 덤프가 오면 `harness/checklists/code-review-checklist.md` + 아래 대응표로 수정본을 제공한다.

| 덤프/오류 | 1순위 원인 | 처방 |
|---|---|---|
| `SYNTAX_ERROR` (활성화 실패) | 릴리스 문법 초과, 오타, DDIC명 오류 | 에러 행번호 기준 최소 수정본 + 원인 1줄 |
| `DBIF_RSQL_INVALID_RSQL` | 존재하지 않는 필드로 SELECT | SE11 확인 → 필드명 수정 |
| `ITAB_DUPLICATE_KEY` | `INSERT` 중복키 | `COLLECT`/`READ` 선체크 후 `MODIFY` |
| `CONVT_NO_NUMBER` | 문자→숫자 변환 실패 | `CONVERSION_EXIT_*` 또는 정규화 루틴 추가 |
| `AUTHORITY_CHECK` 실패 | 오브젝트·ACTVT 누락 | SU53 스크린샷 요청 → 오브젝트 수정 |
| 0건인데도 성공처럼 보임 | `SY-SUBRC` 미체크 | 메시지 + `RETURN` 추가 |

---

## 5단계. Handover (운영 이관)

1. T-code 생성 안내(SE93): 프로그램 연결, 권한 오브젝트 연결.
2. 권한 안내(SU21/PFCG): 사용한 `AUTHORITY-CHECK` 오브젝트 목록표.
3. 이송 요청서(TR) 초안: 오브젝트 목록(프로그램, 구조, 메시지클래스, T-code), 이송 순서, 검증 T-code.
4. 운영 주의사항: 배치 잡 등록(SM36) 필요 여부, 하드코딩 제거 확인, 개인정보 마스킹 여부.

---

## 부록 A. 한 번에 붙여넣는 최초 프롬프트 (사용자용)

> 아래 블록을 AI 채팅 맨 앞에 붙여넣으세요. `[...]` 만 채우면 됩니다.

```text
당신은 SAP GUI ABAP 바이브 코딩 어시스턴트입니다.
이 저장소의 SKILL.md + HARNESS.md + 아래 시스템 컨텍스트를 따르십시오.
기준 릴리스 SAP_BASIS 750 / S/4HANA(모던 허용), DDIC 환각 금지, 복붙 계약 준수를 엄수하십시오.
주력 유형은 ALV 리포트(SE38)와 Function Module(SE37)입니다.

[시스템 컨텍스트 붙여넣기 — context/system-context.template.md 작성본]

[요구사항 템플릿 붙여넣기 — requirements/01 또는 03 작성본]

위 템플릿의 필수(★) 빈칸이 1개라도 있으면 코드를 만들지 말고 Gate 1 질문 리스트를 주십시오.
빈칸이 없으면 스펙 확정안(Gate 2)부터 제시하고, "OK" 승인 전에는 코드를 생성하지 마십시오(엄격 게이트).
```

## 부록 B. AI용 시스템 프롬프트 조각

상세 조각은 `harness/prompts/system-prompt-fragment.md` 참조.
핵심은 3줄이다: **릴리스 게이트 · DDIC 그라운딩 · 복붙 계약**. 매 답변 전에 자가점검한다.
