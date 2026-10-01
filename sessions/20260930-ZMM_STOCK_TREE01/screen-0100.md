# 화면 0100 정의서 — ZMM_STOCK_TREE01

> 작성 2026-10-01 / 세션 `20260930-ZMM_STOCK_TREE01`
> 근거: `practice/error-patterns.md` **PROC-004** — ALV 트리 컨트롤은 Dynpro 커스텀 컨트롤에서만 표시된다.
> 이 화면은 **조회 결과 표시 전용**이다. 입력 필드·저장 로직은 없다.

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
| GUI 상태 / GUI status | 없음 (SE41 작업 없음) |
| 타이틀바 / Title bar | 없음 |
| 화면 수 | 1개. 팝업·서브스크린·탭스트립 없음 |

**다음 화면을 `0`으로 두면 안 된다.** `0` 이면 첫 PAI 가 끝나는 즉시 화면이 닫혀서, 트리가 떴다가 바로 사라진다. SE51 에서 생성 시 비워두면 자기 번호(`0100`)가 자동으로 채워지므로 그대로 두면 된다.

## §2 요소 목록 (Element list)

요소는 **2개뿐**이다. 입력 필드, OK 코드 필드, 테이블 컨트롤, 프레임은 두지 않는다.
아래 표는 SE51 → 화면 0100 → **요소 목록** 탭의 목표 상태다. 레이아웃 편집기에서 요소를 배치하면 이 값들이 채워지며, 값이 다르면 요소 목록에서 직접 고친다. 표에 없는 칼럼은 **전부 기본값(공란·미체크)** 으로 둔다.

### 2.1 일반 속성 탭 (General attributes)

| 이름 Name | 유형 Type | 수정그룹 1~4 | 라인 Line | 칼럼 Col | 정의길이 DLen | 표시길이 VisLen | 높이 Hght |
|---|---|---|---|---|---|---|---|
| `BT_BACK` | 푸시버튼 (PushButton) | 공란 | 1 | 1 | 20 | 20 | 1 |
| `CC_TREE` | 커스텀 컨트롤 (Custom Control) | 공란 | 2 | 1 | 80 | 80 | 22 |

- 두 요소 모두 DDIC 참조가 없다. 사전 참조(From Dict.) 체크하지 않는다.
- `CC_TREE` 의 DLen·Hght 가 곧 트리가 그려지는 영역 크기다. 크게 잡아도 무해하다(화면 폭 한계까지).
- 라인·칼럼·크기는 동작에 영향이 없다. **이름과 유형만 정확해야 한다.**

### 2.2 텍스트 / 입출력 템플릿 탭 (Texts / I/O templates)

| 이름 | 텍스트 Text | 아이콘 Icon | 빠른 정보 Quick info |
|---|---|---|---|
| `BT_BACK` | `뒤로 / Back` | 공란 | `선택화면으로 돌아갑니다 / Back to selection screen` |
| `CC_TREE` | 공란 | 공란 | 공란 |

아이콘을 쓰고 싶으면 `ICON_BACK` 을 넣어도 된다. 필수 아니다.

### 2.3 특수 속성 탭 (Special attributes)

| 이름 | 기능코드 FctCode | 기능유형 FctType | 입력 Input | 출력 Output |
|---|---|---|---|---|
| `BT_BACK` | **`BACK`** | **공란** | 체크 (기본값) | 체크 (기본값) |
| `CC_TREE` | — | — | 해당 없음 | 해당 없음 |

- **기능코드 `BACK` 이 비면 버튼을 눌러도 PAI 가 돌지 않아 화면이 닫히지 않는다.**
- **기능유형을 `E`(Exit command)로 두면 `AT EXIT-COMMAND` 로 분기한다.** 이 프로그램에는 그 블록이 없으므로 역시 닫히지 않는다. 반드시 공란이다.
- 푸시버튼의 입력(Input) 속성은 기본값이 체크다. 해제하면 클릭이 안 된다.

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
| `BT_BACK` 의 기능코드 `BACK` | `MODULE user_command_0100` 의 `WHEN 'BACK' OR 'EXIT' OR 'CANC'` | 버튼을 눌러도 화면이 닫히지 않는다 |
| 화면번호 `0100` | `CALL SCREEN 0100`, `MODULE status_0100` | 런타임 오류(화면 없음) |

요소 **이름**이 계약이고, 텍스트·위치·크기는 바꿔도 동작에 영향이 없다.

### 2.6 OK 코드 필드를 두지 않는 이유

OK 코드 필드(예: `GV_OKCODE`)를 요소 목록에 추가하는 것이 교과서적이지만, 요소 목록 편집이 한 단계 더 늘고 이름을 틀릴 여지가 생긴다. 대신 `MODULE user_command_0100` 에서 `SY-UCOMM` 을 직접 읽고 **읽은 직후 `CLEAR` 한다.** 비우지 않으면 다음 실행의 첫 PAI 에서 이전 `BACK` 이 그대로 다시 처리된다.

```abap
  lv_ucomm = sy-ucomm.
  CLEAR sy-ucomm.
```

OK 코드 필드를 **꼭 두고 싶다면** 요소 목록에 아래 1행을 추가하고, 프로그램에 `DATA gv_okcode TYPE sy-ucomm.` 을 선언한 뒤 PAI 에서 `sy-ucomm` 대신 `gv_okcode` 를 읽으면 된다. 기능은 동일하다.

| 이름 | 유형 | 라인 | 칼럼 | DLen | 비고 |
|---|---|---|---|---|---|
| `GV_OKCODE` | OK 코드 (OK) | 임의 | 임의 | 20 | 화면 속성의 "OK" 필드로 지정 |

### 2.7 크기 조정 (권장, 선택 사항)

기본 상태에서는 창을 최대화해도 트리 영역이 painted 크기(22 × 80)에 고정된다. 넓게 쓰려면:

1. 화면 속성 → 기타 속성 → "크기 조정 가능(Resizable)" 체크 후 최소 라인·칼럼 입력
2. `CC_TREE` 요소 속성 → 크기 조정(Resizing) → 수직·수평 모두 체크

릴리스에 따라 항목 이름이 조금 다르다. 찾기 어려우면 건너뛰어도 기능에는 영향이 없다.

## §3 흐름 로직 (Flow logic)

SE51 이 화면을 생성하면 아래 4줄이 **주석 상태로 자동 생성**된다. 모듈 이름도 코드와 같다. **`*` 만 지우면 끝이다.**

```text
PROCESS BEFORE OUTPUT.
  MODULE status_0100.

PROCESS AFTER INPUT.
  MODULE user_command_0100.
```

| 블록 | 모듈 | 하는 일 |
|---|---|---|
| PBO | `status_0100` | `go_tree` 가 비어 있을 때만 `f_build_tree` 호출 — 두 번째 PBO 에서 다시 만들면 노드가 중복된다 |
| PAI | `user_command_0100` | `SY-UCOMM` 읽고 비운 뒤 `BACK`·`EXIT`·`CANC` 면 `f_free_tree` + `LEAVE TO SCREEN 0` |

`AT EXIT-COMMAND` 는 쓰지 않는다. 따라서 `BT_BACK` 의 기능유형(FctType)은 **공란**이어야 한다. `E` 로 두면 PAI 모듈이 호출되지 않아 화면이 닫히지 않는다.

## §4 PBO — 트리 생성 순서

`f_build_tree` 내부 순서다. 각 단계 실패 시 모달 메시지 + `RETURN` 이므로, 화면은 `BT_BACK` 만 있는 빈 상태로 남는다(조작 불능 상태가 되지 않는다).

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

## §5 이벤트·전환

| # | 사용자 조작 | 처리 경로 | 결과 |
|---|---|---|---|
| 1 | 선택화면에서 F8 | `START-OF-SELECTION` → 조회·집계 → `CALL SCREEN 0100` | 트리 화면. 상태바에 `플랜트 n / 재고 n 건 / 표시 n 행` |
| 2 | 노드 전개·축소 | ALV 트리 컨트롤 자체 처리 | 화면 유지 |
| 3 | 트리 툴바(전개·축소·내보내기·인쇄) | 컨트롤 자체 처리 | 화면 유지 |
| 4 | **자재 노드 더블클릭** | 컨트롤 이벤트 → `lcl_handler` → `gt_nodemap` 조회 → `SET PARAMETER ID 'MAT'` → `CALL TRANSACTION 'MM03' AND SKIP FIRST SCREEN` | MM03 조회. 뒤로 나오면 트리로 복귀 |
| 5 | 폴더 노드(1~4단) 더블클릭 | 같은 핸들러. `gt_nodemap` 에 없으므로 `RETURN` | 아무 일 없음 (의도된 동작) |
| 6 | `BT_BACK` 클릭 | PAI → `f_free_tree` → `LEAVE TO SCREEN 0` | 선택화면 복귀 |
| 7 | 선택화면에서 다시 F8 | `START-OF-SELECTION` 선두의 `f_free_tree` + 전역 `CLEAR` | 2회차도 동일하게 표시 |

F3·Shift+F3·F12 는 GUI 상태가 없어 **동작하지 않는다.** 종료는 `BT_BACK` 버튼으로 한다. 코드의 `CASE` 에 `EXIT`·`CANC` 를 함께 둔 것은, 나중에 GUI 상태를 추가하면 수정 없이 동작하도록 미리 받아둔 것이다.

## §6 생성 절차 (순서대로)

```text
① SE80 → 프로그램 ZMM_STOCK_TREE01 → 우클릭 → 생성 → 화면
     (또는 SE51 → 프로그램·화면번호 0100 → 생성)
② 속성 : 짧은 설명 입력, 화면 유형 = 일반 화면, 다음 화면 = 0100
③ 레이아웃 → 푸시버튼 배치 → 이름 BT_BACK, 텍스트, 기능코드 BACK
④ 레이아웃 → 커스텀 컨트롤 배치 → 이름 CC_TREE, 라인 2부터 화면 전체
⑤ 흐름 로직 → 자동 생성된 MODULE 2줄의 주석(*) 제거
⑥ 화면 활성화
⑦ 프로그램(SE38) 구문검사 → 활성화
⑧ F8 실행
```

## §7 활성화 후 점검 체크리스트

| # | 확인 | 기준 |
|---|---|---|
| 1 | SE51 요소 목록 | `BT_BACK`, `CC_TREE` 2건이 보인다 |
| 2 | `CC_TREE` 유형 | 커스텀 컨트롤로 잡혀 있다 (입력 필드가 아니다) |
| 3 | `BT_BACK` 기능코드 | `BACK` 이 들어가 있다. 기능유형은 공란 |
| 4 | 화면 속성 다음 화면 | `0100` (`0` 아님) |
| 5 | 흐름 로직 | `MODULE` 2줄의 주석이 풀려 있다 |
| 6 | 프로그램 활성화 | "모듈 STATUS_0100 없음" 류 경고가 없다 |

## §8 오류 대응표

| 증상 | 1순위 원인 | 조치 |
|---|---|---|
| 런타임 오류 — 화면이 존재하지 않음 | 화면 0100 미생성 또는 미활성 | SE51 생성 후 활성화 |
| 모달 "CC_TREE 를 찾지 못했습니다" + 빈 화면 | 커스텀 컨트롤 이름 불일치, 또는 입력 필드로 배치됨 | 레이아웃에서 이름·유형 확인 |
| 트리가 떴다가 즉시 사라진다 | 다음 화면 = `0` | 화면 속성에서 `0100` 으로 수정 |
| `BT_BACK` 을 눌러도 닫히지 않는다 | 기능코드 미입력, 또는 기능유형 `E` | 기능코드 `BACK`, 기능유형 공란 |
| 2회차 실행에서 컨테이너 생성 실패 | `START-OF-SELECTION` 선두의 `f_free_tree` 누락 | §5-7 의 초기화 코드 확인 |
| 노드가 2배로 보인다 | PBO 의 `IF go_tree IS INITIAL` 누락 | `status_0100` 모듈 확인 |
| 첫 화면이 한참 안 뜬다 | 노드 수가 많다(리프 7,339 → `add_node` 7천여 회) | 정상. 조건을 좁히거나 `P_MAXROW` 로 상한 관리 |
| 빈 화면에 버튼만 보인다 | `f_build_tree` 가 중간에 `RETURN` 했다 | 직전에 뜬 모달 메시지 내용으로 단계 판별 |

## §9 의도적으로 넣지 않은 것

| # | 항목 | 이유 |
|---|---|---|
| 1 | GUI 상태(SE41) | 수작업 오브젝트를 1개로 줄이기 위해. 종료는 푸시버튼으로 해결된다 |
| 2 | 타이틀바 | 마찬가지. 창 제목은 기본값을 쓴다 |
| 3 | OK 코드 필드 | 요소 목록 편집 단계를 줄이기 위해. `SY-UCOMM` 직독 + `CLEAR` 로 대체 (§2.2) |
| 4 | MM03 전용 툴바 버튼 | GUI 상태를 부른다. 더블클릭으로 대체 (`spec.md` §12) |
| 5 | 두 번째 화면·팝업 | v1 범위 밖. 조회 전용이라 확인 팝업이 필요 없다 |
