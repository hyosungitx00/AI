# 화면 0100 정의서 — ZMM_STOCK_TREE01

> 작성 2026-10-01 / 세션 `20260930-ZMM_STOCK_TREE01`
> 근거: `practice/error-patterns.md` **PROC-004** — ALV 트리 컨트롤은 Dynpro 커스텀 컨트롤에서만 표시된다.
> 이 화면은 **조회 결과 표시 전용**이다. 입력 필드·저장 로직은 없다.
> 선택화면(블록 1·2)의 라벨은 이 문서가 아니라 `text-elements.md` 에 정의했다.

## §1 화면 개요

| 항목 | 값 |
|---|---|
| 프로그램 / Program | `ZMM_STOCK_TREE01` |
| 화면 번호 / Screen number | `0100` |
| 짧은 설명 / Short description | `재고 현황 트리 / Stock tree` |
| 화면 유형 / Screen type | 일반 화면 (Normal) |
| **다음 화면 / Next screen** | **`0100`** (자기 자신) |
| 호출 / Called from | `START-OF-SELECTION` 의 `CALL SCREEN 0100` |
| 복귀 / Returns to | `LEAVE TO SCREEN 0` → 선택화면 |
| **GUI 상태 / GUI status** | **`STAT0100`** (§3) — `SET PF-STATUS 'STAT0100'` |
| **타이틀바 / Title bar** | **`TIT0100`** (§4) — `SET TITLEBAR 'TIT0100' WITH gv_titbu` |
| 화면 수 | 1개. 팝업·서브스크린·탭스트립 없음 |

**다음 화면을 `0`으로 두면 안 된다.** `0` 이면 첫 PAI 가 끝나는 즉시 화면이 닫혀서, 트리가 떴다가 바로 사라진다. SE51 에서 생성 시 비워두면 자기 번호(`0100`)가 자동으로 채워지므로 그대로 두면 된다.

## §2 요소 목록 (Element list)

요소는 **1개뿐**이다. 뒤로·종료는 GUI 상태 `STAT0100`(§3)가 담당하므로 푸시버튼이 필요 없다.
입력 필드, OK 코드 필드, 테이블 컨트롤, 프레임은 두지 않는다.
아래 표는 SE51 → 화면 0100 → **요소 목록** 탭의 목표 상태다. 레이아웃 편집기에서 요소를 배치하면 이 값들이 채워지며, 값이 다르면 요소 목록에서 직접 고친다. 표에 없는 칼럼은 **전부 기본값(공란·미체크)** 으로 둔다.

### 2.1 일반 속성 탭 (General attributes)

| 이름 Name | 유형 Type | 수정그룹 1~4 | 라인 Line | 칼럼 Col | 정의길이 DLen | 표시길이 VisLen | 높이 Hght |
|---|---|---|---|---|---|---|---|
| `CC_TREE` | 커스텀 컨트롤 (Custom Control) | 공란 | 1 | 1 | 80 | 80 | 20 |

- DDIC 참조가 없다. 사전 참조(From Dict.) 체크하지 않는다.
- DLen·Hght 가 곧 트리가 그려지는 영역 크기다. 화면 폭 한계까지 크게 잡아도 무해하다.
- 라인·칼럼·크기는 동작에 영향이 없다. **이름과 유형만 정확해야 한다.**

### 2.2 텍스트 / 입출력 템플릿 탭 (Texts / I/O templates)

| 이름 | 텍스트 Text | 아이콘 Icon | 빠른 정보 Quick info |
|---|---|---|---|
| `CC_TREE` | 공란 | 공란 | 공란 |

커스텀 컨트롤은 텍스트를 갖지 않는다. 이 탭에 입력할 것이 없다.

### 2.3 특수 속성 탭 (Special attributes)

| 이름 | 기능코드 FctCode | 기능유형 FctType | 입력 Input | 출력 Output |
|---|---|---|---|---|
| `CC_TREE` | — | — | 해당 없음 | 해당 없음 |

입력 요소가 없으므로 이 탭도 건드릴 것이 없다.

### 2.4 표시 속성 / 수정 그룹 / 참조 탭

세 탭 모두 **건드리지 않는다.** 전부 기본값이다.

| 탭 | 설정 |
|---|---|
| 표시 속성 (Display attributes) | 기본값 (3D, 밝게·숨김 등 미설정) |
| 수정 그룹 (Modification groups) | 공란 — `LOOP AT SCREEN` 으로 동적 제어하지 않는다 |
| 참조 (References) | 공란 — DDIC 참조 필드가 없다 |

### 2.5 이름이 계약인 요소

| 요소 | 코드 측 연결 | 불일치 시 증상 |
|---|---|---|
| `CC_TREE` | `CREATE OBJECT go_cont EXPORTING container_name = 'CC_TREE'` | 모달 메시지 "화면 0100 의 커스텀 컨트롤 CC_TREE 를 찾지 못했습니다" 후 빈 화면 |
| 화면번호 `0100` | `CALL SCREEN 0100`, `MODULE status_0100` | 런타임 오류(화면 없음) |
| 상태 `STAT0100` | `SET PF-STATUS 'STAT0100'` | 런타임 오류(상태 없음) 또는 툴바 없는 화면 |
| 타이틀 `TIT0100` | `SET TITLEBAR 'TIT0100' WITH gv_titbu` | 창 제목이 비거나 런타임 오류 |

요소 **이름**이 계약이고, 위치·크기는 바꿔도 동작에 영향이 없다.

### 2.6 푸시버튼을 두지 않는 이유

앞선 초안에서는 SE41 작업을 피하려고 종료용 푸시버튼 `BT_BACK`(기능코드 `BACK`)을 화면에 두었다. GUI 상태를 정식으로 정의한 지금은 불필요하다.
**이미 `BT_BACK` 을 그려 두었다면 지우지 않아도 된다.** 기능코드가 `BACK` 으로 같아서 `MODULE user_command_0100` 이 동일하게 처리한다.

### 2.7 OK 코드 필드를 두지 않는 이유

OK 코드 필드(예: `GV_OKCODE`)를 요소 목록에 추가하는 것이 교과서적이지만, 요소 목록 편집이 한 단계 더 늘고 이름을 틀릴 여지가 생긴다. 대신 `MODULE user_command_0100` 에서 `SY-UCOMM` 을 직접 읽고 **읽은 직후 `CLEAR` 한다.** 비우지 않으면 다음 실행의 첫 PAI 에서 이전 `BACK` 이 그대로 다시 처리된다.

```abap
  lv_ucomm = sy-ucomm.
  CLEAR sy-ucomm.
```

OK 코드 필드를 **꼭 두고 싶다면** 요소 목록에 아래 1행을 추가하고, 프로그램에 `DATA gv_okcode TYPE sy-ucomm.` 을 선언한 뒤 PAI 에서 `sy-ucomm` 대신 `gv_okcode` 를 읽으면 된다. 기능은 동일하다.

| 이름 | 유형 | 라인 | 칼럼 | DLen | 비고 |
|---|---|---|---|---|---|
| `GV_OKCODE` | OK 코드 (OK) | 임의 | 임의 | 20 | 화면 속성의 "OK" 필드로 지정 |

### 2.8 크기 조정 (권장, 선택 사항)

기본 상태에서는 창을 최대화해도 트리 영역이 painted 크기(20 × 80)에 고정된다. 넓게 쓰려면:

1. 화면 속성 → 기타 속성 → "크기 조정 가능(Resizable)" 체크 후 최소 라인·칼럼 입력
2. `CC_TREE` 요소 속성 → 크기 조정(Resizing) → 수직·수평 모두 체크

릴리스에 따라 항목 이름이 조금 다르다. 찾기 어려우면 건너뛰어도 기능에는 영향이 없다.

## §3 GUI 상태 STAT0100

SE41(메뉴 페인터) 또는 SE80 → 프로그램 → GUI 상태 → 생성.

| 항목 | 값 |
|---|---|
| 이름 / Name | `STAT0100` |
| 짧은 설명 / Short text | `재고 현황 트리 / Stock tree` |
| 상태 유형 / Status type | 일반 화면 (Normal screen) |
| 코드 측 지정 | `SET PF-STATUS 'STAT0100'.` — `MODULE status_0100` 에서 **매 PBO 마다** |

### 3.1 기능 키 (Function keys) — 표준 툴바

| 키 | 기능코드 FctCode | 텍스트 | 기능유형 FctType | 아이콘 |
|---|---|---|---|---|
| F3 | `BACK` | `뒤로 / Back` | 공란 | `ICON_BACK` (자동) |
| Shift+F3 | `EXIT` | `종료 / Exit` | `E` 권장 | `ICON_SYSTEM_END` (자동) |
| F12 | `CANC` | `취소 / Cancel` | `E` 권장 | `ICON_CANCEL` (자동) |

표준 툴바의 앞 세 자리가 이 세 기능의 고정 위치다. 기능코드를 넣으면 아이콘·텍스트는 자동으로 붙는다.

기능유형 `E`(Exit command)를 주면 `MODULE user_command_0100` 대신 `MODULE exit_0100 AT EXIT-COMMAND` 가 호출된다. **두 모듈 모두 같은 처리를 하도록 코드에 넣어 두었으므로, `E` 를 주든 공란으로 두든 화면은 정상적으로 닫힌다.** 셋 다 공란이어도 무방하다.

### 3.2 메뉴 바 · 애플리케이션 툴바

| 영역 | 설정 | 이유 |
|---|---|---|
| 메뉴 바 (Menu bar) | **비워 둔다** | 시스템(System)·도움말(Help) 메뉴는 SAP 가 자동으로 붙인다 |
| 애플리케이션 툴바 (Application toolbar) | **비워 둔다** | 전개·축소·내보내기·인쇄·필터는 ALV 트리 컨트롤 자체 툴바에 이미 있다 |
| 기능 키 (위 3건 외) | 비워 둔다 | — |

## §4 GUI 타이틀 TIT0100

SE41 또는 SE80 → 프로그램 → GUI 타이틀 → 생성.

| 항목 | 값 |
|---|---|
| 이름 / Name | `TIT0100` |
| 텍스트 / Title text | `재고 현황 트리 조회 - 회사코드 &1` |
| 치환 변수 / Placeholder | `&1` = 회사코드. 여러 건이면 `H322 외 2` 형태 |
| 코드 측 지정 | `SET TITLEBAR 'TIT0100' WITH gv_titbu.` — 매 PBO 마다 |

`&1` 에 넣을 문구는 `FORM f_build_title` 이 선택화면의 `S_BUKRS` 첫 행으로 만든다.

```abap
FORM f_build_title.

  DATA: ls_bu  LIKE LINE OF s_bukrs[],
        lv_cnt TYPE i.

  CLEAR gv_titbu.

  lv_cnt = lines( s_bukrs[] ).
  IF lv_cnt = 0.
    RETURN.
  ENDIF.

  READ TABLE s_bukrs[] INTO ls_bu INDEX 1.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  IF lv_cnt > 1.
    gv_titbu = |{ ls_bu-low } 외 { lv_cnt - 1 }|.
  ELSE.
    gv_titbu = ls_bu-low.
  ENDIF.

ENDFORM.
```

표시 예시

| 선택화면 입력 | 창 제목 |
|---|---|
| `S_BUKRS` = `H322` | `재고 현황 트리 조회 - 회사코드 H322` |
| `S_BUKRS` = `H322`, `H323`, `H324` | `재고 현황 트리 조회 - 회사코드 H322 외 2` |

조회 건수는 제목이 아니라 **상태바**에 남긴다(`플랜트 4 / 재고 689,319 건 / 표시 7,339 행`). 제목은 길이 제한(70자)이 있어 건수까지 넣으면 잘린다.

## §5 흐름 로직 (Flow logic)

SE51 이 화면을 생성하면 `MODULE` 2줄이 **주석 상태로 자동 생성**된다. 모듈 이름도 코드와 같게 맞췄다. 주석(`*`)을 지우고, PAI 첫 줄에 `AT EXIT-COMMAND` 1줄을 **추가**한다.

```text
PROCESS BEFORE OUTPUT.
  MODULE status_0100.

PROCESS AFTER INPUT.
  MODULE exit_0100 AT EXIT-COMMAND.
  MODULE user_command_0100.
```

| 블록 | 모듈 | 하는 일 |
|---|---|---|
| PBO | `status_0100` | `SET PF-STATUS` + `SET TITLEBAR` → `go_tree` 가 비어 있을 때만 `f_build_tree` |
| PAI | `exit_0100` | 기능유형 `E` 인 종료 명령 전용. `f_free_tree` + `LEAVE TO SCREEN 0` |
| PAI | `user_command_0100` | `SY-UCOMM` 읽고 비운 뒤 `BACK`·`EXIT`·`CANC` 면 `f_free_tree` + `LEAVE TO SCREEN 0` |

`MODULE ... AT EXIT-COMMAND` 는 PAI 의 **첫 줄**이어야 한다. 순서를 바꾸면 의미가 없다.
`SET PF-STATUS`·`SET TITLEBAR` 는 `IF go_tree IS INITIAL` **바깥**에 둔다. PBO 마다 지정하지 않으면 두 번째 PBO 에서 툴바와 제목이 사라진다.

## §6 PBO — 트리 생성 순서

`f_build_tree` 내부 순서다. 각 단계 실패 시 모달 메시지 + `RETURN` 이므로, 화면은 툴바만 있는 빈 상태로 남는다. GUI 상태가 있으니 F3 로 빠져나올 수 있고, 조작 불능 상태가 되지 않는다.

| 순서 | 처리 | 실패 시 |
|---|---|---|
| 1 | 필드카탈로그 10열 구성 (`f_build_fieldcat`) | — |
| 2 | 계층 머리글 `TREEV_HHDR` 설정 (제목 `법인/플랜트/재고/자재`, 폭 55) | — |
| 3 | `CL_GUI_CUSTOM_CONTAINER` 생성 (`CC_TREE`) | 모달 메시지 → `RETURN` |
| 4 | `CL_GUI_ALV_TREE` 생성 (`parent = go_cont`) | 모달 메시지 → `RETURN` |
| 5 | `set_table_for_first_display` | — |
| 6 | 더블클릭 핸들러 2건 등록 (`node_double_click`, `item_double_click`) | — |
| 7 | `gt_row` 루프 → 1~5단 노드 생성, 자재 노드키를 `gt_nodemap` 에 기록 | — |
| 8 | `frontend_update` | — |

## §7 이벤트·전환

| # | 사용자 조작 | 처리 경로 | 결과 |
|---|---|---|---|
| 1 | 선택화면에서 F8 | `START-OF-SELECTION` → 조회·집계 → `CALL SCREEN 0100` | 트리 화면. 제목 `재고 현황 트리 조회 - 회사코드 H322`, 상태바 `플랜트 n / 재고 n 건 / 표시 n 행` |
| 2 | 노드 전개·축소 | ALV 트리 컨트롤 자체 처리 | 화면 유지 |
| 3 | 트리 툴바(전개·축소·내보내기·인쇄) | 컨트롤 자체 처리 | 화면 유지 |
| 4 | **자재 노드 더블클릭** | 컨트롤 이벤트 → `lcl_handler` → `gt_nodemap` 조회 → `SET PARAMETER ID 'MAT'` → `CALL TRANSACTION 'MM03' AND SKIP FIRST SCREEN` | MM03 조회. 뒤로 나오면 트리로 복귀 |
| 5 | 폴더 노드(1~4단) 더블클릭 | 같은 핸들러. `gt_nodemap` 에 없으므로 `RETURN` | 아무 일 없음 (의도된 동작) |
| 6 | **F3 (뒤로)** | PAI `user_command_0100` → `f_free_tree` → `LEAVE TO SCREEN 0` | 선택화면 복귀 |
| 7 | **Shift+F3 (종료) · F12 (취소)** | 기능유형 `E` 면 `exit_0100`, 공란이면 `user_command_0100`. 어느 쪽이든 동일 처리 | 선택화면 복귀 |
| 8 | 선택화면에서 다시 F8 | `START-OF-SELECTION` 선두의 `f_free_tree` + 전역 `CLEAR` | 2회차도 동일하게 표시 |

`EXIT`·`CANC` 를 `BACK` 과 같게 처리한다. 조회 전용 화면이라 저장할 것이 없어 종료와 뒤로를 구분할 이유가 없다.

## §8 생성 절차 (순서대로)

```text
① SE80 → 프로그램 ZMM_STOCK_TREE01 → 우클릭 → 생성 → 화면
     (또는 SE51 → 프로그램·화면번호 0100 → 생성)
② 속성 : 짧은 설명 입력, 화면 유형 = 일반 화면, 다음 화면 = 0100
③ 레이아웃 → 커스텀 컨트롤 배치 → 이름 CC_TREE, 라인 1부터 화면 전체
④ 흐름 로직 → 자동 생성된 MODULE 2줄의 주석(*) 제거
             → PAI 첫 줄에 MODULE exit_0100 AT EXIT-COMMAND. 추가
⑤ 화면 활성화
⑥ SE80 → 프로그램 → GUI 상태 → 생성 → STAT0100
     상태 유형 = 일반 화면
     F3 = BACK / Shift+F3 = EXIT / F12 = CANC
     메뉴 바·애플리케이션 툴바 비움 → 활성화
⑦ SE80 → 프로그램 → GUI 타이틀 → 생성 → TIT0100
     텍스트 = 재고 현황 트리 조회 - 회사코드 &1 → 활성화
⑧ 프로그램(SE38) 구문검사 → 활성화
⑨ F8 실행
```

## §9 활성화 후 점검 체크리스트

| # | 확인 | 기준 |
|---|---|---|
| 1 | SE51 요소 목록 | `CC_TREE` 1건 (`BT_BACK` 을 남겨 뒀으면 2건) |
| 2 | `CC_TREE` 유형 | 커스텀 컨트롤로 잡혀 있다 (입력 필드가 아니다) |
| 3 | 화면 속성 다음 화면 | `0100` (`0` 아님) |
| 4 | 흐름 로직 | `MODULE` 3줄이 살아 있고 `AT EXIT-COMMAND` 가 PAI 첫 줄이다 |
| 5 | GUI 상태 | `STAT0100` 활성, F3·Shift+F3·F12 에 `BACK`·`EXIT`·`CANC` |
| 6 | GUI 타이틀 | `TIT0100` 활성, 텍스트에 `&1` 이 들어 있다 |
| 7 | 프로그램 활성화 | "모듈 STATUS_0100 없음", "상태 STAT0100 없음" 류 경고가 없다 |
| 8 | 실행 | 창 제목에 회사코드가 보이고, 초록 뒤로 화살표가 활성(회색 아님)이다 |

## §10 오류 대응표

| 증상 | 1순위 원인 | 조치 |
|---|---|---|
| 런타임 오류 — 화면이 존재하지 않음 | 화면 0100 미생성 또는 미활성 | SE51 생성 후 활성화 |
| 런타임 오류 — 상태·타이틀이 존재하지 않음 | `STAT0100`·`TIT0100` 미생성 또는 미활성 | SE41/SE80 에서 생성·활성화 |
| 모달 "CC_TREE 를 찾지 못했습니다" + 빈 화면 | 커스텀 컨트롤 이름 불일치, 또는 입력 필드로 배치됨 | 레이아웃에서 이름·유형 확인 |
| 트리가 떴다가 즉시 사라진다 | 다음 화면 = `0` | 화면 속성에서 `0100` 으로 수정 |
| 툴바의 뒤로·종료 버튼이 회색이다 | `SET PF-STATUS` 누락, 또는 상태에 기능코드 미할당 | `status_0100` 모듈과 SE41 기능 키 확인 |
| 창 제목이 비어 있다 | `SET TITLEBAR` 누락 또는 타이틀 미활성 | `status_0100` 모듈과 `TIT0100` 확인 |
| 두 번째 PBO 에서 툴바·제목이 사라진다 | `SET PF-STATUS`·`SET TITLEBAR` 를 `IF go_tree IS INITIAL` 안에 넣었다 | `IF` 바깥으로 옮긴다 |
| F3 를 눌러도 닫히지 않는다 | 기능코드 `BACK` 미할당, 또는 `AT EXIT-COMMAND` 줄 누락 + 기능유형 `E` | 상태의 기능코드와 흐름 로직 PAI 첫 줄 확인 |
| 2회차 실행에서 컨테이너 생성 실패 | `START-OF-SELECTION` 선두의 `f_free_tree` 누락 | 초기화 코드 확인 |
| 노드가 2배로 보인다 | PBO 의 `IF go_tree IS INITIAL` 누락 | `status_0100` 모듈 확인 |
| 첫 화면이 한참 안 뜬다 | 노드 수가 많다(리프 7,339 → `add_node` 7천여 회) | 정상. 조건을 좁히거나 `P_MAXROW` 로 상한 관리 |
| 빈 화면에 툴바만 보인다 | `f_build_tree` 가 중간에 `RETURN` 했다 | 직전에 뜬 모달 메시지 내용으로 단계 판별 |

## §11 의도적으로 넣지 않은 것

| # | 항목 | 이유 |
|---|---|---|
| 1 | 메뉴 바 항목 | 시스템·도움말 메뉴로 충분하다. 조회 전용이라 고유 메뉴가 없다 |
| 2 | 애플리케이션 툴바 버튼 | 전개·축소·내보내기·인쇄·필터는 ALV 트리 컨트롤 툴바에 이미 있다 |
| 3 | OK 코드 필드 | 요소 목록 편집 단계를 줄이기 위해. `SY-UCOMM` 직독 + `CLEAR` 로 대체 (§2.7) |
| 4 | MM03 전용 툴바 버튼 | 선택 노드 판정 로직이 추가로 필요하다. 더블클릭으로 대체 (`spec.md` §12) |
| 5 | 두 번째 화면·팝업 | v1 범위 밖. 조회 전용이라 확인 팝업이 필요 없다 |
| 6 | 제목에 조회 건수 표시 | 타이틀 70자 제한으로 잘린다. 건수는 상태바 메시지로 보낸다 |

## §12 변경 이력

| 일자 | 변경 | 이유 |
|---|---|---|
| 2026-10-01 | 초판 — 커스텀 컨트롤 `CC_TREE` + 푸시버튼 `BT_BACK`, GUI 상태·타이틀 없음 | SE41 작업을 피해 수작업 오브젝트를 1개로 줄이려 했다 |
| 2026-10-01 | **개정 — GUI 상태 `STAT0100` + 타이틀 `TIT0100` 추가, 푸시버튼 불필요로 변경** | 상태·타이틀이 없으면 F3 가 먹지 않고 창 제목이 비어 실사용이 불가하다. `practice/error-patterns.md` **PROC-005** 로 등록 |
