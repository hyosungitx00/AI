# 오류·교훈 패턴 (Gate 3 전 확인용)

> AI는 코드 생성 전 이 표를 전수 대조한다. `출처 세션`은 `sessions/` 폴더명.

## ERR — 덤프·Syntax·실행 오류

| ID | 증상 | 1순위 원인 | 처방·사전방지 | 출처 세션 |
|---|---|---|---|---|
| ERR-001 | `SYNTAX_ERROR` 활성화 실패 | 릴리스 문법 초과·오타·DDIC명 오류 | 에러 행 최소 수정본 + 원인 1줄. Gate 3 전 금지문법(`DATA(`·`VALUE #()` 등) 대조 | 공통(HARNESS 대응표) |
| ERR-002 | `DBIF_RSQL_INVALID_RSQL` | 존재하지 않는 필드로 SELECT | SE11 확인 → 필드명 수정. 수집값에 없는 필드 사용 금지 | 공통(HARNESS 대응표) |
| ERR-003 | `ITAB_DUPLICATE_KEY` | `INSERT` 중복키 | `READ` 선체크 후 `MODIFY`, 또는 `COLLECT` | 공통(HARNESS 대응표) |
| ERR-004 | `CONVT_NO_NUMBER` | 문자→숫자 변환 실패 | `CONVERSION_EXIT_*` 또는 정규화 루틴 추가 | 공통(HARNESS 대응표) |
| ERR-005 | 조회 리포트 전건 조회로 과부하 | 선택화면 전체 미입력 허용 | 최소 1조건 필수 + 일자 범위 상한(예: 90일) 검증을 `AT SELECTION-SCREEN`에 선반영 | 20260928-ZMM_PR_LINK_ALV01 |
| ERR-006 | `Field "XXXX-FIELD" is unknown` (SELECT-OPTIONS·PARAMETERS의 사전 참조) | `TABLES` 선언 누락 — SELECT-OPTIONS FOR dict-field는 프로그램에 `TABLES table.` 선언이 필수 | DDIC 참조 선택조건 사용 시 `TABLES` 선언을 코드 상단에 선반영. Gate 3 전 대조 | 20260928-ZMM_PR_LINK_ALV01 |
| ERR-007 | `"GV_TIT1" was already declared` (선택화면 블록 제목·코멘트 필드) | `SELECTION-SCREEN ... WITH FRAME TITLE f` / `COMMENT ... f` 의 `f` 는 컴파일러가 **암시적으로 선언**한다. `DATA f ...` 를 같이 쓰면 중복 선언 | 제목·코멘트 필드는 `DATA` 선언하지 말고 `INITIALIZATION` 에서 값만 넣는다. 이름은 8자 이내(화면 필드 제약). 텍스트 요소(`TEXT-xxx`) 없이 복붙만으로 제목을 띄울 때 쓰는 기법이므로 Gate 3 전 대조 | 20260930-ZMM_STOCK_TREE01 |
| ERR-008 | `Type "LVC_S_HHDR" is unknown` (ALV 트리 계층 머리글) | ALV 트리는 LVC(그리드) 구조와 TREEV(트리 컨트롤) 구조를 **섞어 쓴다**. 필드카탈로그는 `LVC_T_FCAT`·`LVC_S_FCAT`, 노드 레이아웃은 `LVC_S_LAYN` 이지만 계층 머리글은 `TREEV_HHDR` 다 | `CL_GUI_ALV_TREE` 사용 시 `is_hierarchy_header` 는 `TREEV_HHDR` 로 선언한다. 컨트롤 API 타입은 `LVC_` 접두어로 유추하지 말고 확인한다 | 20260930-ZMM_STOCK_TREE01 |

## API — 클래스·메서드 시그니처 확인 관행

| ID | 교훈 | 처방·사전방지 | 출처 세션 |
|---|---|---|---|
| API-001 | **`CL_GUI_ALV_TREE` 는 생성자와 메서드의 작명 규칙이 다르다.** 생성자는 접두어 없음(`parent`·`node_selection_mode`·`item_selection`·`no_html_header`), 메서드는 `i_`·`is_`·`it_`·`e_` 접두어(`i_parent` 아님 주의 / `is_hierarchy_header`·`it_fieldcatalog`·`it_outtab`·`i_relat_node_key`·`i_relationship`·`i_node_text`·`is_node_layout`·`is_outtab_line`·`e_new_node_key`). 2026-10-01 구문검사로 실측 확정 | 한 클래스 안에서도 접두어 관례가 갈릴 수 있으므로 **생성자 파라미터를 메서드 관례로 유추하지 않는다**. 모르면 SE24 → 해당 클래스 → CONSTRUCTOR 파라미터 목록을 회수한다. 구문검사가 `the parameter "XXX" has a similar name` 을 알려주므로 1회 왕복으로 확정 가능 | 20260930-ZMM_STOCK_TREE01 |

## MSG — 메시지·권한 관행

| ID | 증상·요청 | 처방·사전방지 | 출처 세션 |
|---|---|---|---|
| MSG-001 | `AUTHORITY-CHECK` 실패 | SU53 스크린샷 회수 → 오브젝트 수정. 모르면 `TODO(GUI)` 표시 | 공통(HARNESS 대응표) |
| MSG-002 | "SE91 없이 메시지" 요청 | 텍스트 리터럴(`MESSAGE '...' TYPE 'E'`)로 작성, 복사 순서에서 SE91 단계 제외 | 20260928-ZMM_PR_LINK_ALV01 |

## PROC — 데모·설계 관행

| ID | 교훈 | 처방·사전방지 | 출처 세션 |
|---|---|---|---|
| PROC-001 | SE38 실행 리포트 데모를 선택화면+ALV 합성 1화면으로 제시 → Module Pool로 오인됨 | 데모 이미지는 S1 선택화면 / S2 ALV 결과 분리형으로만 생성 | 20260928-ZMM_PR_LINK_ALV01 |
| PROC-002 | 0건인데 성공처럼 보임 | `SY-SUBRC` 체크 + 메시지 + `RETURN` 누락 없이 포함 | 공통(HARNESS 대응표) |
| PROC-003 | 리포트에서 0건 메시지를 `MESSAGE ... TYPE 'S'` + `RETURN` 으로 처리 → 리스트 출력이 없으면 선택화면으로 되돌아가고 메시지가 상태바에만 남아, 사용자에게는 "아무 화면도 안 나옴"으로 보인다. 컨트롤(ALV/트리) 미표시 증상과 구분이 불가능해 원인 추적이 한 왕복 늘어난다 | 조회 리포트의 0건 분기는 **`TYPE 'I'` 모달**로 띄우고, 멈춘 단계와 직전 단계 건수를 문구에 포함한다. 성공 경로에도 단계별 건수 요약을 `WRITE` 로 남겨 "데이터 문제"와 "렌더링 문제"가 한 번의 실행으로 갈리게 만든다 | 20260930-ZMM_STOCK_TREE01 |
| PROC-004 | **리포트 기본 목록(리스트) 위에 `CL_GUI_DOCKING_CONTAINER` 로 컨트롤을 띄우는 방식은 표시되지 않았다.** `START-OF-SELECTION` 에서 도킹 컨테이너 + `CL_GUI_ALV_TREE` 를 만들고 `frontend_update` 까지 호출했는데도(진단 요약 `WRITE` 는 출력됨) 트리가 그려지지 않음. `repid`·`dynnr` 전달/미전달 양쪽 모두 동일. 2026-10-01 실측 | 컨트롤(ALV 트리·그리드)은 **Dynpro 커스텀 컨트롤 + `CL_GUI_CUSTOM_CONTAINER`** 로 띄운다(SAP 표준 데모 `BCALV_TREE_*` 와 같은 구조). SE51 화면 1개(커스텀 컨트롤 + 종료 푸시버튼) 추가 비용을 **Gate 2 설계 단계에서 미리 고지**한다. "복붙만으로 동작"을 지키려고 도킹 컨테이너를 택하면 왕복이 늘어난다. GUI 상태(SE41)는 화면에 기능코드 `BACK` 푸시버튼을 두고 `SY-UCOMM` 을 읽으면 생략 가능. 재실행 시 노드·행 누적을 막기 위해 `free( )` + 전역 테이블 `CLEAR` 를 `START-OF-SELECTION` 선두에 둔다 | 20260930-ZMM_STOCK_TREE01 |
| PROC-005 | **Dynpro 를 추가하면서 GUI 상태·타이틀바를 정의에서 빼면 화면이 실사용 불가다.** SE41 수작업을 줄이려고 종료용 푸시버튼 1개로 대체했더니 ① F3·Shift+F3·F12 가 모두 죽고 ② 창 제목이 비고 ③ 사용자가 "화면 제목·상태 내역이 없다"고 지적했다. 화면 정의서에서 빠뜨리기 쉬운 항목이다 | 화면 1개를 추가하는 순간 **SE51 화면 + SE41 GUI 상태 + SE41 GUI 타이틀을 한 세트**로 정의한다. 상태는 표준 툴바 3자리(F3 `BACK` / Shift+F3 `EXIT` / F12 `CANC`)만 채우고 메뉴 바·애플리케이션 툴바는 비우면 충분하다. 타이틀은 `&1` 치환으로 핵심 조회조건을 넣고 건수는 상태바 메시지로 보낸다(70자 제한). `SET PF-STATUS`·`SET TITLEBAR` 는 **PBO 마다** 호출한다 — 최초 1회 분기(`IF go_tree IS INITIAL`) 안에 넣으면 두 번째 PBO 에서 툴바·제목이 사라진다. 기능유형 `E` 대비로 `MODULE exit_0100 AT EXIT-COMMAND` 를 PAI 첫 줄에 함께 둔다 | 20260930-ZMM_STOCK_TREE01 |
