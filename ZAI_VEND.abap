REPORT zai_vend.

TABLES: kna1, knb1, knvv.

*----------------------------------------------------------------------*
* Event Handler Class Definition
*----------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS: handle_double_click
               FOR EVENT double_click OF cl_gui_alv_grid
               IMPORTING e_row e_column.
ENDCLASS.

*----------------------------------------------------------------------*
* Types
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_output,
         kunnr  TYPE kna1-kunnr,
         name1  TYPE kna1-name1,
         land1  TYPE kna1-land1,
         ort01  TYPE kna1-ort01,
         pstlz  TYPE kna1-pstlz,
         stras  TYPE kna1-stras,
         telf1  TYPE kna1-telf1,
         ktokd  TYPE kna1-ktokd,
         bukrs  TYPE knb1-bukrs,
         zterm  TYPE knb1-zterm,
         akont  TYPE knb1-akont,
         vkorg  TYPE knvv-vkorg,
         vtweg  TYPE knvv-vtweg,
         spart  TYPE knvv-spart,
         kdgrp  TYPE knvv-kdgrp,
         name1t TYPE kna1t-name1,
       END OF ty_output.

*----------------------------------------------------------------------*
* Global Data
*----------------------------------------------------------------------*
DATA: gt_output    TYPE TABLE OF ty_output,
      wa_output    TYPE ty_output,
      go_container TYPE REF TO cl_gui_custom_container,
      go_grid      TYPE REF TO cl_gui_alv_grid,
      go_handler   TYPE REF TO lcl_event_handler,
      ok_code      TYPE sy-ucomm.

*----------------------------------------------------------------------*
* Macro for Field Catalog
*----------------------------------------------------------------------*
DEFINE add_field.
  CLEAR wa_fcat.
  wa_fcat-fieldname = &1.
  wa_fcat-coltext   = &2.
  wa_fcat-outputlen = &3.
  wa_fcat-just      = &4.
  APPEND wa_fcat TO lt_fcat.
END-OF-DEFINITION.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_bukrs FOR knb1-bukrs OBLIGATORY,
                  s_kunnr FOR kna1-kunnr,
                  s_name1 FOR kna1-name1.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  SELECT-OPTIONS: s_land1 FOR kna1-land1,
                  s_ort01 FOR kna1-ort01,
                  s_kdgrp FOR knvv-kdgrp,
                  s_vkorg FOR knvv-vkorg,
                  s_ktokd FOR kna1-ktokd.
SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------------*
* Start of Selection
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM fetch_data.
  IF gt_output IS INITIAL.
    MESSAGE '조회 결과가 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.
  CALL SCREEN 100.

*----------------------------------------------------------------------*
* PBO Module
*----------------------------------------------------------------------*
MODULE pbo_0100 OUTPUT.
  SET PF-STATUS 'MAIN100'.
  SET TITLEBAR 'T100'.
  IF go_container IS INITIAL.
    PERFORM create_alv.
  ENDIF.
ENDMODULE.

*----------------------------------------------------------------------*
* PAI Module
*----------------------------------------------------------------------*
MODULE pai_0100 INPUT.
  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      PERFORM free_alv.
      LEAVE SCREEN 0.
  ENDCASE.
ENDMODULE.

*----------------------------------------------------------------------*
* Event Handler Implementation
*----------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.
  METHOD handle_double_click.
    READ TABLE gt_output INTO wa_output INDEX e_row-index.
    IF sy-subrc = 0.
      SET PARAMETER ID 'BU_PARTNER' FIELD wa_output-kunnr.
      CALL TRANSACTION 'BP' AND SKIP FIRST SCREEN.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Form: Fetch Data
*----------------------------------------------------------------------*
FORM fetch_data.
  SELECT a~kunnr a~name1 a~land1 a~ort01 a~pstlz
         a~stras a~telf1 a~ktokd
         b~bukrs b~zterm b~akont
         c~vkorg c~vtweg c~spart c~kdgrp
         d~name1 AS name1t
    INTO CORRESPONDING FIELDS OF TABLE gt_output
    FROM kna1 AS a
    INNER JOIN knb1  AS b ON a~kunnr = b~kunnr
    LEFT JOIN  knvv  AS c ON a~kunnr = c~kunnr
    LEFT JOIN  kna1t AS d ON a~kunnr = d~kunnr
                          AND d~spras = sy-langu
   WHERE b~bukrs IN s_bukrs
     AND a~kunnr IN s_kunnr
     AND a~name1 IN s_name1
     AND a~land1 IN s_land1
     AND a~ort01 IN s_ort01
     AND c~kdgrp IN s_kdgrp
     AND c~vkorg IN s_vkorg
     AND a~ktokd IN s_ktokd.

  IF sy-subrc = 0.
    SORT gt_output BY bukrs kunnr ASCENDING.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* Form: Create ALV
*----------------------------------------------------------------------*
FORM create_alv.
  DATA: lt_fcat TYPE lvc_t_fcat,
        wa_fcat TYPE lvc_s_fcat,
        ls_layo TYPE lvc_s_layo.

  CREATE OBJECT go_container
    EXPORTING
      container_name              = 'CUSTOM_CONTAINER'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.
  IF sy-subrc <> 0.
    MESSAGE 'ALV 컨테이너 생성에 실패했습니다.' TYPE 'I'.
    RETURN.
  ENDIF.

  CREATE OBJECT go_grid
    EXPORTING
      i_parent          = go_container
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.
  IF sy-subrc <> 0.
    MESSAGE 'ALV Grid 생성에 실패했습니다.' TYPE 'I'.
    RETURN.
  ENDIF.

  add_field 'KUNNR'  '고객번호'       10 'L'.
  add_field 'NAME1'  '고객명'         30 'L'.
  add_field 'LAND1'  '국가'            5 'L'.
  add_field 'ORT01'  '도시'           20 'L'.
  add_field 'PSTLZ'  '우편번호'       10 'L'.
  add_field 'STRAS'  '주소'           35 'L'.
  add_field 'TELF1'  '전화번호'       16 'L'.
  add_field 'KTOKD'  '계정그룹'        8 'L'.
  add_field 'BUKRS'  '회사코드'        6 'L'.
  add_field 'ZTERM'  '지급조건'        8 'L'.
  add_field 'AKONT'  '조정계정'       10 'L'.
  add_field 'VKORG'  '판매조직'        6 'L'.
  add_field 'VTWEG'  '유통채널'        6 'L'.
  add_field 'SPART'  '제품군'          4 'L'.
  add_field 'KDGRP'  '고객그룹'        4 'L'.
  add_field 'NAME1T' '고객명(다국어)' 30 'L'.

  ls_layo-zebra      = 'X'.
  ls_layo-cwidth_opt = 'X'.

  CREATE OBJECT go_handler.
  SET HANDLER go_handler->handle_double_click FOR go_grid.

  CALL METHOD go_grid->set_table_for_first_display
    EXPORTING
      is_layout                     = ls_layo
    CHANGING
      it_outtab                     = gt_output
      it_fieldcatalog               = lt_fcat
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
    MESSAGE 'ALV 출력 중 오류가 발생했습니다.' TYPE 'I'.
  ENDIF.
ENDFORM.

*----------------------------------------------------------------------*
* Form: Free ALV
*----------------------------------------------------------------------*
FORM free_alv.
  IF go_grid IS NOT INITIAL.
    CALL METHOD go_grid->free.
    FREE go_grid.
  ENDIF.
  IF go_container IS NOT INITIAL.
    CALL METHOD go_container->free.
    FREE go_container.
  ENDIF.
ENDFORM.
