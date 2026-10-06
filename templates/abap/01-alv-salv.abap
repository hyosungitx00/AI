*&---------------------------------------------------------------------*
*& Report ZSD_SAMPLE_ALV01
*&---------------------------------------------------------------------*
*& [템플릿] ALV 리포트 골격 — CL_SALV_TABLE 방식
*&      / [Template] ALV report skeleton using CL_SALV_TABLE
*& 기준: SAP_BASIS 750 / S/4HANA, 모던 ABAP 허용
*&      / Baseline: SAP_BASIS 750 / S/4HANA, modern ABAP allowed
*& 패키지 / Package: ZSD01, 메시지 클래스 / Message class: ZSD_MSG
*&
*& 사용법 / How to use:
*&   아래 테이블·필드(VBAK/VBAP/KNA1)는 예시다. Gate F 필드맵과 DDIC 수집값으로 전부 교체한다.
*&   / Replace the sample tables and fields with the confirmed field map before use.
*&   교체 지점은 `TODO(교체)` 주석으로 표시되어 있다. / Replacement points are marked TODO(교체).
*&
*& 복사 순서 / Copy order:
*&   ① SE91 — 메시지 클래스 ZSD_MSG 001/002/003 등록 (아래 메시지 정의서 참조)
*&   ② SE38 — 프로그램 생성 (Type=Executable, Status=Test), 본 파일 전체 붙여넣기
*&   ③ Ctrl+F2 Syntax Check → Ctrl+F3 Extended Check → F8 실행
*&---------------------------------------------------------------------*
REPORT zsd_sample_alv01 NO STANDARD PAGE HEADING
  LINE-SIZE 220 LINE-COUNT 65.

"! 테이블 선언 / Table declaration
"! SELECT-OPTIONS ... FOR <사전필드>에는 TABLES 선언이 필수다 (ERR-006)
"! / TABLES is mandatory for SELECT-OPTIONS on a dictionary field
TABLES vbak.                                   " TODO(교체): 조회 기준 테이블 / Base table

"! 상수 — 매직넘버 금지 / Constants, no magic numbers
CONSTANTS gc_max_days TYPE i VALUE 366.        " 조회 일수 상한 / Max date span
CONSTANTS gc_actvt_display TYPE c LENGTH 2 VALUE '03'.

"! 출력 구조 / Output structure
TYPES: BEGIN OF ty_out,
         vbeln TYPE vbak-vbeln,                " 판매문서 / Sales document
         erdat TYPE vbak-erdat,                " 생성일 / Created on
         kunnr TYPE vbak-kunnr,                " 고객 / Customer
         name1 TYPE kna1-name1,                " 고객명 / Customer name
         netwr TYPE vbap-netwr,                " 순매출 / Net value
         waerk TYPE vbak-waerk,                " 통화 / Currency
       END OF ty_out.

DATA gt_out TYPE STANDARD TABLE OF ty_out.

"! 선택화면 S1 / Selection screen S1
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS p_vkorg TYPE vbak-vkorg OBLIGATORY.   " TODO(교체): 필수 조건 / Mandatory key
  SELECT-OPTIONS s_erdat FOR vbak-erdat.           " TODO(교체): 범위 조건 / Range key
SELECTION-SCREEN END OF BLOCK b1.

"! 선택화면 초기값 / Default values (DDIC 무관하게 당월로 설정)
INITIALIZATION.
  s_erdat-sign = 'I'.
  s_erdat-option = 'BT'.
  s_erdat-low = sy-datum(6) && '01'.
  s_erdat-high = sy-datum.
  APPEND s_erdat.

"! 입력 검증 / Input validation (ERR-005: 전건 조회 과부하 방지)
AT SELECTION-SCREEN.
  IF s_erdat-low > s_erdat-high AND s_erdat-high IS NOT INITIAL.
    MESSAGE e003(zsd_msg).
  ENDIF.
  IF s_erdat-high - s_erdat-low > gc_max_days.
    MESSAGE e003(zsd_msg).
  ENDIF.

START-OF-SELECTION.
  PERFORM frm_check_auth.
  PERFORM frm_get_data.
  PERFORM frm_show_alv.

*&---------------------------------------------------------------------*
*& Form FRM_CHECK_AUTH — 권한 체크 / Authority check
*&---------------------------------------------------------------------*
FORM frm_check_auth.
  " TODO(교체): SU53 TRACE로 실제 권한 오브젝트 확인 / Confirm the object via SU53
  AUTHORITY-CHECK OBJECT 'V_VBAK_VKO'
    ID 'VKORG' FIELD p_vkorg
    ID 'ACTVT' FIELD gc_actvt_display.
  IF sy-subrc <> 0.
    MESSAGE e002(zsd_msg) WITH p_vkorg.
    RETURN.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form FRM_GET_DATA — 데이터 조회 / Data selection
*&---------------------------------------------------------------------*
FORM frm_get_data.
  "! 필요한 필드만 조회 / Select only the required fields (SELECT * 금지)
  " TODO(교체): 조인·WHERE를 승인된 스펙대로 교체 / Replace joins per the approved spec
  SELECT a~vbeln, a~erdat, a~kunnr, c~name1, b~netwr, a~waerk
    INTO TABLE @gt_out
    FROM vbak AS a
    INNER JOIN vbap AS b ON a~vbeln = b~vbeln
    LEFT OUTER JOIN kna1 AS c ON a~kunnr = c~kunnr
    WHERE a~vkorg = @p_vkorg
      AND a~erdat IN @s_erdat.
  IF sy-subrc <> 0.
    MESSAGE s001(zsd_msg) DISPLAY LIKE 'S'.
    RETURN.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form FRM_SHOW_ALV — ALV 표시 S2 / ALV display S2
*&---------------------------------------------------------------------*
FORM frm_show_alv.
  DATA lo_salv TYPE REF TO cl_salv_table.
  DATA lx_msg  TYPE REF TO cx_salv_msg.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_salv
        CHANGING  t_table      = gt_out ).
      lo_salv->get_functions( )->set_all( abap_true ).
      lo_salv->get_columns( )->set_optimize( abap_true ).
      lo_salv->get_display_settings( )->set_list_header( TEXT-002 ).
      lo_salv->display( ).
    CATCH cx_salv_msg INTO lx_msg.
      MESSAGE e004(zsd_msg).
  ENDTRY.
ENDFORM.

"!----------------------------------------------------------------------
"! 텍스트 심볼 / Text symbols (SE38 → Goto → Text elements)
"! TEXT-001 = 조회 조건 / Selection criteria
"! TEXT-002 = 조회 결과 / Result list
"!----------------------------------------------------------------------
"! DDIC 정의서 (SE11 확인용) / DDIC appendix — TODO(교체)
"! VBAK-VBELN CHAR 10 (판매문서 / Sales doc), VBAK-ERDAT DATS 8 (생성일 / Created on),
"! VBAK-KUNNR CHAR 10 → KNA1-NAME1 CHAR 35 (고객명 / Customer name),
"! VBAP-NETWR CURR 15,2 (순매출 / Net value), VBAK-WAERK CUKY 5 (통화 / Currency)
"!----------------------------------------------------------------------
"! 메시지 클래스 정의서 (SE91 ZSD_MSG) / Message definitions
"! 001(S): 조건에 맞는 데이터가 없습니다. / No data found for the selection.
"! 002(E): 영업조직 &1 권한이 없습니다. / No authority for sales org &1.
"! 003(E): 조회 기간 입력이 잘못되었습니다. / Invalid date range.
"! 004(E): ALV 표시 중 오류가 발생했습니다. / Error while displaying ALV.
"! SE91 없이 진행하는 건은 MESSAGE '...' TYPE 'E' 리터럴로 대체한다 (MSG-002).
"!----------------------------------------------------------------------
"! 테스트 절차 / Test procedure (SE38 F8)
"! T1: 대표 조건 → ALV 표시 + 건수 확인 / representative input → ALV with row count
"! T2: 결과 0건 조건 → s001 메시지 / empty result → message s001
"! T3: 권한 없는 유저 또는 잘못된 기간 → e002 / e003
"! 오류 회수: 프로그램명 + 입력값(T1/T2/T3) + 메시지 전문 + ST22 덤프명 + SY-SUBRC
"!----------------------------------------------------------------------
