*&---------------------------------------------------------------------*
*& Report ZMM_DDIC_PROBE01
*&---------------------------------------------------------------------*
*& 목적 / Purpose
*&   재고 관련 테이블·뷰의 실재 여부와 실제 수량·금액·키 필드명을 출력한다.
*&   Print existence and real quantity/amount/key field names of stock tables.
*&   ZMM_STOCK_TREE01 코드 작성 전 DDIC 가정을 제거하기 위한 임시 점검용이다.
*&   Temporary probe to remove DDIC assumptions before coding ZMM_STOCK_TREE01.
*&
*& 기준 / Baseline: SAP_BASIS 750 / S/4HANA, 모던 ABAP 허용
*& 성격 / Nature  : DDIC 메타데이터만 조회. 업무 데이터 변경·오브젝트 생성 없음.
*&                  Reads DDIC metadata only. No data change, no object creation.
*& 사용 후 / After use: 삭제해도 된다 / may be deleted
*&---------------------------------------------------------------------*
REPORT zmm_ddic_probe01 LINE-SIZE 200 NO STANDARD PAGE HEADING.

TYPES: BEGIN OF ty_target,
         tabname TYPE tabname,                      "! 점검 대상 / target name
         usage   TYPE c LENGTH 60,                  "! 용도 / usage
       END OF ty_target.

DATA: gt_target TYPE STANDARD TABLE OF ty_target WITH EMPTY KEY,
      gt_dfies  TYPE ddfields,
      go_descr  TYPE REF TO cl_abap_typedescr,
      go_struct TYPE REF TO cl_abap_structdescr.

START-OF-SELECTION.

*----------------------------------------------------------------------*
* 점검 대상 목록 / Target list
*----------------------------------------------------------------------*
  gt_target = VALUE #(
    ( tabname = 'MARD'         usage = '저장위치 재고 / Storage location stock' )
    ( tabname = 'NSDM_V_MARD'  usage = 'S/4 호환 뷰(MARD) / S4 compat view' )
    ( tabname = 'MSKA'         usage = '판매오더 재고 / Sales order stock' )
    ( tabname = 'MSPR'         usage = '프로젝트 재고 / Project stock' )
    ( tabname = 'MSKU'         usage = '고객 특별재고 / Customer special stock' )
    ( tabname = 'MKOL'         usage = '공급업체 위탁·포장재 / Vendor consignment' )
    ( tabname = 'MSLB'         usage = '공급업체 보유 재고 / Stock with vendor' )
    ( tabname = 'MBEW'         usage = '자재 평가 / Material valuation' )
    ( tabname = 'NSDM_V_MBEW'  usage = 'S/4 호환 뷰(MBEW) / S4 compat view' )
    ( tabname = 'MARA'         usage = '자재 마스터 / Material master' )
    ( tabname = 'MAKT'         usage = '자재 내역 / Material description' )
    ( tabname = 'MARC'         usage = '자재 플랜트 데이터 / Material plant data' )
    ( tabname = 'T001'         usage = '회사코드 / Company code' )
    ( tabname = 'T001K'        usage = '평가영역 / Valuation area' )
    ( tabname = 'T001W'        usage = '플랜트 / Plant' )
    ( tabname = 'T001L'        usage = '저장위치 / Storage location' )
  ).

  WRITE: / '=== DDIC 점검 결과 / DDIC probe result ==='.
  WRITE: / '시스템 / System:', sy-sysid, '  클라이언트 / Client:', sy-mandt,
           '  언어 / Language:', sy-langu.

  LOOP AT gt_target INTO DATA(ls_target).

    ULINE.
    WRITE: / '[', ls_target-tabname, ']', ls_target-usage.

    CLEAR: go_descr, go_struct, gt_dfies.

*   존재 여부 / Existence check
    CALL METHOD cl_abap_typedescr=>describe_by_name
      EXPORTING  p_name         = ls_target-tabname
      RECEIVING  p_descr_ref    = go_descr
      EXCEPTIONS type_not_found = 1.

    IF sy-subrc <> 0 OR go_descr IS NOT BOUND.
      WRITE: /5 '>>> 존재하지 않음 / NOT FOUND'.
      CONTINUE.
    ENDIF.

    TRY.
        go_struct ?= go_descr.
      CATCH cx_sy_move_cast_error.
        WRITE: /5 '>>> 구조형이 아님 / not a structured type'.
        CONTINUE.
    ENDTRY.

*   필드 목록 / Field list
    CALL METHOD go_struct->get_ddic_field_list
      EXPORTING  p_langu      = sy-langu
      RECEIVING  p_field_list = gt_dfies
      EXCEPTIONS not_found    = 1
                 no_ddic_type = 2.

    IF sy-subrc <> 0 OR gt_dfies IS INITIAL.
      WRITE: /5 '>>> DDIC 필드 목록 없음 / no DDIC field list'.
      CONTINUE.
    ENDIF.

*   키 필드 / Key fields
    WRITE: /5 '- 키 필드 / Key fields'.
    LOOP AT gt_dfies INTO DATA(ls_f) WHERE keyflag = abap_true.
      WRITE: /9 ls_f-fieldname, ls_f-rollname, ls_f-datatype, ls_f-fieldtext.
    ENDLOOP.

*   수량 필드 / Quantity fields (DATATYPE = QUAN)
    WRITE: /5 '- 수량 필드 / Quantity fields (QUAN)'.
    LOOP AT gt_dfies INTO ls_f WHERE datatype = 'QUAN'.
      WRITE: /9 ls_f-fieldname, ls_f-rollname, ls_f-fieldtext.
    ENDLOOP.
    IF sy-subrc <> 0.
      WRITE: /9 '(없음 / none)'.
    ENDIF.

*   금액 필드 / Amount fields (DATATYPE = CURR)
    WRITE: /5 '- 금액 필드 / Amount fields (CURR)'.
    LOOP AT gt_dfies INTO ls_f WHERE datatype = 'CURR'.
      WRITE: /9 ls_f-fieldname, ls_f-rollname, ls_f-fieldtext.
    ENDLOOP.
    IF sy-subrc <> 0.
      WRITE: /9 '(없음 / none)'.
    ENDIF.

  ENDLOOP.

  ULINE.
  WRITE: / '=== 끝 / End ==='.
