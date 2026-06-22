*&---------------------------------------------------------------------*
*& Report Z_OPS_MONITOR
*&---------------------------------------------------------------------*
*& 통합 운영 모니터링 (프로토타입 / 단일 프로그램, 로컬 오브젝트)
*&   - SM37 배치 잡 에러 (TBTCO / TBTCP)
*&   - ST22 런타임 에러 (FM RS_ST22_GET_DUMPS / RSDUMPTAB)
*&   - SXI_MONITOR 인터페이스 에러 (SXMSPERROR / SXMSPMAST / SXMSPEMAS)
*&
*& [원칙] READ-ONLY : SELECT / 조회 FM / 표시용 드릴다운만 수행.
*&        INSERT/UPDATE/MODIFY/DELETE/COMMIT/ENQUEUE 등 일절 없음.
*&
*& [주의/TODO]
*&   - RS_ST22_GET_DUMPS : EXPORTING p_day / IMPORTING p_infotab(RSDUMPTAB) 정적 호출.
*&   - 권한 객체(S_BTCH_JOB / S_ADMI_FCD / S_XMB_MONI)는 SU24/STAUTHTRACE 검증 후 확정.
*&   - IGS 차트(CL_GUI_CHART_ENGINE)는 본 프로토타입 제외(Top-N 그리드로 대체).
*&---------------------------------------------------------------------*
REPORT z_ops_monitor.

TYPE-POOLS: icon.

*&---------------------------------------------------------------------*
*& SELECT-OPTIONS 참조용 투명 테이블 선언
*&---------------------------------------------------------------------*
TABLES: tbtco,      " SM37 : jobname / sdluname
        sxmspemas.  " SXI  : ob_name (인터페이스명)

*&---------------------------------------------------------------------*
*& 로컬 타입 정의 (DDIC 미사용)
*&---------------------------------------------------------------------*
TYPES: BEGIN OF ty_sm37,
         light    TYPE c LENGTH 4,
         jobname  TYPE tbtco-jobname,
         jobcount TYPE tbtco-jobcount,
         status   TYPE tbtco-status,
         statustx TYPE c LENGTH 12,
         progname TYPE tbtcp-progname,
         sdluname TYPE tbtco-sdluname,
         strtdate TYPE tbtco-strtdate,
         strttime TYPE tbtco-strttime,
         enddate  TYPE tbtco-enddate,
         endtime  TYPE tbtco-endtime,
       END OF ty_sm37,
       tt_sm37 TYPE STANDARD TABLE OF ty_sm37 WITH DEFAULT KEY.

TYPES: BEGIN OF ty_st22,
         light    TYPE c LENGTH 4,
         datum    TYPE d,
         uzeit    TYPE t,
         uname    TYPE syuname,
         ahost    TYPE c LENGTH 32,
         dumpid   TYPE c LENGTH 30,
         progname TYPE c LENGTH 40,
         include  TYPE c LENGTH 40,
         line     TYPE c LENGTH 5,
       END OF ty_st22,
       tt_st22 TYPE STANDARD TABLE OF ty_st22 WITH DEFAULT KEY.

TYPES: BEGIN OF ty_sxi,
         light     TYPE c LENGTH 4,
         exe_date  TYPE d,
         exe_time  TYPE t,
         if_name   TYPE sxmspemas-ob_name,
         operation TYPE sxmspemas-ob_operation,
         sender    TYPE sxmspemas-ob_system,
         receiver  TYPE sxmspemas-ib_system,
         msgstate  TYPE sxmspmast-msgstate,
         errstat   TYPE sxmsperror-errstat,
         msgguid   TYPE sxmspmast-msgguid,
       END OF ty_sxi,
       tt_sxi TYPE STANDARD TABLE OF ty_sxi WITH DEFAULT KEY.

TYPES: BEGIN OF ty_sum,
         light TYPE c LENGTH 4,
         area  TYPE c LENGTH 30,
         count TYPE i,
       END OF ty_sum,
       tt_sum TYPE STANDARD TABLE OF ty_sum WITH DEFAULT KEY.

TYPES: BEGIN OF ty_top,
         area  TYPE c LENGTH 8,
         key   TYPE c LENGTH 120,
         count TYPE i,
       END OF ty_top,
       tt_top TYPE STANDARD TABLE OF ty_top WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*& 전역 데이터 (SALV/핸들러가 참조하므로 전역 유지)
*&---------------------------------------------------------------------*
DATA: gt_sm37 TYPE tt_sm37,
      gt_st22 TYPE tt_st22,
      gt_sxi  TYPE tt_sxi,
      gt_sum  TYPE tt_sum,
      gt_top  TYPE tt_top.

" 전체 건수(표시 상한 적용 전 = 차트/요약 집계 기준)
DATA: gv_cnt_sm37 TYPE i,
      gv_cnt_st22 TYPE i,
      gv_cnt_sxi  TYPE i.

" 컨테이너 / SALV (전역)
DATA: go_custom TYPE REF TO cl_gui_custom_container,  " 화면 0100 의 Custom Control 'CC_DASH'
      go_split  TYPE REF TO cl_gui_splitter_container,
      go_split2 TYPE REF TO cl_gui_splitter_container.

" 화면 0100 제어
DATA: ok_code  TYPE sy-ucomm,
      gv_built TYPE abap_bool.

DATA: go_salv_sum  TYPE REF TO cl_salv_table,
      go_salv_top  TYPE REF TO cl_salv_table,
      go_salv_sm37 TYPE REF TO cl_salv_table,
      go_salv_st22 TYPE REF TO cl_salv_table,
      go_salv_sxi  TYPE REF TO cl_salv_table.

DATA: go_dd    TYPE REF TO cl_dd_document,      " 요약 텍스트 보드
      go_chart TYPE REF TO cl_gui_chart_engine. " Top-N 차트(IGS)

*&---------------------------------------------------------------------*
*& 신호등 임계치 (O-6 확정) - 클래스/상수 관리
*&---------------------------------------------------------------------*
CONSTANTS: c_st22_red TYPE i VALUE 31,   " ST22 : 1~30 황 / >=31 적
           c_sxi_red  TYPE i VALUE 51.   " SXI  : 1~50 황 / >=51 적
"          SM37 : 0 녹 / >=1 적 (황 없음)

*&---------------------------------------------------------------------*
*& 선택 화면
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.
PARAMETERS: p_frdat TYPE d,
            p_frtim TYPE t,
            p_todat TYPE d,
            p_totim TYPE t,
            p_hours TYPE i DEFAULT 24.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-b02.
PARAMETERS: cb_sm37 TYPE c AS CHECKBOX DEFAULT 'X',
            cb_st22 TYPE c AS CHECKBOX DEFAULT 'X',
            cb_sxi  TYPE c AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-b03.
SELECT-OPTIONS: so_job   FOR tbtco-jobname,
                so_user  FOR tbtco-sdluname,
                so_iface FOR sxmspemas-ob_name.
PARAMETERS: p_mand TYPE mandt DEFAULT sy-mandt.
SELECTION-SCREEN END OF BLOCK b3.

SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-b04.
PARAMETERS: p_maxrow TYPE i DEFAULT 250,
            p_topn   TYPE i DEFAULT 5.
SELECTION-SCREEN END OF BLOCK b4.

*&---------------------------------------------------------------------*
*& 이벤트 핸들러 (로컬 클래스)
*&---------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    METHODS:
      on_dc_sm37 FOR EVENT double_click OF cl_salv_events_table
        IMPORTING row column,
      on_dc_st22 FOR EVENT double_click OF cl_salv_events_table
        IMPORTING row column,
      on_dc_sxi  FOR EVENT double_click OF cl_salv_events_table
        IMPORTING row column.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.
  METHOD on_dc_sm37.
    READ TABLE gt_sm37 INTO DATA(ls) INDEX row.
    IF sy-subrc = 0.
      CALL FUNCTION 'BP_JOBLOG_SHOW'
        EXPORTING
          jobcount        = ls-jobcount
          jobname         = ls-jobname
        EXCEPTIONS
          OTHERS          = 1.
      IF sy-subrc <> 0.
        MESSAGE '잡 로그를 표시할 수 없습니다.' TYPE 'S' DISPLAY LIKE 'W'.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD on_dc_st22.
    READ TABLE gt_st22 INTO DATA(ls) INDEX row.
    IF sy-subrc = 0.
      CALL TRANSACTION 'ST22'.          "#EC CI_CALLTA  (표시 전용)
    ENDIF.
  ENDMETHOD.

  METHOD on_dc_sxi.
    READ TABLE gt_sxi INTO DATA(ls) INDEX row.
    IF sy-subrc = 0.
      CALL TRANSACTION 'SXI_MONITOR'.   "#EC CI_CALLTA  (표시 전용)
    ENDIF.
  ENDMETHOD.
ENDCLASS.

DATA: go_handler TYPE REF TO lcl_handler.

*&---------------------------------------------------------------------*
*& INITIALIZATION : 기본 조회기간 = 현재시각 -24H ~ 현재시각
*&---------------------------------------------------------------------*
INITIALIZATION.
  PERFORM set_default_period.

*&---------------------------------------------------------------------*
*& AT SELECTION-SCREEN : 기간 검증
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN.
  IF p_frdat > p_todat
     OR ( p_frdat = p_todat AND p_frtim > p_totim ).
    MESSAGE '조회 시작이 종료보다 이후입니다.' TYPE 'E'.
  ENDIF.

*&---------------------------------------------------------------------*
*& START-OF-SELECTION
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  CLEAR: gt_sm37, gt_st22, gt_sxi, gt_sum, gt_top,
         gv_cnt_sm37, gv_cnt_st22, gv_cnt_sxi.

  IF cb_sm37 = 'X'.
    PERFORM get_sm37.
  ENDIF.
  IF cb_st22 = 'X'.
    PERFORM get_st22.
  ENDIF.
  IF cb_sxi = 'X'.
    PERFORM get_sxi.
  ENDIF.

  PERFORM build_topn.
  PERFORM build_summary.
  PERFORM apply_maxrow.

  " 전용 화면(Dynpro 0100)에서 대시보드 표시
  CALL SCREEN 0100.

*&---------------------------------------------------------------------*
*& FORM set_default_period
*&---------------------------------------------------------------------*
FORM set_default_period.
  DATA lv_ts TYPE timestamp.

  p_todat = sy-datum.
  p_totim = sy-uzeit.

  CONVERT DATE sy-datum TIME sy-uzeit
          INTO TIME STAMP lv_ts TIME ZONE sy-zonlo.
  lv_ts = cl_abap_tstmp=>subtractsecs( tstmp = lv_ts
                                       secs  = p_hours * 3600 ).
  CONVERT TIME STAMP lv_ts TIME ZONE sy-zonlo
          INTO DATE p_frdat TIME p_frtim.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM get_sm37  (배치 잡 에러 : 종료시각 기준 - O-1)
*&---------------------------------------------------------------------*
FORM get_sm37.
  SELECT jobname jobcount status sdluname
         strtdate strttime enddate endtime
    FROM tbtco
    INTO CORRESPONDING FIELDS OF TABLE gt_sm37
   WHERE status = 'A'
     AND jobname  IN so_job
     AND sdluname IN so_user
     AND ( enddate > p_frdat
        OR ( enddate = p_frdat AND endtime >= p_frtim ) )
     AND ( enddate < p_todat
        OR ( enddate = p_todat AND endtime <= p_totim ) ).

  LOOP AT gt_sm37 ASSIGNING FIELD-SYMBOL(<fs>).
    <fs>-light    = icon_red_light.
    <fs>-statustx = 'Cancelled'.
    " 대표 스텝 프로그램 (마지막 스텝)
    SELECT progname FROM tbtcp
      INTO <fs>-progname
      UP TO 1 ROWS
     WHERE jobname  = <fs>-jobname
       AND jobcount = <fs>-jobcount
     ORDER BY stepcount DESCENDING.
    ENDSELECT.
  ENDLOOP.

  gv_cnt_sm37 = lines( gt_sm37 ).
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM get_st22  (런타임 에러 : RS_ST22_GET_DUMPS 날짜별 호출 - O-11)
*&---------------------------------------------------------------------*
FORM get_st22.
  DATA: lv_date TYPE d.

  lv_date = p_frdat.
  WHILE lv_date <= p_todat.
    PERFORM get_st22_for_date USING lv_date.
    lv_date = lv_date + 1.
  ENDWHILE.

  gv_cnt_st22 = lines( gt_st22 ).
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM get_st22_for_date
*&   RS_ST22_GET_DUMPS( p_day ) 정적 호출 + 경계일 시간 필터
*&---------------------------------------------------------------------*
FORM get_st22_for_date USING iv_date TYPE d.
  DATA: lt_info TYPE rsdumptab,
        lv_date TYPE d.

  lv_date = iv_date.

  TRY.
      CALL FUNCTION 'RS_ST22_GET_DUMPS'
        EXPORTING
          p_day        = lv_date
        IMPORTING
          p_infotab    = lt_info
        EXCEPTIONS
          no_authority = 1
          others       = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    CATCH cx_root.
      " 시그니처 불일치 등 예외 시 해당 날짜 스킵 (프로그램은 계속 동작)
      RETURN.
  ENDTRY.

  LOOP AT lt_info ASSIGNING FIELD-SYMBOL(<info>).
    " 경계일 시간 필터
    IF iv_date = p_frdat AND iv_date = p_todat.
      CHECK <info>-sytime >= p_frtim AND <info>-sytime <= p_totim.
    ELSEIF iv_date = p_frdat.
      CHECK <info>-sytime >= p_frtim.
    ELSEIF iv_date = p_todat.
      CHECK <info>-sytime <= p_totim.
    ENDIF.

    " 사용자 필터(옵션)
    IF so_user IS NOT INITIAL.
      CHECK <info>-syuser IN so_user.
    ENDIF.

    APPEND VALUE ty_st22(
        light    = icon_red_light
        datum    = <info>-sydate
        uzeit    = <info>-sytime
        uname    = <info>-syuser
        ahost    = <info>-syhost
        dumpid   = <info>-dumpid
        progname = <info>-programname
        include  = <info>-includename
        line     = <info>-linenumber ) TO gt_st22.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM get_sxi  (인터페이스 에러 : SXMSPERROR 기점 + 조인 - O-4/O-10)
*&---------------------------------------------------------------------*
FORM get_sxi.
  DATA: lv_tsl  TYPE timestampl,
        lv_from TYPE sxmsperror-exetimest,
        lv_to   TYPE sxmsperror-exetimest.

  " 로컬 일자/시간 -> 긴 형식 UTC 타임스탬프
  CONVERT DATE p_frdat TIME p_frtim INTO TIME STAMP lv_tsl TIME ZONE sy-zonlo.
  lv_from = lv_tsl.
  CONVERT DATE p_todat TIME p_totim INTO TIME STAMP lv_tsl TIME ZONE sy-zonlo.
  lv_to = lv_tsl.

  SELECT err~msgguid AS msgguid,
         err~errstat AS errstat,
         err~exetimest AS exetimest,
         mast~msgstate AS msgstate,
         emas~ob_name AS if_name,
         emas~ob_operation AS operation,
         emas~ob_system AS sender,
         emas~ib_system AS receiver
    FROM sxmsperror AS err
    INNER JOIN sxmspmast AS mast ON  mast~msgguid = err~msgguid
                                 AND mast~pid     = err~pid
    INNER JOIN sxmspemas AS emas ON  emas~msgguid = err~msgguid
                                 AND emas~pid     = err~pid
   WHERE err~exetimest BETWEEN @lv_from AND @lv_to
     AND emas~ob_name <> @space          " 인터페이스명이 존재하는 건만
     AND emas~ob_name IN @so_iface
    INTO TABLE @DATA(lt_sxi).

  LOOP AT lt_sxi ASSIGNING FIELD-SYMBOL(<s>).
    DATA: lv_ts2  TYPE timestampl,
          lv_date TYPE d,
          lv_time TYPE t.
    lv_ts2 = <s>-exetimest.
    CONVERT TIME STAMP lv_ts2 TIME ZONE sy-zonlo INTO DATE lv_date TIME lv_time.

    APPEND VALUE ty_sxi(
        light     = icon_red_light
        exe_date  = lv_date
        exe_time  = lv_time
        if_name   = <s>-if_name
        operation = <s>-operation
        sender    = <s>-sender
        receiver  = <s>-receiver
        msgstate  = <s>-msgstate
        errstat   = <s>-errstat
        msgguid   = <s>-msgguid ) TO gt_sxi.
  ENDLOOP.

  SORT gt_sxi BY exe_date DESCENDING exe_time DESCENDING.
  gv_cnt_sxi = lines( gt_sxi ).
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM build_topn  (영역별 독립 Top-N, 전체 기준 - O-5/O-8)
*&---------------------------------------------------------------------*
FORM build_topn.
  DATA: lt_tmp TYPE tt_top,
        ls_tmp TYPE ty_top.

  " SM37 : JOBNAME
  LOOP AT gt_sm37 INTO DATA(ls_b).
    ls_tmp-area = 'SM37'. ls_tmp-key = ls_b-jobname. ls_tmp-count = 1.
    COLLECT ls_tmp INTO lt_tmp.
  ENDLOOP.
  " ST22 : DUMPID
  LOOP AT gt_st22 INTO DATA(ls_d).
    ls_tmp-area = 'ST22'. ls_tmp-key = ls_d-dumpid. ls_tmp-count = 1.
    COLLECT ls_tmp INTO lt_tmp.
  ENDLOOP.
  " SXI : OB_NAME(if_name)
  LOOP AT gt_sxi INTO DATA(ls_i).
    ls_tmp-area = 'SXI'. ls_tmp-key = ls_i-if_name. ls_tmp-count = 1.
    COLLECT ls_tmp INTO lt_tmp.
  ENDLOOP.

  SORT lt_tmp BY count DESCENDING.

  DELETE lt_tmp FROM ( p_topn + 1 ).

  MOVE-CORRESPONDING lt_tmp TO gt_top.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM build_summary  (신호등 3단계 - O-6)
*&---------------------------------------------------------------------*
FORM build_summary.
  " SM37 : 0 녹 / >=1 적
  APPEND VALUE ty_sum(
      area  = 'SM37 배치 에러'
      count = gv_cnt_sm37
      light = COND #( WHEN gv_cnt_sm37 = 0 THEN icon_green_light
                      ELSE icon_red_light ) ) TO gt_sum.
  " ST22 : 0 녹 / 1~30 황 / >=31 적
  APPEND VALUE ty_sum(
      area  = 'ST22 덤프'
      count = gv_cnt_st22
      light = COND #( WHEN gv_cnt_st22 = 0 THEN icon_green_light
                      WHEN gv_cnt_st22 >= c_st22_red THEN icon_red_light
                      ELSE icon_yellow_light ) ) TO gt_sum.
  " SXI : 0 녹 / 1~50 황 / >=51 적
  APPEND VALUE ty_sum(
      area  = 'SXI 인터페이스 에러'
      count = gv_cnt_sxi
      light = COND #( WHEN gv_cnt_sxi = 0 THEN icon_green_light
                      WHEN gv_cnt_sxi >= c_sxi_red THEN icon_red_light
                      ELSE icon_yellow_light ) ) TO gt_sum.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM apply_maxrow  (표시 상한 - 최신순, 집계는 이미 전체기준 완료)
*&---------------------------------------------------------------------*
FORM apply_maxrow.
  DATA lv_from TYPE i.
  CHECK p_maxrow > 0.
  lv_from = p_maxrow + 1.

  SORT gt_sm37 BY enddate DESCENDING endtime DESCENDING.
  SORT gt_st22 BY datum DESCENDING uzeit DESCENDING.
  " gt_sxi 는 이미 최신순 정렬됨

  IF lines( gt_sm37 ) >= lv_from.
    DELETE gt_sm37 FROM lv_from.
  ENDIF.
  IF lines( gt_st22 ) >= lv_from.
    DELETE gt_st22 FROM lv_from.
  ENDIF.
  IF lines( gt_sxi ) >= lv_from.
    DELETE gt_sxi FROM lv_from.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM show_dashboard
*&   Custom Container + 스플리터(요약 / Top-N / 3분할 ALV)
*&---------------------------------------------------------------------*
FORM show_dashboard.
  DATA: lo_c1 TYPE REF TO cl_gui_container,
        lo_c2 TYPE REF TO cl_gui_container,
        lo_c3 TYPE REF TO cl_gui_container,
        lo_s1 TYPE REF TO cl_gui_container,
        lo_s2 TYPE REF TO cl_gui_container,
        lo_s3 TYPE REF TO cl_gui_container.

  go_handler = NEW lcl_handler( ).

  " 화면 0100 의 Custom Control 'CC_DASH' 에 연결
  go_custom = NEW cl_gui_custom_container( container_name = 'CC_DASH' ).

  " 3행 1열 : 요약 / Top-N / ALV영역
  go_split = NEW cl_gui_splitter_container(
               parent  = go_custom
               rows    = 3
               columns = 1 ).
  go_split->set_row_height( id = 1 height = 14 ).
  go_split->set_row_height( id = 2 height = 28 ).

  lo_c1 = go_split->get_container( row = 1 column = 1 ).
  lo_c2 = go_split->get_container( row = 2 column = 1 ).
  lo_c3 = go_split->get_container( row = 3 column = 1 ).

  " 하단: 1행 3열 (SM37 / ST22 / SXI)
  go_split2 = NEW cl_gui_splitter_container(
                parent  = lo_c3
                rows    = 1
                columns = 3 ).
  lo_s1 = go_split2->get_container( row = 1 column = 1 ).
  lo_s2 = go_split2->get_container( row = 1 column = 2 ).
  lo_s3 = go_split2->get_container( row = 1 column = 3 ).

*  PERFORM build_salv USING lo_c1 'SUMMARY'.
*  PERFORM build_salv USING lo_c2 'TOPN'.
  PERFORM build_summary_dd USING lo_c1.   " 요약 텍스트 보드
  PERFORM build_chart      USING lo_c2.   " Top-N 차트
  PERFORM build_salv USING lo_s1 'SM37'.
  PERFORM build_salv USING lo_s2 'ST22'.
  PERFORM build_salv USING lo_s3 'SXI'.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM build_salv  (각 영역 SALV 생성/표시)
*&---------------------------------------------------------------------*
FORM build_salv USING io_cont TYPE REF TO cl_gui_container
                      iv_kind TYPE string.
  DATA: lo_salv  TYPE REF TO cl_salv_table,
        lo_cols  TYPE REF TO cl_salv_columns_table,
        lo_disp  TYPE REF TO cl_salv_display_settings,
        lv_title TYPE lvc_title.

  TRY.
      CASE iv_kind.
*        WHEN 'SUMMARY'.
*          cl_salv_table=>factory( EXPORTING r_container = io_cont
*                                  IMPORTING r_salv_table = lo_salv
*                                  CHANGING  t_table = gt_sum ).
*          go_salv_sum = lo_salv.
*          lv_title = '운영 모니터링 요약 (신호등)'.
*        WHEN 'TOPN'.
*          cl_salv_table=>factory( EXPORTING r_container = io_cont
*                                  IMPORTING r_salv_table = lo_salv
*                                  CHANGING  t_table = gt_top ).
*          go_salv_top = lo_salv.
*          lv_title = '에러 집중도 Top-N (영역별, 전체 기준)'.
        WHEN 'SM37'.
          cl_salv_table=>factory( EXPORTING r_container = io_cont
                                  IMPORTING r_salv_table = lo_salv
                                  CHANGING  t_table = gt_sm37 ).
          go_salv_sm37 = lo_salv.
          lv_title = |SM37 배치 에러 ({ gv_cnt_sm37 })|.
          SET HANDLER go_handler->on_dc_sm37 FOR lo_salv->get_event( ).
        WHEN 'ST22'.
          cl_salv_table=>factory( EXPORTING r_container = io_cont
                                  IMPORTING r_salv_table = lo_salv
                                  CHANGING  t_table = gt_st22 ).
          go_salv_st22 = lo_salv.
          lv_title = |ST22 덤프 ({ gv_cnt_st22 })|.
          SET HANDLER go_handler->on_dc_st22 FOR lo_salv->get_event( ).
        WHEN 'SXI'.
          cl_salv_table=>factory( EXPORTING r_container = io_cont
                                  IMPORTING r_salv_table = lo_salv
                                  CHANGING  t_table = gt_sxi ).
          go_salv_sxi = lo_salv.
          lv_title = |SXI 인터페이스 에러 ({ gv_cnt_sxi })|.
          SET HANDLER go_handler->on_dc_sxi FOR lo_salv->get_event( ).
      ENDCASE.

      " 공통 표시 옵션
      lo_salv->get_functions( )->set_all( abap_true ).
      lo_disp = lo_salv->get_display_settings( ).
      lo_disp->set_list_header( lv_title ).
      lo_disp->set_striped_pattern( abap_true ).

      lo_cols = lo_salv->get_columns( ).
      lo_cols->set_optimize( abap_true ).
      " 신호등 아이콘 컬럼
      TRY.
          DATA lo_colt TYPE REF TO cl_salv_column_table.
          lo_colt ?= lo_cols->get_column( 'LIGHT' ).
          lo_colt->set_icon( if_salv_c_bool_sap=>true ).
          lo_colt->set_short_text( '상태' ).
          lo_colt->set_medium_text( '상태' ).
          lo_colt->set_long_text( '상태' ).
        CATCH cx_salv_not_found.
      ENDTRY.

      lo_salv->display( ).

    CATCH cx_salv_msg INTO DATA(lx_msg).
      MESSAGE lx_msg->get_text( ) TYPE 'S' DISPLAY LIKE 'W'.
  ENDTRY.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM build_summary_dd  (요약 : 텍스트 보드 - CL_DD_DOCUMENT, ALV 아님)
*&---------------------------------------------------------------------*
FORM build_summary_dd USING io_cont TYPE REF TO cl_gui_container.
  go_dd = NEW cl_dd_document( ).

  go_dd->add_text( text = CONV sdydo_text_element(
      |[ 통합 운영 모니터링 요약 ]  조회: { p_frdat DATE = USER } { p_frtim TIME = USER }|
   && | ~ { p_todat DATE = USER } { p_totim TIME = USER }| ) ).
  go_dd->new_line( ).
  go_dd->new_line( ).
*  go_dd->add_gap( width = 5 ).

  PERFORM add_sum_item USING '배치에러(SM37)'  gv_cnt_sm37 'SM37'.
  PERFORM add_sum_item USING '덤프(ST22)'       gv_cnt_st22 'ST22'.
  PERFORM add_sum_item USING '인터페이스(SXI)'  gv_cnt_sxi  'SXI'.

  go_dd->merge_document( ).
  go_dd->display_document( parent = io_cont ).
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM add_sum_item  (요약 1줄 : 신호등 아이콘 + 라벨 + 건수 + 상태)
*&---------------------------------------------------------------------*
FORM add_sum_item USING iv_label TYPE string
                        iv_cnt   TYPE i
                        iv_kind  TYPE string.
  DATA: lv_icon TYPE string,
        lv_stat TYPE string.

  CASE iv_kind.
    WHEN 'SM37'.
      IF iv_cnt = 0. lv_icon = 'ICON_GREEN_LIGHT'. lv_stat = '정상'.
      ELSE.          lv_icon = 'ICON_RED_LIGHT'.   lv_stat = '심각'. ENDIF.
    WHEN 'ST22'.
      go_dd->add_gap( width = 5 ).
      IF iv_cnt = 0.               lv_icon = 'ICON_GREEN_LIGHT'.  lv_stat = '정상'.
      ELSEIF iv_cnt >= c_st22_red. lv_icon = 'ICON_RED_LIGHT'.    lv_stat = '심각'.
      ELSE.                        lv_icon = 'ICON_YELLOW_LIGHT'. lv_stat = '주의'. ENDIF.
    WHEN 'SXI'.
      go_dd->add_gap( width = 5 ).
      IF iv_cnt = 0.              lv_icon = 'ICON_GREEN_LIGHT'.  lv_stat = '정상'.
      ELSEIF iv_cnt >= c_sxi_red. lv_icon = 'ICON_RED_LIGHT'.    lv_stat = '심각'.
      ELSE.                       lv_icon = 'ICON_YELLOW_LIGHT'. lv_stat = '주의'. ENDIF.
  ENDCASE.

*  go_dd->add_gap( width = 8 ).
  go_dd->add_icon( sap_icon = CONV #( lv_icon ) ).
  go_dd->add_text( text = CONV sdydo_text_element(
      |  { iv_label } : { iv_cnt } 건   [ { lv_stat } ]| ) ).

ENDFORM.

*&---------------------------------------------------------------------*
*& FORM build_chart  (Top-N : CL_GUI_CHART_ENGINE / IGS 차트, ALV 아님)
*&---------------------------------------------------------------------*
FORM build_chart USING io_cont TYPE REF TO cl_gui_container.
  DATA: lv_xml    TYPE string,
        lv_cats   TYPE string,
        lv_points TYPE string,
        lo_ixml   TYPE REF TO if_ixml,
        lo_sf     TYPE REF TO if_ixml_stream_factory,
        lo_is     TYPE REF TO if_ixml_istream,
        lo_doc    TYPE REF TO if_ixml_document,
        lo_parser TYPE REF TO if_ixml_parser.

  IF gt_top IS INITIAL.
    RETURN.
  ENDIF.

  LOOP AT gt_top INTO DATA(ls_top).
    lv_cats   = lv_cats   && |<Category>{ ls_top-key } ({ ls_top-area })</Category>|.
    lv_points = lv_points && |<Point><Value type="y">{ ls_top-count }</Value></Point>|.
  ENDLOOP.

  lv_xml = |<?xml version="1.0" encoding="utf-8"?>|
        && |<ChartData>|
        && |<Categories>| && lv_cats && |</Categories>|
        && |<Series label="에러 건수">| && lv_points && |</Series>|
        && |</ChartData>|.

  TRY.
      lo_ixml   = cl_ixml=>create( ).
      lo_doc    = lo_ixml->create_document( ).
      lo_sf     = lo_ixml->create_stream_factory( ).
      lo_is     = lo_sf->create_istream_string( lv_xml ).
      lo_parser = lo_ixml->create_parser( document       = lo_doc
                                          istream        = lo_is
                                          stream_factory = lo_sf ).
      lo_parser->parse( ).

      go_chart = NEW cl_gui_chart_engine( parent = io_cont ).
      go_chart->set_data( data = lv_xml ).   " DATA = STRING (문자열 XML)
      go_chart->render( ).
    CATCH cx_root INTO DATA(lx).
      MESSAGE |Top-N 차트 표시 실패: { lx->get_text( ) }| TYPE 'S'
              DISPLAY LIKE 'W'.
  ENDTRY.
ENDFORM.

*&---------------------------------------------------------------------*
*& MODULE status_0100 OUTPUT  (PBO)
*&   - GUI 상태 설정 + 대시보드 최초 1회 생성
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.

  IF gv_built = abap_false.
    PERFORM show_dashboard.
    gv_built = abap_true.
  ENDIF.
ENDMODULE.

*&---------------------------------------------------------------------*
*& MODULE user_command_0100 INPUT  (PAI)
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  DATA lv_ok TYPE sy-ucomm.
  lv_ok = ok_code.
  CLEAR ok_code.

  CASE lv_ok.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      IF go_custom IS NOT INITIAL.
        go_custom->free( ).
        CLEAR go_custom.
      ENDIF.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
