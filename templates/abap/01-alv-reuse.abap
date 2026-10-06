*&---------------------------------------------------------------------*
*& Report ZSD_SAMPLE_ALV02
*&---------------------------------------------------------------------*
*& [템플릿] ALV 리포트 골격 — REUSE_ALV_GRID_DISPLAY 방식
*&      / [Template] ALV report skeleton using REUSE_ALV_GRID_DISPLAY
*& 기준: SAP_BASIS 750 / S/4HANA, 모던 ABAP 허용
*&      / Baseline: SAP_BASIS 750 / S/4HANA, modern ABAP allowed
*& 메시지: 텍스트 리터럴 사용 — SE91 생성 불필요 (MSG-002)
*&      / Messages: text literals, no SE91 message class needed
*&
*& 사용법 / How to use:
*&   REUSE 방식은 필드카탈로그를 직접 만들어야 하므로, 컬럼 텍스트·합계·핫스팟을
*&   `frm_build_fieldcat`에서 지정한다. 테이블·필드는 전부 `TODO(교체)` 지점이다.
*&   / Build the field catalog in frm_build_fieldcat; all tables and fields are TODO(교체).
*&
*& 복사 순서 / Copy order:
*&   ① SE38 — 프로그램 생성 (Type=Executable), 본 파일 전체 붙여넣기 (SE91 불필요)
*&   ② Ctrl+F2 Syntax Check → Ctrl+F3 Extended Check → F8 실행
*&---------------------------------------------------------------------*
REPORT zsd_sample_alv02 NO STANDARD PAGE HEADING
  LINE-SIZE 220 LINE-COUNT 65.

"! 전역 타입 / Global ALV types
TYPE-POOLS slis.

"! 테이블 선언 / Table declaration (ERR-006: SELECT-OPTIONS FOR 사전필드에 필수)
TABLES vbak.                                   " TODO(교체): 조회 기준 테이블 / Base table

CONSTANTS gc_max_days TYPE i VALUE 366.        " 조회 일수 상한 / Max date span

TYPES: BEGIN OF ty_out,
         vbeln TYPE vbak-vbeln,                " 판매문서 / Sales document
         erdat TYPE vbak-erdat,                " 생성일 / Created on
         netwr TYPE vbap-netwr,                " 순매출 / Net value
         waerk TYPE vbak-waerk,                " 통화 / Currency
       END OF ty_out.

DATA gt_out      TYPE STANDARD TABLE OF ty_out.
DATA gt_fieldcat TYPE slis_t_fieldcat_alv.
DATA gs_layout   TYPE slis_layout_alv.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS p_vkorg TYPE vbak-vkorg OBLIGATORY.   " TODO(교체)
  SELECT-OPTIONS s_erdat FOR vbak-erdat.           " TODO(교체)
SELECTION-SCREEN END OF BLOCK b1.

"! 입력 검증 / Input validation (ERR-005)
AT SELECTION-SCREEN.
  IF s_erdat-low > s_erdat-high AND s_erdat-high IS NOT INITIAL.
    MESSAGE '시작일이 종료일보다 큽니다. / Start date is later than end date.' TYPE 'E'.
  ENDIF.
  IF s_erdat-high - s_erdat-low > gc_max_days.
    MESSAGE '조회 기간이 상한을 초과했습니다. / Date range exceeds the limit.' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  PERFORM frm_get_data.
  PERFORM frm_build_fieldcat.
  PERFORM frm_show_alv.

*&---------------------------------------------------------------------*
*& Form FRM_GET_DATA — 데이터 조회 / Data selection
*&---------------------------------------------------------------------*
FORM frm_get_data.
  " TODO(교체): 조인·WHERE를 승인된 스펙대로 교체 / Replace joins per the approved spec
  SELECT a~vbeln, a~erdat, b~netwr, a~waerk
    INTO TABLE @gt_out
    FROM vbak AS a
    INNER JOIN vbap AS b ON a~vbeln = b~vbeln
    WHERE a~vkorg = @p_vkorg
      AND a~erdat IN @s_erdat.
  IF sy-subrc <> 0.
    MESSAGE '조건에 맞는 데이터가 없습니다. / No data found.' TYPE 'S'.
    RETURN.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form FRM_BUILD_FIELDCAT — 필드카탈로그 / Field catalog
*&---------------------------------------------------------------------*
FORM frm_build_fieldcat.
  DATA ls_fieldcat TYPE slis_fieldcat_alv.

  CLEAR gt_fieldcat.

  "! 판매문서 — 핫스팟(클릭 시 VA03) / Sales doc with hotspot
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'VBELN'.
  ls_fieldcat-seltext_m = '판매문서'.
  ls_fieldcat-hotspot   = abap_true.
  APPEND ls_fieldcat TO gt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'ERDAT'.
  ls_fieldcat-seltext_m = '생성일'.
  APPEND ls_fieldcat TO gt_fieldcat.

  "! 금액 — 합계 + 통화 참조 / Amount with sum and currency reference
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'NETWR'.
  ls_fieldcat-seltext_m = '순매출'.
  ls_fieldcat-do_sum    = abap_true.
  ls_fieldcat-cfieldname = 'WAERK'.
  APPEND ls_fieldcat TO gt_fieldcat.

  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = 'WAERK'.
  ls_fieldcat-seltext_m = '통화'.
  APPEND ls_fieldcat TO gt_fieldcat.

  gs_layout-colwidth_optimize = abap_true.
  gs_layout-zebra = abap_true.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form FRM_SHOW_ALV — ALV 표시 / ALV display
*&---------------------------------------------------------------------*
FORM frm_show_alv.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      is_layout          = gs_layout
      it_fieldcat        = gt_fieldcat
      i_save             = 'A'
    TABLES
      t_outtab           = gt_out
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
    MESSAGE 'ALV 표시 중 오류가 발생했습니다. / Error while displaying ALV.' TYPE 'E'.
  ENDIF.
ENDFORM.

"!----------------------------------------------------------------------
"! 텍스트 심볼 / Text symbols: TEXT-001 = 조회 조건 / Selection criteria
"!----------------------------------------------------------------------
"! DDIC 정의서 / DDIC appendix — TODO(교체)
"! VBAK-VBELN CHAR 10, VBAK-ERDAT DATS 8, VBAP-NETWR CURR 15,2, VBAK-WAERK CUKY 5
"!----------------------------------------------------------------------
"! SE37 존재 확인 / Verify in SE37: REUSE_ALV_GRID_DISPLAY (표준 FM, 존재 확인 권장)
"!----------------------------------------------------------------------
"! 테스트 절차 / Test procedure (SE38 F8)
"! T1: 대표 조건 → ALV 표시 + 합계 행 / representative input → ALV with totals
"! T2: 결과 0건 조건 → S 메시지 / empty result → S message
"! T3: 기간 상한 초과 → E 메시지 / range over limit → E message
"! 오류 회수: 프로그램명 + 입력값(T1/T2/T3) + 메시지 전문 + ST22 덤프명 + SY-SUBRC
"!----------------------------------------------------------------------
