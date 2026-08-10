*&---------------------------------------------------------------------*
*& Report  Y_OPS_MONITOR_V2
*&---------------------------------------------------------------------*
*& Integrated Ops Monitor (SM37 / ST22 / SXI) — Read-Only Dashboard
*& Built from docs/design/integrated-ops-monitor-design.md + skills
*& Program: Y_OPS_MONITOR_V2 | Message class concept: YOPSMON
*&---------------------------------------------------------------------*
REPORT y_ops_monitor_v2.

INCLUDE <icon>.

*----------------------------------------------------------------------*
* Selection screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-b01.
PARAMETERS: p_frdat TYPE sy-datum OBLIGATORY,
            p_frtim TYPE sy-uzeit OBLIGATORY,
            p_todat TYPE sy-datum OBLIGATORY,
            p_totim TYPE sy-uzeit OBLIGATORY,
            p_hours TYPE i DEFAULT 24.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-b02.
PARAMETERS: cb_sm37 AS CHECKBOX DEFAULT 'X',
            cb_st22 AS CHECKBOX DEFAULT 'X',
            cb_sxi  AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE text-b03.
SELECT-OPTIONS: so_job   FOR sy-repid,
                so_user  FOR sy-uname,
                so_iface FOR sy-repid.
PARAMETERS: p_mand TYPE mandt DEFAULT sy-mandt.
SELECTION-SCREEN END OF BLOCK b3.

SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE text-b04.
PARAMETERS: p_maxrow TYPE i DEFAULT 250,
            p_topn   TYPE i DEFAULT 5.
SELECTION-SCREEN END OF BLOCK b4.

*----------------------------------------------------------------------*
* Global OK-code / UI handle
*----------------------------------------------------------------------*
DATA: ok_code TYPE sy-ucomm,
      g_ok    TYPE sy-ucomm.

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
       END OF ty_sel.

TYPES: BEGIN OF ty_batch,
         jobname  TYPE tbtcjob-jobname,
         jobcount TYPE tbtcjob-jobcount,
         status   TYPE tbtcjob-status,
         progname TYPE programm,
         sdluname TYPE tbtcjob-sdluname,
         strtdate TYPE tbtcjob-strtdate,
         strttime TYPE tbtcjob-strttime,
         enddate  TYPE tbtcjob-enddate,
         endtime  TYPE tbtcjob-endtime,
         line_color TYPE char4,
       END OF ty_batch.
TYPES: ty_batch_tab TYPE STANDARD TABLE OF ty_batch WITH DEFAULT KEY.

TYPES: BEGIN OF ty_dump,
         progname TYPE programm,
         rt_error TYPE char30,
         uname    TYPE syuname,
         datum    TYPE sy-datum,
         uzeit    TYPE sy-uzeit,
         ahost    TYPE snap_beg-ahost,
         include  TYPE programm,
         line     TYPE i,
         line_color TYPE char4,
       END OF ty_dump.
TYPES: ty_dump_tab TYPE STANDARD TABLE OF ty_dump WITH DEFAULT KEY.

TYPES: BEGIN OF ty_iface,
         if_name  TYPE char40,
         msgstate TYPE char3,
         exe_date TYPE sy-datum,
         exe_time TYPE sy-uzeit,
         msgguid  TYPE sxmsmgguid,
         pid      TYPE sxmspid,
         errstat  TYPE char3,
         sender   TYPE char40,
         receiver TYPE char40,
         line_color TYPE char4,
       END OF ty_iface.
TYPES: ty_iface_tab TYPE STANDARD TABLE OF ty_iface WITH DEFAULT KEY.

TYPES: BEGIN OF ty_area_result,
         area      TYPE char10,
         title     TYPE char40,
         count_all TYPE i,
         count_alv TYPE i,
         auth_ok   TYPE abap_bool,
         skipped   TYPE abap_bool,
         message   TYPE string,
         light     TYPE char1, " G/Y/R
       END OF ty_area_result.

TYPES: BEGIN OF ty_chart_bar,
         area  TYPE char10,
         label TYPE char60,
         value TYPE i,
         color TYPE char8,
         tip   TYPE char80,
       END OF ty_chart_bar.
TYPES: ty_chart_tab TYPE STANDARD TABLE OF ty_chart_bar WITH DEFAULT KEY.

TYPES: BEGIN OF ty_bucket,
         area  TYPE char10,
         bkey  TYPE char20,
         label TYPE char20,
         value TYPE i,
       END OF ty_bucket.
TYPES: ty_bucket_tab TYPE STANDARD TABLE OF ty_bucket WITH DEFAULT KEY.
TYPES: ty_string_tab TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

CONSTANTS:
  c_area_sm37 TYPE char10 VALUE 'SM37',
  c_area_st22 TYPE char10 VALUE 'ST22',
  c_area_sxi  TYPE char10 VALUE 'SXI',
  c_col_sm37  TYPE char8  VALUE '#26A69A',
  c_col_st22  TYPE char8  VALUE '#EF5350',
  c_col_sxi   TYPE char8  VALUE '#FFA726',
  c_alv_sm37  TYPE char4  VALUE 'C400',
  c_alv_st22  TYPE char4  VALUE 'C600',
  c_alv_sxi   TYPE char4  VALUE 'C700',
  c_status_a  TYPE char1 VALUE 'A',
  c_sm37_red  TYPE i VALUE 1,
  c_st22_yel  TYPE i VALUE 1,
  c_st22_red  TYPE i VALUE 31,
  c_sxi_yel   TYPE i VALUE 1,
  c_sxi_red   TYPE i VALUE 51,
  c_view_topn TYPE char1 VALUE 'T',
  c_view_time TYPE char1 VALUE 'H',
  c_max_hours TYPE i VALUE 720.

*----------------------------------------------------------------------*
* Interface: data provider contract
*----------------------------------------------------------------------*
INTERFACE lif_mon_data_provider.
  METHODS get_area_info
    EXPORTING
      ev_area  TYPE char10
      ev_title TYPE char40.
  METHODS check_authority
    RETURNING VALUE(rv_ok) TYPE abap_bool.
  METHODS get_data
    IMPORTING is_sel TYPE ty_sel
    EXPORTING
      et_batch TYPE ty_batch_tab
      et_dump  TYPE ty_dump_tab
      et_iface TYPE ty_iface_tab
      ev_count TYPE i
      ev_msg   TYPE string
      ev_ok    TYPE abap_bool.
ENDINTERFACE.

*----------------------------------------------------------------------*
* Utility
*----------------------------------------------------------------------*
CLASS lcl_util DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS apply_hours
      IMPORTING iv_hours TYPE i
      EXPORTING
        ev_frdat TYPE sy-datum
        ev_frtim TYPE sy-uzeit
        ev_todat TYPE sy-datum
        ev_totim TYPE sy-uzeit.
    CLASS-METHODS local_to_utc_tstmp
      IMPORTING
        iv_date TYPE sy-datum
        iv_time TYPE sy-uzeit
      RETURNING VALUE(rv_ts) TYPE timestampl.
    CLASS-METHODS utc_tstmp_to_local
      IMPORTING iv_ts TYPE timestampl
      EXPORTING
        ev_date TYPE sy-datum
        ev_time TYPE sy-uzeit.
    CLASS-METHODS in_datetime_range
      IMPORTING
        iv_date  TYPE sy-datum
        iv_time  TYPE sy-uzeit
        iv_frdat TYPE sy-datum
        iv_frtim TYPE sy-uzeit
        iv_todat TYPE sy-datum
        iv_totim TYPE sy-uzeit
      RETURNING VALUE(rv_ok) TYPE abap_bool.
    CLASS-METHODS traffic_light
      IMPORTING
        iv_area  TYPE char10
        iv_count TYPE i
      RETURNING VALUE(rv_light) TYPE char1.
    CLASS-METHODS area_color
      IMPORTING iv_area TYPE char10
      RETURNING VALUE(rv_color) TYPE char8.
    CLASS-METHODS area_alv_color
      IMPORTING iv_area TYPE char10
      RETURNING VALUE(rv_color) TYPE char4.
    CLASS-METHODS escape_html
      IMPORTING iv_text TYPE clike
      RETURNING VALUE(rv_text) TYPE string.
ENDCLASS.

CLASS lcl_util IMPLEMENTATION.
  METHOD apply_hours.
    DATA: lv_ts TYPE timestampl,
          lv_sec TYPE i.
    ev_todat = sy-datum.
    ev_totim = sy-uzeit.
    GET TIME STAMP FIELD lv_ts.
    lv_sec = iv_hours * 3600.
    TRY.
        lv_ts = cl_abap_tstmp=>subtractsecs( tstmp = lv_ts secs = lv_sec ).
      CATCH cx_root ##CATCH_ALL.
        ev_frdat = sy-datum - 1.
        ev_frtim = sy-uzeit.
        RETURN.
    ENDTRY.
    CONVERT TIME STAMP lv_ts TIME ZONE sy-zonlo
            INTO DATE ev_frdat TIME ev_frtim.
  ENDMETHOD.

  METHOD local_to_utc_tstmp.
    CONVERT DATE iv_date TIME iv_time
            INTO TIME STAMP rv_ts TIME ZONE sy-zonlo.
  ENDMETHOD.

  METHOD utc_tstmp_to_local.
    CONVERT TIME STAMP iv_ts TIME ZONE sy-zonlo
            INTO DATE ev_date TIME ev_time.
  ENDMETHOD.

  METHOD in_datetime_range.
    DATA lv_val TYPE char14.
    DATA lv_fr  TYPE char14.
    DATA lv_to  TYPE char14.
    lv_val = |{ iv_date }{ iv_time }|.
    lv_fr  = |{ iv_frdat }{ iv_frtim }|.
    lv_to  = |{ iv_todat }{ iv_totim }|.
    rv_ok = boolc( lv_val >= lv_fr AND lv_val <= lv_to ).
  ENDMETHOD.

  METHOD traffic_light.
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

  METHOD area_color.
    CASE iv_area.
      WHEN c_area_sm37. rv_color = c_col_sm37.
      WHEN c_area_st22. rv_color = c_col_st22.
      WHEN c_area_sxi.  rv_color = c_col_sxi.
      WHEN OTHERS.      rv_color = '#90A4AE'.
    ENDCASE.
  ENDMETHOD.

  METHOD area_alv_color.
    CASE iv_area.
      WHEN c_area_sm37. rv_color = c_alv_sm37.
      WHEN c_area_st22. rv_color = c_alv_st22.
      WHEN c_area_sxi.  rv_color = c_alv_sxi.
      WHEN OTHERS.      rv_color = 'C000'.
    ENDCASE.
  ENDMETHOD.

  METHOD escape_html.
    rv_text = iv_text.
    REPLACE ALL OCCURRENCES OF '&' IN rv_text WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<' IN rv_text WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>' IN rv_text WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF '"' IN rv_text WITH '&quot;'.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Provider: SM37 / TBTCO+TBTCP
*----------------------------------------------------------------------*
CLASS lcl_mon_dp_batch DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES lif_mon_data_provider.
ENDCLASS.

CLASS lcl_mon_dp_batch IMPLEMENTATION.
  METHOD lif_mon_data_provider~get_area_info.
    ev_area  = c_area_sm37.
    ev_title = 'SM37 배치 에러'.
  ENDMETHOD.

  METHOD lif_mon_data_provider~check_authority.
    AUTHORITY-CHECK OBJECT 'S_BTCH_JOB'
      ID 'JOBGROUP'  FIELD '*'
      ID 'JOBACTION' FIELD 'SHOW'.
    rv_ok = boolc( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD lif_mon_data_provider~get_data.
    DATA: lt_tbtco TYPE STANDARD TABLE OF tbtco,
          ls_tbtco TYPE tbtco,
          lt_tbtcp TYPE STANDARD TABLE OF tbtcp,
          ls_tbtcp TYPE tbtcp,
          ls_out   TYPE ty_batch,
          lv_from  TYPE char14,
          lv_to    TYPE char14,
          lv_end   TYPE char14.

    CLEAR: et_batch, et_dump, et_iface, ev_count, ev_msg.
    ev_ok = abap_false.

    IF lif_mon_data_provider~check_authority( ) = abap_false.
      ev_msg = 'SM37 권한 없음 (S_BTCH_JOB/SHOW)'.
      RETURN.
    ENDIF.

    lv_from = |{ is_sel-frdat }{ is_sel-frtim }|.
    lv_to   = |{ is_sel-todat }{ is_sel-totim }|.

    SELECT jobname jobcount status sdluname
           strtdate strttime enddate endtime
      FROM tbtco
      INTO CORRESPONDING FIELDS OF TABLE lt_tbtco
      WHERE status  = c_status_a
        AND enddate >= is_sel-frdat
        AND enddate <= is_sel-todat
        AND jobname IN so_job
        AND sdluname IN so_user.
    IF sy-subrc <> 0.
      ev_ok = abap_true.
      ev_msg = 'SM37 에러 없음'.
      RETURN.
    ENDIF.

    LOOP AT lt_tbtco INTO ls_tbtco.
      lv_end = |{ ls_tbtco-enddate }{ ls_tbtco-endtime }|.
      IF lv_end < lv_from OR lv_end > lv_to.
        CONTINUE.
      ENDIF.
      CLEAR ls_out.
      ls_out-jobname  = ls_tbtco-jobname.
      ls_out-jobcount = ls_tbtco-jobcount.
      ls_out-status   = ls_tbtco-status.
      ls_out-sdluname = ls_tbtco-sdluname.
      ls_out-strtdate = ls_tbtco-strtdate.
      ls_out-strttime = ls_tbtco-strttime.
      ls_out-enddate  = ls_tbtco-enddate.
      ls_out-endtime  = ls_tbtco-endtime.
      ls_out-line_color = lcl_util=>area_alv_color( c_area_sm37 ).
      APPEND ls_out TO et_batch.
    ENDLOOP.

    IF et_batch IS NOT INITIAL.
      SELECT jobname jobcount stepcount progname variant sdluname
        FROM tbtcp
        INTO CORRESPONDING FIELDS OF TABLE lt_tbtcp
        FOR ALL ENTRIES IN et_batch
        WHERE jobname  = et_batch-jobname
          AND jobcount = et_batch-jobcount.
      SORT lt_tbtcp BY jobname jobcount stepcount.
      LOOP AT et_batch ASSIGNING FIELD-SYMBOL(<b>).
        READ TABLE lt_tbtcp INTO ls_tbtcp
          WITH KEY jobname = <b>-jobname jobcount = <b>-jobcount
          BINARY SEARCH.
        IF sy-subrc = 0.
          <b>-progname = ls_tbtcp-progname.
        ENDIF.
      ENDLOOP.
    ENDIF.

    SORT et_batch BY enddate DESCENDING endtime DESCENDING.
    ev_count = lines( et_batch ).
    ev_ok = abap_true.
    IF ev_count = 0.
      ev_msg = 'SM37 에러 없음'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Provider: ST22 via RS_ST22_GET_DUMPS
*----------------------------------------------------------------------*
CLASS lcl_mon_dp_dump DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES lif_mon_data_provider.
ENDCLASS.

CLASS lcl_mon_dp_dump IMPLEMENTATION.
  METHOD lif_mon_data_provider~get_area_info.
    ev_area  = c_area_st22.
    ev_title = 'ST22 런타임 에러'.
  ENDMETHOD.

  METHOD lif_mon_data_provider~check_authority.
    AUTHORITY-CHECK OBJECT 'S_ABAPDUMP'
      ID 'ACTVT'     FIELD '03'
      ID 'DUMP_INFO' FIELD 'FULL'
      ID 'DUMP_CCLNT' FIELD 'ALL'
      ID 'DUMP_CUSER' FIELD 'ALL'.
    rv_ok = boolc( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD lif_mon_data_provider~get_data.
    DATA: lt_info TYPE rsdumptab,
          ls_info TYPE LINE OF rsdumptab,
          ls_out  TYPE ty_dump,
          lv_day  TYPE sy-datum,
          lv_end  TYPE sy-datum.

    CLEAR: et_batch, et_dump, et_iface, ev_count, ev_msg.
    ev_ok = abap_false.

    IF lif_mon_data_provider~check_authority( ) = abap_false.
      ev_msg = 'ST22 권한 없음 (S_ABAPDUMP)'.
      RETURN.
    ENDIF.

    lv_day = is_sel-frdat.
    lv_end = is_sel-todat.
    WHILE lv_day <= lv_end.
      CLEAR lt_info.
      CALL FUNCTION 'RS_ST22_GET_DUMPS'
        EXPORTING
          p_day     = lv_day
        IMPORTING
          p_infotab = lt_info
        EXCEPTIONS
          OTHERS    = 1.
      IF sy-subrc = 0.
        LOOP AT lt_info INTO ls_info.
          IF lcl_util=>in_datetime_range(
               iv_date  = ls_info-sydate
               iv_time  = ls_info-sytime
               iv_frdat = is_sel-frdat
               iv_frtim = is_sel-frtim
               iv_todat = is_sel-todat
               iv_totim = is_sel-totim ) = abap_false.
            CONTINUE.
          ENDIF.
          IF so_user IS NOT INITIAL AND ls_info-syuser NOT IN so_user.
            CONTINUE.
          ENDIF.
          CLEAR ls_out.
          ls_out-progname = ls_info-programname.
          ls_out-rt_error = ls_info-dumpid.
          ls_out-uname    = ls_info-syuser.
          ls_out-datum    = ls_info-sydate.
          ls_out-uzeit    = ls_info-sytime.
          ls_out-ahost    = ls_info-syhost.
          ls_out-include  = ls_info-includename.
          ls_out-line     = ls_info-linenumber.
          ls_out-line_color = lcl_util=>area_alv_color( c_area_st22 ).
          APPEND ls_out TO et_dump.
        ENDLOOP.
      ENDIF.
      lv_day = lv_day + 1.
    ENDWHILE.

    SORT et_dump BY datum DESCENDING uzeit DESCENDING.
    ev_count = lines( et_dump ).
    ev_ok = abap_true.
    IF ev_count = 0.
      ev_msg = 'ST22 덤프 없음'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Provider: SXI / SXMSPERROR + masters
*----------------------------------------------------------------------*
CLASS lcl_mon_dp_interface DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES lif_mon_data_provider.
ENDCLASS.

CLASS lcl_mon_dp_interface IMPLEMENTATION.
  METHOD lif_mon_data_provider~get_area_info.
    ev_area  = c_area_sxi.
    ev_title = 'SXI 인터페이스 에러'.
  ENDMETHOD.

  METHOD lif_mon_data_provider~check_authority.
    AUTHORITY-CHECK OBJECT 'S_XMB_MONI'
      ID 'ACTVT' FIELD '03'.
    rv_ok = boolc( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD lif_mon_data_provider~get_data.
    TYPES: BEGIN OF ty_err,
             msgguid   TYPE sxmsmgguid,
             pid       TYPE sxmspid,
             errstat   TYPE char3,
             exetimest TYPE timestampl,
           END OF ty_err.
    DATA: lt_err  TYPE STANDARD TABLE OF ty_err,
          ls_err  TYPE ty_err,
          lv_fr   TYPE timestampl,
          lv_to   TYPE timestampl,
          ls_out  TYPE ty_iface,
          lv_mand TYPE mandt.

    CLEAR: et_batch, et_dump, et_iface, ev_count, ev_msg.
    ev_ok = abap_false.

    IF lif_mon_data_provider~check_authority( ) = abap_false.
      ev_msg = 'SXI 권한 없음 (S_XMB_MONI)'.
      RETURN.
    ENDIF.

    lv_mand = is_sel-mandt.
    IF lv_mand IS INITIAL.
      lv_mand = sy-mandt.
    ENDIF.

    lv_fr = lcl_util=>local_to_utc_tstmp( iv_date = is_sel-frdat iv_time = is_sel-frtim ).
    lv_to = lcl_util=>local_to_utc_tstmp( iv_date = is_sel-todat iv_time = is_sel-totim ).

    SELECT msgguid pid errstat exetimest
      FROM sxmsperror CLIENT SPECIFIED
      INTO CORRESPONDING FIELDS OF TABLE lt_err
      WHERE mandt = lv_mand
        AND exetimest >= lv_fr
        AND exetimest <= lv_to.
    IF sy-subrc <> 0.
      ev_ok = abap_true.
      ev_msg = 'SXI 에러 없음'.
      RETURN.
    ENDIF.

    TYPES: BEGIN OF ty_mas,
             msgguid  TYPE sxmsmgguid,
             pid      TYPE sxmspid,
             msgstate TYPE char3,
           END OF ty_mas.
    TYPES: BEGIN OF ty_ema,
             msgguid      TYPE sxmsmgguid,
             pid          TYPE sxmspid,
             ob_name      TYPE char40,
             ob_system    TYPE char40,
             ib_system    TYPE char40,
             ob_operation TYPE char40,
           END OF ty_ema.
    DATA: lt_mas TYPE STANDARD TABLE OF ty_mas,
          lt_ema TYPE STANDARD TABLE OF ty_ema,
          ls_mas TYPE ty_mas,
          ls_ema TYPE ty_ema,
          lv_date TYPE sy-datum,
          lv_time TYPE sy-uzeit.

    IF lt_err IS NOT INITIAL.
      SELECT msgguid pid msgstate
        FROM sxmspmast CLIENT SPECIFIED
        INTO CORRESPONDING FIELDS OF TABLE lt_mas
        FOR ALL ENTRIES IN lt_err
        WHERE mandt   = lv_mand
          AND msgguid = lt_err-msgguid
          AND pid     = lt_err-pid.
      SELECT msgguid pid ob_name ob_system ib_system ob_operation
        FROM sxmspemas CLIENT SPECIFIED
        INTO CORRESPONDING FIELDS OF TABLE lt_ema
        FOR ALL ENTRIES IN lt_err
        WHERE mandt   = lv_mand
          AND msgguid = lt_err-msgguid
          AND pid     = lt_err-pid.
    ENDIF.
    SORT lt_mas BY msgguid pid.
    SORT lt_ema BY msgguid pid.

    LOOP AT lt_err INTO ls_err.
      CLEAR ls_out.
      ls_out-msgguid = ls_err-msgguid.
      ls_out-pid     = ls_err-pid.
      ls_out-errstat = ls_err-errstat.
      lcl_util=>utc_tstmp_to_local(
        EXPORTING iv_ts = ls_err-exetimest
        IMPORTING ev_date = lv_date ev_time = lv_time ).
      ls_out-exe_date = lv_date.
      ls_out-exe_time = lv_time.
      READ TABLE lt_mas INTO ls_mas
        WITH KEY msgguid = ls_err-msgguid pid = ls_err-pid BINARY SEARCH.
      IF sy-subrc = 0.
        ls_out-msgstate = ls_mas-msgstate.
      ENDIF.
      READ TABLE lt_ema INTO ls_ema
        WITH KEY msgguid = ls_err-msgguid pid = ls_err-pid BINARY SEARCH.
      IF sy-subrc = 0.
        ls_out-if_name  = ls_ema-ob_name.
        ls_out-sender   = ls_ema-ob_system.
        ls_out-receiver = ls_ema-ib_system.
      ENDIF.
      IF so_iface IS NOT INITIAL AND ls_out-if_name NOT IN so_iface.
        CONTINUE.
      ENDIF.
      ls_out-line_color = lcl_util=>area_alv_color( c_area_sxi ).
      APPEND ls_out TO et_iface.
    ENDLOOP.

    SORT et_iface BY exe_date DESCENDING exe_time DESCENDING.
    ev_count = lines( et_iface ).
    ev_ok = abap_true.
    IF ev_count = 0.
      ev_msg = 'SXI 에러 없음'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Aggregator — Top-N / time buckets (full count, independent scale)
*----------------------------------------------------------------------*
CLASS lcl_mon_aggregator DEFINITION FINAL.
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
      RETURNING VALUE(rt_bars) TYPE ty_chart_tab.
    CLASS-METHODS build_time
      IMPORTING
        it_batch TYPE ty_batch_tab
        it_dump  TYPE ty_dump_tab
        it_iface TYPE ty_iface_tab
        is_sel   TYPE ty_sel
        iv_sm37  TYPE abap_bool
        iv_st22  TYPE abap_bool
        iv_sxi   TYPE abap_bool
      EXPORTING
        et_bars     TYPE ty_chart_tab
        ev_first    TYPE char20
        ev_last     TYPE char20
        ev_unit_txt TYPE char40.
  PRIVATE SECTION.
    CLASS-METHODS topn_from_keys
      IMPORTING
        it_keys  TYPE ty_string_tab
        iv_area  TYPE char10
        iv_topn  TYPE i
      CHANGING
        ct_bars  TYPE ty_chart_tab.
    CLASS-METHODS bucket_seconds
      IMPORTING is_sel TYPE ty_sel
      EXPORTING
        ev_secs TYPE i
        ev_unit TYPE char40.
ENDCLASS.

CLASS lcl_mon_aggregator IMPLEMENTATION.
  METHOD build_topn.
    DATA: lt_keys TYPE ty_string_tab,
          ls_b TYPE ty_batch,
          ls_d TYPE ty_dump,
          ls_i TYPE ty_iface,
          lv_n TYPE i.
    lv_n = iv_topn.
    IF lv_n <= 0.
      lv_n = 5.
    ENDIF.
    IF iv_sm37 = abap_true.
      CLEAR lt_keys.
      LOOP AT it_batch INTO ls_b.
        APPEND |{ ls_b-jobname }| TO lt_keys.
      ENDLOOP.
      topn_from_keys( EXPORTING it_keys = lt_keys iv_area = c_area_sm37 iv_topn = lv_n
                      CHANGING ct_bars = rt_bars ).
    ENDIF.
    IF iv_st22 = abap_true.
      CLEAR lt_keys.
      LOOP AT it_dump INTO ls_d.
        APPEND |{ ls_d-rt_error }| TO lt_keys.
      ENDLOOP.
      topn_from_keys( EXPORTING it_keys = lt_keys iv_area = c_area_st22 iv_topn = lv_n
                      CHANGING ct_bars = rt_bars ).
    ENDIF.
    IF iv_sxi = abap_true.
      CLEAR lt_keys.
      LOOP AT it_iface INTO ls_i.
        APPEND |{ ls_i-if_name }| TO lt_keys.
      ENDLOOP.
      topn_from_keys( EXPORTING it_keys = lt_keys iv_area = c_area_sxi iv_topn = lv_n
                      CHANGING ct_bars = rt_bars ).
    ENDIF.
  ENDMETHOD.

  METHOD topn_from_keys.
    TYPES: BEGIN OF ty_agg,
             key TYPE string,
             cnt TYPE i,
           END OF ty_agg.
    DATA: lt_agg TYPE STANDARD TABLE OF ty_agg,
          ls_agg TYPE ty_agg,
          lv_key TYPE string,
          ls_bar TYPE ty_chart_bar,
          lv_left TYPE i.
    LOOP AT it_keys INTO lv_key.
      IF lv_key IS INITIAL.
        lv_key = '(empty)'.
      ENDIF.
      READ TABLE lt_agg ASSIGNING FIELD-SYMBOL(<a>) WITH KEY key = lv_key.
      IF sy-subrc = 0.
        <a>-cnt = <a>-cnt + 1.
      ELSE.
        ls_agg-key = lv_key.
        ls_agg-cnt = 1.
        APPEND ls_agg TO lt_agg.
      ENDIF.
    ENDLOOP.
    SORT lt_agg BY cnt DESCENDING key ASCENDING.
    lv_left = iv_topn.
    LOOP AT lt_agg INTO ls_agg.
      IF lv_left <= 0.
        EXIT.
      ENDIF.
      CLEAR ls_bar.
      ls_bar-area  = iv_area.
      ls_bar-label = ls_agg-key.
      ls_bar-value = ls_agg-cnt.
      ls_bar-color = lcl_util=>area_color( iv_area ).
      ls_bar-tip   = |{ iv_area }: { ls_agg-key } = { ls_agg-cnt }|.
      APPEND ls_bar TO ct_bars.
      lv_left = lv_left - 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD bucket_seconds.
    DATA: lv_from TYPE timestampl,
          lv_to   TYPE timestampl,
          lv_diff TYPE tzntstmpl.
    lv_from = lcl_util=>local_to_utc_tstmp( iv_date = is_sel-frdat iv_time = is_sel-frtim ).
    lv_to   = lcl_util=>local_to_utc_tstmp( iv_date = is_sel-todat iv_time = is_sel-totim ).
    TRY.
        lv_diff = cl_abap_tstmp=>subtract( tstmp1 = lv_to tstmp2 = lv_from ).
      CATCH cx_root ##CATCH_ALL.
        lv_diff = 86400.
    ENDTRY.
    IF lv_diff <= 86400.
      ev_secs = 3600.
      ev_unit = '1칸=1시간'.
    ELSEIF lv_diff <= 604800.
      ev_secs = 86400.
      ev_unit = '1칸=1일'.
    ELSE.
      ev_secs = 604800.
      ev_unit = '1칸=1주'.
    ENDIF.
  ENDMETHOD.

  METHOD build_time.
    DATA: lv_secs TYPE i,
          lv_unit TYPE char40,
          lv_from TYPE timestampl,
          lv_ts   TYPE timestampl,
          lv_idx  TYPE i,
          lv_max  TYPE i,
          lv_off  TYPE tzntstmpl,
          lv_off_i TYPE i,
          ls_bar  TYPE ty_chart_bar,
          lt_map  TYPE HASHED TABLE OF ty_bucket WITH UNIQUE KEY area bkey,
          ls_bkt  TYPE ty_bucket,
          lv_bkey TYPE char20,
          lv_lab  TYPE char20,
          lv_date TYPE sy-datum,
          lv_time TYPE sy-uzeit,
          ls_batch TYPE ty_batch,
          ls_dump  TYPE ty_dump,
          ls_iface TYPE ty_iface.
    FIELD-SYMBOLS <m> TYPE ty_bucket.

    CLEAR: et_bars, ev_first, ev_last, ev_unit_txt.
    bucket_seconds( EXPORTING is_sel = is_sel IMPORTING ev_secs = lv_secs ev_unit = lv_unit ).
    ev_unit_txt = lv_unit.
    WRITE is_sel-frdat TO ev_first.
    WRITE is_sel-todat TO ev_last.
    CONDENSE ev_first.
    CONDENSE ev_last.
    lv_from = lcl_util=>local_to_utc_tstmp( iv_date = is_sel-frdat iv_time = is_sel-frtim ).

    IF iv_sm37 = abap_true.
      LOOP AT it_batch INTO ls_batch.
        lv_ts = lcl_util=>local_to_utc_tstmp( iv_date = ls_batch-enddate iv_time = ls_batch-endtime ).
        TRY.
            lv_off = cl_abap_tstmp=>subtract( tstmp1 = lv_ts tstmp2 = lv_from ).
          CATCH cx_root ##CATCH_ALL.
            lv_off = 0.
        ENDTRY.
        IF lv_off < 0.
          lv_off = 0.
        ENDIF.
        lv_off_i = lv_off.
        lv_idx = lv_off_i DIV lv_secs.
        lv_bkey = |{ lv_idx WIDTH = 6 ALIGN = RIGHT PAD = '0' }|.
        READ TABLE lt_map ASSIGNING <m> WITH TABLE KEY area = c_area_sm37 bkey = lv_bkey.
        IF sy-subrc = 0.
          <m>-value = <m>-value + 1.
        ELSE.
          CLEAR ls_bkt.
          ls_bkt-area = c_area_sm37.
          ls_bkt-bkey = lv_bkey.
          ls_bkt-value = 1.
          INSERT ls_bkt INTO TABLE lt_map.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF iv_st22 = abap_true.
      LOOP AT it_dump INTO ls_dump.
        lv_ts = lcl_util=>local_to_utc_tstmp( iv_date = ls_dump-datum iv_time = ls_dump-uzeit ).
        TRY.
            lv_off = cl_abap_tstmp=>subtract( tstmp1 = lv_ts tstmp2 = lv_from ).
          CATCH cx_root ##CATCH_ALL.
            lv_off = 0.
        ENDTRY.
        IF lv_off < 0. lv_off = 0. ENDIF.
        lv_off_i = lv_off.
        lv_idx = lv_off_i DIV lv_secs.
        lv_bkey = |{ lv_idx WIDTH = 6 ALIGN = RIGHT PAD = '0' }|.
        READ TABLE lt_map ASSIGNING <m> WITH TABLE KEY area = c_area_st22 bkey = lv_bkey.
        IF sy-subrc = 0.
          <m>-value = <m>-value + 1.
        ELSE.
          CLEAR ls_bkt.
          ls_bkt-area = c_area_st22.
          ls_bkt-bkey = lv_bkey.
          ls_bkt-value = 1.
          INSERT ls_bkt INTO TABLE lt_map.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF iv_sxi = abap_true.
      LOOP AT it_iface INTO ls_iface.
        lv_ts = lcl_util=>local_to_utc_tstmp( iv_date = ls_iface-exe_date iv_time = ls_iface-exe_time ).
        TRY.
            lv_off = cl_abap_tstmp=>subtract( tstmp1 = lv_ts tstmp2 = lv_from ).
          CATCH cx_root ##CATCH_ALL.
            lv_off = 0.
        ENDTRY.
        IF lv_off < 0. lv_off = 0. ENDIF.
        lv_off_i = lv_off.
        lv_idx = lv_off_i DIV lv_secs.
        lv_bkey = |{ lv_idx WIDTH = 6 ALIGN = RIGHT PAD = '0' }|.
        READ TABLE lt_map ASSIGNING <m> WITH TABLE KEY area = c_area_sxi bkey = lv_bkey.
        IF sy-subrc = 0.
          <m>-value = <m>-value + 1.
        ELSE.
          CLEAR ls_bkt.
          ls_bkt-area = c_area_sxi.
          ls_bkt-bkey = lv_bkey.
          ls_bkt-value = 1.
          INSERT ls_bkt INTO TABLE lt_map.
        ENDIF.
      ENDLOOP.
    ENDIF.

    LOOP AT lt_map INTO ls_bkt.
      CLEAR ls_bar.
      ls_bar-area  = ls_bkt-area.
      ls_bar-label = ls_bkt-bkey.
      ls_bar-value = ls_bkt-value.
      ls_bar-color = lcl_util=>area_color( ls_bkt-area ).
      ls_bar-tip   = |{ ls_bkt-area } bucket { ls_bkt-bkey } = { ls_bkt-value }|.
      APPEND ls_bar TO et_bars.
    ENDLOOP.
    SORT et_bars BY area ASCENDING label ASCENDING.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Navigator — display-only drill-down
*----------------------------------------------------------------------*
CLASS lcl_mon_navigator DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS to_batch
      IMPORTING is_batch TYPE ty_batch.
    CLASS-METHODS to_dump
      IMPORTING is_dump TYPE ty_dump.
    CLASS-METHODS to_iface
      IMPORTING is_iface TYPE ty_iface.
ENDCLASS.

CLASS lcl_mon_navigator IMPLEMENTATION.
  METHOD to_batch.
    CHECK is_batch-jobname IS NOT INITIAL.
    CALL FUNCTION 'BP_JOBLOG_SHOW'
      EXPORTING
        client                = sy-mandt
        jobcount              = is_batch-jobcount
        jobname               = is_batch-jobname
      EXCEPTIONS
        OTHERS                = 1.
    IF sy-subrc <> 0.
      MESSAGE '잡 로그 표시 실패' TYPE 'S' DISPLAY LIKE 'E'.
    ENDIF.
  ENDMETHOD.

  METHOD to_dump.
    SET PARAMETER ID 'ADAY' FIELD is_dump-datum.
    SET PARAMETER ID 'AUID' FIELD is_dump-uname.
    CALL TRANSACTION 'ST22' AND SKIP FIRST SCREEN. "#EC CI_CALLTA
  ENDMETHOD.

  METHOD to_iface.
    SET PARAMETER ID 'SXI' FIELD is_iface-msgguid.
    CALL TRANSACTION 'SXI_MONITOR' AND SKIP FIRST SCREEN. "#EC CI_CALLTA
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Controller
*----------------------------------------------------------------------*
CLASS lcl_mon_controller DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor.
    METHODS run
      IMPORTING is_sel TYPE ty_sel.
    METHODS get_results
      EXPORTING
        et_batch   TYPE ty_batch_tab
        et_dump    TYPE ty_dump_tab
        et_iface   TYPE ty_iface_tab
        es_sm37    TYPE ty_area_result
        es_st22    TYPE ty_area_result
        es_sxi     TYPE ty_area_result
        et_topn    TYPE ty_chart_tab
        et_time    TYPE ty_chart_tab
        ev_tfirst  TYPE char20
        ev_tlast   TYPE char20
        ev_tunit   TYPE char40
        ev_elapsed TYPE i.
  PRIVATE SECTION.
    DATA: mo_batch TYPE REF TO lcl_mon_dp_batch,
          mo_dump  TYPE REF TO lcl_mon_dp_dump,
          mo_iface TYPE REF TO lcl_mon_dp_interface,
          mt_batch TYPE ty_batch_tab,
          mt_dump  TYPE ty_dump_tab,
          mt_iface TYPE ty_iface_tab,
          ms_sm37  TYPE ty_area_result,
          ms_st22  TYPE ty_area_result,
          ms_sxi   TYPE ty_area_result,
          mt_topn  TYPE ty_chart_tab,
          mt_time  TYPE ty_chart_tab,
          mv_tfirst TYPE char20,
          mv_tlast  TYPE char20,
          mv_tunit  TYPE char40,
          mv_elapsed TYPE i,
          ms_sel   TYPE ty_sel.
    METHODS run_area
      IMPORTING
        io_prov TYPE REF TO lif_mon_data_provider
        iv_on   TYPE abap_bool
        is_sel  TYPE ty_sel
      EXPORTING
        es_res  TYPE ty_area_result.
ENDCLASS.

CLASS lcl_mon_controller IMPLEMENTATION.
  METHOD constructor.
    CREATE OBJECT mo_batch.
    CREATE OBJECT mo_dump.
    CREATE OBJECT mo_iface.
  ENDMETHOD.

  METHOD run.
    DATA: lv_t0 TYPE i,
          lv_t1 TYPE i,
          lt_b TYPE ty_batch_tab,
          lt_d TYPE ty_dump_tab,
          lt_i TYPE ty_iface_tab,
          lv_cnt TYPE i,
          lv_msg TYPE string,
          lv_ok  TYPE abap_bool.

    ms_sel = is_sel.
    CLEAR: mt_batch, mt_dump, mt_iface, mt_topn, mt_time.
    GET RUN TIME FIELD lv_t0.

    " SM37
    CLEAR: ms_sm37, lt_b, lt_d, lt_i, lv_cnt, lv_msg, lv_ok.
    ms_sm37-area = c_area_sm37.
    ms_sm37-title = 'SM37 배치 에러'.
    IF is_sel-sm37 = abap_false.
      ms_sm37-skipped = abap_true.
      ms_sm37-message = '영역 Off'.
      ms_sm37-light = 'G'.
    ELSE.
      TRY.
          IF mo_batch->lif_mon_data_provider~check_authority( ) = abap_false.
            ms_sm37-auth_ok = abap_false.
            ms_sm37-message = '권한 없음 — 영역 스킵'.
            ms_sm37-light = 'Y'.
          ELSE.
            ms_sm37-auth_ok = abap_true.
            mo_batch->lif_mon_data_provider~get_data(
              EXPORTING is_sel = is_sel
              IMPORTING et_batch = lt_b ev_count = lv_cnt ev_msg = lv_msg ev_ok = lv_ok ).
            mt_batch = lt_b.
            ms_sm37-count_all = lv_cnt.
            ms_sm37-message = lv_msg.
            ms_sm37-light = lcl_util=>traffic_light( iv_area = c_area_sm37 iv_count = lv_cnt ).
          ENDIF.
        CATCH cx_root INTO DATA(lx1) ##CATCH_ALL.
          ms_sm37-message = |SM37 오류: { lx1->get_text( ) }|.
          ms_sm37-light = 'Y'.
          CLEAR mt_batch.
      ENDTRY.
    ENDIF.

    " ST22
    CLEAR: ms_st22, lt_b, lt_d, lt_i, lv_cnt, lv_msg, lv_ok.
    ms_st22-area = c_area_st22.
    ms_st22-title = 'ST22 런타임 에러'.
    IF is_sel-st22 = abap_false.
      ms_st22-skipped = abap_true.
      ms_st22-message = '영역 Off'.
      ms_st22-light = 'G'.
    ELSE.
      TRY.
          IF mo_dump->lif_mon_data_provider~check_authority( ) = abap_false.
            ms_st22-auth_ok = abap_false.
            ms_st22-message = '권한 없음 — 영역 스킵'.
            ms_st22-light = 'Y'.
          ELSE.
            ms_st22-auth_ok = abap_true.
            mo_dump->lif_mon_data_provider~get_data(
              EXPORTING is_sel = is_sel
              IMPORTING et_dump = lt_d ev_count = lv_cnt ev_msg = lv_msg ev_ok = lv_ok ).
            mt_dump = lt_d.
            ms_st22-count_all = lv_cnt.
            ms_st22-message = lv_msg.
            ms_st22-light = lcl_util=>traffic_light( iv_area = c_area_st22 iv_count = lv_cnt ).
          ENDIF.
        CATCH cx_root INTO DATA(lx2) ##CATCH_ALL.
          ms_st22-message = |ST22 오류: { lx2->get_text( ) }|.
          ms_st22-light = 'Y'.
          CLEAR mt_dump.
      ENDTRY.
    ENDIF.

    " SXI
    CLEAR: ms_sxi, lt_b, lt_d, lt_i, lv_cnt, lv_msg, lv_ok.
    ms_sxi-area = c_area_sxi.
    ms_sxi-title = 'SXI 인터페이스 에러'.
    IF is_sel-sxi = abap_false.
      ms_sxi-skipped = abap_true.
      ms_sxi-message = '영역 Off'.
      ms_sxi-light = 'G'.
    ELSE.
      TRY.
          IF mo_iface->lif_mon_data_provider~check_authority( ) = abap_false.
            ms_sxi-auth_ok = abap_false.
            ms_sxi-message = '권한 없음 — 영역 스킵'.
            ms_sxi-light = 'Y'.
          ELSE.
            ms_sxi-auth_ok = abap_true.
            mo_iface->lif_mon_data_provider~get_data(
              EXPORTING is_sel = is_sel
              IMPORTING et_iface = lt_i ev_count = lv_cnt ev_msg = lv_msg ev_ok = lv_ok ).
            mt_iface = lt_i.
            ms_sxi-count_all = lv_cnt.
            ms_sxi-message = lv_msg.
            ms_sxi-light = lcl_util=>traffic_light( iv_area = c_area_sxi iv_count = lv_cnt ).
          ENDIF.
        CATCH cx_root INTO DATA(lx3) ##CATCH_ALL.
          ms_sxi-message = |SXI 오류: { lx3->get_text( ) }|.
          ms_sxi-light = 'Y'.
          CLEAR mt_iface.
      ENDTRY.
    ENDIF.

    mt_topn = lcl_mon_aggregator=>build_topn(
      it_batch = mt_batch it_dump = mt_dump it_iface = mt_iface
      iv_topn = is_sel-topn
      iv_sm37 = boolc( is_sel-sm37 = abap_true AND ms_sm37-auth_ok = abap_true AND ms_sm37-skipped = abap_false )
      iv_st22 = boolc( is_sel-st22 = abap_true AND ms_st22-auth_ok = abap_true AND ms_st22-skipped = abap_false )
      iv_sxi  = boolc( is_sel-sxi  = abap_true AND ms_sxi-auth_ok  = abap_true AND ms_sxi-skipped  = abap_false ) ).

    lcl_mon_aggregator=>build_time(
      EXPORTING
        it_batch = mt_batch it_dump = mt_dump it_iface = mt_iface is_sel = is_sel
        iv_sm37 = boolc( is_sel-sm37 = abap_true AND ms_sm37-auth_ok = abap_true AND ms_sm37-skipped = abap_false )
        iv_st22 = boolc( is_sel-st22 = abap_true AND ms_st22-auth_ok = abap_true AND ms_st22-skipped = abap_false )
        iv_sxi  = boolc( is_sel-sxi  = abap_true AND ms_sxi-auth_ok  = abap_true AND ms_sxi-skipped  = abap_false )
      IMPORTING
        et_bars = mt_time ev_first = mv_tfirst ev_last = mv_tlast ev_unit_txt = mv_tunit ).

    GET RUN TIME FIELD lv_t1.
    mv_elapsed = ( lv_t1 - lv_t0 ) / 1000.
  ENDMETHOD.

  METHOD get_results.
    et_batch = mt_batch.
    et_dump  = mt_dump.
    et_iface = mt_iface.
    es_sm37  = ms_sm37.
    es_st22  = ms_st22.
    es_sxi   = ms_sxi.
    et_topn  = mt_topn.
    et_time  = mt_time.
    ev_tfirst = mv_tfirst.
    ev_tlast  = mv_tlast.
    ev_tunit  = mv_tunit.
    ev_elapsed = mv_elapsed.
  ENDMETHOD.

  METHOD run_area.
    " reserved for registry-style extension
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* UI Dashboard
*----------------------------------------------------------------------*
CLASS lcl_mon_ui_dashboard DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_controller TYPE REF TO lcl_mon_controller
                is_sel        TYPE ty_sel.
    METHODS display.
    METHODS refresh.
    METHODS toggle_view.
    METHODS show_stats.
    METHODS show_help.
    METHODS handle_ucomm
      IMPORTING iv_ucomm TYPE sy-ucomm.
  PRIVATE SECTION.
    DATA: mo_controller TYPE REF TO lcl_mon_controller,
          ms_sel        TYPE ty_sel,
          mv_view       TYPE char1 VALUE c_view_topn,
          mv_query_ts   TYPE timestampl,
          mv_elapsed    TYPE i,
          " containers
          mo_dock       TYPE REF TO cl_gui_docking_container,
          mo_split_main TYPE REF TO cl_gui_splitter_container,
          mo_cont_kpi   TYPE REF TO cl_gui_container,
          mo_cont_chart TYPE REF TO cl_gui_container,
          mo_cont_alv   TYPE REF TO cl_gui_container,
          mo_split_alv  TYPE REF TO cl_gui_splitter_container,
          mo_cont_a1    TYPE REF TO cl_gui_container,
          mo_cont_a2    TYPE REF TO cl_gui_container,
          mo_cont_a3    TYPE REF TO cl_gui_container,
          " html
          mo_kpi_html   TYPE REF TO cl_gui_html_viewer,
          mo_chart_html TYPE REF TO cl_gui_html_viewer,
          " dialogs
          mo_stats_dlg  TYPE REF TO cl_gui_dialogbox_container,
          mo_stats_html TYPE REF TO cl_gui_html_viewer,
          mo_help_dlg   TYPE REF TO cl_gui_dialogbox_container,
          mo_help_html  TYPE REF TO cl_gui_html_viewer,
          " alv
          mo_alv_sm37   TYPE REF TO cl_gui_alv_grid,
          mo_alv_st22   TYPE REF TO cl_gui_alv_grid,
          mo_alv_sxi    TYPE REF TO cl_gui_alv_grid,
          " data mirrors
          mt_batch      TYPE ty_batch_tab,
          mt_dump       TYPE ty_dump_tab,
          mt_iface      TYPE ty_iface_tab,
          mt_batch_alv  TYPE ty_batch_tab,
          mt_dump_alv   TYPE ty_dump_tab,
          mt_iface_alv  TYPE ty_iface_tab,
          ms_sm37       TYPE ty_area_result,
          ms_st22       TYPE ty_area_result,
          ms_sxi        TYPE ty_area_result,
          mt_topn       TYPE ty_chart_tab,
          mt_time       TYPE ty_chart_tab,
          mv_tfirst     TYPE char20,
          mv_tlast      TYPE char20,
          mv_tunit      TYPE char40.

    METHODS create_containers.
    METHODS load_data_from_controller.
    METHODS apply_maxrow.
    METHODS render_kpi.
    METHODS render_chart.
    METHODS render_alv.
    METHODS build_kpi_html RETURNING VALUE(rv_html) TYPE string.
    METHODS build_chart_html RETURNING VALUE(rv_html) TYPE string.
    METHODS build_topn_html
      IMPORTING iv_area TYPE char10
      RETURNING VALUE(rv_html) TYPE string.
    METHODS build_time_html
      IMPORTING iv_area TYPE char10
      RETURNING VALUE(rv_html) TYPE string.
    METHODS build_stats_html RETURNING VALUE(rv_html) TYPE string.
    METHODS build_help_html RETURNING VALUE(rv_html) TYPE string.
    METHODS show_html_dialog
      IMPORTING
        iv_title TYPE clike
        iv_html  TYPE string
      CHANGING
        co_dlg   TYPE REF TO cl_gui_dialogbox_container
        co_html  TYPE REF TO cl_gui_html_viewer.
    METHODS load_html
      IMPORTING
        io_html TYPE REF TO cl_gui_html_viewer
        iv_html TYPE string.
    METHODS exclude_toolbar
      RETURNING VALUE(rt_excl) TYPE ui_functions.
    METHODS on_double_sm37
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column.
    METHODS on_double_st22
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column.
    METHODS on_double_sxi
      FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row e_column.
    METHODS on_hotspot_sm37
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
    METHODS on_hotspot_st22
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
    METHODS on_hotspot_sxi
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id.
    METHODS on_stats_close
      FOR EVENT close OF cl_gui_dialogbox_container.
    METHODS on_help_close
      FOR EVENT close OF cl_gui_dialogbox_container.
    METHODS fcat_sm37 RETURNING VALUE(rt) TYPE lvc_t_fcat.
    METHODS fcat_st22 RETURNING VALUE(rt) TYPE lvc_t_fcat.
    METHODS fcat_sxi  RETURNING VALUE(rt) TYPE lvc_t_fcat.
ENDCLASS.

CLASS lcl_mon_ui_dashboard IMPLEMENTATION.
  METHOD constructor.
    mo_controller = io_controller.
    ms_sel = is_sel.
    mv_view = c_view_topn.
  ENDMETHOD.

  METHOD display.
    create_containers( ).
    load_data_from_controller( ).
    apply_maxrow( ).
    render_kpi( ).
    render_chart( ).
    render_alv( ).
  ENDMETHOD.

  METHOD refresh.
    mo_controller->run( ms_sel ).
    load_data_from_controller( ).
    apply_maxrow( ).
    render_kpi( ).
    render_chart( ).
    IF mo_alv_sm37 IS BOUND.
      mo_alv_sm37->refresh_table_display( ).
    ENDIF.
    IF mo_alv_st22 IS BOUND.
      mo_alv_st22->refresh_table_display( ).
    ENDIF.
    IF mo_alv_sxi IS BOUND.
      mo_alv_sxi->refresh_table_display( ).
    ENDIF.
  ENDMETHOD.

  METHOD toggle_view.
    IF mv_view = c_view_topn.
      mv_view = c_view_time.
    ELSE.
      mv_view = c_view_topn.
    ENDIF.
    render_chart( ).
  ENDMETHOD.

  METHOD handle_ucomm.
    CASE iv_ucomm.
      WHEN 'BACK' OR 'EXIT' OR 'CANC' OR 'CANCEL'.
        LEAVE TO SCREEN 0.
      WHEN 'REFRESH'.
        refresh( ).
      WHEN 'TOGGLE'.
        toggle_view( ).
      WHEN 'STATS'.
        show_stats( ).
      WHEN 'HELP' OR 'HELPON'.
        show_help( ).
    ENDCASE.
  ENDMETHOD.

  METHOD create_containers.
    CHECK mo_dock IS NOT BOUND.
    CREATE OBJECT mo_dock
      EXPORTING
        repid     = sy-repid
        dynnr     = sy-dynnr
        side      = cl_gui_docking_container=>dock_at_left
        extension = 3000.
    CREATE OBJECT mo_split_main
      EXPORTING
        parent  = mo_dock
        rows    = 3
        columns = 1.
    mo_split_main->set_row_height( id = 1 height = 12 ).
    mo_split_main->set_row_height( id = 2 height = 28 ).
    mo_split_main->set_row_height( id = 3 height = 60 ).
    mo_cont_kpi   = mo_split_main->get_container( row = 1 column = 1 ).
    mo_cont_chart = mo_split_main->get_container( row = 2 column = 1 ).
    mo_cont_alv   = mo_split_main->get_container( row = 3 column = 1 ).
    CREATE OBJECT mo_split_alv
      EXPORTING
        parent  = mo_cont_alv
        rows    = 1
        columns = 3.
    mo_cont_a1 = mo_split_alv->get_container( row = 1 column = 1 ).
    mo_cont_a2 = mo_split_alv->get_container( row = 1 column = 2 ).
    mo_cont_a3 = mo_split_alv->get_container( row = 1 column = 3 ).
    CREATE OBJECT mo_kpi_html
      EXPORTING parent = mo_cont_kpi.
    CREATE OBJECT mo_chart_html
      EXPORTING parent = mo_cont_chart.
  ENDMETHOD.

  METHOD load_data_from_controller.
    mo_controller->get_results(
      IMPORTING
        et_batch = mt_batch et_dump = mt_dump et_iface = mt_iface
        es_sm37 = ms_sm37 es_st22 = ms_st22 es_sxi = ms_sxi
        et_topn = mt_topn et_time = mt_time
        ev_tfirst = mv_tfirst ev_tlast = mv_tlast ev_tunit = mv_tunit
        ev_elapsed = mv_elapsed ).
    GET TIME STAMP FIELD mv_query_ts.
  ENDMETHOD.

  METHOD apply_maxrow.
    DATA: lv_max TYPE i,
          lv_n TYPE i.
    lv_max = ms_sel-maxrow.
    IF lv_max <= 0.
      lv_max = 250.
    ENDIF.
    CLEAR: mt_batch_alv, mt_dump_alv, mt_iface_alv.
    lv_n = 0.
    LOOP AT mt_batch INTO DATA(ls_b).
      lv_n = lv_n + 1.
      IF lv_n > lv_max. EXIT. ENDIF.
      APPEND ls_b TO mt_batch_alv.
    ENDLOOP.
    ms_sm37-count_alv = lines( mt_batch_alv ).
    lv_n = 0.
    LOOP AT mt_dump INTO DATA(ls_d).
      lv_n = lv_n + 1.
      IF lv_n > lv_max. EXIT. ENDIF.
      APPEND ls_d TO mt_dump_alv.
    ENDLOOP.
    ms_st22-count_alv = lines( mt_dump_alv ).
    lv_n = 0.
    LOOP AT mt_iface INTO DATA(ls_i).
      lv_n = lv_n + 1.
      IF lv_n > lv_max. EXIT. ENDIF.
      APPEND ls_i TO mt_iface_alv.
    ENDLOOP.
    ms_sxi-count_alv = lines( mt_iface_alv ).
  ENDMETHOD.

  METHOD render_kpi.
    load_html( io_html = mo_kpi_html iv_html = build_kpi_html( ) ).
  ENDMETHOD.

  METHOD render_chart.
    load_html( io_html = mo_chart_html iv_html = build_chart_html( ) ).
  ENDMETHOD.

  METHOD exclude_toolbar.
    DATA ls TYPE ui_func.
    " Keep Find / Sort / Filter; exclude export/sum/info etc. (ECC-safe fcodes)
    ls = cl_gui_alv_grid=>mc_fc_detail. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_check. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_refresh. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_insert_row. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_delete_row. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_copy_row. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_append_row. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_cut. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_copy. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_paste. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_loc_undo. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_graph. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_info. APPEND ls TO rt_excl.
    ls = '&EXPORT'. APPEND ls TO rt_excl.
    ls = '&PC'. APPEND ls TO rt_excl.
    ls = '&XXL'. APPEND ls TO rt_excl.
    ls = '&AQW'. APPEND ls TO rt_excl.
    ls = '&PRINT_BACK'. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_sum. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_average. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_minimum. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_maximum. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_subtot. APPEND ls TO rt_excl.
    ls = cl_gui_alv_grid=>mc_fc_views. APPEND ls TO rt_excl.
  ENDMETHOD.

  METHOD fcat_sm37.
    DATA ls TYPE lvc_s_fcat.
    CLEAR ls. ls-fieldname = 'JOBNAME'.  ls-coltext = '잡명'.     ls-seltext = ls-coltext. ls-outputlen = 24. ls-hotspot = 'X'. APPEND ls TO rt.
    CLEAR ls. ls-fieldname = 'PROGNAME'. ls-coltext = '프로그램'. ls-seltext = ls-coltext. ls-outputlen = 24. APPEND ls TO rt.
    CLEAR ls. ls-fieldname = 'SDLUNAME'. ls-coltext = '사용자'.   ls-seltext = ls-coltext. ls-outputlen = 12. APPEND ls TO rt.
    CLEAR ls. ls-fieldname = 'STRTDATE'. ls-coltext = '시작일'.   ls-seltext = ls-coltext. ls-outputlen = 10. APPEND ls TO rt.
    CLEAR ls. ls-fieldname = 'STRTTIME'. ls-coltext = '시작시간'. ls-seltext = ls-coltext. ls-outputlen = 8. APPEND ls TO rt.
    CLEAR ls. ls-fieldname = 'ENDDATE'.  ls-coltext = '종료일'.   ls-seltext = ls-coltext. ls-outputlen = 10. APPEND ls TO rt.
    CLEAR ls. ls-fieldname = 'ENDTIME'.  ls-coltext = '종료시간'. ls-seltext = ls-coltext. ls-outputlen = 8. APPEND ls TO rt.
  ENDMETHOD.

  METHOD fcat_st22.
    DATA ls TYPE lvc_s_fcat.
    CLEAR ls. ls-fieldname = 'PROGNAME'. ls-coltext = '프로그램'. ls-seltext = ls-coltext. ls-outputlen = 24. ls-hotspot = 'X'. APPEND ls TO rt.
    CLEAR ls. ls-fieldname = 'RT_ERROR'. ls-coltext = '에러유형'. ls-seltext = ls-coltext. ls-outputlen = 24. APPEND ls TO rt.
    CLEAR ls. ls-fieldname = 'UNAME'.    ls-coltext = '사용자'.   ls-seltext = ls-coltext. ls-outputlen = 12. APPEND ls TO rt.
    CLEAR ls. ls-fieldname = 'DATUM'.    ls-coltext = '발생일'.   ls-seltext = ls-coltext. ls-outputlen = 10. APPEND ls TO rt.
    CLEAR ls. ls-fieldname = 'UZEIT'.    ls-coltext = '발생시간'. ls-seltext = ls-coltext. ls-outputlen = 8. APPEND ls TO rt.
  ENDMETHOD.

  METHOD fcat_sxi.
    DATA ls TYPE lvc_s_fcat.
    CLEAR ls. ls-fieldname = 'IF_NAME'.  ls-coltext = '인터페이스'. ls-seltext = ls-coltext. ls-outputlen = 28. ls-hotspot = 'X'. APPEND ls TO rt.
    CLEAR ls. ls-fieldname = 'MSGSTATE'. ls-coltext = '상태'.       ls-seltext = ls-coltext. ls-outputlen = 8. APPEND ls TO rt.
    CLEAR ls. ls-fieldname = 'EXE_DATE'. ls-coltext = '발생일'.     ls-seltext = ls-coltext. ls-outputlen = 10. APPEND ls TO rt.
    CLEAR ls. ls-fieldname = 'EXE_TIME'. ls-coltext = '발생시간'.   ls-seltext = ls-coltext. ls-outputlen = 8. APPEND ls TO rt.
  ENDMETHOD.

  METHOD render_alv.
    DATA: lt_fcat TYPE lvc_t_fcat,
          ls_layo TYPE lvc_s_layo,
          lt_excl TYPE ui_functions.

    lt_excl = exclude_toolbar( ).
    ls_layo-zebra = abap_true.
    ls_layo-cwidth_opt = abap_true.
    ls_layo-info_fname = 'LINE_COLOR'.
    ls_layo-sel_mode = 'A'.

    IF mo_alv_sm37 IS NOT BOUND.
      CREATE OBJECT mo_alv_sm37 EXPORTING i_parent = mo_cont_a1.
      SET HANDLER on_double_sm37 on_hotspot_sm37 FOR mo_alv_sm37.
      lt_fcat = fcat_sm37( ).
      mo_alv_sm37->set_table_for_first_display(
        EXPORTING is_layout = ls_layo it_toolbar_excluding = lt_excl
        CHANGING  it_outtab = mt_batch_alv it_fieldcatalog = lt_fcat ).
    ELSE.
      mo_alv_sm37->refresh_table_display( ).
    ENDIF.

    IF mo_alv_st22 IS NOT BOUND.
      CREATE OBJECT mo_alv_st22 EXPORTING i_parent = mo_cont_a2.
      SET HANDLER on_double_st22 on_hotspot_st22 FOR mo_alv_st22.
      lt_fcat = fcat_st22( ).
      mo_alv_st22->set_table_for_first_display(
        EXPORTING is_layout = ls_layo it_toolbar_excluding = lt_excl
        CHANGING  it_outtab = mt_dump_alv it_fieldcatalog = lt_fcat ).
    ELSE.
      mo_alv_st22->refresh_table_display( ).
    ENDIF.

    IF mo_alv_sxi IS NOT BOUND.
      CREATE OBJECT mo_alv_sxi EXPORTING i_parent = mo_cont_a3.
      SET HANDLER on_double_sxi on_hotspot_sxi FOR mo_alv_sxi.
      lt_fcat = fcat_sxi( ).
      mo_alv_sxi->set_table_for_first_display(
        EXPORTING is_layout = ls_layo it_toolbar_excluding = lt_excl
        CHANGING  it_outtab = mt_iface_alv it_fieldcatalog = lt_fcat ).
    ELSE.
      mo_alv_sxi->refresh_table_display( ).
    ENDIF.
  ENDMETHOD.

  METHOD on_double_sm37.
    DATA ls TYPE ty_batch.
    DATA lv_idx TYPE lvc_index.
    lv_idx = e_row-index.
    CHECK lv_idx > 0.
    READ TABLE mt_batch_alv INTO ls INDEX lv_idx.
    CHECK sy-subrc = 0.
    lcl_mon_navigator=>to_batch( ls ).
  ENDMETHOD.

  METHOD on_double_st22.
    DATA ls TYPE ty_dump.
    DATA lv_idx TYPE lvc_index.
    lv_idx = e_row-index.
    CHECK lv_idx > 0.
    READ TABLE mt_dump_alv INTO ls INDEX lv_idx.
    CHECK sy-subrc = 0.
    lcl_mon_navigator=>to_dump( ls ).
  ENDMETHOD.

  METHOD on_double_sxi.
    DATA ls TYPE ty_iface.
    DATA lv_idx TYPE lvc_index.
    lv_idx = e_row-index.
    CHECK lv_idx > 0.
    READ TABLE mt_iface_alv INTO ls INDEX lv_idx.
    CHECK sy-subrc = 0.
    lcl_mon_navigator=>to_iface( ls ).
  ENDMETHOD.

  METHOD on_hotspot_sm37.
    DATA ls TYPE ty_batch.
    DATA lv_idx TYPE lvc_index.
    lv_idx = e_row_id-index.
    CHECK lv_idx > 0.
    READ TABLE mt_batch_alv INTO ls INDEX lv_idx.
    CHECK sy-subrc = 0.
    lcl_mon_navigator=>to_batch( ls ).
  ENDMETHOD.

  METHOD on_hotspot_st22.
    DATA ls TYPE ty_dump.
    DATA lv_idx TYPE lvc_index.
    lv_idx = e_row_id-index.
    CHECK lv_idx > 0.
    READ TABLE mt_dump_alv INTO ls INDEX lv_idx.
    CHECK sy-subrc = 0.
    lcl_mon_navigator=>to_dump( ls ).
  ENDMETHOD.

  METHOD on_hotspot_sxi.
    DATA ls TYPE ty_iface.
    DATA lv_idx TYPE lvc_index.
    lv_idx = e_row_id-index.
    CHECK lv_idx > 0.
    READ TABLE mt_iface_alv INTO ls INDEX lv_idx.
    CHECK sy-subrc = 0.
    lcl_mon_navigator=>to_iface( ls ).
  ENDMETHOD.

  METHOD on_stats_close.
    IF mo_stats_html IS BOUND.
      mo_stats_html->free( ).
      CLEAR mo_stats_html.
    ENDIF.
    IF mo_stats_dlg IS BOUND.
      mo_stats_dlg->free( ).
      CLEAR mo_stats_dlg.
    ENDIF.
  ENDMETHOD.

  METHOD on_help_close.
    IF mo_help_html IS BOUND.
      mo_help_html->free( ).
      CLEAR mo_help_html.
    ENDIF.
    IF mo_help_dlg IS BOUND.
      mo_help_dlg->free( ).
      CLEAR mo_help_dlg.
    ENDIF.
  ENDMETHOD.

  METHOD load_html.
    DATA: lt_html TYPE STANDARD TABLE OF w3html WITH DEFAULT KEY,
          ls_html TYPE w3html,
          lv_html TYPE string,
          lv_url  TYPE char255,
          lv_off  TYPE i,
          lv_len  TYPE i,
          lv_chunk TYPE string.
    lv_html = iv_html.
    lv_len = strlen( lv_html ).
    lv_off = 0.
    WHILE lv_off < lv_len.
      IF lv_len - lv_off > 255.
        lv_chunk = lv_html+lv_off(255).
        lv_off = lv_off + 255.
      ELSE.
        lv_chunk = lv_html+lv_off.
        lv_off = lv_len.
      ENDIF.
      ls_html-line = lv_chunk.
      APPEND ls_html TO lt_html.
    ENDWHILE.
    io_html->load_data(
      EXPORTING type = 'text' subtype = 'html' size = lv_len
      IMPORTING assigned_url = lv_url
      CHANGING  data_table = lt_html
      EXCEPTIONS OTHERS = 1 ).
    IF sy-subrc = 0.
      io_html->show_url( url = lv_url ).
    ENDIF.
  ENDMETHOD.

  METHOD show_html_dialog.
    IF co_html IS BOUND.
      co_html->free( ).
      CLEAR co_html.
    ENDIF.
    IF co_dlg IS BOUND.
      co_dlg->free( ).
      CLEAR co_dlg.
    ENDIF.
    CREATE OBJECT co_dlg
      EXPORTING
        width   = 640
        height  = 480
        top     = 40
        left    = 40
        caption = iv_title.
    CREATE OBJECT co_html
      EXPORTING parent = co_dlg.
    IF iv_title CS 'STATS' OR iv_title CS '통계' OR iv_title CS 'KPI'.
      SET HANDLER on_stats_close FOR co_dlg.
    ELSE.
      SET HANDLER on_help_close FOR co_dlg.
    ENDIF.
    load_html( io_html = co_html iv_html = iv_html ).
  ENDMETHOD.

  METHOD show_stats.
    show_html_dialog(
      EXPORTING iv_title = 'STATS — 운영 헬스' iv_html = build_stats_html( )
      CHANGING  co_dlg = mo_stats_dlg co_html = mo_stats_html ).
  ENDMETHOD.

  METHOD show_help.
    show_html_dialog(
      EXPORTING iv_title = 'HELP — 사용 안내' iv_html = build_help_html( )
      CHANGING  co_dlg = mo_help_dlg co_html = mo_help_html ).
  ENDMETHOD.

  METHOD build_kpi_html.
    DATA: lv_icon_s TYPE string,
          lv_icon_d TYPE string,
          lv_icon_x TYPE string,
          lv_css TYPE string,
          lv_body TYPE string,
          lv_view TYPE string.

    CASE ms_sm37-light.
      WHEN 'R'. lv_icon_s = '🔴'.
      WHEN 'Y'. lv_icon_s = '🟡'.
      WHEN OTHERS. lv_icon_s = '🟢'.
    ENDCASE.
    CASE ms_st22-light.
      WHEN 'R'. lv_icon_d = '🔴'.
      WHEN 'Y'. lv_icon_d = '🟡'.
      WHEN OTHERS. lv_icon_d = '🟢'.
    ENDCASE.
    CASE ms_sxi-light.
      WHEN 'R'. lv_icon_x = '🔴'.
      WHEN 'Y'. lv_icon_x = '🟡'.
      WHEN OTHERS. lv_icon_x = '🟢'.
    ENDCASE.
    IF mv_view = c_view_topn.
      lv_view = 'Top-N'.
    ELSE.
      lv_view = '시간추이'.
    ENDIF.

    lv_css =
      'body{margin:0;font-family:Arial,Helvetica,sans-serif;background:#0f172a;color:#e2e8f0;}' &&
      '.wrap{display:flex;gap:12px;padding:8px 12px;align-items:center;}' &&
      '.kpi{flex:1;background:#1e293b;border-radius:8px;padding:8px 12px;border-left:5px solid #26A69A;}' &&
      '.kpi.st22{border-left-color:#EF5350;}' &&
      '.kpi.sxi{border-left-color:#FFA726;}' &&
      '.t{font-size:12px;opacity:.85;}.n{font-size:20px;font-weight:700;}' &&
      '.meta{font-size:11px;opacity:.7;margin-left:auto;}'.

    lv_body =
      '<div class="wrap">' &&
      '<div class="kpi"><div class="t">' && lv_icon_s && ' SM37 배치</div>' &&
      '<div class="n">' && |{ ms_sm37-count_all }| && '건</div></div>' &&
      '<div class="kpi st22"><div class="t">' && lv_icon_d && ' ST22 덤프</div>' &&
      '<div class="n">' && |{ ms_st22-count_all }| && '건</div></div>' &&
      '<div class="kpi sxi"><div class="t">' && lv_icon_x && ' SXI 인터페이스</div>' &&
      '<div class="n">' && |{ ms_sxi-count_all }| && '건</div></div>' &&
      '<div class="meta">조회 ' && |{ ms_sel-hours }| && 'H · ' &&
      |{ mv_elapsed }| && 'ms · 관점 ' && lv_view &&
      ' · REFRESH/TOGGLE/STATS/HELP</div></div>'.

    rv_html = '<html><head><meta charset="utf-8"><style>' && lv_css &&
              '</style></head><body>' && lv_body && '</body></html>'.
  ENDMETHOD.

  METHOD build_topn_html.
    DATA: lt TYPE ty_chart_tab,
          ls TYPE ty_chart_bar,
          lv_max TYPE i VALUE 1,
          lv_pct TYPE i,
          lv_w TYPE i,
          lv_lab TYPE string,
          lv_rows TYPE string,
          lv_col TYPE string.

    lv_col = lcl_util=>area_color( iv_area ).
    LOOP AT mt_topn INTO ls WHERE area = iv_area.
      APPEND ls TO lt.
      IF ls-value > lv_max.
        lv_max = ls-value.
      ENDIF.
    ENDLOOP.
    IF lt IS INITIAL.
      rv_html = '<div class="sec"><div class="h" style="color:' && lv_col && ';">' &&
                iv_area && ' Top-N</div><div class="empty">데이터 없음</div></div>'.
      RETURN.
    ENDIF.
    LOOP AT lt INTO ls.
      lv_pct = ls-value * 100 / lv_max.
      IF lv_pct < 2 AND ls-value > 0.
        lv_pct = 2.
      ENDIF.
      lv_w = lv_pct.
      lv_lab = lcl_util=>escape_html( ls-label ).
      lv_rows = lv_rows &&
        '<div class="row" title="' && lcl_util=>escape_html( ls-tip ) && '">' &&
        '<div class="lab">' && lv_lab && '</div>' &&
        '<div class="barw"><div class="bar" style="width:' && |{ lv_w }| &&
        '%;background:' && lv_col && ';"></div></div>' &&
        '<div class="val">' && |{ ls-value }| && '</div></div>'.
    ENDLOOP.
    rv_html = '<div class="sec"><div class="h" style="color:' && lv_col && ';">' &&
              iv_area && ' Top-N (독립스케일)</div>' && lv_rows && '</div>'.
  ENDMETHOD.

  METHOD build_time_html.
    DATA: lt TYPE ty_chart_tab,
          ls TYPE ty_chart_bar,
          lv_max TYPE i VALUE 1,
          lv_pct TYPE i,
          lv_h TYPE i,
          lv_bars TYPE string,
          lv_col TYPE string,
          lv_axis TYPE string.

    lv_col = lcl_util=>area_color( iv_area ).
    LOOP AT mt_time INTO ls WHERE area = iv_area.
      APPEND ls TO lt.
      IF ls-value > lv_max.
        lv_max = ls-value.
      ENDIF.
    ENDLOOP.
    lv_axis = lcl_util=>escape_html( mv_tfirst ) && ' | ' &&
              lcl_util=>escape_html( mv_tunit ) && ' | ' &&
              lcl_util=>escape_html( mv_tlast ).
    IF lt IS INITIAL.
      rv_html = '<div class="sec"><div class="h" style="color:' && lv_col && ';">' &&
                iv_area && ' 추이</div><div class="empty">데이터 없음</div>' &&
                '<div class="axis">' && lv_axis && '</div></div>'.
      RETURN.
    ENDIF.
    LOOP AT lt INTO ls.
      lv_pct = ls-value * 100 / lv_max.
      IF lv_pct < 3 AND ls-value > 0.
        lv_pct = 3.
      ENDIF.
      lv_h = lv_pct.
      lv_bars = lv_bars &&
        '<div class="vcol" title="' && lcl_util=>escape_html( ls-tip ) && '">' &&
        '<div class="vbar" style="height:' && |{ lv_h }| &&
        '%;background:' && lv_col && ';"></div></div>'.
    ENDLOOP.
    rv_html = '<div class="sec"><div class="h" style="color:' && lv_col && ';">' &&
              iv_area && ' 시간추이 (독립스케일)</div>' &&
              '<div class="vwrap">' && lv_bars && '</div>' &&
              '<div class="axis">' && lv_axis && '</div></div>'.
  ENDMETHOD.

  METHOD build_chart_html.
    DATA: lv_css TYPE string,
          lv_body TYPE string,
          lv_title TYPE string.
    lv_css =
      'body{margin:0;font-family:Arial,Helvetica,sans-serif;background:#f8fafc;color:#0f172a;}' &&
      '.box{padding:6px 10px;}' &&
      '.grid{display:flex;gap:10px;}' &&
      '.sec{flex:1;background:#fff;border:1px solid #e2e8f0;border-radius:8px;padding:8px;}' &&
      '.h{font-size:12px;font-weight:700;margin-bottom:6px;}' &&
      '.row{display:flex;align-items:center;gap:6px;margin:3px 0;font-size:11px;}' &&
      '.lab{width:38%;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}' &&
      '.barw{flex:1;background:#e2e8f0;height:12px;border-radius:3px;}' &&
      '.bar{height:12px;border-radius:3px;}' &&
      '.val{width:28px;text-align:right;}' &&
      '.vwrap{display:flex;align-items:flex-end;height:90px;gap:2px;padding:4px 0;}' &&
      '.vcol{flex:1;height:100%;display:flex;align-items:flex-end;}' &&
      '.vbar{width:100%;border-radius:3px 3px 0 0;min-height:2px;}' &&
      '.axis{font-size:10px;color:#64748b;margin-top:4px;text-align:center;}' &&
      '.empty{font-size:11px;color:#94a3b8;}' &&
      '.ttl{font-size:12px;margin-bottom:6px;font-weight:700;}'.
    IF mv_view = c_view_topn.
      lv_title = '관점: 영역별 Top-N 집중도 (가로 막대 · 영역별 독립 스케일)'.
      lv_body = '<div class="grid">' &&
                build_topn_html( c_area_sm37 ) &&
                build_topn_html( c_area_st22 ) &&
                build_topn_html( c_area_sxi ) &&
                '</div>'.
    ELSE.
      lv_title = '관점: 시간대별 추이 (세로 막대 · 축=first|단위|last)'.
      lv_body = '<div class="grid">' &&
                build_time_html( c_area_sm37 ) &&
                build_time_html( c_area_st22 ) &&
                build_time_html( c_area_sxi ) &&
                '</div>'.
    ENDIF.
    rv_html = '<html><head><meta charset="utf-8"><style>' && lv_css &&
              '</style></head><body><div class="box"><div class="ttl">' &&
              lv_title && '</div>' && lv_body && '</div></body></html>'.
  ENDMETHOD.

  METHOD build_stats_html.
    DATA: lv_total TYPE i,
          lv_health TYPE string,
          lv_hcol TYPE string,
          lv_css TYPE string,
          lv_cards TYPE string,
          lv_share TYPE i,
          lv_bar TYPE i,
          lv_badge TYPE string,
          lv_ts TYPE string.

    lv_total = ms_sm37-count_all + ms_st22-count_all + ms_sxi-count_all.
    IF ms_sm37-light = 'R' OR ms_st22-light = 'R' OR ms_sxi-light = 'R'.
      lv_health = 'CRITICAL'.
      lv_hcol = '#EF5350'.
    ELSEIF ms_sm37-light = 'Y' OR ms_st22-light = 'Y' OR ms_sxi-light = 'Y'.
      lv_health = 'WARNING'.
      lv_hcol = '#FFA726'.
    ELSEIF lv_total = 0.
      lv_health = 'ALL CLEAR'.
      lv_hcol = '#26A69A'.
    ELSE.
      lv_health = 'STABLE'.
      lv_hcol = '#42A5F5'.
    ENDIF.

    lv_ts = |{ sy-datum DATE = USER } { sy-uzeit TIME = USER }|.

    IF lv_total > 0. lv_share = ( ms_sm37-count_all * 100 ) / lv_total. ELSE. lv_share = 0. ENDIF.
    lv_bar = lv_share.
    IF ms_sm37-light = 'R'. lv_badge = 'RED'. ELSEIF ms_sm37-light = 'Y'. lv_badge = 'YELLOW'. ELSE. lv_badge = 'GREEN'. ENDIF.
    lv_cards = lv_cards &&
      '<div class="card" style="border-left:6px solid ' && c_col_sm37 && ';">' &&
      '<div class="ct">SM37 배치</div><div class="cn">' && |{ ms_sm37-count_all }| && '건</div>' &&
      '<div class="badge">' && lv_badge && ' · 점유 ' && |{ lv_share }| && '%</div>' &&
      '<div class="share"><div style="width:' && |{ lv_bar }| && '%;background:' && c_col_sm37 && ';"></div></div></div>'.

    IF lv_total > 0. lv_share = ( ms_st22-count_all * 100 ) / lv_total. ELSE. lv_share = 0. ENDIF.
    lv_bar = lv_share.
    IF ms_st22-light = 'R'. lv_badge = 'RED'. ELSEIF ms_st22-light = 'Y'. lv_badge = 'YELLOW'. ELSE. lv_badge = 'GREEN'. ENDIF.
    lv_cards = lv_cards &&
      '<div class="card" style="border-left:6px solid ' && c_col_st22 && ';">' &&
      '<div class="ct">ST22 덤프</div><div class="cn">' && |{ ms_st22-count_all }| && '건</div>' &&
      '<div class="badge">' && lv_badge && ' · 점유 ' && |{ lv_share }| && '%</div>' &&
      '<div class="share"><div style="width:' && |{ lv_bar }| && '%;background:' && c_col_st22 && ';"></div></div></div>'.

    IF lv_total > 0. lv_share = ( ms_sxi-count_all * 100 ) / lv_total. ELSE. lv_share = 0. ENDIF.
    lv_bar = lv_share.
    IF ms_sxi-light = 'R'. lv_badge = 'RED'. ELSEIF ms_sxi-light = 'Y'. lv_badge = 'YELLOW'. ELSE. lv_badge = 'GREEN'. ENDIF.
    lv_cards = lv_cards &&
      '<div class="card" style="border-left:6px solid ' && c_col_sxi && ';">' &&
      '<div class="ct">SXI 인터페이스</div><div class="cn">' && |{ ms_sxi-count_all }| && '건</div>' &&
      '<div class="badge">' && lv_badge && ' · 점유 ' && |{ lv_share }| && '%</div>' &&
      '<div class="share"><div style="width:' && |{ lv_bar }| && '%;background:' && c_col_sxi && ';"></div></div></div>'.

    lv_css =
      'body{margin:0;font-family:Arial,Helvetica,sans-serif;background:#f1f5f9;color:#0f172a;}' &&
      '.hdr{background:' && lv_hcol && ';color:#fff;padding:16px 18px;}' &&
      '.hdr .lab{font-size:12px;opacity:.9;}.hdr .big{font-size:28px;font-weight:800;}' &&
      '.hdr .sub{font-size:13px;margin-top:4px;}' &&
      '.body{padding:14px;}' &&
      '.card{background:#fff;border-radius:8px;padding:10px 12px;margin:8px 0;' &&
      'box-shadow:0 1px 2px rgba(0,0,0,.06);}' &&
      '.ct{font-size:12px;color:#64748b;}.cn{font-size:22px;font-weight:700;}' &&
      '.badge{font-size:11px;margin:4px 0;}' &&
      '.share{background:#e2e8f0;height:8px;border-radius:4px;}' &&
      '.share div{height:8px;border-radius:4px;}' &&
      '.chips span{display:inline-block;background:#e2e8f0;border-radius:4px;' &&
      'padding:2px 8px;margin:2px;font-size:11px;}' &&
      '.ft{padding:10px 14px;font-size:11px;color:#64748b;border-top:1px solid #e2e8f0;}'.

    rv_html =
      '<html><head><meta charset="utf-8"><style>' && lv_css && '</style></head><body>' &&
      '<div class="hdr"><div class="lab">OPS HEALTH</div><div class="big">' &&
      lv_health && '</div><div class="sub">총 에러 ' && |{ lv_total }| &&
      '건</div></div><div class="body">' && lv_cards &&
      '<div class="chips"><span>조회시각 ' && lv_ts && '</span><span>소요 ' &&
      |{ mv_elapsed }| && 'ms</span><span>기간 ' && |{ ms_sel-hours }| &&
      'H</span></div></div>' &&
      '<div class="ft">읽기 전용 · 창 닫기(X)</div></body></html>'.
  ENDMETHOD.

  METHOD build_help_html.
    DATA lv_css TYPE string.
    lv_css =
      'body{margin:0;font-family:Arial,Helvetica,sans-serif;background:#f8fafc;color:#0f172a;}' &&
      '.hdr{background:linear-gradient(90deg,#0f172a,#334155);color:#fff;padding:16px;}' &&
      '.hdr h1{margin:0;font-size:18px;}' &&
      '.body{padding:14px;}' &&
      '.step{background:#fff;border:1px solid #e2e8f0;border-radius:8px;padding:10px;' &&
      'margin:8px 0;}' &&
      '.n{display:inline-block;width:22px;height:22px;border-radius:50%;background:#26A69A;' &&
      'color:#fff;text-align:center;font-size:12px;line-height:22px;margin-right:6px;}' &&
      'code{background:#e2e8f0;padding:1px 6px;border-radius:4px;font-size:12px;}' &&
      '.note{background:#FFF8E1;border-left:4px solid #FFA726;padding:10px;margin-top:10px;' &&
      'font-size:12px;}' &&
      '.ft{padding:10px;font-size:11px;color:#64748b;}'.

    rv_html =
      '<html><head><meta charset="utf-8"><style>' && lv_css && '</style></head><body>' &&
      '<div class="hdr"><h1>Y_OPS_MONITOR_V2 사용 안내</h1>' &&
      '<div>읽기 전용 통합 운영 모니터 (SM37 / ST22 / SXI)</div></div><div class="body">' &&
      '<div class="step"><span class="n">1</span>선택화면에서 기간·영역 On/Off 후 실행(F8)</div>' &&
      '<div class="step"><span class="n">2</span>상단 KPI로 영역별 신호등·건수를 확인</div>' &&
      '<div class="step"><span class="n">3</span><code>TOGGLE</code> 로 Top-N ↔ 시간추이 전환</div>' &&
      '<div class="step"><span class="n">4</span><code>STATS</code> 헬스 카드 / <code>HELP</code> 본 안내</div>' &&
      '<div class="step"><span class="n">5</span>ALV 더블클릭·핫스팟 → 표준 표시 화면 드릴다운</div>' &&
      '<div class="step"><span class="n">6</span><code>REFRESH</code> 로 동일 조건 재조회</div>' &&
      '<div class="note">본 프로그램은 읽기 전용입니다. 잡 재실행·메시지 재전송·DML/COMMIT/' &&
      'Enqueue/Update Task 를 수행하지 않습니다.</div></div>' &&
      '<div class="ft">읽기 전용 · 창 닫기(X)</div></body></html>'.
  ENDMETHOD.
ENDCLASS.

*----------------------------------------------------------------------*
* Global objects
*----------------------------------------------------------------------*
DATA: go_controller TYPE REF TO lcl_mon_controller,
      go_ui         TYPE REF TO lcl_mon_ui_dashboard,
      gs_sel        TYPE ty_sel.

*----------------------------------------------------------------------*
* Selection-screen logic
*----------------------------------------------------------------------*
INITIALIZATION.
  lcl_util=>apply_hours(
    EXPORTING iv_hours = 24
    IMPORTING ev_frdat = p_frdat ev_frtim = p_frtim
              ev_todat = p_todat ev_totim = p_totim ).
  p_hours = 24.
  p_maxrow = 250.
  p_topn = 5.
  p_mand = sy-mandt.

AT SELECTION-SCREEN ON p_hours.
  IF p_hours <= 0 OR p_hours > c_max_hours.
    MESSAGE 'P_HOURS 범위 오류(1~720)' TYPE 'E'.
  ENDIF.
  lcl_util=>apply_hours(
    EXPORTING iv_hours = p_hours
    IMPORTING ev_frdat = p_frdat ev_frtim = p_frtim
              ev_todat = p_todat ev_totim = p_totim ).

AT SELECTION-SCREEN.
  IF p_frdat > p_todat OR ( p_frdat = p_todat AND p_frtim > p_totim ).
    MESSAGE '조회기간 FROM > TO' TYPE 'E'.
  ENDIF.
  IF cb_sm37 IS INITIAL AND cb_st22 IS INITIAL AND cb_sxi IS INITIAL.
    MESSAGE '최소 1개 영역을 선택' TYPE 'E'.
  ENDIF.
  IF p_maxrow <= 0.
    p_maxrow = 250.
  ENDIF.
  IF p_topn <= 0.
    p_topn = 5.
  ENDIF.

START-OF-SELECTION.
  CLEAR gs_sel.
  gs_sel-frdat  = p_frdat.
  gs_sel-frtim  = p_frtim.
  gs_sel-todat  = p_todat.
  gs_sel-totim  = p_totim.
  gs_sel-hours  = p_hours.
  gs_sel-sm37   = boolc( cb_sm37 = abap_true ).
  gs_sel-st22   = boolc( cb_st22 = abap_true ).
  gs_sel-sxi    = boolc( cb_sxi  = abap_true ).
  gs_sel-mandt  = p_mand.
  gs_sel-maxrow = p_maxrow.
  gs_sel-topn   = p_topn.

  CREATE OBJECT go_controller.
  go_controller->run( gs_sel ).
  CREATE OBJECT go_ui
    EXPORTING
      io_controller = go_controller
      is_sel        = gs_sel.
  CALL SCREEN 0100.

*----------------------------------------------------------------------*
* Screen 0100 — empty dynpro; docking fills the area
* Create in SE51: screen 0100, no elements, OK_CODE = OK_CODE
* GUI status YOPS_STAT with: BACK EXIT CANC REFRESH TOGGLE STATS HELP
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'YOPS_STAT'.
  SET TITLEBAR 'YOPS_TIT'.
  IF go_ui IS BOUND.
    go_ui->display( ).
  ENDIF.
ENDMODULE.

MODULE user_command_0100 INPUT.
  g_ok = ok_code.
  CLEAR ok_code.
  IF go_ui IS BOUND.
    go_ui->handle_ucomm( g_ok ).
  ELSE.
    CASE g_ok.
      WHEN 'BACK' OR 'EXIT' OR 'CANC' OR 'CANCEL'.
        LEAVE TO SCREEN 0.
    ENDCASE.
  ENDIF.
ENDMODULE.

*----------------------------------------------------------------------*
* SE51 Screen 0100 flow logic (create empty dynpro + OK_CODE field):
*
*   PROCESS BEFORE OUTPUT.
*     MODULE status_0100.
*   PROCESS AFTER INPUT.
*     MODULE user_command_0100.
*
* GUI Status YOPS_STAT function keys / buttons:
*   BACK, EXIT, CANC, REFRESH, TOGGLE, STATS, HELP
* Title YOPS_TIT: 통합 운영 모니터 V2
*
* Selection-screen text symbols (SE38 → Text elements):
*   B01 조회 기간 / B02 조회 영역 / B03 추가 필터 / B04 표시 옵션
*----------------------------------------------------------------------*
