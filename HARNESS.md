# SAP GUI ABAP Vibe Coding Harness

> SKILL.md의 표준 워크플로우를 실행하기 위한 구체 절차서.
> AI(또는 사용자)는 아래 5단계를 순서대로 수행한다. 각 단계에는 **게이트(Gate)** 가 있으며,
> 게이트를 통과하지 못하면 다음 단계로 넘어가지 않는다.
>
> 확정 사항(사용자 답변 반영, 2026-09-22): 기준 `SAP_BASIS 750 / S/4HANA`, 주력 `ALV 리포트(SE38) + Function Module(SE37)`,
> ALV 방식 `건별 유연 선택`, `엄격 게이트(스펙 OK 전 코드 금지)`, 사용 도구 `Cursor`.

## 전체 그림 (인터뷰 전용: 인테이크·데모-퍼스트)

```text
[0. 사전준비 1회] system-context + 네이밍 확정
        ↓
[0.5 인테이크·데모-퍼스트 — 매 세션] 인터뷰 시작 요청 1줄 → I-0~I-8 인터뷰(한 턴 최대 3문항)
        ↓ Gate U: AI 이해 내용 점검·승인
[0.5 데모 분기] 데모 있음 → 08-demo 경로A 분석 → 점검
               데모 없음 → 08-demo 경로B AI 생성 → 점검
        ↓ Gate D: 화면 컨펌
[0.5 필드맵] 09-fieldmap(필드 연결 + 구현 방식) → 점검
        ↓ Gate F: 필드·구현 승인 → 유형 템플릿(01~07)으로 구조화
[1. Context 수집] requirements/00-common + 유형 템플릿(주력 01 ALV / 03 FM) + DDIC 수집
        ↓ Gate 1: 빈칸율 체크 (★ 1개라도 비면 코드 금지)
[2. Spec 확정] 테이블·조인·화면·예외 스펙 문서화 → 사용자 OK
        ↓ Gate 2: 스펙 승인
[3. Code 생성] 복붙 계약 준수 코드 + DDIC/메시지/T-code 정의서
        ↓ Gate 3: 정적 체크리스트
[4. Verify 안내] 활성화 순서 + 테스트 케이스 + 덤프 대응
        ↓ Gate 4: SE38 활성화·실행 결과 회수
[5. Handover] 권한·T-code·이송 요청서 → 운영 이관
```

> 기존 방식(템플릿 00+01~07을 사용자가 직접 채워 시작)·작성 틀 한 번에 입력·자유 텍스트·파일 첨부 접수는 더 이상 받지 않는다.
> 모든 신규 세션은 인터뷰(I-0 → I-8)로 시작하며, 해당 형식 입력이 오면 인터뷰로 전환한다.

---

## 0단계. 사전준비 (프로젝트당 1회)

1. `context/system-context.template.md` 를 복사해 1부 작성한다.
   - SAP_BASIS 릴리스, ECC/S4 여부, 클라이언트(개발/검증/운영), 로그온 언어, 한글 입력 가능 여부
   - 네이밍 prefix(`ZSD`, `ZMM` …), 패키지(`$TMP` 금지, `Z***` 지정), 요청번호(TR) 규칙
   - 문법 상한(보수적 ECC 호환 vs 모던 허용), ALV 방식(`REUSE_ALV_GRID_DISPLAY` vs `CL_SALV_TABLE` vs `CL_GUI_ALV_GRID`)
2. AI에게 시스템 컨텍스트를 **대화 맨 앞에** 붙여넣는다. 이후 모든 코드 생성에 자동 적용된다.

**Gate 0**: 릴리스 + 패키지 + 네이밍 prefix가 비어 있으면 1단계로 진행 금지.

---

## 0.5단계. 인테이크·데모-퍼스트 (매 세션, 인터뷰 전용)

신규 세션은 `requirements/00-intake.md` 커버 없이 인터뷰 시작 요청 1줄로 시작한다.

### 0.5.1 접수 (인터뷰 I-0~I-8)

1. 사용자가 `[신규 프로그램 요구사항 인터뷰 시작 요청]` 한 줄을 보내면,
   AI가 `harness/prompts/interview-script.md` 순서(I-0 접수 → I-8 테스트값, 한 턴 최대 3문항)로 질문하고 답변을 받아 설계한다.
   작성 틀(`requirements/00-intake-prompt.md`) 한 번에 입력·자유 텍스트 붙여넣기·파일 첨부(md / txt / xlsx / docx / pdf / 이미지 / html 데모)로는 접수하지 않으며, 해당 입력이 오면 인터뷰 I-0으로 전환한다.
2. AI는 인터뷰 답변을 기준으로만 판단하고, 이전 세션의 요구사항·코드를 끌어오지 않는다.

### Gate U — AI 이해 내용 점검

- AI는 코드·데모를 만들지 않고, 아래 형식의 **이해도 확인서**를 먼저 제시한다.

```markdown
### 이해도 확인서 — (프로그램 가칭)
- 목적(한 줄): ...
- 사용자·빈도: ... (없으면 [모름] 표시)
- 핵심 기능(번호): ① ... ② ...
- 입력(화면·조건): ... / 출력(조회·저장·서식): ...
- 예외·비정상(추정 포함): ...
- 모호점(사용자 답변 필요): ① ... ② ...
- 데모 분기: [ ] 제공 데모 있음 → 08 경로A로 진행 [ ] 데모 없음 → 08 경로B(AI 생성)로 진행
[OK] 라고 답하면 데모 단계로 진행합니다. 수정은 번호로 지시해 주세요.
```

- 사용자가 **"OK / 진행"이라고 답했을 때만** 데모 단계로 간다. 승인 전에는 데모·필드맵·스펙·코드 모두 금지.

### 0.5.2 데모 분기 (08-demo)

- **경로 A (제공 데모 있음)**: AI가 첨부 데모를 분해해 `08-demo.md` 경로A(화면별 구성 요소·전환/이벤트·확정/추정/모호점)를 작성하고 점검받는다.
- **경로 B (데모 없음)**: AI가 요구사항을 분석해 `08-demo.md` 경로B(텍스트 목업 + 생성 근거 + `[추정]` 표시)를 생성하고 점검받는다.

### Gate D — 화면 컨펌 (2중 검증)

- `08-demo.md` 공통 §3의 화면 컨펌이 **"컨펌(OK)"일 때만** 데모 이미지 단계로 간다.
- **데모 이미지 재검증 (Gate D-2)**: 텍스트 목업 컨펌 후 AI가 화면 데모 이미지를 생성해 다시 검증을 받는다. 이미지 컨펌 전에는 필드맵·스펙·코드 금지.
- **실행가능 리포트(SE38) 데모 규칙**: 선택화면과 ALV를 한 화면에 합치지 않는다. 반드시 분리된 2화면으로 만든다 — S1 선택화면(조건 + F8 실행 안내) / S2 ALV 결과(그리드 + 상태바). 한 화면 합성형은 Module Pool로 오인되므로 금지.
- "수정 요청"이면 번호 지시대로 데모를 고쳐 다시 컨펌받는다. 화면 컨펌 전에는 필드맵·스펙·코드 금지.

### 0.5.3 필드맵 (09-fieldmap)

- 화면 컨펌 완료 후 AI가 `09-fieldmap.md`(화면-필드 연결표 + 테이블·조인·로직 + 구현 방식 + T1~T3 테스트값)를 작성해 점검받는다.
- DDIC 미확정 필드는 `[모름-SE11 확인 예정]`으로 두고, `ddic-collect` 절차로 회수한다.

### Gate F — 필드·구현 승인

- `09-fieldmap.md` §5 컨펌이 **"컨펌(OK)"일 때만** 해당 유형 템플릿(01~07)으로 구조화해 1단계로 진입한다.
- 승인 후 AI는 필드맵 값을 유형 템플릿 칸에 옮겨 적고(값이 바뀌면 안 됨), 이어서 Gate 1(빈칸 체크) → Gate 2(스펙 확정) 순으로 진행한다.

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

1. 먼저 `context/ddic-cache.md`를 확인한다. 상태가 `확정`인 테이블-필드는 **다시 묻지 않고 그대로 쓴다**
   (이전 세션에서 활성화로 실재가 증명된 사실이다).
2. 캐시에 없거나 `미확인`인 항목만 `context/ddic-collect.template.md` 절차대로 SE11/SE16N 화면값을 받아 온다.
3. AI는 수집값과 캐시 확정 행을 기준으로만 `SELECT` 절과 구조체(`TYPES`)를 만든다.
   캐시에 자기 지식으로 행을 추가하는 것은 금지다 (승격 근거는 SE11 출력 또는 활성화 성공 기록뿐).

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

### 3.0 골격 복제 (빈 화면에서 쓰지 않는다)

`templates/abap/`에서 유형에 맞는 골격을 복제해 시작한다. 골격에는 `practice/error-patterns.md`의
승격 패턴(ERR-005/006·MSG-001·PROC-001/002)이 이미 선반영되어 있다.

| 유형·방식 | 골격 파일 |
|---|---|
| 01 ALV — `CL_SALV_TABLE` (기본) | `templates/abap/01-alv-salv.abap` |
| 01 ALV — `REUSE_ALV_GRID_DISPLAY` | `templates/abap/01-alv-reuse.abap` |
| 03 Function Module (SE37) | `templates/abap/03-function-module.abap` |

```bash
cp templates/abap/01-alv-salv.abap sessions/<세션폴더>/code.abap
```

골격의 예시 값(VBAK·VBAP·KNA1·ZSD_MSG)은 `TODO(교체)` 지점을 따라 세션 값으로 전부 바꾼다.
교체 체크리스트는 `templates/abap/README.md` 참조.

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

**1) 자동 점검 — 오류 0건이 될 때까지 코드를 사용자에게 제시하지 않는다.**

```bash
python3 tools/abap_check.py sessions/<세션폴더>/code.abap
grep -n "TODO(교체)" sessions/<세션폴더>/code.abap   # 0건이어야 한다
```

점검기는 아래 체크 항목 대부분(`SELECT *`·루프 내 SELECT·`FOR ALL ENTRIES` 빈 체크·`SY-SUBRC`·
`TABLES` 선언·릴리스 문법·헤더·부록·병기 주석)을 규칙 `CHK-001`~`CHK-017`로 기계 점검한다.
규칙표와 예외 지정 방법은 `tools/README.md` 참조. "보수적으로" 지정 건은 `--release classic`을 붙인다.
경고를 남겨 둔 건은 사유를 답변에 한 줄로 적는다.

**2) 사람 판단이 필요한 항목 — 점검기가 잡지 못하므로 직접 확인한다.**

- [ ] `practice/error-patterns.md` 전수 대조 후 해당 패턴 선반영됨? (대조 없이 코드 금지)
- [ ] DDIC 필드명이 수집값·`context/ddic-cache.md` 확정 행과 일치함? (추측 필드에 `[확인필요]` 표기)
- [ ] 조인 방향·WHERE가 승인된 Gate 2 스펙과 일치함?
- [ ] 메시지 번호·전문과 권한 오브젝트가 세션 확정값임? (미확정이면 `TODO(GUI)` 명시)
- [ ] 선택화면(S1)·결과(S2) 분리 구조가 유지됨? (PROC-001)
- [ ] 세부 항목은 `harness/checklists/code-review-checklist.md` A~C 통과

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

### Gate 4 — 실행 결과 회수 (질문 형식)

- AI가 `interview-script.md` V-1(활성화) → V-2(실행 테스트) 순으로 질문하고 답변을 받아 마무리한다.
  오류 발생 시 V-3(덤프명·메시지 전문·입력값·SY-SUBRC) 질문으로 회수하고, 덤프 대응표로 수정본을 제공한다.
- 회수 후 AI는 `practice/error-patterns.md`를 먼저 대조한다. 기존 패턴이면 그 ID 처방으로, 신규면 새 ID로 패턴 추가 후 수정본을 제공한다.
  덤프 대응표는 `error-patterns.md` ERR 표와 동일하게 유지한다.
- 신규 패턴이 기계 점검 가능한 형태면 `tools/abap_check.py`에 `CHK-nnn` 규칙으로도 추가한다 (추가 절차는 `tools/README.md`).
- 활성화가 Syntax 0건으로 통과하면, 그 코드가 참조한 테이블-필드를 `context/ddic-cache.md`에 `확정`으로 승격한다.
- "활성화 OK + T1~T3 결과"가 돌아오기 전에는 5단계(Handover)로 가지 않는다.
- V-4 Verify 확정(`Handover로 넘어갈까요?`) 확인 후에만 Handover 산출물을 만든다.

| 덤프/오류 | 1순위 원인 | 처방 |
|---|---|---|
| `SYNTAX_ERROR` (활성화 실패) | 릴리스 문법 초과, 오타, DDIC명 오류 | 에러 행번호 기준 최소 수정본 + 원인 1줄 |
| `DBIF_RSQL_INVALID_RSQL` | 존재하지 않는 필드로 SELECT | SE11 확인 → 필드명 수정 |
| `ITAB_DUPLICATE_KEY` | `INSERT` 중복키 | `COLLECT`/`READ` 선체크 후 `MODIFY` |
| `CONVT_NO_NUMBER` | 문자→숫자 변환 실패 | `CONVERSION_EXIT_*` 또는 정규화 루틴 추가 |
| `AUTHORITY_CHECK` 실패 | 오브젝트·ACTVT 누락 | SU53 스크린샷 요청 → 오브젝트 수정 |
| 0건인데도 성공처럼 보임 | `SY-SUBRC` 미체크 | 메시지 + `RETURN` 추가 |

---

## 5단계. Handover (운영 이관 — 질문 형식)

AI가 `interview-script.md` H-1 순서(T-code 필요 여부 → SU53 권한 확정 → 이송 희망일·배치잡 여부)로 질문하고 답변을 받아 아래 묶음을 제공한다. 마지막 `완료/수정` 확인을 받아야 세션 종료.

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
모든 신규 세션은 인터뷰 전용으로 진행하십시오(작성 틀·자유 텍스트·파일 접수는 받지 않고 인터뷰 I-0으로 전환).

[시스템 컨텍스트 붙여넣기 — context/system-context.template.md 작성본]

[신규 세션 입력 — 인터뷰 시작 요청 1줄: [신규 프로그램 요구사항 인터뷰 시작 요청]]

먼저 인터뷰(I-0 → I-8, 한 턴 최대 3문항)로 요구사항을 수집한 뒤 Gate U 이해도 확인서를 제시하고, "OK" 승인 전에는 데모·필드맵·스펙·코드를 만들지 마십시오.
Gate U 승인 후 08-demo(데모 있음→경로A 분석 / 없음→경로B 생성) → Gate D 화면 컨펌 →
09-fieldmap 작성 → Gate F 승인 → 유형 템플릿 구조화 → Gate 2 스펙 확정 순으로 진행하고,
Gate 2 "OK" 승인 전에는 코드를 생성하지 마십시오(엄격 게이트).
```

## 부록 B. AI용 시스템 프롬프트 조각

상세 조각은 `harness/prompts/system-prompt-fragment.md` 참조.
핵심은 3줄이다: **릴리스 게이트 · DDIC 그라운딩 · 복붙 계약**. 매 답변 전에 자가점검한다.
