*&---------------------------------------------------------------------*
*& Report ZSD_SALES_ALV01
*&---------------------------------------------------------------------*
*& 판매조직별 판매실적 ALV (샘플) / Sample ALV by sales org
*& 시스템 전제: SAP_BASIS 750, CL_SALV_TABLE 사용
*& 패키지: ZSD01, 메시지 클래스: ZSD_MSG(별도 SE91 생성)
*& 복사 순서: ① SE91 ZSD_MSG 001 등록 ② SE38 본 프로그램 생성·붙여넣기
*&---------------------------------------------------------------------*
REPORT zsd_sales_alv01 NO STANDARD PAGE HEADING
  LINE-SIZE 220 LINE-COUNT 65.

"! 타입 정의 / Type definitions
TYPES: BEGIN OF ty_sales,
         vbeln TYPE vbak-vbeln,
         erdat TYPE vbak-erdat,
         kunnr TYPE vbak-kunnr,
         name1 TYPE kna1-name1,
         netwr TYPE vbap-netwr,
         waerk TYPE vbak-waerk,
       END OF ty_sales.

DATA: gt_sales TYPE STANDARD TABLE OF ty_sales,
      gs_sales TYPE ty_sales.

"! 선택화면 / Selection screen
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_vkorg TYPE vbak-vkorg OBLIGATORY DEFAULT '1000'.
  SELECT-OPTIONS: s_erdat FOR gs_sales-erdat DEFAULT '20240101' TO '20241231'.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.
  PERFORM frm_get_data.
  PERFORM frm_show_alv.

*&---------------------------------------------------------------------*
*& Form FRM_GET_DATA
*&---------------------------------------------------------------------*
FORM frm_get_data.
  SELECT a~vbeln a~erdat a~kunnr c~name1 b~netwr a~waerk
    INTO TABLE gt_sales
    FROM vbak AS a
    INNER JOIN vbap AS b ON a~vbeln = b~vbeln
    LEFT OUTER JOIN kna1 AS c ON a~kunnr = c~kunnr
    WHERE a~vkorg = p_vkorg
      AND a~erdat IN s_erdat.

  IF sy-subrc <> 0.
    MESSAGE s001(zsd_msg) DISPLAY LIKE 'S'.
    " TODO(GUI): SE91 ZSD_MSG 001 = '조건에 맞는 데이터가 없습니다.'
    RETURN.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form FRM_SHOW_ALV
*&---------------------------------------------------------------------*
FORM frm_show_alv.
  DATA: lo_salv TYPE REF TO cl_salv_table,
        lx_msg  TYPE REF TO cx_salv_msg.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_salv
        CHANGING  t_table      = gt_sales ).
      lo_salv->get_functions( )->set_all( abap_true ).
      lo_salv->get_display_settings( )->set_list_header( 'Sales by org'(002) ).
      lo_salv->display( ).
    CATCH cx_salv_msg INTO lx_msg.
      MESSAGE e002(zsd_msg) DISPLAY LIKE 'E'.
      " TODO(GUI): SE91 ZSD_MSG 002 = 'ALV 표시 중 오류가 발생했습니다.'
  ENDTRY.
ENDFORM.
