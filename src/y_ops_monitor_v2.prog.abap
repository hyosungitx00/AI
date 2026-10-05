*&---------------------------------------------------------------------*
*& Report  Y_OPS_MONITOR_V2
*&---------------------------------------------------------------------*
*& 통합 운영 모니터링 (읽기 전용) — SM37 / ST22 / SXI_MONITOR
*& 설계서: docs/design/integrated-ops-monitor-design.md
*& 불변: DML/COMMIT/Enqueue/Update Task/재처리 금지
*&
*& [SE38 붙여넣기]
*&  1) 프로그램 Y_OPS_MONITOR_V2 (Executable) 생성 후 본 소스 전체 붙여넣기
*&  2) Screen 0100: 빈 화면(요소 없음), OK 코드 필드 OK_CODE
*&  3) GUI Status STAT0100 (Screen 0100): 기능키
*&       REFRESH, TOGGLE, STATS, HELP, BACK, EXIT, CANCEL
*&  4) 선택화면 텍스트: SE38 → Goto → Text elements
*&     [Text symbols] 프레임 제목
*&       T01  조회 기간
*&       T02  조회 영역 선택
*&       T03  추가 필터 / 표시 옵션
*&     [Selection texts] 파라미터/셀렉트옵션 라벨
*&       P_FRDAT  시작 일자          P_FRTIM  시작 시간
*&       P_TODAT  종료 일자          P_TOTIM  종료 시간
*&       P_HOURS  조회 범위(시간)
*&       CB_SM37  배치 에러(SM37)    CB_ST22  런타임 에러(ST22)
*&       CB_SXI   인터페이스(SXI)
*&       SO_JOB   잡명               SO_USER  사용자
*&       SO_IFACE 인터페이스명       P_MAND   클라이언트
*&       P_MAXROW 영역별 최대 표시행 P_TOPN   차트 Top-N
*&       P_AUTO   자동 갱신          P_SEC    주기(초)
*&  5) 활성화 (선언부 포함 전체 → 구현 → 활성화)
*&---------------------------------------------------------------------*
REPORT y_ops_monitor_v2.

TYPE-POOLS: icon.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.
PARAMETERS: p_frdat TYPE sy-datum OBLIGATORY,
            p_frtim TYPE sy-uzeit OBLIGATORY,
            p_todat TYPE sy-datum OBLIGATORY,
            p_totim TYPE sy-uzeit OBLIGATORY,
            p_hours TYPE i DEFAULT 24.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-t02.
PARAMETERS: cb_sm37 AS CHECKBOX DEFAULT 'X',
            cb_st22 AS CHECKBOX DEFAULT 'X',
            cb_sxi  AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE text-t03.
SELECT-OPTIONS: so_job   FOR sy-repid,
                so_user  FOR sy-uname,
                so_iface FOR sy-repid.
PARAMETERS: p_mand   TYPE mandt DEFAULT sy-mandt,
            p_maxrow TYPE i DEFAULT 250,
            p_topn   TYPE i DEFAULT 5,
            p_auto   AS CHECKBOX DEFAULT ' ',
            p_sec    TYPE i DEFAULT 60.
SELECTION-SCREEN END OF BLOCK b3.

*----------------------------------------------------------------------*
* Global OK code / app reference
*----------------------------------------------------------------------*
DATA: ok_code TYPE sy-ucomm,
      gv_ok   TYPE sy-ucomm.

*----------------------------------------------------------------------*
* Types
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_sel,
         frdat  TYPE sy-datum,
         frtim  TYPE sy-uzeit,
         todat  TYPE sy-datum,
         totim  TYPE sy-uzeit,
         hours  TYPE i,
         sm37   TYPE abap_bool,
         st22   TYPE abap_bool,
         sxi    TYPE abap_bool,
         mandt  TYPE mandt,
         maxrow TYPE i,
         topn   TYPE i,
         auto   TYPE abap_bool,
         sec    TYPE i,
       END OF ty_sel.

TYPES: BEGIN OF ty_batch,
         jobname    TYPE tbtcjob-jobname,
         jobcount   TYPE tbtcjob-jobcount,
         status     TYPE tbtcjob-status,
         progname   TYPE programm,
         sdluname   TYPE sy-uname,
         strtdate   TYPE sy-datum,
         strttime   TYPE sy-uzeit,
         enddate    TYPE sy-datum,
         endtime    TYPE sy-uzeit,
         line_color TYPE char4,
       END OF ty_batch.
TYPES: ty_batch_tab TYPE STANDARD TABLE OF ty_batch WITH DEFAULT KEY.

TYPES: BEGIN OF ty_dump,
         datum      TYPE sy-datum,
         uzeit      TYPE sy-uzeit,
         uname      TYPE sy-uname,
         ahost      TYPE snap_beg-ahost,
         modno      TYPE snap-modno,
         mandt      TYPE snap-mandt,
         rt_error   TYPE char30,
         progname   TYPE programm,
         include    TYPE programm,
         line       TYPE i,
         line_color TYPE char4,
       END OF ty_dump.
TYPES: ty_dump_tab TYPE STANDARD TABLE OF ty_dump WITH DEFAULT KEY.

TYPES: BEGIN OF ty_iface,
         exe_date   TYPE sy-datum,
         exe_time   TYPE sy-uzeit,
         if_name    TYPE char120,
         if_ns      TYPE char120,
         operation  TYPE char120,
         sender     TYPE char120,
         receiver   TYPE char120,
         msgstate   TYPE sxmspmast-msgstate,
         errstat    TYPE sxmsperror-errstat,
         msgguid    TYPE sxmspmast-msgguid,
         pid        TYPE sxmspmast-pid,
         line_color TYPE char4,
       END OF ty_iface.
TYPES: ty_iface_tab TYPE STANDARD TABLE OF ty_iface WITH DEFAULT KEY.

TYPES: BEGIN OF ty_area_status,
         area      TYPE char10,
         title     TYPE char40,
         count     TYPE i,
         auth_ok   TYPE abap_bool,
         error     TYPE abap_bool,
         message   TYPE char120,
         light     TYPE char1,
         color_hex TYPE char7,
         alv_color TYPE char4,
       END OF ty_area_status.
TYPES: ty_area_status_tab TYPE STANDARD TABLE OF ty_area_status WITH DEFAULT KEY.

TYPES: BEGIN OF ty_chart_item,
         area  TYPE char10,
         key   TYPE char120,
         count TYPE i,
         color TYPE char7,
       END OF ty_chart_item.
TYPES: ty_chart_tab TYPE STANDARD TABLE OF ty_chart_item WITH DEFAULT KEY.

TYPES: BEGIN OF ty_bucket,
         label TYPE char20,
         sm37  TYPE i,
         st22  TYPE i,
         sxi   TYPE i,
       END OF ty_bucket.
TYPES: ty_bucket_tab TYPE STANDARD TABLE OF ty_bucket WITH DEFAULT KEY.

TYPES: BEGIN OF ty_topn_group,
         area  TYPE char10,
         items TYPE ty_chart_tab,
         maxc  TYPE i,
       END OF ty_topn_group.
TYPES: ty_topn_group_tab TYPE STANDARD TABLE OF ty_topn_group WITH DEFAULT KEY.

CONSTANTS:
  c_area_sm37 TYPE char10 VALUE 'SM37',
  c_area_st22 TYPE char10 VALUE 'ST22',
  c_area_sxi  TYPE char10 VALUE 'SXI',
  c_col_sm37  TYPE char7  VALUE '#26A69A',
  c_col_st22  TYPE char7  VALUE '#EF5350',
  c_col_sxi   TYPE char7  VALUE '#FFA726',
  c_alv_sm37  TYPE char4  VALUE 'C400',
  c_alv_st22  TYPE char4  VALUE 'C600',
  c_alv_sxi   TYPE char4  VALUE 'C700',
  c_status_a  TYPE tbtcjob-status VALUE 'A',
  c_sm37_red  TYPE i VALUE 1,
  c_st22_yel  TYPE i VALUE 1,
  c_st22_red  TYPE i VALUE 31,
  c_sxi_yel   TYPE i VALUE 1,
  c_sxi_red   TYPE i VALUE 51,
  c_persp_top TYPE char1 VALUE 'T',
  c_persp_tim TYPE char1 VALUE 'H',
  c_def_max   TYPE i VALUE 250,
  c_def_topn  TYPE i VALUE 5,
  c_def_hours TYPE i VALUE 24.

*----------------------------------------------------------------------*
* Forward declarations
*----------------------------------------------------------------------*
CLASS lcl_util DEFINITION DEFERRED.
CLASS lcl_dp_batch DEFINITION DEFERRED.
CLASS lcl_dp_dump DEFINITION DEFERRED.
CLASS lcl_dp_interface DEFINITION DEFERRED.
CLASS lcl_aggregator DEFINITION DEFERRED.
CLASS lcl_navigator DEFINITION DEFERRED.
CLASS lcl_ui_dashboard DEFINITION DEFERRED.
CLASS lcl_controller DEFINITION DEFERRED.

DATA: go_controller TYPE REF TO lcl_controller.

*----------------------------------------------------------------------*
* Interface
*----------------------------------------------------------------------*
INTERFACE lif_mon_data_provider.
  METHODS get_area_info
    EXPORTING
      ev_area  TYPE char10
      ev_title TYPE char40
      ev_color TYPE char7
      ev_alv   TYPE char4.
  METHODS get_data
    IMPORTING
      is_sel     TYPE ty_sel
    EXPORTING
      ev_count   TYPE i
      ev_auth_ok TYPE abap_bool
      ev_error   TYPE abap_bool
      ev_message TYPE char120.
ENDINTERFACE.

*----------------------------------------------------------------------*
* Utility
*----------------------------------------------------------------------*
CLASS lcl_util DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS apply_hours_to_range
      IMPORTING iv_hours TYPE i
      EXPORTING ev_frdat TYPE sy-datum
                ev_frtim TYPE sy-uzeit
                ev_todat TYPE sy-datum
                ev_totim TYPE sy-uzeit.
    CLASS-METHODS local_to_utc_tstmp
      IMPORTING iv_date TYPE sy-datum
                iv_time TYPE sy-uzeit
      RETURNING VALUE(rv_ts) TYPE timestampl.
    CLASS-METHODS utc_tstmp_to_local
      IMPORTING iv_ts TYPE timestampl
      EXPORTING ev_date TYPE sy-datum
                ev_time TYPE sy-uzeit.
    CLASS-METHODS html_escape
      IMPORTING iv_text TYPE clike
      RETURNING VALUE(rv_text) TYPE string.
    CLASS-METHODS light_for_area
      IMPORTING iv_area  TYPE char10
                iv_count TYPE i
      RETURNING VALUE(rv_light) TYPE char1.
    CLASS-METHODS health_label
      IMPORTING it_status TYPE ty_area_status_tab
      RETURNING VALUE(rv_label) TYPE char20.
    CLASS-METHODS health_label_ko
      IMPORTING iv_health TYPE clike
      RETURNING VALUE(rv_label) TYPE char20.
    CLASS-METHODS light_label_ko
      IMPORTING iv_light TYPE char1
      RETURNING VALUE(rv_label) TYPE char10.
    CLASS-METHODS short_status
      IMPORTING iv_text TYPE clike
                iv_count TYPE i OPTIONAL
                iv_error TYPE abap_bool OPTIONAL
                iv_auth_ok TYPE abap_bool OPTIONAL
      RETURNING VALUE(rv_text) TYPE char60.
    CLASS-METHODS icon_for_light
      IMPORTING iv_light TYPE char1
      RETURNING VALUE(rv_icon) TYPE icon_d.
ENDCLASS.

CLASS lcl_util IMPLEMENTATION.
  METHOD apply_hours_to_range.
    DATA: lv_hours TYPE i,
          lv_sec   TYPE i,
          lv_ts    TYPE timestampl.
    lv_hours = iv_hours.
    IF lv_hours <= 0.
      lv_hours = c_def_hours.
    ENDIF.
    ev_todat = sy-datum.
    ev_totim = sy-uzeit.
    lv_sec = lv_hours * 3600.
    GET TIME STAMP FIELD lv_ts.
    TRY.
        lv_ts = cl_abap_tstmp=>subtractsecs( tstmp = lv_ts secs = lv_sec ).
      CATCH cx_parameter_invalid_range cx_parameter_invalid_type.
        ev_frdat = sy-datum - 1.
        ev_frtim = sy-uzeit.
        RETURN.
    ENDTRY.
    CONVERT TIME STAMP lv_ts TIME ZONE sy-zonlo
      INTO DATE ev_frdat TIME ev_frtim.
  ENDMETHOD.

  METHOD local_to_utc_tstmp.
    DATA lv_ts TYPE timestampl.
    CONVERT DATE iv_date TIME iv_time INTO TIME STAMP lv_ts TIME ZONE sy-zonlo.
    rv_ts = lv_ts.
  ENDMETHOD.

  METHOD utc_tstmp_to_local.
    CLEAR: ev_date, ev_time.
    CHECK iv_ts IS NOT INITIAL.
    CONVERT TIME STAMP iv_ts TIME ZONE sy-zonlo
      INTO DATE ev_date TIME ev_time.
  ENDMETHOD.

  METHOD html_escape.
    rv_text = iv_text.
    REPLACE ALL OCCURRENCES OF '&' IN rv_text WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN rv_text WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN rv_text WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF '"' IN rv_text WITH '&quot;'.
  ENDMETHOD.

  METHOD light_for_area.
    CASE iv_area.
      WHEN c_area_sm37.
        IF iv_count >= c_sm37_red.
          rv_light = 'R'.
        ELSE.
          rv_light = 'G'.
        ENDIF.
      WHEN c_area_st22.
        IF iv_count >= c_st22_red.
          rv_light = 'R'.
        ELSEIF iv_count >= c_st22_yel.
          rv_light = 'Y'.
        ELSE.
          rv_light = 'G'.
        ENDIF.
      WHEN c_area_sxi.
        IF iv_count >= c_sxi_red.
          rv_light = 'R'.
        ELSEIF iv_count >= c_sxi_yel.
          rv_light = 'Y'.
        ELSE.
          rv_light = 'G'.
        ENDIF.
      WHEN OTHERS.
        rv_light = 'G'.
    ENDCASE.
  ENDMETHOD.

  METHOD health_label.
    DATA: lv_has_r TYPE abap_bool,
          lv_has_y TYPE abap_bool,
          lv_total TYPE i.
    LOOP AT it_status ASSIGNING FIELD-SYMBOL(<s>).
      lv_total = lv_total + <s>-count.
      IF <s>-light = 'R'.
        lv_has_r = abap_true.
      ELSEIF <s>-light = 'Y'.
        lv_has_y = abap_true.
      ENDIF.
    ENDLOOP.
    IF lv_has_r = abap_true.
      rv_label = 'CRITICAL'.
    ELSEIF lv_has_y = abap_true.
      rv_label = 'WARNING'.
    ELSEIF lv_total = 0.
      rv_label = 'ALL CLEAR'.
    ELSE.
      rv_label = 'STABLE'.
    ENDIF.
  ENDMETHOD.

  METHOD health_label_ko.
    CASE iv_health.
      WHEN 'CRITICAL'.
        rv_label = '위험'.
      WHEN 'WARNING'.
        rv_label = '주의'.
      WHEN 'ALL CLEAR'.
        rv_label = '정상'.
      WHEN OTHERS.
        rv_label = '안정'.
    ENDCASE.
  ENDMETHOD.

  METHOD light_label_ko.
    CASE iv_light.
      WHEN 'R'.
        rv_label = '위험'.
      WHEN 'Y'.
        rv_label = '주의'.
      WHEN OTHERS.
        rv_label = '정상'.
    ENDCASE.
  ENDMETHOD.

  METHOD short_status.
    DATA lv TYPE string.
    IF iv_auth_ok = abap_false AND iv_auth_ok IS SUPPLIED.
      rv_text = '권한 없음'.
      RETURN.
    ENDIF.
    IF iv_error = abap_true.
      lv = iv_text.
      IF lv CS 'PARAM_NOT_FOUND' OR lv CS 'CX_SY_DYN_CALL'.
        rv_text = '조회 FM 호출 실패'.
      ELSEIF strlen( lv ) > 40.
        rv_text = lv(40) && '...'.
      ELSE.
        rv_text = lv.
      ENDIF.
      IF rv_text IS INITIAL.
        rv_text = '조회 오류'.
      ENDIF.
      RETURN.
    ENDIF.
    IF iv_text IS NOT INITIAL.
      rv_text = iv_text.
      RETURN.
    ENDIF.
    IF iv_count = 0.
      rv_text = '에러 없음'.
    ELSE.
      rv_text = '조회 완료'.
    ENDIF.
  ENDMETHOD.

  METHOD icon_for_light.
    CASE iv_light.
      WHEN 'R'.
        rv_icon = icon_red_light.
      WHEN 'Y'.
        rv_icon = icon_yellow_light.
      WHEN OTHERS.
        rv_icon = icon_green_light.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Providers
*----------------------------------------------------------------------*
CLASS lcl_dp_batch DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES lif_mon_data_provider.
    METHODS get_rows
      RETURNING VALUE(rt_rows) TYPE ty_batch_tab.
    METHODS get_all_rows
      RETURNING VALUE(rt_rows) TYPE ty_batch_tab.
  PRIVATE SECTION.
    DATA: mt_all TYPE ty_batch_tab,
          mt_alv TYPE ty_batch_tab.
    METHODS check_auth RETURNING VALUE(rv_ok) TYPE abap_bool.
    METHODS select_jobs IMPORTING is_sel TYPE ty_sel.
ENDCLASS.

CLASS lcl_dp_batch IMPLEMENTATION.
  METHOD lif_mon_data_provider~get_area_info.
    ev_area  = c_area_sm37.
    ev_title = 'SM37 배치 에러'.
    ev_color = c_col_sm37.
    ev_alv   = c_alv_sm37.
  ENDMETHOD.

  METHOD check_auth.
    AUTHORITY-CHECK OBJECT 'S_BTCH_JOB'
      ID 'JOBGROUP'  FIELD '*'
      ID 'JOBACTION' FIELD 'SHOW'.
    rv_ok = boolc( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD select_jobs.
    DATA: lt_tbtco TYPE STANDARD TABLE OF tbtco,
          ls_row   TYPE ty_batch,
          lt_tbtcp TYPE STANDARD TABLE OF tbtcp,
          lv_prog  TYPE programm.

    CLEAR: mt_all, mt_alv.

    IF is_sel-frdat = is_sel-todat.
      SELECT jobname jobcount status strtdate strttime
             enddate endtime sdluname
        FROM tbtco
        INTO CORRESPONDING FIELDS OF TABLE lt_tbtco
        WHERE status   = c_status_a
          AND enddate  = is_sel-frdat
          AND endtime  BETWEEN is_sel-frtim AND is_sel-totim
          AND jobname  IN so_job
          AND sdluname IN so_user.
    ELSE.
      SELECT jobname jobcount status strtdate strttime
             enddate endtime sdluname
        FROM tbtco
        INTO CORRESPONDING FIELDS OF TABLE lt_tbtco
        WHERE status = c_status_a
          AND ( ( enddate = is_sel-frdat AND endtime >= is_sel-frtim )
             OR ( enddate > is_sel-frdat AND enddate < is_sel-todat )
             OR ( enddate = is_sel-todat AND endtime <= is_sel-totim ) )
          AND jobname  IN so_job
          AND sdluname IN so_user.
    ENDIF.

    IF lt_tbtco IS NOT INITIAL.
      SELECT jobname jobcount stepcount progname
        FROM tbtcp
        INTO CORRESPONDING FIELDS OF TABLE lt_tbtcp
        FOR ALL ENTRIES IN lt_tbtco
        WHERE jobname  = lt_tbtco-jobname
          AND jobcount = lt_tbtco-jobcount.
      SORT lt_tbtcp BY jobname jobcount stepcount.
    ENDIF.

    LOOP AT lt_tbtco ASSIGNING FIELD-SYMBOL(<j>).
      CLEAR ls_row.
      ls_row-jobname  = <j>-jobname.
      ls_row-jobcount = <j>-jobcount.
      ls_row-status   = <j>-status.
      ls_row-sdluname = <j>-sdluname.
      ls_row-strtdate = <j>-strtdate.
      ls_row-strttime = <j>-strttime.
      ls_row-enddate  = <j>-enddate.
      ls_row-endtime  = <j>-endtime.
      ls_row-line_color = c_alv_sm37.
      CLEAR lv_prog.
      READ TABLE lt_tbtcp ASSIGNING FIELD-SYMBOL(<p>)
        WITH KEY jobname = <j>-jobname jobcount = <j>-jobcount BINARY SEARCH.
      IF sy-subrc = 0.
        lv_prog = <p>-progname.
      ENDIF.
      ls_row-progname = lv_prog.
      APPEND ls_row TO mt_all.
    ENDLOOP.

    SORT mt_all BY enddate DESCENDING endtime DESCENDING.
    mt_alv = mt_all.
    IF is_sel-maxrow > 0 AND lines( mt_alv ) > is_sel-maxrow.
      DELETE mt_alv FROM is_sel-maxrow + 1.
    ENDIF.
  ENDMETHOD.

  METHOD lif_mon_data_provider~get_data.
    DATA lv_msg TYPE string.
    CLEAR: ev_count, ev_error, ev_message.
    ev_auth_ok = check_auth( ).
    IF ev_auth_ok = abap_false.
      ev_message = '권한 없음'.
      CLEAR: mt_all, mt_alv.
      RETURN.
    ENDIF.
    TRY.
        select_jobs( is_sel ).
        ev_count = lines( mt_all ).
        IF is_sel-maxrow > 0 AND ev_count > is_sel-maxrow.
          lv_msg = |상위 { is_sel-maxrow }건 표시(전체 { ev_count })|.
          ev_message = lv_msg.
        ELSEIF ev_count = 0.
          ev_message = '에러 없음'.
        ELSE.
          ev_message = '조회 완료'.
        ENDIF.
      CATCH cx_root.
        ev_error = abap_true.
        ev_message = 'SM37 조회 오류'.
        CLEAR: mt_all, mt_alv.
    ENDTRY.
  ENDMETHOD.

  METHOD get_rows.
    rt_rows = mt_alv.
  ENDMETHOD.

  METHOD get_all_rows.
    rt_rows = mt_all.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_dp_dump DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES lif_mon_data_provider.
    METHODS get_rows RETURNING VALUE(rt_rows) TYPE ty_dump_tab.
    METHODS get_all_rows RETURNING VALUE(rt_rows) TYPE ty_dump_tab.
  PRIVATE SECTION.
    DATA: mt_all TYPE ty_dump_tab,
          mt_alv TYPE ty_dump_tab.
    METHODS check_auth RETURNING VALUE(rv_ok) TYPE abap_bool.
    METHODS select_dumps IMPORTING is_sel TYPE ty_sel.
    METHODS call_st22_fm
      IMPORTING iv_day TYPE sy-datum
      EXPORTING et_info TYPE rsdumptab
                ev_ok   TYPE abap_bool.
    METHODS map_dump_row
      IMPORTING is_info TYPE any
      EXPORTING es_row  TYPE ty_dump.
    METHODS select_dumps_snap IMPORTING is_sel TYPE ty_sel.
    METHODS append_filtered
      IMPORTING is_sel TYPE ty_sel
                is_row TYPE ty_dump.
ENDCLASS.

CLASS lcl_dp_dump IMPLEMENTATION.
  METHOD lif_mon_data_provider~get_area_info.
    ev_area  = c_area_st22.
    ev_title = 'ST22 런타임 에러'.
    ev_color = c_col_st22.
    ev_alv   = c_alv_st22.
  ENDMETHOD.

  METHOD check_auth.
    AUTHORITY-CHECK OBJECT 'S_ABAPDUMP'
      ID 'ACTVT'      FIELD '03'
      ID 'DUMP_INFO'  FIELD 'FULL'
      ID 'DUMP_CCLNT' FIELD 'ALL'
      ID 'DUMP_CUSER' FIELD 'ALL'.
    rv_ok = boolc( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD map_dump_row.
    " RSDUMPINFO 필드명 버전 차이를 흡수
    CLEAR es_row.
    ASSIGN COMPONENT 'SYDATE' OF STRUCTURE is_info TO FIELD-SYMBOL(<v>).
    IF sy-subrc = 0.
      es_row-datum = <v>.
    ENDIF.
    ASSIGN COMPONENT 'SYTIME' OF STRUCTURE is_info TO <v>.
    IF sy-subrc = 0.
      es_row-uzeit = <v>.
    ENDIF.
    ASSIGN COMPONENT 'SYUSER' OF STRUCTURE is_info TO <v>.
    IF sy-subrc = 0.
      es_row-uname = <v>.
    ENDIF.
    ASSIGN COMPONENT 'SYHOST' OF STRUCTURE is_info TO <v>.
    IF sy-subrc = 0.
      es_row-ahost = <v>.
    ENDIF.
    ASSIGN COMPONENT 'DUMPID' OF STRUCTURE is_info TO <v>.
    IF sy-subrc = 0.
      es_row-rt_error = <v>.
    ELSE.
      ASSIGN COMPONENT 'ERRORID' OF STRUCTURE is_info TO <v>.
      IF sy-subrc = 0.
        es_row-rt_error = <v>.
      ENDIF.
    ENDIF.
    ASSIGN COMPONENT 'PROGRAMNAME' OF STRUCTURE is_info TO <v>.
    IF sy-subrc = 0.
      es_row-progname = <v>.
    ELSE.
      ASSIGN COMPONENT 'PROGNAME' OF STRUCTURE is_info TO <v>.
      IF sy-subrc = 0.
        es_row-progname = <v>.
      ENDIF.
    ENDIF.
    ASSIGN COMPONENT 'INCLUDENAME' OF STRUCTURE is_info TO <v>.
    IF sy-subrc = 0.
      es_row-include = <v>.
    ENDIF.
    ASSIGN COMPONENT 'LINENUMBER' OF STRUCTURE is_info TO <v>.
    IF sy-subrc = 0.
      es_row-line = <v>.
    ENDIF.
    ASSIGN COMPONENT 'MODNO' OF STRUCTURE is_info TO <v>.
    IF sy-subrc = 0.
      es_row-modno = <v>.
    ELSE.
      ASSIGN COMPONENT 'SYMODNO' OF STRUCTURE is_info TO <v>.
      IF sy-subrc = 0.
        es_row-modno = <v>.
      ENDIF.
    ENDIF.
    ASSIGN COMPONENT 'MANDT' OF STRUCTURE is_info TO <v>.
    IF sy-subrc = 0.
      es_row-mandt = <v>.
    ELSE.
      ASSIGN COMPONENT 'SYMANDT' OF STRUCTURE is_info TO <v>.
      IF sy-subrc = 0.
        es_row-mandt = <v>.
      ENDIF.
    ENDIF.
    IF es_row-mandt IS INITIAL.
      es_row-mandt = sy-mandt.
    ENDIF.
    es_row-line_color = c_alv_st22.
    IF es_row-rt_error IS INITIAL.
      es_row-rt_error = 'SHORTDUMP'.
    ENDIF.
  ENDMETHOD.

  METHOD append_filtered.
    DATA ls TYPE ty_dump.
    ls = is_row.
    IF ls-datum < is_sel-frdat OR ls-datum > is_sel-todat.
      RETURN.
    ENDIF.
    IF ls-datum = is_sel-frdat AND ls-uzeit < is_sel-frtim.
      RETURN.
    ENDIF.
    IF ls-datum = is_sel-todat AND ls-uzeit > is_sel-totim.
      RETURN.
    ENDIF.
    IF so_user IS NOT INITIAL AND ls-uname NOT IN so_user.
      RETURN.
    ENDIF.
    APPEND ls TO mt_all.
  ENDMETHOD.

  METHOD call_st22_fm.
    DATA lv_subrc TYPE sysubrc.

    CLEAR: et_info, ev_ok.
    " 표준(신): P_INFOTAB 은 IMPORTING (TABLES 아님)
    TRY.
        CALL FUNCTION 'RS_ST22_GET_DUMPS'
          EXPORTING
            p_day       = iv_day
          IMPORTING
            p_infotab   = et_info
          EXCEPTIONS
            no_authority = 1
            OTHERS       = 2.
        lv_subrc = sy-subrc.
        IF lv_subrc = 0.
          ev_ok = abap_true.
          RETURN.
        ENDIF.
      CATCH cx_sy_dyn_call_param_not_found
            cx_sy_dyn_call_illegal_type
            cx_sy_dyn_call_illegal_func.
        CLEAR et_info.
    ENDTRY.

    " 대안: datum + IMPORTING
    TRY.
        CALL FUNCTION 'RS_ST22_GET_DUMPS'
          EXPORTING
            datum       = iv_day
          IMPORTING
            p_infotab   = et_info
          EXCEPTIONS
            no_authority = 1
            OTHERS       = 2.
        IF sy-subrc = 0.
          ev_ok = abap_true.
          RETURN.
        ENDIF.
      CATCH cx_sy_dyn_call_param_not_found
            cx_sy_dyn_call_illegal_type.
        CLEAR et_info.
    ENDTRY.

    " 구형: TABLES p_infotab
    TRY.
        CALL FUNCTION 'RS_ST22_GET_DUMPS'
          EXPORTING
            p_day     = iv_day
          TABLES
            p_infotab = et_info
          EXCEPTIONS
            no_authority = 1
            OTHERS       = 2.
        IF sy-subrc = 0.
          ev_ok = abap_true.
          RETURN.
        ENDIF.
      CATCH cx_sy_dyn_call_param_not_found
            cx_sy_dyn_call_illegal_type.
        CLEAR et_info.
    ENDTRY.
  ENDMETHOD.

  METHOD select_dumps_snap.
    " FM 실패 시 표준 SNAP 헤더(SEQNO=000)로 기간 바운드 조회
    TYPES: BEGIN OF ty_snap,
             datum TYPE snap-datum,
             uzeit TYPE snap-uzeit,
             uname TYPE snap-uname,
             ahost TYPE snap-ahost,
             modno TYPE snap-modno,
             mandt TYPE snap-mandt,
           END OF ty_snap.
    DATA: lt_snap TYPE STANDARD TABLE OF ty_snap,
          ls_row  TYPE ty_dump.

    CLEAR lt_snap.
    IF is_sel-frdat = is_sel-todat.
      SELECT datum uzeit uname ahost modno mandt
        FROM snap
        INTO CORRESPONDING FIELDS OF TABLE lt_snap
        WHERE seqno = '000'
          AND datum = is_sel-frdat
          AND uzeit BETWEEN is_sel-frtim AND is_sel-totim.
    ELSE.
      SELECT datum uzeit uname ahost modno mandt
        FROM snap
        INTO CORRESPONDING FIELDS OF TABLE lt_snap
        WHERE seqno = '000'
          AND ( ( datum = is_sel-frdat AND uzeit >= is_sel-frtim )
             OR ( datum > is_sel-frdat AND datum < is_sel-todat )
             OR ( datum = is_sel-todat AND uzeit <= is_sel-totim ) ).
    ENDIF.

    LOOP AT lt_snap ASSIGNING FIELD-SYMBOL(<s>).
      CLEAR ls_row.
      ls_row-datum      = <s>-datum.
      ls_row-uzeit      = <s>-uzeit.
      ls_row-uname      = <s>-uname.
      ls_row-ahost      = <s>-ahost.
      ls_row-modno      = <s>-modno.
      ls_row-mandt      = <s>-mandt.
      IF ls_row-mandt IS INITIAL.
        ls_row-mandt = sy-mandt.
      ENDIF.
      ls_row-rt_error   = 'SHORTDUMP'.
      ls_row-line_color = c_alv_st22.
      append_filtered( is_sel = is_sel is_row = ls_row ).
    ENDLOOP.
  ENDMETHOD.

  METHOD select_dumps.
    DATA: lv_day  TYPE sy-datum,
          lt_info TYPE rsdumptab,
          ls_row  TYPE ty_dump,
          lv_ok   TYPE abap_bool,
          lv_fm_ok TYPE abap_bool.

    CLEAR: mt_all, mt_alv.
    lv_day = is_sel-frdat.
    WHILE lv_day <= is_sel-todat.
      CLEAR lt_info.
      call_st22_fm(
        EXPORTING iv_day = lv_day
        IMPORTING et_info = lt_info ev_ok = lv_ok ).
      IF lv_ok = abap_true.
        lv_fm_ok = abap_true.
        LOOP AT lt_info ASSIGNING FIELD-SYMBOL(<d>).
          map_dump_row(
            EXPORTING is_info = <d>
            IMPORTING es_row  = ls_row ).
          append_filtered( is_sel = is_sel is_row = ls_row ).
        ENDLOOP.
      ENDIF.
      lv_day = lv_day + 1.
    ENDWHILE.

    " FM이 하루도 성공하지 못하면 SNAP 폴백
    IF lv_fm_ok = abap_false AND mt_all IS INITIAL.
      select_dumps_snap( is_sel ).
    ENDIF.

    SORT mt_all BY datum DESCENDING uzeit DESCENDING.
    mt_alv = mt_all.
    IF is_sel-maxrow > 0 AND lines( mt_alv ) > is_sel-maxrow.
      DELETE mt_alv FROM is_sel-maxrow + 1.
    ENDIF.
  ENDMETHOD.

  METHOD lif_mon_data_provider~get_data.
    DATA lv_msg TYPE string.
    CLEAR: ev_count, ev_error, ev_message.
    ev_auth_ok = check_auth( ).
    IF ev_auth_ok = abap_false.
      ev_message = '권한 없음'.
      CLEAR: mt_all, mt_alv.
      RETURN.
    ENDIF.
    TRY.
        select_dumps( is_sel ).
        ev_count = lines( mt_all ).
        IF is_sel-maxrow > 0 AND ev_count > is_sel-maxrow.
          lv_msg = |상위 { is_sel-maxrow }건 표시(전체 { ev_count })|.
          ev_message = lv_msg.
        ELSEIF ev_count = 0.
          ev_message = '에러 없음'.
        ELSE.
          ev_message = '조회 완료'.
        ENDIF.
      CATCH cx_root.
        ev_error = abap_true.
        ev_message = 'ST22 조회 오류'.
        CLEAR: mt_all, mt_alv.
    ENDTRY.
  ENDMETHOD.

  METHOD get_rows.
    rt_rows = mt_alv.
  ENDMETHOD.

  METHOD get_all_rows.
    rt_rows = mt_all.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_dp_interface DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES lif_mon_data_provider.
    METHODS get_rows RETURNING VALUE(rt_rows) TYPE ty_iface_tab.
    METHODS get_all_rows RETURNING VALUE(rt_rows) TYPE ty_iface_tab.
  PRIVATE SECTION.
    DATA: mt_all TYPE ty_iface_tab,
          mt_alv TYPE ty_iface_tab.
    METHODS check_auth RETURNING VALUE(rv_ok) TYPE abap_bool.
    METHODS select_iface IMPORTING is_sel TYPE ty_sel.
ENDCLASS.

CLASS lcl_dp_interface IMPLEMENTATION.
  METHOD lif_mon_data_provider~get_area_info.
    ev_area  = c_area_sxi.
    ev_title = 'SXI 인터페이스 에러'.
    ev_color = c_col_sxi.
    ev_alv   = c_alv_sxi.
  ENDMETHOD.

  METHOD check_auth.
    AUTHORITY-CHECK OBJECT 'S_XMB_MONI'
      ID 'ACTVT' FIELD '03'.
    rv_ok = boolc( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD select_iface.
    TYPES: BEGIN OF ty_err,
             msgguid   TYPE sxmspmast-msgguid,
             pid       TYPE sxmspmast-pid,
             errstat   TYPE sxmsperror-errstat,
             exetimest TYPE sxmsperror-exetimest,
           END OF ty_err.
    TYPES: BEGIN OF ty_mast,
             msgguid  TYPE sxmspmast-msgguid,
             pid      TYPE sxmspmast-pid,
             msgstate TYPE sxmspmast-msgstate,
           END OF ty_mast.
    TYPES: BEGIN OF ty_emas,
             msgguid      TYPE sxmspmast-msgguid,
             pid          TYPE sxmspmast-pid,
             ob_name      TYPE char120,
             ob_ns        TYPE char120,
             ob_operation TYPE char120,
             ob_system    TYPE char120,
             ib_system    TYPE char120,
             ob_party     TYPE char120,
             ib_party     TYPE char120,
           END OF ty_emas.

    DATA: lt_err  TYPE STANDARD TABLE OF ty_err,
          lt_mast TYPE STANDARD TABLE OF ty_mast,
          lt_emas TYPE STANDARD TABLE OF ty_emas,
          ls_row  TYPE ty_iface,
          lv_from TYPE sxmsperror-exetimest,
          lv_to   TYPE sxmsperror-exetimest,
          lv_date TYPE sy-datum,
          lv_time TYPE sy-uzeit,
          lv_send TYPE char120,
          lv_recv TYPE char120.

    CLEAR: mt_all, mt_alv.
    lv_from = lcl_util=>local_to_utc_tstmp( iv_date = is_sel-frdat iv_time = is_sel-frtim ).
    lv_to   = lcl_util=>local_to_utc_tstmp( iv_date = is_sel-todat iv_time = is_sel-totim ).

    " P_MAND 필터: CLIENT SPECIFIED 시에만 MANDT WHERE 허용
    SELECT msgguid pid errstat exetimest
      FROM sxmsperror CLIENT SPECIFIED
      INTO CORRESPONDING FIELDS OF TABLE lt_err
      WHERE mandt     = is_sel-mandt
        AND exetimest BETWEEN lv_from AND lv_to.

    IF lt_err IS INITIAL.
      RETURN.
    ENDIF.

    SELECT msgguid pid msgstate
      FROM sxmspmast CLIENT SPECIFIED
      INTO CORRESPONDING FIELDS OF TABLE lt_mast
      FOR ALL ENTRIES IN lt_err
      WHERE mandt   = is_sel-mandt
        AND msgguid = lt_err-msgguid
        AND pid     = lt_err-pid.

    SELECT msgguid pid ob_name ob_ns ob_operation
           ob_system ib_system ob_party ib_party
      FROM sxmspemas CLIENT SPECIFIED
      INTO CORRESPONDING FIELDS OF TABLE lt_emas
      FOR ALL ENTRIES IN lt_err
      WHERE mandt   = is_sel-mandt
        AND msgguid = lt_err-msgguid
        AND pid     = lt_err-pid.

    SORT lt_mast BY msgguid pid.
    SORT lt_emas BY msgguid pid.

    LOOP AT lt_err ASSIGNING FIELD-SYMBOL(<e>).
      CLEAR ls_row.
      ls_row-msgguid = <e>-msgguid.
      ls_row-pid     = <e>-pid.
      ls_row-errstat = <e>-errstat.
      lcl_util=>utc_tstmp_to_local(
        EXPORTING iv_ts = <e>-exetimest
        IMPORTING ev_date = lv_date ev_time = lv_time ).
      ls_row-exe_date = lv_date.
      ls_row-exe_time = lv_time.
      READ TABLE lt_mast ASSIGNING FIELD-SYMBOL(<m>)
        WITH KEY msgguid = <e>-msgguid pid = <e>-pid BINARY SEARCH.
      IF sy-subrc = 0.
        ls_row-msgstate = <m>-msgstate.
      ENDIF.
      READ TABLE lt_emas ASSIGNING FIELD-SYMBOL(<x>)
        WITH KEY msgguid = <e>-msgguid pid = <e>-pid BINARY SEARCH.
      IF sy-subrc = 0.
        ls_row-if_name   = <x>-ob_name.
        ls_row-if_ns     = <x>-ob_ns.
        ls_row-operation = <x>-ob_operation.
        lv_send = <x>-ob_system.
        IF lv_send IS INITIAL.
          lv_send = <x>-ob_party.
        ENDIF.
        lv_recv = <x>-ib_system.
        IF lv_recv IS INITIAL.
          lv_recv = <x>-ib_party.
        ENDIF.
        ls_row-sender   = lv_send.
        ls_row-receiver = lv_recv.
      ENDIF.
      " Top-N/ALV 가독성: 인터페이스명 비어 있으면 대체 키
      IF ls_row-if_name IS INITIAL.
        IF ls_row-operation IS NOT INITIAL.
          ls_row-if_name = ls_row-operation.
        ELSEIF lv_send IS NOT INITIAL OR lv_recv IS NOT INITIAL.
          CONCATENATE lv_send '→' lv_recv INTO ls_row-if_name.
        ELSE.
          ls_row-if_name = '(이름없음)'.
        ENDIF.
      ENDIF.
      IF so_iface IS NOT INITIAL AND ls_row-if_name NOT IN so_iface.
        CONTINUE.
      ENDIF.
      ls_row-line_color = c_alv_sxi.
      APPEND ls_row TO mt_all.
    ENDLOOP.

    SORT mt_all BY exe_date DESCENDING exe_time DESCENDING.
    mt_alv = mt_all.
    IF is_sel-maxrow > 0 AND lines( mt_alv ) > is_sel-maxrow.
      DELETE mt_alv FROM is_sel-maxrow + 1.
    ENDIF.
  ENDMETHOD.

  METHOD lif_mon_data_provider~get_data.
    DATA lv_msg TYPE string.
    CLEAR: ev_count, ev_error, ev_message.
    ev_auth_ok = check_auth( ).
    IF ev_auth_ok = abap_false.
      ev_message = '권한 없음'.
      CLEAR: mt_all, mt_alv.
      RETURN.
    ENDIF.
    TRY.
        select_iface( is_sel ).
        ev_count = lines( mt_all ).
        IF is_sel-maxrow > 0 AND ev_count > is_sel-maxrow.
          lv_msg = |상위 { is_sel-maxrow }건 표시(전체 { ev_count })|.
          ev_message = lv_msg.
        ELSEIF ev_count = 0.
          ev_message = '에러 없음'.
        ELSE.
          ev_message = '조회 완료'.
        ENDIF.
      CATCH cx_root.
        ev_error = abap_true.
        ev_message = 'SXI 조회 오류'.
        CLEAR: mt_all, mt_alv.
    ENDTRY.
  ENDMETHOD.

  METHOD get_rows.
    rt_rows = mt_alv.
  ENDMETHOD.

  METHOD get_all_rows.
    rt_rows = mt_all.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Aggregator
*----------------------------------------------------------------------*
CLASS lcl_aggregator DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS build_topn
      IMPORTING
        it_batch TYPE ty_batch_tab
        it_dump  TYPE ty_dump_tab
        it_iface TYPE ty_iface_tab
        iv_topn  TYPE i
        iv_sm37  TYPE abap_bool
        iv_st22  TYPE abap_bool
        iv_sxi   TYPE abap_bool
      RETURNING VALUE(rt_groups) TYPE ty_topn_group_tab.
    CLASS-METHODS build_timeline
      IMPORTING
        it_batch TYPE ty_batch_tab
        it_dump  TYPE ty_dump_tab
        it_iface TYPE ty_iface_tab
        is_sel   TYPE ty_sel
        iv_sm37  TYPE abap_bool
        iv_st22  TYPE abap_bool
        iv_sxi   TYPE abap_bool
      EXPORTING
        et_buckets TYPE ty_bucket_tab
        ev_unit    TYPE char20.
  PRIVATE SECTION.
    CLASS-METHODS topn_from_keys
      IMPORTING
        it_keys  TYPE string_table
        iv_area  TYPE char10
        iv_color TYPE char7
        iv_topn  TYPE i
      RETURNING VALUE(rs_group) TYPE ty_topn_group.
ENDCLASS.

CLASS lcl_aggregator IMPLEMENTATION.
  METHOD topn_from_keys.
    TYPES: BEGIN OF ty_cnt,
             key TYPE char120,
             cnt TYPE i,
           END OF ty_cnt.
    DATA: lt_cnt  TYPE STANDARD TABLE OF ty_cnt,
          ls_cnt  TYPE ty_cnt,
          ls_item TYPE ty_chart_item,
          lv_top  TYPE i,
          lv_max  TYPE i.

    lv_top = iv_topn.
    IF lv_top <= 0.
      lv_top = c_def_topn.
    ENDIF.

    LOOP AT it_keys ASSIGNING FIELD-SYMBOL(<k>).
      ls_cnt-key = <k>.
      IF ls_cnt-key IS INITIAL.
        ls_cnt-key = '(이름없음)'.
      ENDIF.
      READ TABLE lt_cnt ASSIGNING FIELD-SYMBOL(<c>) WITH KEY key = ls_cnt-key.
      IF sy-subrc = 0.
        <c>-cnt = <c>-cnt + 1.
      ELSE.
        ls_cnt-cnt = 1.
        APPEND ls_cnt TO lt_cnt.
      ENDIF.
    ENDLOOP.
    SORT lt_cnt BY cnt DESCENDING key ASCENDING.
    IF lines( lt_cnt ) > lv_top.
      DELETE lt_cnt FROM lv_top + 1.
    ENDIF.

    CLEAR rs_group.
    rs_group-area = iv_area.
    LOOP AT lt_cnt ASSIGNING <c>.
      CLEAR ls_item.
      ls_item-area  = iv_area.
      ls_item-key   = <c>-key.
      ls_item-count = <c>-cnt.
      ls_item-color = iv_color.
      APPEND ls_item TO rs_group-items.
      IF <c>-cnt > lv_max.
        lv_max = <c>-cnt.
      ENDIF.
    ENDLOOP.
    rs_group-maxc = lv_max.
  ENDMETHOD.

  METHOD build_topn.
    DATA: lt_keys TYPE string_table,
          ls_grp  TYPE ty_topn_group.

    CLEAR rt_groups.
    IF iv_sm37 = abap_true.
      CLEAR lt_keys.
      LOOP AT it_batch ASSIGNING FIELD-SYMBOL(<b>).
        APPEND <b>-jobname TO lt_keys.
      ENDLOOP.
      ls_grp = topn_from_keys( it_keys = lt_keys iv_area = c_area_sm37
                               iv_color = c_col_sm37 iv_topn = iv_topn ).
      APPEND ls_grp TO rt_groups.
    ENDIF.
    IF iv_st22 = abap_true.
      CLEAR lt_keys.
      LOOP AT it_dump ASSIGNING FIELD-SYMBOL(<d>).
        APPEND <d>-rt_error TO lt_keys.
      ENDLOOP.
      ls_grp = topn_from_keys( it_keys = lt_keys iv_area = c_area_st22
                               iv_color = c_col_st22 iv_topn = iv_topn ).
      APPEND ls_grp TO rt_groups.
    ENDIF.
    IF iv_sxi = abap_true.
      CLEAR lt_keys.
      LOOP AT it_iface ASSIGNING FIELD-SYMBOL(<i>).
        APPEND <i>-if_name TO lt_keys.
      ENDLOOP.
      ls_grp = topn_from_keys( it_keys = lt_keys iv_area = c_area_sxi
                               iv_color = c_col_sxi iv_topn = iv_topn ).
      APPEND ls_grp TO rt_groups.
    ENDIF.
  ENDMETHOD.

  METHOD build_timeline.
    DATA: lv_from_ts TYPE timestampl,
          lv_to_ts   TYPE timestampl,
          lv_diff    TYPE tzntstmpl,
          lv_bucket  TYPE i,
          lv_secs    TYPE i,
          lv_idx     TYPE i,
          lv_cnt     TYPE i,
          lv_ts      TYPE timestampl,
          lv_label   TYPE char20,
          lv_tmp     TYPE char20,
          ls_b       TYPE ty_bucket,
          lv_d       TYPE sy-datum,
          lv_t       TYPE sy-uzeit.

    CLEAR: et_buckets, ev_unit.
    lv_from_ts = lcl_util=>local_to_utc_tstmp( iv_date = is_sel-frdat iv_time = is_sel-frtim ).
    lv_to_ts   = lcl_util=>local_to_utc_tstmp( iv_date = is_sel-todat iv_time = is_sel-totim ).
    TRY.
        lv_diff = cl_abap_tstmp=>subtract(
          tstmp1 = lv_to_ts
          tstmp2 = lv_from_ts ).
      CATCH cx_parameter_invalid_range cx_parameter_invalid_type.
        lv_diff = 3600.
    ENDTRY.
    IF lv_diff <= 0.
      lv_diff = 3600.
    ENDIF.

    IF lv_diff <= 86400.
      lv_bucket = 3600.
      ev_unit = '1칸=1시간'.
    ELSEIF lv_diff <= 604800.
      lv_bucket = 86400.
      ev_unit = '1칸=1일'.
    ELSE.
      lv_bucket = 86400 * 7.
      ev_unit = '1칸=1주'.
    ENDIF.

    " 가독성: 막대 최대 12개 (너무 잘게 쪼개지 않음)
    lv_cnt = lv_diff DIV lv_bucket + 1.
    IF lv_cnt > 12.
      lv_cnt = 12.
      lv_bucket = lv_diff DIV lv_cnt.
      IF lv_bucket <= 0.
        lv_bucket = 3600.
      ENDIF.
      IF lv_bucket < 3600.
        ev_unit = '1칸=구간'.
      ELSEIF lv_bucket < 86400.
        ev_unit = |1칸≈{ lv_bucket DIV 3600 }시간|.
      ELSEIF lv_bucket < 604800.
        ev_unit = |1칸≈{ lv_bucket DIV 86400 }일|.
      ENDIF.
    ENDIF.

    DO lv_cnt TIMES.
      lv_idx = sy-index - 1.
      lv_secs = lv_idx * lv_bucket.
      TRY.
          lv_ts = cl_abap_tstmp=>add(
            tstmp = lv_from_ts
            secs  = lv_secs ).
        CATCH cx_parameter_invalid_range cx_parameter_invalid_type.
          CONTINUE.
      ENDTRY.
      lcl_util=>utc_tstmp_to_local(
        EXPORTING iv_ts = lv_ts
        IMPORTING ev_date = lv_d ev_time = lv_t ).
      CLEAR ls_b.
      " 축/툴팁용 짧은 시각 라벨 (예: 08/11 14시)
      IF lv_bucket < 86400.
        CONCATENATE lv_d+4(2) '/' lv_d+6(2) INTO lv_tmp.
        CONCATENATE lv_tmp lv_t+0(2) INTO lv_label SEPARATED BY space.
        CONCATENATE lv_label '시' INTO lv_label.
      ELSE.
        CONCATENATE lv_d+4(2) '/' lv_d+6(2) INTO lv_label.
      ENDIF.
      ls_b-label = lv_label.
      APPEND ls_b TO et_buckets.
    ENDDO.

    IF iv_sm37 = abap_true.
      LOOP AT it_batch ASSIGNING FIELD-SYMBOL(<jb>).
        lv_ts = lcl_util=>local_to_utc_tstmp( iv_date = <jb>-enddate iv_time = <jb>-endtime ).
        TRY.
            lv_diff = cl_abap_tstmp=>subtract( tstmp1 = lv_ts tstmp2 = lv_from_ts ).
          CATCH cx_parameter_invalid_range cx_parameter_invalid_type.
            CONTINUE.
        ENDTRY.
        IF lv_diff < 0.
          CONTINUE.
        ENDIF.
        lv_idx = lv_diff DIV lv_bucket + 1.
        READ TABLE et_buckets ASSIGNING FIELD-SYMBOL(<bk>) INDEX lv_idx.
        IF sy-subrc = 0.
          <bk>-sm37 = <bk>-sm37 + 1.
        ENDIF.
      ENDLOOP.
    ENDIF.
    IF iv_st22 = abap_true.
      LOOP AT it_dump ASSIGNING FIELD-SYMBOL(<jd>).
        lv_ts = lcl_util=>local_to_utc_tstmp( iv_date = <jd>-datum iv_time = <jd>-uzeit ).
        TRY.
            lv_diff = cl_abap_tstmp=>subtract( tstmp1 = lv_ts tstmp2 = lv_from_ts ).
          CATCH cx_parameter_invalid_range cx_parameter_invalid_type.
            CONTINUE.
        ENDTRY.
        IF lv_diff < 0.
          CONTINUE.
        ENDIF.
        lv_idx = lv_diff DIV lv_bucket + 1.
        READ TABLE et_buckets ASSIGNING <bk> INDEX lv_idx.
        IF sy-subrc = 0.
          <bk>-st22 = <bk>-st22 + 1.
        ENDIF.
      ENDLOOP.
    ENDIF.
    IF iv_sxi = abap_true.
      LOOP AT it_iface ASSIGNING FIELD-SYMBOL(<ji>).
        lv_ts = lcl_util=>local_to_utc_tstmp( iv_date = <ji>-exe_date iv_time = <ji>-exe_time ).
        TRY.
            lv_diff = cl_abap_tstmp=>subtract( tstmp1 = lv_ts tstmp2 = lv_from_ts ).
          CATCH cx_parameter_invalid_range cx_parameter_invalid_type.
            CONTINUE.
        ENDTRY.
        IF lv_diff < 0.
          CONTINUE.
        ENDIF.
        lv_idx = lv_diff DIV lv_bucket + 1.
        READ TABLE et_buckets ASSIGNING <bk> INDEX lv_idx.
        IF sy-subrc = 0.
          <bk>-sxi = <bk>-sxi + 1.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Navigator (display-only)
*----------------------------------------------------------------------*
CLASS lcl_navigator DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS to_batch
      IMPORTING is_row TYPE ty_batch.
    CLASS-METHODS build_dump_detail_html
      IMPORTING is_row TYPE ty_dump
      RETURNING VALUE(rv_html) TYPE string.
    CLASS-METHODS to_iface
      IMPORTING is_row TYPE ty_iface.
ENDCLASS.

CLASS lcl_navigator IMPLEMENTATION.
  METHOD to_batch.
    CHECK is_row-jobname IS NOT INITIAL AND is_row-jobcount IS NOT INITIAL.
    CALL FUNCTION 'BP_JOBLOG_SHOW'
      EXPORTING
        client                = sy-mandt
        jobcount              = is_row-jobcount
        jobname               = is_row-jobname
      EXCEPTIONS
        cant_show_joblog      = 1
        error_reading_jobdata = 2
        jobcount_missing      = 3
        joblog_does_not_exist = 4
        joblog_is_empty       = 5
        joblog_show_canceled  = 6
        jobname_missing       = 7
        job_does_not_exist    = 8
        no_joblog_there       = 9
        OTHERS                = 10.
    IF sy-subrc <> 0.
      MESSAGE '잡 로그를 표시할 수 없습니다' TYPE 'S'.
    ENDIF.
  ENDMETHOD.

  METHOD build_dump_detail_html.
    DATA: lt_ft    TYPE rsdump_ft_it,
          lv_modno TYPE snap-modno,
          lv_mandt TYPE snap-mandt,
          lv_css   TYPE string,
          lv_body  TYPE string,
          lv_pre   TYPE string,
          lv_line  TYPE string,
          lv_id    TYPE string,
          lv_val   TYPE string,
          lv_cnt   TYPE i,
          lv_ok    TYPE abap_bool,
          lv_ts    TYPE string.

    lv_modno = is_row-modno.
    IF lv_modno IS INITIAL.
      lv_modno = '00'.
    ENDIF.
    lv_mandt = is_row-mandt.
    IF lv_mandt IS INITIAL.
      lv_mandt = sy-mandt.
    ENDIF.

    " 표준 읽기 FM — 덤프 상세(Free Text) 조회
    TRY.
        CALL FUNCTION 'RS_ST22_GET_FT'
          EXPORTING
            datum = is_row-datum
            uzeit = is_row-uzeit
            uname = is_row-uname
            ahost = is_row-ahost
            modno = lv_modno
            mandt = lv_mandt
          IMPORTING
            ft    = lt_ft
          EXCEPTIONS
            OTHERS = 1.
        IF sy-subrc = 0 AND lt_ft IS NOT INITIAL.
          lv_ok = abap_true.
        ENDIF.
      CATCH cx_sy_dyn_call_param_not_found
            cx_sy_dyn_call_illegal_type
            cx_sy_dyn_call_illegal_func.
        CLEAR lt_ft.
    ENDTRY.

    " 일부 시스템: FT 가 TABLES
    IF lv_ok = abap_false.
      TRY.
          CALL FUNCTION 'RS_ST22_GET_FT'
            EXPORTING
              datum = is_row-datum
              uzeit = is_row-uzeit
              uname = is_row-uname
              ahost = is_row-ahost
              modno = lv_modno
              mandt = lv_mandt
            TABLES
              ft    = lt_ft
            EXCEPTIONS
              OTHERS = 1.
          IF sy-subrc = 0 AND lt_ft IS NOT INITIAL.
            lv_ok = abap_true.
          ENDIF.
        CATCH cx_sy_dyn_call_param_not_found
              cx_sy_dyn_call_illegal_type.
          CLEAR lt_ft.
      ENDTRY.
    ENDIF.

    LOOP AT lt_ft ASSIGNING FIELD-SYMBOL(<ft>).
      lv_cnt = lv_cnt + 1.
      IF lv_cnt > 800.
        lv_pre = lv_pre && '... (이하 생략)' && cl_abap_char_utilities=>cr_lf.
        EXIT.
      ENDIF.
      CLEAR: lv_id, lv_val.
      ASSIGN COMPONENT 'ID' OF STRUCTURE <ft> TO FIELD-SYMBOL(<c>).
      IF sy-subrc = 0.
        lv_id = <c>.
      ELSE.
        ASSIGN COMPONENT 'FTID' OF STRUCTURE <ft> TO <c>.
        IF sy-subrc = 0.
          lv_id = <c>.
        ENDIF.
      ENDIF.
      ASSIGN COMPONENT 'VALUE' OF STRUCTURE <ft> TO <c>.
      IF sy-subrc = 0.
        lv_val = <c>.
      ELSE.
        ASSIGN COMPONENT 'FTVALUE' OF STRUCTURE <ft> TO <c>.
        IF sy-subrc = 0.
          lv_val = <c>.
        ELSE.
          ASSIGN COMPONENT 'CONT' OF STRUCTURE <ft> TO <c>.
          IF sy-subrc = 0.
            lv_val = <c>.
          ENDIF.
        ENDIF.
      ENDIF.
      lv_line = lcl_util=>html_escape( lv_id ).
      IF lv_val IS NOT INITIAL.
        IF lv_line IS NOT INITIAL.
          lv_line = lv_line && '  '.
        ENDIF.
        lv_line = lv_line && lcl_util=>html_escape( lv_val ).
      ENDIF.
      IF lv_line IS NOT INITIAL.
        lv_pre = lv_pre && lv_line && cl_abap_char_utilities=>cr_lf.
      ENDIF.
    ENDLOOP.

    lv_ts = |{ is_row-datum DATE = USER } { is_row-uzeit TIME = USER }|.

    lv_css =
      'body{margin:0;font-family:Arial,Helvetica,sans-serif;background:#fafafa;color:#212121;}' &&
      '.hdr{padding:10px 12px;background:#c62828;color:#fff;}' &&
      '.hl{font-size:16px;font-weight:700;}' &&
      '.sub{font-size:12px;opacity:.95;margin-top:3px;}' &&
      '.meta{padding:8px 12px;background:#eeeeee;font-size:12px;}' &&
      '.meta b{display:inline-block;min-width:70px;color:#616161;}' &&
      '.wrap{padding:8px 12px;}' &&
      'pre{margin:0;padding:10px;background:#fff;border:1px solid #bdbdbd;' &&
      'border-radius:4px;font-family:Consolas,monospace;font-size:11px;' &&
      'white-space:pre-wrap;word-break:break-all;max-height:360px;overflow:auto;}' &&
      '.ft{margin-top:8px;font-size:11px;color:#757575;}' &&
      '.warn{padding:10px;background:#fff3e0;border:1px solid #ffb74d;border-radius:4px;}'.

    lv_body =
      '<div class="hdr"><div class="hl">' &&
      lcl_util=>html_escape( is_row-rt_error ) &&
      '</div><div class="sub">Runtime Error 상세 (읽기 전용)</div></div>' &&
      '<div class="meta">' &&
      '<div><b>일시</b> ' && lcl_util=>html_escape( lv_ts ) && '</div>' &&
      '<div><b>사용자</b> ' && lcl_util=>html_escape( is_row-uname ) && '</div>' &&
      '<div><b>서버</b> ' && lcl_util=>html_escape( is_row-ahost ) && '</div>' &&
      '<div><b>프로그램</b> ' && lcl_util=>html_escape( is_row-progname ) && '</div>' &&
      '<div><b>Include</b> ' && lcl_util=>html_escape( is_row-include ) &&
      ' / Line ' && |{ is_row-line }| && '</div></div><div class="wrap">'.

    IF lv_ok = abap_true AND lv_pre IS NOT INITIAL.
      lv_body = lv_body && '<pre>' && lv_pre && '</pre>'.
    ELSE.
      lv_body = lv_body &&
        '<div class="warn">상세 텍스트(RS_ST22_GET_FT)를 읽지 못했습니다. ' &&
        '키: ' && lcl_util=>html_escape( lv_ts ) && ' / ' &&
        lcl_util=>html_escape( is_row-uname ) && ' / ' &&
        lcl_util=>html_escape( is_row-ahost ) && '</div>'.
    ENDIF.
    lv_body = lv_body &&
      '<div class="ft">우상단 X 로 닫기 · 읽기 전용 (ST22 트랜잭션 미호출)</div></div>'.

    rv_html =
      '<!DOCTYPE html><html><head><meta charset="utf-8"><style>' &&
      lv_css && '</style></head><body>' && lv_body && '</body></html>'.
  ENDMETHOD.

  METHOD to_iface.
    SET PARAMETER ID 'BDC' FIELD space.
    CALL TRANSACTION 'SXI_MONITOR' AND SKIP FIRST SCREEN. "#EC CI_CALLTA
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* UI Dashboard
*----------------------------------------------------------------------*
CLASS lcl_ui_dashboard DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_controller TYPE REF TO lcl_controller.
    METHODS display
      IMPORTING
        is_sel     TYPE ty_sel
        it_status  TYPE ty_area_status_tab
        it_batch   TYPE ty_batch_tab
        it_dump    TYPE ty_dump_tab
        it_iface   TYPE ty_iface_tab
        it_batch_all TYPE ty_batch_tab
        it_dump_all  TYPE ty_dump_tab
        it_iface_all TYPE ty_iface_tab
        iv_runtime TYPE i.
    METHODS refresh.
    METHODS toggle_perspective.
    METHODS show_stats.
    METHODS show_help.
    METHODS show_dump_detail IMPORTING is_dump TYPE ty_dump.
    METHODS handle_user_command IMPORTING iv_ucomm TYPE sy-ucomm.
    METHODS free.
    METHODS on_stats_close FOR EVENT close OF cl_gui_dialogbox_container
      IMPORTING sender.
    METHODS on_help_close FOR EVENT close OF cl_gui_dialogbox_container
      IMPORTING sender.
    METHODS on_dump_close FOR EVENT close OF cl_gui_dialogbox_container
      IMPORTING sender.
    METHODS on_double_click_batch FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column.
    METHODS on_double_click_dump FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column.
    METHODS on_double_click_iface FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column.
    METHODS on_hotspot_batch FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
    METHODS on_hotspot_dump FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
    METHODS on_hotspot_iface FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
    METHODS on_timer FOR EVENT finished OF cl_gui_timer.
  PRIVATE SECTION.
    DATA: mo_controller TYPE REF TO lcl_controller,
          mo_splitter   TYPE REF TO cl_gui_splitter_container,
          mo_top        TYPE REF TO cl_gui_container,
          mo_chart      TYPE REF TO cl_gui_container,
          mo_bottom     TYPE REF TO cl_gui_container,
          mo_alv_split  TYPE REF TO cl_gui_splitter_container,
          mo_cont_b     TYPE REF TO cl_gui_container,
          mo_cont_d     TYPE REF TO cl_gui_container,
          mo_cont_i     TYPE REF TO cl_gui_container,
          mo_html_kpi   TYPE REF TO cl_gui_html_viewer,
          mo_html_chart TYPE REF TO cl_gui_html_viewer,
          mo_alv_b      TYPE REF TO cl_gui_alv_grid,
          mo_alv_d      TYPE REF TO cl_gui_alv_grid,
          mo_alv_i      TYPE REF TO cl_gui_alv_grid,
          mo_stats_dlg  TYPE REF TO cl_gui_dialogbox_container,
          mo_stats_html TYPE REF TO cl_gui_html_viewer,
          mo_help_dlg   TYPE REF TO cl_gui_dialogbox_container,
          mo_help_html  TYPE REF TO cl_gui_html_viewer,
          mo_dump_dlg   TYPE REF TO cl_gui_dialogbox_container,
          mo_dump_html  TYPE REF TO cl_gui_html_viewer,
          mo_timer      TYPE REF TO cl_gui_timer,
          ms_sel        TYPE ty_sel,
          mt_status     TYPE ty_area_status_tab,
          mt_batch      TYPE ty_batch_tab,
          mt_dump       TYPE ty_dump_tab,
          mt_iface      TYPE ty_iface_tab,
          mt_batch_all  TYPE ty_batch_tab,
          mt_dump_all   TYPE ty_dump_tab,
          mt_iface_all  TYPE ty_iface_tab,
          mt_groups     TYPE ty_topn_group_tab,
          mt_buckets    TYPE ty_bucket_tab,
          mv_unit       TYPE char20,
          mv_persp      TYPE char1,
          mv_runtime    TYPE i,
          mv_query_ts   TYPE timestampl,
          mv_alv_b_ok   TYPE abap_bool,
          mv_alv_d_ok   TYPE abap_bool,
          mv_alv_i_ok   TYPE abap_bool.
    METHODS ensure_controls.
    METHODS build_alv_exclude RETURNING VALUE(rt_excl) TYPE ui_functions.
    METHODS setup_alv_batch.
    METHODS setup_alv_dump.
    METHODS setup_alv_iface.
    METHODS render_kpi.
    METHODS render_chart.
    METHODS build_kpi_html RETURNING VALUE(rv_html) TYPE string.
    METHODS build_topn_html RETURNING VALUE(rv_html) TYPE string.
    METHODS build_time_html RETURNING VALUE(rv_html) TYPE string.
    METHODS build_stats_html RETURNING VALUE(rv_html) TYPE string.
    METHODS build_help_html RETURNING VALUE(rv_html) TYPE string.
    METHODS load_html
      IMPORTING
        io_viewer TYPE REF TO cl_gui_html_viewer
        iv_html   TYPE string.
    METHODS show_html_dialog
      IMPORTING
        iv_title  TYPE char40
        iv_html   TYPE string
        iv_width  TYPE i DEFAULT 460
        iv_height TYPE i DEFAULT 340
      CHANGING
        co_dlg   TYPE REF TO cl_gui_dialogbox_container
        co_html  TYPE REF TO cl_gui_html_viewer.
    METHODS reaggregate.
    METHODS area_count IMPORTING iv_area TYPE char10 RETURNING VALUE(rv) TYPE i.
ENDCLASS.

*----------------------------------------------------------------------*
* Controller
*----------------------------------------------------------------------*
CLASS lcl_controller DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor.
    METHODS run.
    METHODS refresh.
    METHODS get_ui RETURNING VALUE(ro_ui) TYPE REF TO lcl_ui_dashboard.
    METHODS get_sel RETURNING VALUE(rs_sel) TYPE ty_sel.
  PRIVATE SECTION.
    DATA: mo_ui    TYPE REF TO lcl_ui_dashboard,
          mo_batch TYPE REF TO lcl_dp_batch,
          mo_dump  TYPE REF TO lcl_dp_dump,
          mo_iface TYPE REF TO lcl_dp_interface,
          ms_sel   TYPE ty_sel.
    METHODS read_sel.
    METHODS collect_and_display.
ENDCLASS.

CLASS lcl_controller IMPLEMENTATION.
  METHOD constructor.
    CREATE OBJECT mo_batch.
    CREATE OBJECT mo_dump.
    CREATE OBJECT mo_iface.
    CREATE OBJECT mo_ui
      EXPORTING
        io_controller = me.
  ENDMETHOD.

  METHOD get_ui.
    ro_ui = mo_ui.
  ENDMETHOD.

  METHOD get_sel.
    rs_sel = ms_sel.
  ENDMETHOD.

  METHOD read_sel.
    CLEAR ms_sel.
    ms_sel-frdat  = p_frdat.
    ms_sel-frtim  = p_frtim.
    ms_sel-todat  = p_todat.
    ms_sel-totim  = p_totim.
    ms_sel-hours  = p_hours.
    ms_sel-sm37   = boolc( cb_sm37 = abap_true ).
    ms_sel-st22   = boolc( cb_st22 = abap_true ).
    ms_sel-sxi    = boolc( cb_sxi  = abap_true ).
    ms_sel-mandt  = p_mand.
    ms_sel-maxrow = p_maxrow.
    ms_sel-topn   = p_topn.
    ms_sel-auto   = boolc( p_auto = abap_true ).
    ms_sel-sec    = p_sec.
    IF ms_sel-maxrow <= 0.
      ms_sel-maxrow = c_def_max.
    ENDIF.
    IF ms_sel-topn <= 0.
      ms_sel-topn = c_def_topn.
    ENDIF.
    IF ms_sel-mandt IS INITIAL.
      ms_sel-mandt = sy-mandt.
    ENDIF.
  ENDMETHOD.

  METHOD collect_and_display.
    DATA: lt_status TYPE ty_area_status_tab,
          ls_st     TYPE ty_area_status,
          lv_count  TYPE i,
          lv_auth   TYPE abap_bool,
          lv_err    TYPE abap_bool,
          lv_msg    TYPE char120,
          lv_area   TYPE char10,
          lv_title  TYPE char40,
          lv_color  TYPE char7,
          lv_alv    TYPE char4,
          lv_t0     TYPE i,
          lv_t1     TYPE i,
          lv_runtime TYPE i,
          lt_batch  TYPE ty_batch_tab,
          lt_dump   TYPE ty_dump_tab,
          lt_iface  TYPE ty_iface_tab,
          lt_batch_all TYPE ty_batch_tab,
          lt_dump_all  TYPE ty_dump_tab,
          lt_iface_all TYPE ty_iface_tab.

    GET RUN TIME FIELD lv_t0.

    IF ms_sel-sm37 = abap_true.
      CLEAR: ls_st, lv_count, lv_auth, lv_err, lv_msg.
      mo_batch->lif_mon_data_provider~get_area_info(
        IMPORTING ev_area = lv_area ev_title = lv_title
                  ev_color = lv_color ev_alv = lv_alv ).
      TRY.
          mo_batch->lif_mon_data_provider~get_data(
            EXPORTING is_sel = ms_sel
            IMPORTING ev_count = lv_count ev_auth_ok = lv_auth
                      ev_error = lv_err ev_message = lv_msg ).
        CATCH cx_root INTO DATA(lx1).
          lv_err = abap_true.
          lv_msg = 'SM37 조회 오류'.
      ENDTRY.
      ls_st-area = lv_area.
      ls_st-title = lv_title.
      ls_st-count = lv_count.
      ls_st-auth_ok = lv_auth.
      ls_st-error = lv_err.
      ls_st-message = lv_msg.
      ls_st-color_hex = lv_color.
      ls_st-alv_color = lv_alv.
      ls_st-light = lcl_util=>light_for_area( iv_area = c_area_sm37 iv_count = lv_count ).
      IF lv_auth = abap_false OR lv_err = abap_true.
        ls_st-light = 'Y'.
      ENDIF.
      APPEND ls_st TO lt_status.
      lt_batch = mo_batch->get_rows( ).
      lt_batch_all = mo_batch->get_all_rows( ).
    ENDIF.

    IF ms_sel-st22 = abap_true.
      CLEAR: ls_st, lv_count, lv_auth, lv_err, lv_msg.
      mo_dump->lif_mon_data_provider~get_area_info(
        IMPORTING ev_area = lv_area ev_title = lv_title
                  ev_color = lv_color ev_alv = lv_alv ).
      TRY.
          mo_dump->lif_mon_data_provider~get_data(
            EXPORTING is_sel = ms_sel
            IMPORTING ev_count = lv_count ev_auth_ok = lv_auth
                      ev_error = lv_err ev_message = lv_msg ).
        CATCH cx_root INTO DATA(lx2).
          lv_err = abap_true.
          lv_msg = 'ST22 조회 오류'.
      ENDTRY.
      ls_st-area = lv_area.
      ls_st-title = lv_title.
      ls_st-count = lv_count.
      ls_st-auth_ok = lv_auth.
      ls_st-error = lv_err.
      ls_st-message = lv_msg.
      ls_st-color_hex = lv_color.
      ls_st-alv_color = lv_alv.
      ls_st-light = lcl_util=>light_for_area( iv_area = c_area_st22 iv_count = lv_count ).
      IF lv_auth = abap_false OR lv_err = abap_true.
        ls_st-light = 'Y'.
      ENDIF.
      APPEND ls_st TO lt_status.
      lt_dump = mo_dump->get_rows( ).
      lt_dump_all = mo_dump->get_all_rows( ).
    ENDIF.

    IF ms_sel-sxi = abap_true.
      CLEAR: ls_st, lv_count, lv_auth, lv_err, lv_msg.
      mo_iface->lif_mon_data_provider~get_area_info(
        IMPORTING ev_area = lv_area ev_title = lv_title
                  ev_color = lv_color ev_alv = lv_alv ).
      TRY.
          mo_iface->lif_mon_data_provider~get_data(
            EXPORTING is_sel = ms_sel
            IMPORTING ev_count = lv_count ev_auth_ok = lv_auth
                      ev_error = lv_err ev_message = lv_msg ).
        CATCH cx_root INTO DATA(lx3).
          lv_err = abap_true.
          lv_msg = 'SXI 조회 오류'.
      ENDTRY.
      ls_st-area = lv_area.
      ls_st-title = lv_title.
      ls_st-count = lv_count.
      ls_st-auth_ok = lv_auth.
      ls_st-error = lv_err.
      ls_st-message = lv_msg.
      ls_st-color_hex = lv_color.
      ls_st-alv_color = lv_alv.
      ls_st-light = lcl_util=>light_for_area( iv_area = c_area_sxi iv_count = lv_count ).
      IF lv_auth = abap_false OR lv_err = abap_true.
        ls_st-light = 'Y'.
      ENDIF.
      APPEND ls_st TO lt_status.
      lt_iface = mo_iface->get_rows( ).
      lt_iface_all = mo_iface->get_all_rows( ).
    ENDIF.

    GET RUN TIME FIELD lv_t1.
    lv_runtime = ( lv_t1 - lv_t0 ) / 1000.

    mo_ui->display(
      EXPORTING
        is_sel = ms_sel
        it_status = lt_status
        it_batch = lt_batch
        it_dump = lt_dump
        it_iface = lt_iface
        it_batch_all = lt_batch_all
        it_dump_all = lt_dump_all
        it_iface_all = lt_iface_all
        iv_runtime = lv_runtime ).
  ENDMETHOD.

  METHOD run.
    read_sel( ).
    IF ms_sel-sm37 = abap_false AND ms_sel-st22 = abap_false AND ms_sel-sxi = abap_false.
      MESSAGE '조회 영역을 하나 이상 선택하세요'(e01) TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.
    collect_and_display( ).
  ENDMETHOD.

  METHOD refresh.
    read_sel( ).
    collect_and_display( ).
  ENDMETHOD.
ENDCLASS.

CLASS lcl_ui_dashboard IMPLEMENTATION.
  METHOD constructor.
    mo_controller = io_controller.
    mv_persp = c_persp_top.
  ENDMETHOD.

  METHOD free.
    IF mo_timer IS BOUND.
      mo_timer->cancel( ).
      FREE mo_timer.
    ENDIF.
    IF mo_stats_html IS BOUND.
      FREE mo_stats_html.
    ENDIF.
    IF mo_stats_dlg IS BOUND.
      FREE mo_stats_dlg.
    ENDIF.
    IF mo_help_html IS BOUND.
      FREE mo_help_html.
    ENDIF.
    IF mo_help_dlg IS BOUND.
      FREE mo_help_dlg.
    ENDIF.
    IF mo_dump_html IS BOUND.
      FREE mo_dump_html.
    ENDIF.
    IF mo_dump_dlg IS BOUND.
      FREE mo_dump_dlg.
    ENDIF.
  ENDMETHOD.

  METHOD handle_user_command.
    CASE iv_ucomm.
      WHEN 'REFRESH'.
        refresh( ).
      WHEN 'TOGGLE'.
        toggle_perspective( ).
      WHEN 'STATS'.
        show_stats( ).
      WHEN 'HELP'.
        show_help( ).
      WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
        free( ).
        LEAVE TO SCREEN 0.
    ENDCASE.
  ENDMETHOD.

  METHOD refresh.
    mo_controller->refresh( ).
  ENDMETHOD.

  METHOD toggle_perspective.
    IF mv_persp = c_persp_top.
      mv_persp = c_persp_tim.
    ELSE.
      mv_persp = c_persp_top.
    ENDIF.
    reaggregate( ).
    render_chart( ).
  ENDMETHOD.

  METHOD area_count.
    READ TABLE mt_status ASSIGNING FIELD-SYMBOL(<s>) WITH KEY area = iv_area.
    IF sy-subrc = 0.
      rv = <s>-count.
    ENDIF.
  ENDMETHOD.

  METHOD reaggregate.
    mt_groups = lcl_aggregator=>build_topn(
      it_batch = mt_batch_all
      it_dump  = mt_dump_all
      it_iface = mt_iface_all
      iv_topn  = ms_sel-topn
      iv_sm37  = ms_sel-sm37
      iv_st22  = ms_sel-st22
      iv_sxi   = ms_sel-sxi ).
    lcl_aggregator=>build_timeline(
      EXPORTING
        it_batch = mt_batch_all
        it_dump  = mt_dump_all
        it_iface = mt_iface_all
        is_sel   = ms_sel
        iv_sm37  = ms_sel-sm37
        iv_st22  = ms_sel-st22
        iv_sxi   = ms_sel-sxi
      IMPORTING
        et_buckets = mt_buckets
        ev_unit    = mv_unit ).
  ENDMETHOD.

  METHOD display.
    ms_sel = is_sel.
    mt_status = it_status.
    mt_batch = it_batch.
    mt_dump = it_dump.
    mt_iface = it_iface.
    mt_batch_all = it_batch_all.
    mt_dump_all = it_dump_all.
    mt_iface_all = it_iface_all.
    mv_runtime = iv_runtime.
    GET TIME STAMP FIELD mv_query_ts.
    ensure_controls( ).
    reaggregate( ).
    render_kpi( ).
    render_chart( ).
    setup_alv_batch( ).
    setup_alv_dump( ).
    setup_alv_iface( ).

    IF ms_sel-auto = abap_true AND ms_sel-sec > 0.
      IF mo_timer IS NOT BOUND.
        CREATE OBJECT mo_timer.
        SET HANDLER on_timer FOR mo_timer.
      ENDIF.
      mo_timer->interval = ms_sel-sec.
      mo_timer->run( ).
    ELSEIF mo_timer IS BOUND.
      mo_timer->cancel( ).
    ENDIF.
  ENDMETHOD.

  METHOD on_timer.
    refresh( ).
    IF ms_sel-auto = abap_true AND mo_timer IS BOUND.
      mo_timer->run( ).
    ENDIF.
  ENDMETHOD.

  METHOD ensure_controls.
    DATA: lv_cols TYPE i,
          lv_pos  TYPE i.

    IF mo_splitter IS BOUND.
      RETURN.
    ENDIF.

    CREATE OBJECT mo_splitter
      EXPORTING
        parent  = cl_gui_container=>default_screen
        rows    = 3
        columns = 1.
    " 상단·중간은 스크롤 없이 들어가게 얇게, ALV 넓게
    mo_splitter->set_row_height( id = 1 height = 11 ).
    mo_splitter->set_row_height( id = 2 height = 20 ).
    mo_splitter->set_row_height( id = 3 height = 69 ).
    mo_top    = mo_splitter->get_container( row = 1 column = 1 ).
    mo_chart  = mo_splitter->get_container( row = 2 column = 1 ).
    mo_bottom = mo_splitter->get_container( row = 3 column = 1 ).

    lv_cols = 0.
    IF ms_sel-sm37 = abap_true. lv_cols = lv_cols + 1. ENDIF.
    IF ms_sel-st22 = abap_true. lv_cols = lv_cols + 1. ENDIF.
    IF ms_sel-sxi  = abap_true. lv_cols = lv_cols + 1. ENDIF.
    IF lv_cols = 0.
      lv_cols = 1.
    ENDIF.

    CREATE OBJECT mo_alv_split
      EXPORTING
        parent  = mo_bottom
        rows    = 1
        columns = lv_cols.

    lv_pos = 1.
    IF ms_sel-sm37 = abap_true.
      mo_cont_b = mo_alv_split->get_container( row = 1 column = lv_pos ).
      lv_pos = lv_pos + 1.
    ENDIF.
    IF ms_sel-st22 = abap_true.
      mo_cont_d = mo_alv_split->get_container( row = 1 column = lv_pos ).
      lv_pos = lv_pos + 1.
    ENDIF.
    IF ms_sel-sxi = abap_true.
      mo_cont_i = mo_alv_split->get_container( row = 1 column = lv_pos ).
    ENDIF.

    CREATE OBJECT mo_html_kpi
      EXPORTING
        parent = mo_top.
    CREATE OBJECT mo_html_chart
      EXPORTING
        parent = mo_chart.
  ENDMETHOD.

  METHOD build_alv_exclude.
    DATA ls TYPE ui_func.
    " Keep Find/Sort/Filter; exclude export/edit/sum via ECC-safe fcodes
    ls = cl_gui_alv_grid=>mc_fc_detail. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_check. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_refresh. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_insert_row. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_delete_row. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_copy_row. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_append_row. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_copy. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_cut. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_paste. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_undo. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_graph. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_info. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_views. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_subtot. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_sum. APPEND ls TO rt_excl.
    ls = '&EXPORT'. APPEND ls TO rt_excl.
    ls = '&PC'. APPEND ls TO rt_excl.
    ls = '&XXL'. APPEND ls TO rt_excl.
    ls = '&AQW'. APPEND ls TO rt_excl.
    ls = '&PRINT_BACK'. APPEND ls TO rt_excl.
    ls = '&AVE'. APPEND ls TO rt_excl.
    ls = '&MIN'. APPEND ls TO rt_excl.
    ls = '&MAX'. APPEND ls TO rt_excl.
    ls = '&COUNT'. APPEND ls TO rt_excl.
  ENDMETHOD.

  METHOD setup_alv_batch.
    DATA: lt_fcat TYPE lvc_t_fcat,
          ls_fcat TYPE lvc_s_fcat,
          ls_layo TYPE lvc_s_layo,
          lt_excl TYPE ui_functions.

    IF mo_cont_b IS NOT BOUND.
      RETURN.
    ENDIF.
    IF mo_alv_b IS NOT BOUND.
      CREATE OBJECT mo_alv_b
        EXPORTING
          i_parent = mo_cont_b.
      SET HANDLER on_double_click_batch FOR mo_alv_b.
      SET HANDLER on_hotspot_batch FOR mo_alv_b.
    ENDIF.

    CLEAR lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'JOBNAME'.
    ls_fcat-coltext   = '잡명'.
    ls_fcat-outputlen = 20.
    ls_fcat-hotspot   = 'X'.
    APPEND ls_fcat TO lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'PROGNAME'.
    ls_fcat-coltext   = '프로그램'.
    ls_fcat-outputlen = 20.
    ls_fcat-hotspot   = ' '.
    APPEND ls_fcat TO lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'SDLUNAME'.
    ls_fcat-coltext   = '사용자'.
    ls_fcat-outputlen = 12.
    ls_fcat-hotspot   = ' '.
    APPEND ls_fcat TO lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'STRTDATE'.
    ls_fcat-coltext   = '시작일'.
    ls_fcat-outputlen = 10.
    ls_fcat-hotspot   = ' '.
    APPEND ls_fcat TO lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'STRTTIME'.
    ls_fcat-coltext   = '시작시간'.
    ls_fcat-outputlen = 8.
    ls_fcat-hotspot   = ' '.
    APPEND ls_fcat TO lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'ENDDATE'.
    ls_fcat-coltext   = '종료일'.
    ls_fcat-outputlen = 10.
    ls_fcat-hotspot   = ' '.
    APPEND ls_fcat TO lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'ENDTIME'.
    ls_fcat-coltext   = '종료시간'.
    ls_fcat-outputlen = 8.
    ls_fcat-hotspot   = ' '.
    APPEND ls_fcat TO lt_fcat.

    CLEAR ls_layo.
    ls_layo-zebra = abap_true.
    ls_layo-cwidth_opt = abap_true.
    ls_layo-sel_mode = 'A'.
    ls_layo-info_fname = 'LINE_COLOR'.
    ls_layo-grid_title = 'SM37 배치 에러'.
    lt_excl = build_alv_exclude( ).

    IF mv_alv_b_ok = abap_true.
      mo_alv_b->refresh_table_display( ).
    ELSE.
      mo_alv_b->set_table_for_first_display(
        EXPORTING
          is_layout            = ls_layo
          it_toolbar_excluding = lt_excl
        CHANGING
          it_outtab            = mt_batch
          it_fieldcatalog      = lt_fcat ).
      mv_alv_b_ok = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD setup_alv_dump.
    DATA: lt_fcat TYPE lvc_t_fcat,
          ls_fcat TYPE lvc_s_fcat,
          ls_layo TYPE lvc_s_layo,
          lt_excl TYPE ui_functions.

    IF mo_cont_d IS NOT BOUND.
      RETURN.
    ENDIF.
    IF mo_alv_d IS NOT BOUND.
      CREATE OBJECT mo_alv_d
        EXPORTING
          i_parent = mo_cont_d.
      SET HANDLER on_double_click_dump FOR mo_alv_d.
      SET HANDLER on_hotspot_dump FOR mo_alv_d.
    ENDIF.

    CLEAR lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'PROGNAME'.
    ls_fcat-coltext   = '프로그램'.
    ls_fcat-outputlen = 24.
    ls_fcat-hotspot   = 'X'.
    APPEND ls_fcat TO lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'RT_ERROR'.
    ls_fcat-coltext   = '에러유형'.
    ls_fcat-outputlen = 24.
    ls_fcat-hotspot   = 'X'.
    APPEND ls_fcat TO lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'UNAME'.
    ls_fcat-coltext   = '사용자'.
    ls_fcat-outputlen = 12.
    ls_fcat-hotspot   = ' '.
    APPEND ls_fcat TO lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'DATUM'.
    ls_fcat-coltext   = '발생일'.
    ls_fcat-outputlen = 10.
    ls_fcat-hotspot   = ' '.
    APPEND ls_fcat TO lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'UZEIT'.
    ls_fcat-coltext   = '발생시간'.
    ls_fcat-outputlen = 8.
    ls_fcat-hotspot   = ' '.
    APPEND ls_fcat TO lt_fcat.

    CLEAR ls_layo.
    ls_layo-zebra = abap_true.
    ls_layo-cwidth_opt = abap_true.
    ls_layo-sel_mode = 'A'.
    ls_layo-info_fname = 'LINE_COLOR'.
    ls_layo-grid_title = 'ST22 런타임 에러'.
    lt_excl = build_alv_exclude( ).

    IF mv_alv_d_ok = abap_true.
      mo_alv_d->refresh_table_display( ).
    ELSE.
      mo_alv_d->set_table_for_first_display(
        EXPORTING
          is_layout            = ls_layo
          it_toolbar_excluding = lt_excl
        CHANGING
          it_outtab            = mt_dump
          it_fieldcatalog      = lt_fcat ).
      mv_alv_d_ok = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD setup_alv_iface.
    DATA: lt_fcat TYPE lvc_t_fcat,
          ls_fcat TYPE lvc_s_fcat,
          ls_layo TYPE lvc_s_layo,
          lt_excl TYPE ui_functions.

    IF mo_cont_i IS NOT BOUND.
      RETURN.
    ENDIF.
    IF mo_alv_i IS NOT BOUND.
      CREATE OBJECT mo_alv_i
        EXPORTING
          i_parent = mo_cont_i.
      SET HANDLER on_double_click_iface FOR mo_alv_i.
      SET HANDLER on_hotspot_iface FOR mo_alv_i.
    ENDIF.

    CLEAR lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'IF_NAME'.
    ls_fcat-coltext   = '인터페이스'.
    ls_fcat-outputlen = 28.
    ls_fcat-hotspot   = 'X'.
    APPEND ls_fcat TO lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'MSGSTATE'.
    ls_fcat-coltext   = '상태'.
    ls_fcat-outputlen = 8.
    ls_fcat-hotspot   = ' '.
    APPEND ls_fcat TO lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'EXE_DATE'.
    ls_fcat-coltext   = '발생일'.
    ls_fcat-outputlen = 10.
    ls_fcat-hotspot   = ' '.
    APPEND ls_fcat TO lt_fcat.
    CLEAR ls_fcat.
    ls_fcat-fieldname = 'EXE_TIME'.
    ls_fcat-coltext   = '발생시간'.
    ls_fcat-outputlen = 8.
    ls_fcat-hotspot   = ' '.
    APPEND ls_fcat TO lt_fcat.

    CLEAR ls_layo.
    ls_layo-zebra = abap_true.
    ls_layo-cwidth_opt = abap_true.
    ls_layo-sel_mode = 'A'.
    ls_layo-info_fname = 'LINE_COLOR'.
    ls_layo-grid_title = 'SXI 인터페이스 에러'.
    lt_excl = build_alv_exclude( ).

    IF mv_alv_i_ok = abap_true.
      mo_alv_i->refresh_table_display( ).
    ELSE.
      mo_alv_i->set_table_for_first_display(
        EXPORTING
          is_layout            = ls_layo
          it_toolbar_excluding = lt_excl
        CHANGING
          it_outtab            = mt_iface
          it_fieldcatalog      = lt_fcat ).
      mv_alv_i_ok = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD on_double_click_batch.
    DATA ls_row TYPE ty_batch.
    DATA lv_idx TYPE lvc_index.
    lv_idx = e_row-index.
    CHECK lv_idx > 0.
    READ TABLE mt_batch INTO ls_row INDEX lv_idx.
    CHECK sy-subrc = 0.
    lcl_navigator=>to_batch( ls_row ).
  ENDMETHOD.

  METHOD on_hotspot_batch.
    DATA ls_row TYPE ty_batch.
    DATA lv_idx TYPE lvc_index.
    lv_idx = e_row_id-index.
    CHECK lv_idx > 0.
    READ TABLE mt_batch INTO ls_row INDEX lv_idx.
    CHECK sy-subrc = 0.
    lcl_navigator=>to_batch( ls_row ).
  ENDMETHOD.

  METHOD on_double_click_dump.
    DATA ls_row TYPE ty_dump.
    DATA lv_idx TYPE lvc_index.
    lv_idx = e_row-index.
    CHECK lv_idx > 0.
    READ TABLE mt_dump INTO ls_row INDEX lv_idx.
    CHECK sy-subrc = 0.
    show_dump_detail( ls_row ).
  ENDMETHOD.

  METHOD on_hotspot_dump.
    DATA ls_row TYPE ty_dump.
    DATA lv_idx TYPE lvc_index.
    lv_idx = e_row_id-index.
    CHECK lv_idx > 0.
    READ TABLE mt_dump INTO ls_row INDEX lv_idx.
    CHECK sy-subrc = 0.
    show_dump_detail( ls_row ).
  ENDMETHOD.

  METHOD on_double_click_iface.
    DATA ls_row TYPE ty_iface.
    DATA lv_idx TYPE lvc_index.
    lv_idx = e_row-index.
    CHECK lv_idx > 0.
    READ TABLE mt_iface INTO ls_row INDEX lv_idx.
    CHECK sy-subrc = 0.
    lcl_navigator=>to_iface( ls_row ).
  ENDMETHOD.

  METHOD on_hotspot_iface.
    DATA ls_row TYPE ty_iface.
    DATA lv_idx TYPE lvc_index.
    lv_idx = e_row_id-index.
    CHECK lv_idx > 0.
    READ TABLE mt_iface INTO ls_row INDEX lv_idx.
    CHECK sy-subrc = 0.
    lcl_navigator=>to_iface( ls_row ).
  ENDMETHOD.

  METHOD load_html.
    DATA: lt_html  TYPE STANDARD TABLE OF w3html,
          ls_html  TYPE w3html,
          lv_html  TYPE string,
          lv_url   TYPE c LENGTH 2048,
          lv_len   TYPE i,
          lv_off   TYPE i,
          lv_chunk TYPE string.

    CHECK io_viewer IS BOUND.
    lv_html = iv_html.
    lv_len = strlen( lv_html ).
    lv_off = 0.
    CLEAR lt_html.
    WHILE lv_off < lv_len.
      IF lv_len - lv_off >= 255.
        lv_chunk = lv_html+lv_off(255).
        lv_off = lv_off + 255.
      ELSE.
        lv_chunk = lv_html+lv_off.
        lv_off = lv_len.
      ENDIF.
      CLEAR ls_html.
      ls_html-line = lv_chunk.
      APPEND ls_html TO lt_html.
    ENDWHILE.

    io_viewer->load_data(
      EXPORTING
        type         = 'text'
        subtype      = 'html'
        encoding     = '65001'
      IMPORTING
        assigned_url = lv_url
      CHANGING
        data_table   = lt_html
      EXCEPTIONS
        OTHERS       = 1 ).
    IF sy-subrc = 0.
      io_viewer->show_url( url = lv_url ).
    ENDIF.
  ENDMETHOD.

  METHOD render_kpi.
    load_html( io_viewer = mo_html_kpi iv_html = build_kpi_html( ) ).
  ENDMETHOD.

  METHOD render_chart.
    DATA lv_html TYPE string.
    IF mv_persp = c_persp_tim.
      lv_html = build_time_html( ).
    ELSE.
      lv_html = build_topn_html( ).
    ENDIF.
    load_html( io_viewer = mo_html_chart iv_html = lv_html ).
  ENDMETHOD.

  METHOD build_kpi_html.
    DATA: lv_css     TYPE string,
          lv_body    TYPE string,
          lv_card    TYPE string,
          lv_health  TYPE char20,
          lv_hko     TYPE char20,
          lv_total   TYPE i,
          lv_auto    TYPE string,
          lv_ts      TYPE string,
          lv_light   TYPE string,
          lv_badge   TYPE char10,
          lv_share   TYPE p DECIMALS 1,
          lv_acol    TYPE char7,
          lv_area_ko TYPE char20.

    lv_health = lcl_util=>health_label( mt_status ).
    lv_hko = lcl_util=>health_label_ko( lv_health ).
    LOOP AT mt_status ASSIGNING FIELD-SYMBOL(<t>).
      lv_total = lv_total + <t>-count.
    ENDLOOP.

    " 스크롤 없이 KPI 패널에 맞춤 (overflow hidden)
    lv_css =
      'html,body{margin:0;height:100%;overflow:hidden;' &&
      'font-family:Arial,Helvetica,sans-serif;background:#0f172a;color:#e2e8f0;}' &&
      '.wrap{padding:4px 8px;height:100%;box-sizing:border-box;}' &&
      '.head{display:flex;justify-content:space-between;align-items:center;margin-bottom:3px;}' &&
      '.hlabel{font-size:14px;font-weight:700;}' &&
      '.meta{font-size:10px;color:#94a3b8;}' &&
      '.chip{display:inline-block;background:#1e293b;border:1px solid #334155;' &&
      'border-radius:8px;padding:0 5px;margin-left:3px;}' &&
      '.row{display:flex;gap:5px;}' &&
      '.card{flex:1;background:#1e293b;border-radius:5px;padding:4px 7px;' &&
      'border-left:4px solid #64748b;min-width:0;}' &&
      '.ttl{font-size:10px;color:#94a3b8;}' &&
      '.num{font-size:18px;font-weight:700;line-height:1.15;}' &&
      '.badge{font-size:9px;padding:0 5px;border-radius:7px;margin-left:3px;}' &&
      '.R{background:#7f1d1d;color:#fecaca;}' &&
      '.Y{background:#78350f;color:#fde68a;}' &&
      '.G{background:#14532d;color:#bbf7d0;}'.

    CASE lv_health.
      WHEN 'CRITICAL'.
        lv_light = '#EF5350'.
      WHEN 'WARNING'.
        lv_light = '#FFA726'.
      WHEN OTHERS.
        lv_light = '#26A69A'.
    ENDCASE.

    IF ms_sel-auto = abap_true.
      lv_auto = |ON { ms_sel-sec }s|.
    ELSE.
      lv_auto = 'OFF'.
    ENDIF.
    lv_ts = |{ sy-datum DATE = USER } { sy-uzeit TIME = USER }|.

    lv_body =
      '<div class="wrap"><div class="head">' &&
      '<div class="hlabel" style="color:' && lv_light && ';">' &&
      lcl_util=>html_escape( lv_hko ) &&
      ' <span style="font-size:12px;color:#cbd5e1;">총 ' &&
      |{ lv_total }| && '건</span></div>' &&
      '<div class="meta">' &&
      '<span class="chip">' && lcl_util=>html_escape( lv_ts ) && '</span>' &&
      '<span class="chip">' && |{ mv_runtime }| && 'ms</span>' &&
      '<span class="chip">자동 ' && lv_auto && '</span>' &&
      '</div></div><div class="row">'.

    LOOP AT mt_status ASSIGNING FIELD-SYMBOL(<s>).
      lv_badge = lcl_util=>light_label_ko( <s>-light ).
      CASE <s>-area.
        WHEN c_area_sm37.
          lv_area_ko = 'SM37 배치'.
        WHEN c_area_st22.
          lv_area_ko = 'ST22 덤프'.
        WHEN OTHERS.
          lv_area_ko = 'SXI IF'.
      ENDCASE.
      IF lv_total > 0.
        lv_share = <s>-count * 100 / lv_total.
      ELSE.
        lv_share = 0.
      ENDIF.
      lv_acol = <s>-color_hex.
      lv_card =
        '<div class="card" style="border-left-color:' && lv_acol && ';" title="' &&
        lcl_util=>html_escape( <s>-message ) && '">' &&
        '<div class="ttl">' && lv_area_ko &&
        ' <span class="badge ' && <s>-light && '">' && lv_badge && '</span></div>' &&
        '<div class="num">' && |{ <s>-count }| &&
        '<span style="font-size:10px;color:#94a3b8;font-weight:400;"> · ' &&
        |{ lv_share }| && '%</span></div></div>'.
      lv_body = lv_body && lv_card.
    ENDLOOP.

    lv_body = lv_body && '</div></div>'.
    rv_html =
      '<!DOCTYPE html><html><head><meta charset="utf-8"><style>' &&
      lv_css && '</style></head><body>' && lv_body && '</body></html>'.
  ENDMETHOD.

  METHOD build_topn_html.
    DATA: lv_css     TYPE string,
          lv_body    TYPE string,
          lv_row     TYPE string,
          lv_pct     TYPE i,
          lv_max     TYPE i,
          lv_key     TYPE string,
          lv_col     TYPE char7,
          lv_empty   TYPE abap_bool,
          lv_area_ko TYPE char20,
          lv_shown   TYPE i.

    lv_css =
      'html,body{margin:0;height:100%;overflow:hidden;' &&
      'font-family:Arial,Helvetica,sans-serif;background:#0b1220;color:#e2e8f0;}' &&
      '.wrap{padding:4px 8px;height:100%;box-sizing:border-box;}' &&
      '.head{display:flex;justify-content:space-between;align-items:center;margin-bottom:3px;}' &&
      'h3{margin:0;font-size:12px;}' &&
      '.hint{font-size:10px;color:#94a3b8;}' &&
      '.areas{display:flex;gap:6px;height:calc(100% - 18px);}' &&
      '.area{flex:1;min-width:0;background:#111827;border-radius:5px;padding:4px 6px;overflow:hidden;}' &&
      '.at{font-size:10px;font-weight:700;margin-bottom:2px;}' &&
      '.row{display:flex;align-items:center;margin:1px 0;}' &&
      '.lab{width:40%;font-size:9px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}' &&
      '.track{flex:1;height:8px;background:#1e293b;border-radius:2px;margin:0 4px;}' &&
      '.fill{height:8px;border-radius:2px;}' &&
      '.cnt{width:24px;text-align:right;font-size:9px;}'.

    lv_body =
      '<div class="wrap"><div class="head"><h3>영역별 Top-N</h3>' &&
      '<div class="hint">TOGGLE=시간추이</div></div><div class="areas">'.

    lv_empty = abap_true.
    LOOP AT mt_groups ASSIGNING FIELD-SYMBOL(<g>).
      lv_empty = abap_false.
      CASE <g>-area.
        WHEN c_area_sm37.
          lv_col = c_col_sm37.
          lv_area_ko = 'SM37 잡명'.
        WHEN c_area_st22.
          lv_col = c_col_st22.
          lv_area_ko = 'ST22 유형'.
        WHEN OTHERS.
          lv_col = c_col_sxi.
          lv_area_ko = 'SXI IF'.
      ENDCASE.
      lv_max = <g>-maxc.
      IF lv_max <= 0.
        lv_max = 1.
      ENDIF.
      lv_body = lv_body && '<div class="area"><div class="at" style="color:' &&
                lv_col && ';">' && lv_area_ko && '</div>'.
      IF <g>-items IS INITIAL.
        lv_body = lv_body && '<div class="hint">에러 없음</div>'.
      ENDIF.
      CLEAR lv_shown.
      LOOP AT <g>-items ASSIGNING FIELD-SYMBOL(<it>).
        lv_shown = lv_shown + 1.
        IF lv_shown > 4.
          EXIT.
        ENDIF.
        lv_pct = <it>-count * 100 / lv_max.
        IF lv_pct = 0 AND <it>-count > 0.
          lv_pct = 1.
        ENDIF.
        lv_key = lcl_util=>html_escape( <it>-key ).
        lv_row =
          '<div class="row" title="' && lv_key && '">' &&
          '<div class="lab">' && lv_key && '</div>' &&
          '<div class="track"><div class="fill" style="width:' &&
          |{ lv_pct }| && '%;background:' && <it>-color && ';"></div></div>' &&
          '<div class="cnt">' && |{ <it>-count }| && '</div></div>'.
        lv_body = lv_body && lv_row.
      ENDLOOP.
      lv_body = lv_body && '</div>'.
    ENDLOOP.

    IF lv_empty = abap_true.
      lv_body = lv_body && '<div class="hint">차트 데이터 없음</div>'.
    ENDIF.
    lv_body = lv_body && '</div></div>'.
    rv_html =
      '<!DOCTYPE html><html><head><meta charset="utf-8"><style>' &&
      lv_css && '</style></head><body>' && lv_body && '</body></html>'.
  ENDMETHOD.

  METHOD build_time_html.
    DATA: lv_css   TYPE string,
          lv_body  TYPE string,
          lv_bar   TYPE string,
          lv_max   TYPE i,
          lv_sum   TYPE i,
          lv_h     TYPE i,
          lv_first TYPE char20,
          lv_last  TYPE char20,
          lv_n     TYPE i,
          lv_peak  TYPE i,
          lv_tot_b TYPE i.

    " 스크롤 없음 · 막대 굵게 · 축은 시작|단위|종료만
    lv_css =
      'html,body{margin:0;height:100%;overflow:hidden;' &&
      'font-family:Arial,Helvetica,sans-serif;background:#0b1220;color:#e2e8f0;}' &&
      '.wrap{padding:4px 8px;height:100%;box-sizing:border-box;display:flex;flex-direction:column;}' &&
      '.head{display:flex;justify-content:space-between;align-items:center;flex:0 0 auto;}' &&
      'h3{margin:0;font-size:12px;}' &&
      '.hint{font-size:10px;color:#94a3b8;}' &&
      '.leg{margin:2px 0;flex:0 0 auto;}' &&
      '.leg span{margin-right:8px;font-size:10px;}' &&
      '.dot{display:inline-block;width:7px;height:7px;border-radius:2px;margin-right:2px;}' &&
      '.main{flex:1 1 auto;display:flex;min-height:0;}' &&
      '.yaxis{width:28px;display:flex;flex-direction:column;justify-content:space-between;' &&
      'font-size:9px;color:#94a3b8;padding:2px 2px 14px 0;text-align:right;}' &&
      '.chart{flex:1;display:flex;align-items:stretch;gap:5px;' &&
      'border-bottom:1px solid #475569;border-left:1px solid #334155;padding:0 2px 0 0;min-width:0;}' &&
      '.col{flex:1;height:100%;display:flex;flex-direction:column-reverse;align-items:stretch;' &&
      'justify-content:flex-start;min-width:12px;max-width:56px;margin:0 auto;}' &&
      '.s{width:100%;border-radius:1px 1px 0 0;min-height:2px;}' &&
      '.axis{display:flex;justify-content:space-between;font-size:10px;color:#cbd5e1;' &&
      'margin-top:3px;flex:0 0 auto;padding-left:28px;}' &&
      '.axis b{color:#e2e8f0;font-weight:600;}'.

    lv_n = lines( mt_buckets ).
    IF lv_n > 0.
      READ TABLE mt_buckets ASSIGNING FIELD-SYMBOL(<f>) INDEX 1.
      lv_first = <f>-label.
      READ TABLE mt_buckets ASSIGNING FIELD-SYMBOL(<l>) INDEX lv_n.
      lv_last = <l>-label.
    ENDIF.

    LOOP AT mt_buckets ASSIGNING FIELD-SYMBOL(<b>).
      lv_sum = <b>-sm37 + <b>-st22 + <b>-sxi.
      IF lv_sum > lv_max.
        lv_max = lv_sum.
      ENDIF.
      lv_tot_b = lv_tot_b + lv_sum.
    ENDLOOP.
    lv_peak = lv_max.
    IF lv_max <= 0.
      lv_max = 1.
    ENDIF.

    lv_body =
      '<div class="wrap"><div class="head"><h3>시간대별 추이</h3>' &&
      '<div class="hint">TOGGLE=Top-N · 막대에 마우스=상세 · 최대 ' &&
      |{ lv_peak }| && '건</div></div>' &&
      '<div class="leg">' &&
      '<span><i class="dot" style="background:#26A69A;"></i>SM37</span>' &&
      '<span><i class="dot" style="background:#EF5350;"></i>ST22</span>' &&
      '<span><i class="dot" style="background:#FFA726;"></i>SXI</span>' &&
      '<span style="color:#94a3b8;">합계 ' && |{ lv_tot_b }| && '건 / ' &&
      |{ lv_n }| && '구간</span></div><div class="main">' &&
      '<div class="yaxis"><div>' && |{ lv_peak }| && '</div><div>0</div></div>' &&
      '<div class="chart">'.

    LOOP AT mt_buckets ASSIGNING <b>.
      lv_sum = <b>-sm37 + <b>-st22 + <b>-sxi.
      lv_bar = '<div class="col" title="' &&
               lcl_util=>html_escape( <b>-label ) &&
               ' | SM37 ' && |{ <b>-sm37 }| &&
               ' · ST22 ' && |{ <b>-st22 }| &&
               ' · SXI ' && |{ <b>-sxi }| &&
               ' · 합 ' && |{ lv_sum }| && '">' .
      IF <b>-sxi > 0.
        lv_h = <b>-sxi * 100 / lv_max.
        IF lv_h = 0.
          lv_h = 2.
        ENDIF.
        lv_bar = lv_bar && '<div class="s" style="height:' && |{ lv_h }| &&
                 '%;background:#FFA726;"></div>'.
      ENDIF.
      IF <b>-st22 > 0.
        lv_h = <b>-st22 * 100 / lv_max.
        IF lv_h = 0.
          lv_h = 2.
        ENDIF.
        lv_bar = lv_bar && '<div class="s" style="height:' && |{ lv_h }| &&
                 '%;background:#EF5350;"></div>'.
      ENDIF.
      IF <b>-sm37 > 0.
        lv_h = <b>-sm37 * 100 / lv_max.
        IF lv_h = 0.
          lv_h = 2.
        ENDIF.
        lv_bar = lv_bar && '<div class="s" style="height:' && |{ lv_h }| &&
                 '%;background:#26A69A;"></div>'.
      ENDIF.
      IF lv_sum = 0.
        lv_bar = lv_bar && '<div class="s" style="height:2px;background:#334155;"></div>'.
      ENDIF.
      lv_bar = lv_bar && '</div>'.
      lv_body = lv_body && lv_bar.
    ENDLOOP.

    lv_body = lv_body && '</div></div><div class="axis">' &&
              '<span><b>시작</b> ' && lcl_util=>html_escape( lv_first ) && '</span>' &&
              '<span>' && lcl_util=>html_escape( mv_unit ) && '</span>' &&
              '<span><b>종료</b> ' && lcl_util=>html_escape( lv_last ) && '</span>' &&
              '</div></div>'.

    rv_html =
      '<!DOCTYPE html><html><head><meta charset="utf-8"><style>' &&
      lv_css && '</style></head><body>' && lv_body && '</body></html>'.
  ENDMETHOD.

  METHOD build_stats_html.
    DATA: lv_css    TYPE string,
          lv_body   TYPE string,
          lv_card   TYPE string,
          lv_health TYPE char20,
          lv_hko    TYPE char20,
          lv_total  TYPE i,
          lv_hdr    TYPE string,
          lv_badge  TYPE char10,
          lv_share  TYPE p DECIMALS 1,
          lv_bar    TYPE i,
          lv_persp  TYPE string,
          lv_auto   TYPE string,
          lv_msg    TYPE char60.

    lv_health = lcl_util=>health_label( mt_status ).
    lv_hko = lcl_util=>health_label_ko( lv_health ).
    LOOP AT mt_status ASSIGNING FIELD-SYMBOL(<t>).
      lv_total = lv_total + <t>-count.
    ENDLOOP.

    CASE lv_health.
      WHEN 'CRITICAL'.
        lv_hdr = '#b91c1c'.
      WHEN 'WARNING'.
        lv_hdr = '#d97706'.
      WHEN OTHERS.
        lv_hdr = '#0f766e'.
    ENDCASE.

    IF mv_persp = c_persp_tim.
      lv_persp = '시간추이'.
    ELSE.
      lv_persp = 'Top-N'.
    ENDIF.
    IF ms_sel-auto = abap_true.
      lv_auto = |ON/{ ms_sel-sec }s|.
    ELSE.
      lv_auto = 'OFF'.
    ENDIF.

    lv_css =
      'body{margin:0;font-family:Arial,Helvetica,sans-serif;background:#0f172a;color:#e2e8f0;}' &&
      '.hdr{padding:10px 12px;background:' && lv_hdr && ';}' &&
      '.hl{font-size:18px;font-weight:700;}' &&
      '.sub{font-size:12px;opacity:.95;margin-top:2px;}' &&
      '.wrap{padding:8px 12px;}' &&
      '.card{background:#1e293b;border-radius:6px;padding:8px 10px;margin:6px 0;' &&
      'border-left:4px solid #64748b;}' &&
      '.row{display:flex;justify-content:space-between;align-items:center;}' &&
      '.num{font-size:18px;font-weight:700;}' &&
      '.badge{font-size:10px;padding:1px 6px;border-radius:8px;}' &&
      '.R{background:#7f1d1d;color:#fecaca;}' &&
      '.Y{background:#78350f;color:#fde68a;}' &&
      '.G{background:#14532d;color:#bbf7d0;}' &&
      '.barbg{height:4px;background:#334155;border-radius:2px;margin-top:4px;}' &&
      '.barfg{height:4px;border-radius:2px;}' &&
      '.chips span{display:inline-block;background:#1e293b;border:1px solid #334155;' &&
      'border-radius:8px;padding:2px 6px;margin:3px 3px 0 0;font-size:10px;}' &&
      '.ft{margin-top:8px;font-size:11px;color:#cbd5e1;}' &&
      '.msg{font-size:10px;color:#94a3b8;margin-top:2px;white-space:nowrap;' &&
      'overflow:hidden;text-overflow:ellipsis;}'.

    lv_body =
      '<div class="hdr"><div class="hl">' && lcl_util=>html_escape( lv_hko ) &&
      ' · 총 ' && |{ lv_total }| && '건</div>' &&
      '<div class="sub">영역별 에러 요약 (읽기 전용)</div></div><div class="wrap">'.

    LOOP AT mt_status ASSIGNING FIELD-SYMBOL(<s>).
      lv_badge = lcl_util=>light_label_ko( <s>-light ).
      lv_msg = lcl_util=>short_status(
        iv_text    = <s>-message
        iv_count   = <s>-count
        iv_error   = <s>-error
        iv_auth_ok = <s>-auth_ok ).
      IF lv_total > 0.
        lv_share = <s>-count * 100 / lv_total.
        lv_bar = <s>-count * 100 / lv_total.
      ELSE.
        lv_share = 0.
        lv_bar = 0.
      ENDIF.
      lv_card =
        '<div class="card" style="border-left-color:' && <s>-color_hex && ';">' &&
        '<div class="row"><div>' && lcl_util=>html_escape( <s>-title ) &&
        '</div><span class="badge ' && <s>-light && '">' && lv_badge &&
        '</span></div>' &&
        '<div class="row"><div class="num">' && |{ <s>-count }| &&
        '</div><div>' && |{ lv_share }| && '%</div></div>' &&
        '<div class="barbg"><div class="barfg" style="width:' && |{ lv_bar }| &&
        '%;background:' && <s>-color_hex && ';"></div></div>' &&
        '<div class="msg">' && lcl_util=>html_escape( lv_msg ) && '</div></div>'.
      lv_body = lv_body && lv_card.
    ENDLOOP.

    lv_body = lv_body &&
      '<div class="chips">' &&
      '<span>' && |{ sy-datum DATE = USER } { sy-uzeit TIME = USER }| && '</span>' &&
      '<span>' && |{ mv_runtime }| && 'ms</span>' &&
      '<span>' && lv_persp && '</span>' &&
      '<span>자동 ' && lv_auto && '</span></div>' &&
      '<div class="ft">우상단 X 로 닫기 · 읽기 전용</div></div>'.

    rv_html =
      '<!DOCTYPE html><html><head><meta charset="utf-8"><style>' &&
      lv_css && '</style></head><body>' && lv_body && '</body></html>'.
  ENDMETHOD.

  METHOD build_help_html.
    DATA: lv_css  TYPE string,
          lv_body TYPE string.

    lv_css =
      'body{margin:0;font-family:Arial,Helvetica,sans-serif;background:#0f172a;color:#e2e8f0;}' &&
      '.hdr{padding:10px 12px;background:#0284c7;}' &&
      '.hl{font-size:16px;font-weight:700;}' &&
      '.wrap{padding:8px 12px;}' &&
      '.step{background:#1e293b;border-radius:6px;padding:7px 10px;margin:5px 0;font-size:12px;}' &&
      '.n{display:inline-block;width:18px;height:18px;border-radius:50%;' &&
      'background:#0ea5e9;color:#0f172a;text-align:center;font-weight:700;' &&
      'margin-right:6px;font-size:11px;line-height:18px;}' &&
      '.cmd{display:inline-block;background:#334155;border-radius:3px;' &&
      'padding:0 5px;font-family:Consolas,monospace;font-size:11px;margin:0 2px;}' &&
      '.note{background:#422006;border:1px solid #b45309;border-radius:6px;' &&
      'padding:8px;margin-top:8px;font-size:11px;color:#fde68a;}' &&
      '.ft{margin-top:8px;font-size:11px;color:#cbd5e1;}'.

    lv_body =
      '<div class="hdr"><div class="hl">사용 안내</div></div>' &&
      '<div class="wrap">' &&
      '<div class="step"><span class="n">1</span>기간·영역 지정 후 F8 실행</div>' &&
      '<div class="step"><span class="n">2</span><span class="cmd">REFRESH</span> 동일 조건 재조회</div>' &&
      '<div class="step"><span class="n">3</span><span class="cmd">TOGGLE</span> Top-N ↔ 시간추이</div>' &&
      '<div class="step"><span class="n">4</span><span class="cmd">STATS</span> KPI 요약 팝업</div>' &&
      '<div class="step"><span class="n">5</span>SM37/SXI 더블클릭 → 표준 상세(표시 전용)</div>' &&
      '<div class="step"><span class="n">6</span>ST22 더블클릭 → 런타임 에러 상세 팝업(ST22 미호출)</div>' &&
      '<div class="note">읽기 전용: 재실행/재전송/DML/COMMIT/Enqueue 없음</div>' &&
      '<div class="ft">우상단 X 로 닫기</div></div>'.

    rv_html =
      '<!DOCTYPE html><html><head><meta charset="utf-8"><style>' &&
      lv_css && '</style></head><body>' && lv_body && '</body></html>'.
  ENDMETHOD.

  METHOD show_html_dialog.
    " 기존 팝업이 있으면 컨트롤 free 후 재생성
    IF co_html IS BOUND.
      co_html->free( EXCEPTIONS OTHERS = 1 ).
      CLEAR co_html.
    ENDIF.
    IF co_dlg IS BOUND.
      co_dlg->free( EXCEPTIONS OTHERS = 1 ).
      CLEAR co_dlg.
    ENDIF.

    CREATE OBJECT co_dlg
      EXPORTING
        width   = iv_width
        height  = iv_height
        top     = 40
        left    = 80
        caption = iv_title.
    CREATE OBJECT co_html
      EXPORTING
        parent = co_dlg.
    load_html( io_viewer = co_html iv_html = iv_html ).
  ENDMETHOD.

  METHOD show_stats.
    show_html_dialog(
      EXPORTING
        iv_title = 'STATS — KPI 요약'
        iv_html  = build_stats_html( )
      CHANGING
        co_dlg  = mo_stats_dlg
        co_html = mo_stats_html ).
    " X(닫기) → CLOSE 이벤트: free 필수
    SET HANDLER on_stats_close FOR mo_stats_dlg ACTIVATION 'X'.
  ENDMETHOD.

  METHOD show_help.
    show_html_dialog(
      EXPORTING
        iv_title = 'HELP — 사용 안내'
        iv_html  = build_help_html( )
      CHANGING
        co_dlg  = mo_help_dlg
        co_html = mo_help_html ).
    SET HANDLER on_help_close FOR mo_help_dlg ACTIVATION 'X'.
  ENDMETHOD.

  METHOD show_dump_detail.
    " ST22 트랜잭션 호출 금지 — HTML dialogbox 만 사용
    DATA: lv_html TYPE string,
          lv_title TYPE char40.

    lv_title = 'Runtime Error Detail'.
    lv_html  = lcl_navigator=>build_dump_detail_html( is_dump ).

    IF mo_dump_html IS BOUND.
      mo_dump_html->free( EXCEPTIONS OTHERS = 1 ).
      CLEAR mo_dump_html.
    ENDIF.
    IF mo_dump_dlg IS BOUND.
      mo_dump_dlg->free( EXCEPTIONS OTHERS = 1 ).
      CLEAR mo_dump_dlg.
    ENDIF.

    CREATE OBJECT mo_dump_dlg
      EXPORTING
        width   = 920
        height  = 620
        top     = 40
        left    = 80
        caption = lv_title
      EXCEPTIONS
        OTHERS  = 1.
    IF sy-subrc <> 0 OR mo_dump_dlg IS NOT BOUND.
      MESSAGE '덤프 상세 팝업을 열 수 없습니다' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    SET HANDLER on_dump_close FOR mo_dump_dlg ACTIVATION 'X'.

    CREATE OBJECT mo_dump_html
      EXPORTING
        parent = mo_dump_dlg
      EXCEPTIONS
        OTHERS = 1.
    IF sy-subrc <> 0 OR mo_dump_html IS NOT BOUND.
      MESSAGE '덤프 상세 뷰어를 생성할 수 없습니다' TYPE 'S' DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    load_html( io_viewer = mo_dump_html iv_html = lv_html ).
  ENDMETHOD.

  METHOD on_stats_close.
    " Dialogbox X는 CLOSE만 올리고 자동 소멸하지 않음 → sender->free 필요
    IF mo_stats_html IS BOUND.
      mo_stats_html->free( EXCEPTIONS OTHERS = 1 ).
      CLEAR mo_stats_html.
    ENDIF.
    IF sender IS BOUND.
      sender->free( EXCEPTIONS OTHERS = 1 ).
    ENDIF.
    CLEAR mo_stats_dlg.
    cl_gui_cfw=>flush( EXCEPTIONS OTHERS = 1 ).
  ENDMETHOD.

  METHOD on_help_close.
    IF mo_help_html IS BOUND.
      mo_help_html->free( EXCEPTIONS OTHERS = 1 ).
      CLEAR mo_help_html.
    ENDIF.
    IF sender IS BOUND.
      sender->free( EXCEPTIONS OTHERS = 1 ).
    ENDIF.
    CLEAR mo_help_dlg.
    cl_gui_cfw=>flush( EXCEPTIONS OTHERS = 1 ).
  ENDMETHOD.

  METHOD on_dump_close.
    IF mo_dump_html IS BOUND.
      mo_dump_html->free( EXCEPTIONS OTHERS = 1 ).
      CLEAR mo_dump_html.
    ENDIF.
    IF sender IS BOUND.
      sender->free( EXCEPTIONS OTHERS = 1 ).
    ENDIF.
    CLEAR mo_dump_dlg.
    cl_gui_cfw=>flush( EXCEPTIONS OTHERS = 1 ).
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Events
*----------------------------------------------------------------------*
DATA gv_screen_started TYPE abap_bool.

INITIALIZATION.
  lcl_util=>apply_hours_to_range(
    EXPORTING iv_hours = p_hours
    IMPORTING ev_frdat = p_frdat
              ev_frtim = p_frtim
              ev_todat = p_todat
              ev_totim = p_totim ).
  p_mand = sy-mandt.
  IF p_maxrow IS INITIAL OR p_maxrow <= 0.
    p_maxrow = c_def_max.
  ENDIF.
  IF p_topn IS INITIAL OR p_topn <= 0.
    p_topn = c_def_topn.
  ENDIF.

AT SELECTION-SCREEN ON p_hours.
  IF p_hours > 0.
    lcl_util=>apply_hours_to_range(
      EXPORTING iv_hours = p_hours
      IMPORTING ev_frdat = p_frdat
                ev_frtim = p_frtim
                ev_todat = p_todat
                ev_totim = p_totim ).
  ENDIF.

AT SELECTION-SCREEN.
  IF p_frdat > p_todat OR ( p_frdat = p_todat AND p_frtim > p_totim ).
    MESSAGE '조회 기간 FROM 이 TO 보다 클 수 없습니다'(e02) TYPE 'E'.
  ENDIF.
  IF cb_sm37 IS INITIAL AND cb_st22 IS INITIAL AND cb_sxi IS INITIAL.
    MESSAGE '조회 영역을 하나 이상 선택하세요'(e01) TYPE 'E'.
  ENDIF.
  IF p_maxrow <= 0.
    MESSAGE '최대 행수는 1 이상이어야 합니다'(e03) TYPE 'E'.
  ENDIF.
  IF p_topn <= 0.
    MESSAGE 'Top-N 은 1 이상이어야 합니다'(e04) TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  CREATE OBJECT go_controller.
  gv_screen_started = abap_false.
  CALL SCREEN 0100.

*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STAT0100'.
  SET TITLEBAR 'TIT100'.
  IF go_controller IS NOT BOUND.
    CREATE OBJECT go_controller.
  ENDIF.
  IF gv_screen_started = abap_false.
    go_controller->run( ).
    gv_screen_started = abap_true.
  ENDIF.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Module USER_COMMAND_0100 INPUT
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  gv_ok = ok_code.
  CLEAR ok_code.
  IF go_controller IS BOUND.
    go_controller->get_ui( )->handle_user_command( gv_ok ).
  ELSE.
    CASE gv_ok.
      WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
        LEAVE TO SCREEN 0.
    ENDCASE.
  ENDIF.
ENDMODULE.

*&---------------------------------------------------------------------*
*& Screen 0100 flow logic (SE51에 동일 반영)
*& PROCESS BEFORE OUTPUT.
*&   MODULE status_0100.
*& PROCESS AFTER INPUT.
*&   MODULE user_command_0100.
*&---------------------------------------------------------------------*
