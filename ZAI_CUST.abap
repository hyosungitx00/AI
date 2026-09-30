*&---------------------------------------------------------------------*
*& 파일 위치 : SE38 → 프로그램명 ZAI_CUST → Source Code
*& 프로그램명 : ZAI_CUST
*& 유형      : 1 (Executable Program)
*& 기능명    : 공급업체 관련 테이블을 통해서 데이터 조회
*& 참조 테이블: LFA1, LFB1, LFBK
*& SAP 환경  : S/4HANA On-Premise
*&
*& [Text Elements 등록 필요 - SE38 → Goto → Text Elements → Text Symbols]
*&   001 = 공급업체 조건
*&   002 = 상세 조건
*&---------------------------------------------------------------------*
REPORT zai_cust.

*----------------------------------------------------------------------*
* 테이블 선언 (SELECT-OPTIONS FOR 절 참조용)
*----------------------------------------------------------------------*
TABLES: lfa1,
        lfb1,
        lfbk.

*----------------------------------------------------------------------*
* ALV 이벤트 핸들러 클래스 정의 (더블클릭 → BP 트랜잭션 호출)
*----------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS: handle_double_click
               FOR EVENT double_click OF cl_gui_alv_grid
               IMPORTING e_row e_column.
ENDCLASS.

*----------------------------------------------------------------------*
* 타입 정의
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_output,
         lifnr TYPE lfa1-lifnr,   " 공급업체 번호
         name1 TYPE lfa1-name1,   " 공급업체명
         land1 TYPE lfa1-land1,   " 국가
         ort01 TYPE lfa1-ort01,   " 도시
         pstlz TYPE lfa1-pstlz,   " 우편번호
         stras TYPE lfa1-stras,   " 주소
         telf1 TYPE lfa1-telf1,   " 전화번호
         ktokk TYPE lfa1-ktokk,   " 계정그룹
         bukrs TYPE lfb1-bukrs,   " 회사코드
         zterm TYPE lfb1-zterm,   " 지급조건
         akont TYPE lfb1-akont,   " 조정계정
         banks TYPE lfbk-banks,   " 은행국가
         bankl TYPE lfbk-bankl,   " 은행키
       END OF ty_output.

*----------------------------------------------------------------------*
* 전역 변수
*----------------------------------------------------------------------*
DATA: gt_output    TYPE TABLE OF ty_output,
      wa_output    TYPE ty_output,
      go_container TYPE REF TO cl_gui_custom_container,
      go_grid      TYPE REF TO cl_gui_alv_grid,
      go_handler   TYPE REF TO lcl_event_handler.

*----------------------------------------------------------------------*
* FIELDCAT 매크로
*----------------------------------------------------------------------*
DEFINE add_field.
  CLEAR ls_fieldcat.
  ls_fieldcat-fieldname = &1.
  ls_fieldcat-coltext   = &2.
  ls_fieldcat-ref_table = &3.
  ls_fieldcat-ref_field = &4.
  ls_fieldcat-outputlen = &5.
  ls_fieldcat-just      = &6.
  APPEND ls_fieldcat TO lt_fieldcat.
END-OF-DEFINITION.

*----------------------------------------------------------------------*
* Selection Screen
* ※ TEXT-001, TEXT-002는 SE38 → Text Elements에 등록 필요
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS:     p_bukrs TYPE lfb1-bukrs OBLIGATORY.
  SELECT-OPTIONS: s_lifnr FOR lfa1-lifnr.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.
  SELECT-OPTIONS: s_name1 FOR lfa1-name1,
                  s_land1 FOR lfa1-land1,
                  s_ktokk FOR lfa1-ktokk.
SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------------*
* START-OF-SELECTION
*----------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM fetch_data.

  IF gt_output IS INITIAL.
    MESSAGE '조회 결과가 없습니다.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  CALL SCREEN 100.

*----------------------------------------------------------------------*
* Screen 100 PBO 모듈
*----------------------------------------------------------------------*
MODULE pbo_0100 OUTPUT.
  SET PF-STATUS 'STATUS_100'.
  SET TITLEBAR 'TITLE_100'.

  IF go_container IS INITIAL.
    PERFORM create_alv.
  ENDIF.
ENDMODULE.

*----------------------------------------------------------------------*
* Screen 100 PAI 모듈
*----------------------------------------------------------------------*
MODULE pai_0100 INPUT.
  DATA: lv_ok_code TYPE sy-ucomm.
  lv_ok_code = sy-ucomm.
  CLEAR sy-ucomm.

  CASE lv_ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      PERFORM free_alv.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.

*----------------------------------------------------------------------*
* 이벤트 핸들러 구현
*----------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.
  METHOD handle_double_click.
    READ TABLE gt_output INTO wa_output INDEX e_row-index.
    IF sy-subrc <> 0 OR wa_output-lifnr IS INITIAL.
      RETURN.
    ENDIF.

    " BP 트랜잭션 호출
    " ※ BP는 Business Partner GUID 기반이므로 실제 환경에서 파라미터 ID 확인 필요
    "   대안: FK03 사용 시 → SET PARAMETER ID 'LIF' / CALL TRANSACTION 'FK03'
    SET PARAMETER ID 'LIF' FIELD wa_output-lifnr.
    CALL TRANSACTION 'BP' AND SKIP FIRST SCREEN.
  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*& FORM: fetch_data
*&---------------------------------------------------------------------*
FORM fetch_data.
  CLEAR: gt_output.

  SELECT a~lifnr
         a~name1
         a~land1
         a~ort01
         a~pstlz
         a~stras
         a~telf1
         a~ktokk
         b~bukrs
         b~zterm
         b~akont
         c~banks
         c~bankl
    INTO TABLE gt_output
    FROM lfa1 AS a
    LEFT JOIN lfb1 AS b ON  a~lifnr = b~lifnr
                        AND b~bukrs = p_bukrs
    LEFT JOIN lfbk AS c ON  a~lifnr = c~lifnr
   WHERE a~lifnr IN s_lifnr
     AND a~name1 IN s_name1
     AND a~land1 IN s_land1
     AND a~ktokk IN s_ktokk
     AND a~loevm = ''.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: create_alv
*&---------------------------------------------------------------------*
FORM create_alv.
  DATA: lt_fieldcat TYPE lvc_t_fcat,
        ls_fieldcat TYPE lvc_s_fcat,
        ls_layout   TYPE lvc_s_layo.

  CREATE OBJECT go_container
    EXPORTING
      container_name = 'CUSTOM_CONTAINER'.

  CREATE OBJECT go_grid
    EXPORTING
      i_parent = go_container.

  ls_layout-grid_title = '공급업체 목록'.
  ls_layout-cwidth_opt = 'X'.
  ls_layout-col_opt    = 'X'.

  add_field 'LIFNR' '공급업체 번호' 'LFA1' 'LIFNR' '10' 'L'.
  add_field 'NAME1' '공급업체명'    'LFA1' 'NAME1' '30' 'L'.
  add_field 'LAND1' '국가'         'LFA1' 'LAND1' ' 3' 'C'.
  add_field 'ORT01' '도시'         'LFA1' 'ORT01' '25' 'L'.
  add_field 'PSTLZ' '우편번호'     'LFA1' 'PSTLZ' '10' 'L'.
  add_field 'STRAS' '주소'         'LFA1' 'STRAS' '35' 'L'.
  add_field 'TELF1' '전화번호'     'LFA1' 'TELF1' '16' 'L'.
  add_field 'KTOKK' '계정그룹'     'LFA1' 'KTOKK' ' 4' 'C'.
  add_field 'BUKRS' '회사코드'     'LFB1' 'BUKRS' ' 4' 'C'.
  add_field 'ZTERM' '지급조건'     'LFB1' 'ZTERM' ' 4' 'C'.
  add_field 'AKONT' '조정계정'     'LFB1' 'AKONT' '10' 'L'.
  add_field 'BANKS' '은행국가'     'LFBK' 'BANKS' ' 3' 'C'.
  add_field 'BANKL' '은행키'       'LFBK' 'BANKL' '15' 'L'.

  CREATE OBJECT go_handler.
  SET HANDLER go_handler->handle_double_click FOR go_grid.

  CALL METHOD go_grid->set_table_for_first_display
    EXPORTING
      is_layout       = ls_layout
    CHANGING
      it_outtab       = gt_output
      it_fieldcatalog = lt_fieldcat.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: free_alv
*&---------------------------------------------------------------------*
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
