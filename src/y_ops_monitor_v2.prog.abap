*&---------------------------------------------------------------------*
*& Report  Y_OPS_MONITOR_V2
*&---------------------------------------------------------------------*
*& 통합 운영 모니터링 (SM37 / ST22 / SXI_MONITOR) - 로컬 우선(V2) 구현
*&
*& 설계서: docs/design/integrated-ops-monitor-design.md (v0.6)
*&
*& [로컬 우선 원칙]
*&  - 새 저장소 오브젝트(DDIC/글로벌 클래스/인터페이스/메시지 클래스)를
*&    생성하지 않고, 단일 실행형 리포트 내부의 로컬 타입/클래스로만 구성한다.
*&  - 정상 작동 검증 후 글로벌 오브젝트로 분리(리팩터링)한다.
*&
*& [읽기 전용 원칙 - 필수]
*&  - INSERT/UPDATE/MODIFY/DELETE, COMMIT WORK, ENQUEUE/DEQUEUE,
*&    IN UPDATE TASK, 상태 변경 BAPI/FM 전면 금지.
*&  - 드릴다운은 표시(Display) 모드 표준 화면/FM만 호출한다.
*&
*& [데모 하이라이트]
*&  - 신호등 KPI 배너 / 조회소요시간 / 자동갱신 / 관점토글 차트
*&  - ALV 핫스팟·툴바 / STATS·HELP 커맨드 / 선택영역 동적 분할
*&
*& [화면] Dynpro 0100 + GUI Status 'S0100'
*&        (REFRESH/TOGGLE/STATS/HELP/BACK) 은 SE51/SE41 로 생성.
*&        생성 방법: docs/build/y_ops_monitor_v2-build-guide.md 참조.
*&---------------------------------------------------------------------*
REPORT y_ops_monitor_v2.

TYPE-POOLS: icon.

*&---------------------------------------------------------------------*
*&  선택 화면 필드용 전역 참조 변수
*&---------------------------------------------------------------------*
DATA: gv_jobname    TYPE tbtco-jobname,
      gv_uname      TYPE tbtco-sdluname,
      gv_iface      TYPE sxmspemas-ob_name,
      gv_hours_last TYPE i.              " P_HOURS 변경 감지용

*&---------------------------------------------------------------------*
*&  선택 화면 (Selection Screen)
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b0 WITH FRAME TITLE TEXT-b00.  " 프로그램 소개
SELECTION-SCREEN COMMENT /1(72) txt_bnr.   " 코멘트명 최대 8자, INITIALIZATION 에서 설정
SELECTION-SCREEN END OF BLOCK b0.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-b01.  " 조회 기간
PARAMETERS: p_frdat TYPE d,
            p_frtim TYPE t,
            p_todat TYPE d,
            p_totim TYPE t,
            p_hours TYPE i DEFAULT 24.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-b02.  " 조회 영역 선택
PARAMETERS: cb_sm37 AS CHECKBOX DEFAULT 'X',
            cb_st22 AS CHECKBOX DEFAULT 'X',
            cb_sxi  AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-b03.  " 추가 필터(옵션)
SELECT-OPTIONS: so_job   FOR gv_jobname,
                so_user  FOR gv_uname,
                so_iface FOR gv_iface.
PARAMETERS:     p_mand   TYPE mandt DEFAULT sy-mandt.
SELECTION-SCREEN END OF BLOCK b3.

SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-b04.  " 표시 옵션
PARAMETERS: p_maxrow TYPE i DEFAULT 250,
            p_topn   TYPE i DEFAULT 5,
            p_autorf TYPE i DEFAULT 0.    " 자동 새로고침 주기(초), 0=사용 안 함
SELECTION-SCREEN END OF BLOCK b4.

*&---------------------------------------------------------------------*
*&  공통 타입 정의
*&---------------------------------------------------------------------*
TYPES: ty_r_job   TYPE RANGE OF tbtco-jobname,
       ty_r_user  TYPE RANGE OF tbtco-sdluname,
       ty_r_iface TYPE RANGE OF sxmspemas-ob_name.

TYPES: BEGIN OF ty_sel,
         from_date TYPE d,
         from_time TYPE t,
         to_date   TYPE d,
         to_time   TYPE t,
         job_rng   TYPE ty_r_job,
         user_rng  TYPE ty_r_user,
         iface_rng TYPE ty_r_iface,
         mandt     TYPE mandt,
         topn      TYPE i,
         maxrow    TYPE i,
         autorf    TYPE i,
       END OF ty_sel.

" 영역별 출력 구조 (DDIC ZMON_S_* 대체) ---------------------------------
TYPES: BEGIN OF ty_batch,           " SM37 (ZMON_S_BATCH 대체)
         line_color TYPE c LENGTH 4,     " ALV 행 색상(영역 고정색)
         icon      TYPE icon_d,
         jobname   TYPE tbtco-jobname,
         jobcount  TYPE tbtco-jobcount,
         status    TYPE tbtco-status,
         status_tx TYPE c LENGTH 40,    " ALV 는 STRING 미지원 -> CHAR
         progname  TYPE tbtcp-progname,
         sdluname  TYPE tbtco-sdluname,
         strtdate  TYPE tbtco-strtdate,
         strttime  TYPE tbtco-strttime,
         enddate   TYPE tbtco-enddate,
         endtime   TYPE tbtco-endtime,
       END OF ty_batch,
       ty_batch_tab TYPE STANDARD TABLE OF ty_batch WITH DEFAULT KEY.

TYPES: BEGIN OF ty_dump,            " ST22 (ZMON_S_DUMP 대체, <- RSDUMPTAB)
         line_color TYPE c LENGTH 4,     " ALV 행 색상(영역 고정색)
         icon     TYPE icon_d,
         datum    TYPE d,
         uzeit    TYPE t,
         uname    TYPE syuname,
         ahost    TYPE snap_beg-ahost,
         rt_error TYPE c LENGTH 36,  " DUMPID (런타임 에러 유형)
         progname TYPE c LENGTH 40,
         include  TYPE c LENGTH 40,
         line     TYPE i,
       END OF ty_dump,
       ty_dump_tab TYPE STANDARD TABLE OF ty_dump WITH DEFAULT KEY.

TYPES: BEGIN OF ty_iface,           " SXI (ZMON_S_IFACE 대체)
         line_color TYPE c LENGTH 4,     " ALV 행 색상(영역 고정색)
         icon      TYPE icon_d,
         exe_date  TYPE d,
         exe_time  TYPE t,
         if_name   TYPE sxmspemas-ob_name,     " OB_NAME
         operation TYPE sxmspemas-ob_operation,
         sender    TYPE sxmspemas-ob_system,
         receiver  TYPE sxmspemas-ib_system,
         msgstate  TYPE sxmspmast-msgstate,
         errstat   TYPE sxmsperror-errstat,
         msgguid   TYPE sxmspmast-msgguid,
         pid       TYPE sxmsperror-pid,        " 드릴다운(파이프라인 ID)
       END OF ty_iface,
       ty_iface_tab TYPE STANDARD TABLE OF ty_iface WITH DEFAULT KEY.

" 요약 / 차트 집계용 -----------------------------------------------------
TYPES: BEGIN OF ty_summary,
         area     TYPE c LENGTH 10,
         area_txt TYPE c LENGTH 40,
         count    TYPE i,
         icon     TYPE icon_d,
         level    TYPE i,           " 1=녹색 2=황색 3=적색
       END OF ty_summary,
       ty_summary_tab TYPE STANDARD TABLE OF ty_summary WITH DEFAULT KEY.

TYPES: ty_str_tab TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

TYPES: BEGIN OF ty_key_count,
         key   TYPE string,
         count TYPE i,
       END OF ty_key_count,
       ty_key_count_tab TYPE STANDARD TABLE OF ty_key_count WITH DEFAULT KEY.

TYPES: BEGIN OF ty_time_pt,
         d TYPE d,
         t TYPE t,
       END OF ty_time_pt,
       ty_time_tab TYPE STANDARD TABLE OF ty_time_pt WITH DEFAULT KEY.

TYPES: BEGIN OF ty_chart_topn,
         area  TYPE c LENGTH 10,
         key   TYPE c LENGTH 120,
         count TYPE i,
       END OF ty_chart_topn,
       ty_chart_topn_tab TYPE STANDARD TABLE OF ty_chart_topn WITH DEFAULT KEY.

TYPES: BEGIN OF ty_chart_time,
         bucket TYPE c LENGTH 40,
         sm37   TYPE i,
         st22   TYPE i,
         sxi    TYPE i,
         total  TYPE i,
       END OF ty_chart_time,
       ty_chart_time_tab TYPE STANDARD TABLE OF ty_chart_time WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*&  데이터 프로바이더 공통 계약 (ZIF_MON_DATA_PROVIDER 대체)
*&---------------------------------------------------------------------*
INTERFACE lif_data_provider.
  METHODS:
    area_id       RETURNING VALUE(rv_id)  TYPE string,
    area_text     RETURNING VALUE(rv_txt) TYPE string,
    is_selected   RETURNING VALUE(rv)     TYPE abap_bool,
    has_authority RETURNING VALUE(rv)     TYPE abap_bool,
    fetch         IMPORTING is_sel        TYPE ty_sel,
    count         RETURNING VALUE(rv)     TYPE i,
    is_skipped    RETURNING VALUE(rv)     TYPE abap_bool,
    summary       RETURNING VALUE(rs)     TYPE ty_summary,
    alv_data      RETURNING VALUE(rr)     TYPE REF TO data,
    fieldcat      RETURNING VALUE(rt)     TYPE lvc_t_fcat,
    topn_source   RETURNING VALUE(rt)     TYPE ty_str_tab,
    time_points   RETURNING VALUE(rt)     TYPE ty_time_tab,
    navigate      IMPORTING iv_row        TYPE i.
ENDINTERFACE.

TYPES ty_provider_tab TYPE STANDARD TABLE OF REF TO lif_data_provider WITH DEFAULT KEY.

*&---------------------------------------------------------------------*
*&  유틸리티 (필드카탈로그 / 타임존 변환)
*&---------------------------------------------------------------------*
CLASS lcl_util DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS add_col
      IMPORTING iv_field   TYPE lvc_fname
                iv_text    TYPE string
                iv_icon    TYPE abap_bool DEFAULT abap_false
                iv_hide    TYPE abap_bool DEFAULT abap_false
                iv_hotspot TYPE abap_bool DEFAULT abap_false
      CHANGING  ct_fcat    TYPE lvc_t_fcat.
    CLASS-METHODS local_to_utc
      IMPORTING iv_date      TYPE d
                iv_time      TYPE t
      RETURNING VALUE(rv_ts) TYPE timestampl.
    CLASS-METHODS utc_to_local
      IMPORTING iv_ts   TYPE timestampl
      EXPORTING ev_date TYPE d
                ev_time TYPE t.
    " ALV 툴바: 검색/정렬/필터만 남기고 나머지 제외 목록
    CLASS-METHODS alv_toolbar_exclude
      RETURNING VALUE(rt) TYPE ui_functions.
ENDCLASS.

CLASS lcl_util IMPLEMENTATION.
  METHOD add_col.
    DATA ls TYPE lvc_s_fcat.
    ls-fieldname = iv_field.
    ls-coltext   = iv_text.
    ls-scrtext_l = iv_text.
    ls-scrtext_m = iv_text.
    ls-scrtext_s = iv_text.
    ls-icon      = iv_icon.
    ls-no_out    = iv_hide.
    ls-hotspot   = iv_hotspot.
    APPEND ls TO ct_fcat.
  ENDMETHOD.

  METHOD local_to_utc.
    " 로컬 일자/시간 -> UTC 긴 형식 타임스탬프 (사용자 타임존 기준)
    CONVERT DATE iv_date TIME iv_time
            INTO TIME STAMP rv_ts TIME ZONE sy-zonlo.
  ENDMETHOD.

  METHOD utc_to_local.
    CONVERT TIME STAMP iv_ts TIME ZONE sy-zonlo
            INTO DATE ev_date TIME ev_time.
  ENDMETHOD.

  METHOD alv_toolbar_exclude.
    " 유지: FIND / FIND_MORE / SORT_ASC / SORT_DSC / FILTER / DELETE_FILTER
    " 그 외(합계·인쇄·엑셀·내보내기·레이아웃·정보·편집 등) 제거
    APPEND cl_gui_alv_grid=>mc_fc_sum              TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_subtot           TO rt.
    APPEND cl_gui_alv_grid=>mc_mb_sum             TO rt.
    APPEND cl_gui_alv_grid=>mc_mb_subtot          TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_print           TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_print_back      TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_print_prev      TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_views           TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_view_crystal    TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_view_excel      TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_view_grid       TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_view_lotus      TO rt.
    APPEND cl_gui_alv_grid=>mc_mb_view            TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_export          TO rt.
    APPEND cl_gui_alv_grid=>mc_mb_export          TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_graph           TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_info            TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_detail          TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_help            TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_html            TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_word_processor  TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_send            TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_to_office       TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_call_abc        TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_call_xxl        TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_call_crystal    TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_expcrdesig      TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_expcrtempl      TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_fix_layout      TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_maximum         TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_minimum         TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_average         TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_count           TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_auf             TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_check           TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_refresh         TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_loc_copy        TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_loc_copy_row    TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_loc_cut         TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_loc_delete_row  TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_loc_insert_row  TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_loc_move_row    TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_loc_append_row  TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_loc_paste       TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_loc_paste_new_row TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_loc_undo        TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_select_all      TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_deselect_all    TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_data_save       TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_load_variant    TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_current_variant TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_save_variant    TO rt.
    APPEND cl_gui_alv_grid=>mc_fc_maintain_variant TO rt.
    APPEND cl_gui_alv_grid=>mc_mb_variant         TO rt.
  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*&  집계기 (ZCL_MON_AGGREGATOR 대체) - 차트 데이터 파생
*&---------------------------------------------------------------------*
CLASS lcl_aggregator DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS build_topn
      IMPORTING it_keys      TYPE ty_str_tab
                iv_topn      TYPE i
      RETURNING VALUE(rt)    TYPE ty_key_count_tab.
    CLASS-METHODS bucket_size_hours
      IMPORTING iv_from_date TYPE d
                iv_from_time TYPE t
                iv_to_date   TYPE d
                iv_to_time   TYPE t
      RETURNING VALUE(rv)    TYPE i.
    CLASS-METHODS bucket_label
      IMPORTING iv_d          TYPE d
                iv_t          TYPE t
                iv_size_hours TYPE i
      RETURNING VALUE(rv)     TYPE string.
ENDCLASS.

CLASS lcl_aggregator IMPLEMENTATION.
  METHOD build_topn.
    DATA lt TYPE ty_key_count_tab.
    LOOP AT it_keys INTO DATA(lv_key).
      READ TABLE lt ASSIGNING FIELD-SYMBOL(<c>) WITH KEY key = lv_key.
      IF sy-subrc = 0.
        <c>-count = <c>-count + 1.
      ELSE.
        APPEND VALUE #( key = lv_key count = 1 ) TO lt.
      ENDIF.
    ENDLOOP.
    SORT lt BY count DESCENDING key ASCENDING.
    " Top-N 은 1~5 로 제한(초과/미입력 시 5)
    DATA(lv_n) = COND i( WHEN iv_topn BETWEEN 1 AND 5 THEN iv_topn ELSE 5 ).
    LOOP AT lt INTO DATA(ls).
      IF sy-tabix > lv_n.
        EXIT.
      ENDIF.
      APPEND ls TO rt.
    ENDLOOP.
  ENDMETHOD.

  METHOD bucket_size_hours.
    DATA(lv_from) = lcl_util=>local_to_utc( iv_date = iv_from_date iv_time = iv_from_time ).
    DATA(lv_to)   = lcl_util=>local_to_utc( iv_date = iv_to_date   iv_time = iv_to_time ).
    DATA(lv_secs) = cl_abap_tstmp=>subtract( tstmp1 = lv_to tstmp2 = lv_from ).
    DATA(lv_hours) = lv_secs / 3600.
    IF    lv_hours <= 24.  rv = 1.       " 1시간
    ELSEIF lv_hours <= 168. rv = 24.     " 1일
    ELSE.                   rv = 168.    " 1주
    ENDIF.
  ENDMETHOD.

  METHOD bucket_label.
    IF iv_size_hours <= 1.
      rv = |{ iv_d DATE = USER } { iv_t(2) }:00|.
    ELSEIF iv_size_hours <= 24.
      rv = |{ iv_d DATE = USER }|.
    ELSE.
      rv = |{ iv_d DATE = USER } (주)|.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*&  네비게이터 (ZCL_MON_NAVIGATOR 대체) - 드릴다운(표시 전용)
*&---------------------------------------------------------------------*
CLASS lcl_navigator DEFINITION.
  PUBLIC SECTION.
    METHODS show_joblog
      IMPORTING iv_jobname   TYPE tbtco-jobname
                iv_jobcount  TYPE tbtco-jobcount.
    METHODS show_dump
      IMPORTING iv_datum TYPE d
                iv_uzeit TYPE t
                iv_uname TYPE syuname
                iv_ahost TYPE snap_beg-ahost.
    METHODS show_message
      IMPORTING iv_msgguid TYPE sxmspmast-msgguid
                iv_pid     TYPE sxmsperror-pid.
ENDCLASS.

CLASS lcl_navigator IMPLEMENTATION.
  METHOD show_joblog.
    " 표시 전용 - 잡 로그 조회 (읽기 전용, 잡키로 정밀 이동)
    CALL FUNCTION 'BP_JOBLOG_SHOW'
      EXPORTING
        jobcount             = iv_jobcount
        jobname              = iv_jobname
      EXCEPTIONS
        error_reading_joblog = 1
        job_does_not_exist   = 2
        no_joblog_there      = 3
        OTHERS               = 4.
    IF sy-subrc <> 0.
      MESSAGE 'Job log를 표시할 수 없습니다.' TYPE 'S' DISPLAY LIKE 'W'. "#EC NOTEXT
      "TODO: 메시지 클래스(ZOPSMON) 전환
    ENDIF.
  ENDMETHOD.

  METHOD show_dump.
    " 표시 전용 - ST22 상세 (RS_SNAP_DUMP_DISPLAY).
    " SNAP 은 SEQNO 단위로 여러 행이므로 헤더 뷰 SNAP_BEG + SEQNO='000' 만 사용.
    " (TYPE snap / SEQNO 없는 SELECT SINGLE 은 키 불일치·런타임 덤프 유발 가능)
    DATA: BEGIN OF ls_key,
            ahost TYPE snap_beg-ahost,
            datum TYPE snap_beg-datum,
            mandt TYPE snap_beg-mandt,
            modno TYPE snap_beg-modno,
            seqno TYPE snap_beg-seqno,
            uname TYPE snap_beg-uname,
            uzeit TYPE snap_beg-uzeit,
          END OF ls_key.
    DATA lv_ahost TYPE snap_beg-ahost.
    DATA lv_found TYPE abap_bool.

    lv_ahost = iv_ahost.
    CONDENSE lv_ahost.

    " 1) 일자/시간/사용자/서버 + SEQNO=000
    IF lv_ahost IS NOT INITIAL.
      SELECT SINGLE ahost, datum, mandt, modno, seqno, uname, uzeit
        FROM snap_beg
        INTO @ls_key
        WHERE datum = @iv_datum
          AND uzeit = @iv_uzeit
          AND uname = @iv_uname
          AND ahost = @lv_ahost
          AND seqno = '000'.
      IF sy-subrc = 0.
        lv_found = abap_true.
      ENDIF.
    ENDIF.

    " 2) 서버명 불일치 시 일자/시간/사용자로 재조회
    IF lv_found = abap_false.
      SELECT SINGLE ahost, datum, mandt, modno, seqno, uname, uzeit
        FROM snap_beg
        INTO @ls_key
        WHERE datum = @iv_datum
          AND uzeit = @iv_uzeit
          AND uname = @iv_uname
          AND seqno = '000'.
      IF sy-subrc = 0.
        lv_found = abap_true.
      ENDIF.
    ENDIF.

    IF lv_found = abap_true.
      CALL FUNCTION 'RS_SNAP_DUMP_DISPLAY'
        EXPORTING
          ahost          = ls_key-ahost
          datum          = ls_key-datum
          mandt          = ls_key-mandt
          modno          = ls_key-modno
          seqno          = ls_key-seqno
          uname          = ls_key-uname
          uzeit          = ls_key-uzeit
        EXCEPTIONS
          no_entry_found = 1
          OTHERS         = 2.
      IF sy-subrc = 0.
        RETURN.
      ENDIF.
    ENDIF.

    " 폴백: 상세 조회 불가 시 표준 ST22 진입
    MESSAGE '해당 덤프 상세를 열 수 없어 ST22로 이동합니다.' TYPE 'S' DISPLAY LIKE 'W'. "#EC NOTEXT
    CALL TRANSACTION 'ST22'.                              "#EC CI_CALLTA
  ENDMETHOD.

  METHOD show_message.
    " 표시 전용 - 선택한 XML 메시지의 상세 모니터를 직접 표시 (MSGGUID + PID).
    CALL FUNCTION 'SXMB_DISPLAY_MESSAGE_MONITOR'
      EXPORTING
        im_message_id     = iv_msgguid
        im_pipeline_id    = iv_pid
      EXCEPTIONS
        message_not_found = 1
        not_authorized    = 2
        OTHERS            = 3.
    IF sy-subrc <> 0.
      " 폴백: 상세 조회 불가 시 표준 SXI_MONITOR 진입
      MESSAGE '해당 메시지 상세를 열 수 없어 SXI_MONITOR로 이동합니다.' TYPE 'S' DISPLAY LIKE 'W'. "#EC NOTEXT
      CALL TRANSACTION 'SXI_MONITOR'.                     "#EC CI_CALLTA
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*&  SM37 배치 에러 프로바이더 (ZCL_MON_DP_BATCH 대체)
*&---------------------------------------------------------------------*
CLASS lcl_dp_batch DEFINITION.
  PUBLIC SECTION.
    INTERFACES lif_data_provider.
    METHODS constructor IMPORTING io_nav TYPE REF TO lcl_navigator.
  PRIVATE SECTION.
    CONSTANTS: c_status_aborted TYPE tbtco-status VALUE 'A',
               c_red            TYPE i VALUE 1.       " SM37: 1건이상 적색
    DATA: mo_nav     TYPE REF TO lcl_navigator,
          mt_all     TYPE ty_batch_tab,   " 전체(차트용)
          mt_view    TYPE ty_batch_tab,   " 표시용(maxrow 제한)
          mv_skipped TYPE abap_bool.
ENDCLASS.

CLASS lcl_dp_batch IMPLEMENTATION.
  METHOD constructor.
    mo_nav = io_nav.
  ENDMETHOD.

  METHOD lif_data_provider~area_id.
    rv_id = 'SM37'.
  ENDMETHOD.

  METHOD lif_data_provider~area_text.
    rv_txt = '배치 잡 에러(SM37)'.                          "#EC NOTEXT
  ENDMETHOD.

  METHOD lif_data_provider~is_selected.
    rv = cb_sm37.
  ENDMETHOD.

  METHOD lif_data_provider~has_authority.
    AUTHORITY-CHECK OBJECT 'S_BTCH_JOB'
      ID 'JOBGROUP'  FIELD '*'
      ID 'JOBACTION' FIELD 'SHOW'.
    rv = boolc( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD lif_data_provider~fetch.
    CLEAR: mt_all, mt_view, mv_skipped.

    IF lif_data_provider~has_authority( ) = abap_false.
      mv_skipped = abap_true.
      RETURN.
    ENDIF.

    " 종료시각(ENDDATE/ENDTIME) 기준, 자정 경계 복합 조건
    SELECT jobname, jobcount, status, strtdate, strttime,
           enddate, endtime, sdluname
      FROM tbtco
      WHERE status   = @c_status_aborted
        AND jobname  IN @is_sel-job_rng
        AND sdluname IN @is_sel-user_rng
        AND ( enddate > @is_sel-from_date
           OR ( enddate = @is_sel-from_date AND endtime >= @is_sel-from_time ) )
        AND ( enddate < @is_sel-to_date
           OR ( enddate = @is_sel-to_date AND endtime <= @is_sel-to_time ) )
      INTO TABLE @DATA(lt_job).

    IF lt_job IS NOT INITIAL.
      SELECT jobname, jobcount, stepcount, progname
        FROM tbtcp
        FOR ALL ENTRIES IN @lt_job
        WHERE jobname  = @lt_job-jobname
          AND jobcount = @lt_job-jobcount
        INTO TABLE @DATA(lt_step).
      SORT lt_step BY jobname jobcount stepcount.
    ENDIF.

    LOOP AT lt_job INTO DATA(ls_job).
      DATA(ls_out) = VALUE ty_batch(
        line_color = 'C400'                                 " SM37 영역색
        icon      = icon_red_light
        jobname   = ls_job-jobname
        jobcount  = ls_job-jobcount
        status    = ls_job-status
        status_tx = 'Cancelled (Aborted)'                   "#EC NOTEXT
        sdluname  = ls_job-sdluname
        strtdate  = ls_job-strtdate
        strttime  = ls_job-strttime
        enddate   = ls_job-enddate
        endtime   = ls_job-endtime ).
      READ TABLE lt_step INTO DATA(ls_step)
        WITH KEY jobname = ls_job-jobname jobcount = ls_job-jobcount
        BINARY SEARCH.
      IF sy-subrc = 0.
        ls_out-progname = ls_step-progname.
      ENDIF.
      APPEND ls_out TO mt_all.
    ENDLOOP.

    " 최신순 정렬 후 표시용 maxrow 제한 (차트는 mt_all 전체 사용)
    SORT mt_all BY enddate DESCENDING endtime DESCENDING.
    mt_view = mt_all.
    IF is_sel-maxrow > 0 AND lines( mt_view ) > is_sel-maxrow.
      DATA(lv_del) = is_sel-maxrow + 1.
      DELETE mt_view FROM lv_del.
    ENDIF.
  ENDMETHOD.

  METHOD lif_data_provider~count.
    rv = lines( mt_all ).
  ENDMETHOD.

  METHOD lif_data_provider~is_skipped.
    rv = mv_skipped.
  ENDMETHOD.

  METHOD lif_data_provider~summary.
    rs-area     = lif_data_provider~area_id( ).
    rs-area_txt = lif_data_provider~area_text( ).
    rs-count    = lif_data_provider~count( ).
    IF rs-count >= c_red.
      rs-level = 3. rs-icon = icon_red_light.
    ELSE.
      rs-level = 1. rs-icon = icon_green_light.
    ENDIF.
  ENDMETHOD.

  METHOD lif_data_provider~alv_data.
    GET REFERENCE OF mt_view INTO rr.
  ENDMETHOD.

  METHOD lif_data_provider~fieldcat.
    " 표시 열: 잡명(핫스팟), 프로그램, 사용자, 시작일, 시작시간, 종료일, 종료시간
    lcl_util=>add_col( EXPORTING iv_field = 'JOBNAME'  iv_text = '잡명'
                                 iv_hotspot = abap_true CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'PROGNAME' iv_text = '프로그램' CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'SDLUNAME' iv_text = '사용자'   CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'STRTDATE' iv_text = '시작일'   CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'STRTTIME' iv_text = '시작시간' CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'ENDDATE'  iv_text = '종료일'   CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'ENDTIME'  iv_text = '종료시간' CHANGING ct_fcat = rt ).
  ENDMETHOD.

  METHOD lif_data_provider~topn_source.
    " Top-N 키 = JOBNAME (전체 기준)
    LOOP AT mt_all INTO DATA(ls).
      APPEND |{ ls-jobname }| TO rt.
    ENDLOOP.
  ENDMETHOD.

  METHOD lif_data_provider~time_points.
    LOOP AT mt_all INTO DATA(ls).
      APPEND VALUE #( d = ls-enddate t = ls-endtime ) TO rt.
    ENDLOOP.
  ENDMETHOD.

  METHOD lif_data_provider~navigate.
    " SM37 전용 — show_dump/ls-datum 사용 금지 (ty_batch 에 DATUM 없음)
    DATA ls_job TYPE ty_batch.
    READ TABLE mt_view INTO ls_job INDEX iv_row.
    IF sy-subrc = 0.
      mo_nav->show_joblog( iv_jobname = ls_job-jobname
                           iv_jobcount = ls_job-jobcount ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*&  ST22 덤프 프로바이더 (ZCL_MON_DP_DUMP 대체)
*&---------------------------------------------------------------------*
CLASS lcl_dp_dump DEFINITION.
  PUBLIC SECTION.
    INTERFACES lif_data_provider.
    METHODS constructor IMPORTING io_nav TYPE REF TO lcl_navigator.
  PRIVATE SECTION.
    CONSTANTS: c_yellow TYPE i VALUE 1,     " ST22: 1~30 황색
               c_red    TYPE i VALUE 31.    " ST22: 31건이상 적색
    DATA: mo_nav     TYPE REF TO lcl_navigator,
          mt_all     TYPE ty_dump_tab,
          mt_view    TYPE ty_dump_tab,
          mv_skipped TYPE abap_bool.
ENDCLASS.

CLASS lcl_dp_dump IMPLEMENTATION.
  METHOD constructor.
    mo_nav = io_nav.
  ENDMETHOD.

  METHOD lif_data_provider~area_id.
    rv_id = 'ST22'.
  ENDMETHOD.

  METHOD lif_data_provider~area_text.
    rv_txt = '런타임 에러(ST22)'.                           "#EC NOTEXT
  ENDMETHOD.

  METHOD lif_data_provider~is_selected.
    rv = cb_st22.
  ENDMETHOD.

  METHOD lif_data_provider~has_authority.
    AUTHORITY-CHECK OBJECT 'S_ABAPDUMP'
      ID 'ACTVT'      FIELD '03'
      ID 'DUMP_INFO'  FIELD 'FULL'
      ID 'DUMP_CCLNT' FIELD 'ALL'
      ID 'DUMP_CUSER' FIELD 'ALL'.
    rv = boolc( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD lif_data_provider~fetch.
    CLEAR: mt_all, mt_view, mv_skipped.

    IF lif_data_provider~has_authority( ) = abap_false.
      mv_skipped = abap_true.
      RETURN.
    ENDIF.

    " import 파라미터가 덤프 날짜(단일)이므로 조회기간 내 날짜별 반복 호출 후
    " 반환 항목의 SYTIME 을 시간 범위로 ABAP 필터링한다.
    DATA lv_date TYPE d.
    lv_date = is_sel-from_date.
    WHILE lv_date <= is_sel-to_date.

      "TODO: SE37 에서 RS_ST22_GET_DUMPS 의 정확한 파라미터명을 확인 후 조정.
      "      (설계 근거: EXPORT P_INFOTAB TYPE RSDUMPTAB, import=덤프 날짜(단일))
      DATA lt_dumps TYPE rsdumptab.
      CLEAR lt_dumps.
      CALL FUNCTION 'RS_ST22_GET_DUMPS'
        EXPORTING
          p_day     = lv_date
        IMPORTING
          p_infotab = lt_dumps
        EXCEPTIONS
          OTHERS    = 1.

      IF sy-subrc = 0.
        LOOP AT lt_dumps INTO DATA(ls_d).
          " 시간 범위 필터 (자정 경계 대응)
          DATA(lv_ok) = abap_true.
          IF lv_date = is_sel-from_date AND ls_d-sytime < is_sel-from_time.
            lv_ok = abap_false.
          ENDIF.
          IF lv_date = is_sel-to_date   AND ls_d-sytime > is_sel-to_time.
            lv_ok = abap_false.
          ENDIF.
          " 사용자 필터(옵션) - SYUSER
          IF lv_ok = abap_true AND is_sel-user_rng IS NOT INITIAL.
            IF NOT ls_d-syuser IN is_sel-user_rng.
              lv_ok = abap_false.
            ENDIF.
          ENDIF.
          IF lv_ok = abap_true.
            APPEND VALUE ty_dump(
              line_color = 'C600'                            " ST22 영역색
              icon     = icon_red_light
              datum    = ls_d-sydate
              uzeit    = ls_d-sytime
              uname    = ls_d-syuser
              ahost    = ls_d-syhost
              rt_error = |{ ls_d-dumpid }|
              progname = |{ ls_d-programname }|
              include  = |{ ls_d-includename }|
              line     = ls_d-linenumber ) TO mt_all.
          ENDIF.
        ENDLOOP.
      ENDIF.

      lv_date = lv_date + 1.
    ENDWHILE.

    SORT mt_all BY datum DESCENDING uzeit DESCENDING.
    mt_view = mt_all.
    IF is_sel-maxrow > 0 AND lines( mt_view ) > is_sel-maxrow.
      DATA(lv_del) = is_sel-maxrow + 1.
      DELETE mt_view FROM lv_del.
    ENDIF.
  ENDMETHOD.

  METHOD lif_data_provider~count.
    rv = lines( mt_all ).
  ENDMETHOD.

  METHOD lif_data_provider~is_skipped.
    rv = mv_skipped.
  ENDMETHOD.

  METHOD lif_data_provider~summary.
    rs-area     = lif_data_provider~area_id( ).
    rs-area_txt = lif_data_provider~area_text( ).
    rs-count    = lif_data_provider~count( ).
    IF     rs-count >= c_red.
      rs-level = 3. rs-icon = icon_red_light.
    ELSEIF rs-count >= c_yellow.
      rs-level = 2. rs-icon = icon_yellow_light.
    ELSE.
      rs-level = 1. rs-icon = icon_green_light.
    ENDIF.
  ENDMETHOD.

  METHOD lif_data_provider~alv_data.
    GET REFERENCE OF mt_view INTO rr.
  ENDMETHOD.

  METHOD lif_data_provider~fieldcat.
    " 표시 열: 프로그램(핫스팟), 에러유형, 사용자, 발생일, 발생시간
    lcl_util=>add_col( EXPORTING iv_field = 'PROGNAME' iv_text = '프로그램'
                                 iv_hotspot = abap_true CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'RT_ERROR' iv_text = '에러유형' CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'UNAME'    iv_text = '사용자'   CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'DATUM'    iv_text = '발생일'   CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'UZEIT'    iv_text = '발생시간' CHANGING ct_fcat = rt ).
  ENDMETHOD.

  METHOD lif_data_provider~topn_source.
    " Top-N 키 = DUMPID (런타임 에러 유형)
    LOOP AT mt_all INTO DATA(ls_dump).
      APPEND ls_dump-rt_error TO rt.
    ENDLOOP.
  ENDMETHOD.

  METHOD lif_data_provider~time_points.
    LOOP AT mt_all INTO DATA(ls_dump).
      APPEND VALUE #( d = ls_dump-datum t = ls_dump-uzeit ) TO rt.
    ENDLOOP.
  ENDMETHOD.

  METHOD lif_data_provider~navigate.
    " ls / RSDUMP 구조체와 혼동 방지: ty_dump 명시 (DATUM/UZEIT/UNAME/AHOST)
    DATA ls_dump TYPE ty_dump.
    READ TABLE mt_view INTO ls_dump INDEX iv_row.
    IF sy-subrc = 0.
      mo_nav->show_dump( iv_datum = ls_dump-datum
                         iv_uzeit = ls_dump-uzeit
                         iv_uname = ls_dump-uname
                         iv_ahost = ls_dump-ahost ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*&  SXI 인터페이스 에러 프로바이더 (ZCL_MON_DP_INTERFACE 대체)
*&---------------------------------------------------------------------*
CLASS lcl_dp_interface DEFINITION.
  PUBLIC SECTION.
    INTERFACES lif_data_provider.
    METHODS constructor IMPORTING io_nav TYPE REF TO lcl_navigator.
  PRIVATE SECTION.
    CONSTANTS: c_yellow TYPE i VALUE 1,     " SXI: 1~50 황색
               c_red    TYPE i VALUE 51.    " SXI: 51건이상 적색
    DATA: mo_nav     TYPE REF TO lcl_navigator,
          mt_all     TYPE ty_iface_tab,
          mt_view    TYPE ty_iface_tab,
          mv_skipped TYPE abap_bool.
ENDCLASS.

CLASS lcl_dp_interface IMPLEMENTATION.
  METHOD constructor.
    mo_nav = io_nav.
  ENDMETHOD.

  METHOD lif_data_provider~area_id.
    rv_id = 'SXI'.
  ENDMETHOD.

  METHOD lif_data_provider~area_text.
    rv_txt = '인터페이스 에러(SXI)'.                        "#EC NOTEXT
  ENDMETHOD.

  METHOD lif_data_provider~is_selected.
    rv = cb_sxi.
  ENDMETHOD.

  METHOD lif_data_provider~has_authority.
    AUTHORITY-CHECK OBJECT 'S_XMB_MONI'
      ID 'ACTVT'      FIELD '03'
      ID 'SXMBPARTY'  DUMMY
      ID 'SXMBPRTAG'  DUMMY
      ID 'SXMBPRTTYP' DUMMY
      ID 'SXMBSERV'   DUMMY
      ID 'SXMBIFNS'   DUMMY
      ID 'SXMBIFNAME' DUMMY.
    rv = boolc( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD lif_data_provider~fetch.
    CLEAR: mt_all, mt_view, mv_skipped.

    IF lif_data_provider~has_authority( ) = abap_false.
      mv_skipped = abap_true.
      RETURN.
    ENDIF.

    " 기간(EXETIMEST, UTC) : 로컬 FROM/TO -> UTC 긴 형식 타임스탬프 변환
    "TODO: SXMSPERROR-EXETIMEST 의 실제 타입/정밀도를 시스템에서 확인 후 조정.
    DATA: lv_from TYPE sxmsperror-exetimest,
          lv_to   TYPE sxmsperror-exetimest.
    lv_from = lcl_util=>local_to_utc( iv_date = is_sel-from_date iv_time = is_sel-from_time ).
    lv_to   = lcl_util=>local_to_utc( iv_date = is_sel-to_date   iv_time = is_sel-to_time ).

    " 1) 에러 레코드(SXMSPERROR)를 기간으로 먼저 조회 (방식 A)
    SELECT msgguid, pid, errstat, exetimest
      FROM sxmsperror
      WHERE exetimest BETWEEN @lv_from AND @lv_to
      INTO TABLE @DATA(lt_err).

    IF lt_err IS INITIAL.
      RETURN.
    ENDIF.

    " 2) 마스터/확장 마스터 조인 (MSGGUID + PID)
    SELECT msgguid, pid, msgstate
      FROM sxmspmast
      FOR ALL ENTRIES IN @lt_err
      WHERE msgguid = @lt_err-msgguid
        AND pid     = @lt_err-pid
      INTO TABLE @DATA(lt_mast).
    SORT lt_mast BY msgguid pid.

    SELECT msgguid, pid, ob_name, ob_ns, ob_operation, ob_system, ib_system
      FROM sxmspemas
      FOR ALL ENTRIES IN @lt_err
      WHERE msgguid = @lt_err-msgguid
        AND pid     = @lt_err-pid
      INTO TABLE @DATA(lt_emas).
    SORT lt_emas BY msgguid pid.

    LOOP AT lt_err INTO DATA(ls_err).
      DATA(ls_out) = VALUE ty_iface(
        line_color = 'C700'                                 " SXI 영역색
        icon    = icon_red_light
        errstat = ls_err-errstat
        msgguid = ls_err-msgguid
        pid     = ls_err-pid ).

      lcl_util=>utc_to_local(
        EXPORTING iv_ts   = CONV timestampl( ls_err-exetimest )
        IMPORTING ev_date = ls_out-exe_date
                  ev_time = ls_out-exe_time ).

      READ TABLE lt_emas INTO DATA(ls_em)
        WITH KEY msgguid = ls_err-msgguid pid = ls_err-pid BINARY SEARCH.
      IF sy-subrc = 0.
        ls_out-if_name   = ls_em-ob_name.
        ls_out-operation = ls_em-ob_operation.
        ls_out-sender    = ls_em-ob_system.
        ls_out-receiver  = ls_em-ib_system.
      ENDIF.

      READ TABLE lt_mast INTO DATA(ls_ma)
        WITH KEY msgguid = ls_err-msgguid pid = ls_err-pid BINARY SEARCH.
      IF sy-subrc = 0.
        ls_out-msgstate = ls_ma-msgstate.
      ENDIF.

      " 인터페이스명 필터(옵션) - OB_NAME (원본값 기준으로 필터)
      IF is_sel-iface_rng IS NOT INITIAL AND NOT ls_out-if_name IN is_sel-iface_rng.
        CONTINUE.
      ENDIF.

      " 인터페이스명이 비면(초기단계 실패/시스템 메시지 등) 하나의 덩어리로 뭉치지 않도록
      " 의미 있는 대체 키로 분해한다. (삭제하지 않음: 실제 에러, 누락 방지)
      "  1순위: 송신→수신 시스템, 2순위: 에러상태(ERRSTAT, 에러 분류), 최후: (미상)
      " 상세는 더블클릭(SXI_MONITOR)로 확인.
      IF ls_out-if_name IS INITIAL.
        ls_out-if_name = COND #(
          WHEN ls_out-sender IS NOT INITIAL OR ls_out-receiver IS NOT INITIAL
            THEN |{ ls_out-sender }->{ ls_out-receiver }|
          WHEN ls_out-errstat IS NOT INITIAL
            THEN |상태:{ ls_out-errstat }|
          ELSE '(미상)' ).                                  "#EC NOTEXT
      ENDIF.

      APPEND ls_out TO mt_all.
    ENDLOOP.

    SORT mt_all BY exe_date DESCENDING exe_time DESCENDING.
    mt_view = mt_all.
    IF is_sel-maxrow > 0 AND lines( mt_view ) > is_sel-maxrow.
      DATA(lv_del) = is_sel-maxrow + 1.
      DELETE mt_view FROM lv_del.
    ENDIF.
  ENDMETHOD.

  METHOD lif_data_provider~count.
    rv = lines( mt_all ).
  ENDMETHOD.

  METHOD lif_data_provider~is_skipped.
    rv = mv_skipped.
  ENDMETHOD.

  METHOD lif_data_provider~summary.
    rs-area     = lif_data_provider~area_id( ).
    rs-area_txt = lif_data_provider~area_text( ).
    rs-count    = lif_data_provider~count( ).
    IF     rs-count >= c_red.
      rs-level = 3. rs-icon = icon_red_light.
    ELSEIF rs-count >= c_yellow.
      rs-level = 2. rs-icon = icon_yellow_light.
    ELSE.
      rs-level = 1. rs-icon = icon_green_light.
    ENDIF.
  ENDMETHOD.

  METHOD lif_data_provider~alv_data.
    GET REFERENCE OF mt_view INTO rr.
  ENDMETHOD.

  METHOD lif_data_provider~fieldcat.
    " 표시 열: 인터페이스(핫스팟), 상태, 발생일, 발생시간
    " MSGGUID/PID 는 드릴다운 키로만 내부 보관 (ALV 미표시)
    lcl_util=>add_col( EXPORTING iv_field = 'IF_NAME'  iv_text = '인터페이스'
                                 iv_hotspot = abap_true CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'MSGSTATE' iv_text = '상태'       CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'EXE_DATE' iv_text = '발생일'     CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'EXE_TIME' iv_text = '발생시간'   CHANGING ct_fcat = rt ).
  ENDMETHOD.

  METHOD lif_data_provider~topn_source.
    " Top-N 키 = OB_NAME (송신 인터페이스명)
    LOOP AT mt_all INTO DATA(ls).
      APPEND |{ ls-if_name }| TO rt.
    ENDLOOP.
  ENDMETHOD.

  METHOD lif_data_provider~time_points.
    LOOP AT mt_all INTO DATA(ls).
      APPEND VALUE #( d = ls-exe_date t = ls-exe_time ) TO rt.
    ENDLOOP.
  ENDMETHOD.

  METHOD lif_data_provider~navigate.
    READ TABLE mt_view INTO DATA(ls) INDEX iv_row.
    IF sy-subrc = 0.
      mo_nav->show_message( iv_msgguid = ls-msgguid
                            iv_pid     = ls-pid ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*&  컨트롤러 (ZCL_MON_CONTROLLER 대체) - 프로바이더 레지스트리/오케스트레이션
*&---------------------------------------------------------------------*
CLASS lcl_controller DEFINITION.
  PUBLIC SECTION.
    METHODS constructor.
    METHODS run IMPORTING is_sel TYPE ty_sel.
    METHODS providers RETURNING VALUE(rt) TYPE ty_provider_tab.
    METHODS elapsed_sec RETURNING VALUE(rv) TYPE i.
    METHODS selected_count RETURNING VALUE(rv) TYPE i.
  PRIVATE SECTION.
    DATA: mo_nav        TYPE REF TO lcl_navigator,
          mt_provider   TYPE ty_provider_tab,
          mv_elapsed_sec TYPE i.
ENDCLASS.

CLASS lcl_controller IMPLEMENTATION.
  METHOD constructor.
    CREATE OBJECT mo_nav.
    " 프로바이더 레지스트리 (신규 영역 추가 시 여기에 등록만 하면 됨)
    APPEND NEW lcl_dp_batch( io_nav = mo_nav )     TO mt_provider.
    APPEND NEW lcl_dp_dump( io_nav = mo_nav )      TO mt_provider.
    APPEND NEW lcl_dp_interface( io_nav = mo_nav ) TO mt_provider.
  ENDMETHOD.

  METHOD run.
    DATA: lv_t0 TYPE timestampl,
          lv_t1 TYPE timestampl.
    GET TIME STAMP FIELD lv_t0.

    LOOP AT mt_provider INTO DATA(lo_prov).
      IF lo_prov->is_selected( ) = abap_false.
        CONTINUE.
      ENDIF.
      TRY.
          lo_prov->fetch( is_sel ).
        CATCH cx_root INTO DATA(lx).
          DATA(lv_txt) = lx->get_text( ).
          MESSAGE lv_txt TYPE 'S' DISPLAY LIKE 'W'.
      ENDTRY.
    ENDLOOP.

    GET TIME STAMP FIELD lv_t1.
    mv_elapsed_sec = CONV i( cl_abap_tstmp=>subtract( tstmp1 = lv_t1 tstmp2 = lv_t0 ) ).
    IF mv_elapsed_sec < 0.
      mv_elapsed_sec = 0.
    ENDIF.
  ENDMETHOD.

  METHOD providers.
    rt = mt_provider.
  ENDMETHOD.

  METHOD elapsed_sec.
    rv = mv_elapsed_sec.
  ENDMETHOD.

  METHOD selected_count.
    rv = 0.
    LOOP AT mt_provider INTO DATA(lo_prov).
      IF lo_prov->is_selected( ) = abap_true.
        rv = rv + 1.
      ENDIF.
    ENDLOOP.
    IF rv < 1.
      rv = 1.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*&  대시보드 UI (ZCL_MON_UI_DASHBOARD 대체)
*&---------------------------------------------------------------------*
CLASS lcl_ui_dashboard DEFINITION.
  PUBLIC SECTION.
    METHODS constructor IMPORTING io_ctrl TYPE REF TO lcl_controller
                                  is_sel  TYPE ty_sel.
    METHODS display.
    METHODS toggle_perspective.
    METHODS refresh.
    METHODS show_stats.   " KPI 팝업 (STATS)
    METHODS show_help.    " 사용법 팝업 (HELP)
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_grid_map,
             grid TYPE REF TO cl_gui_alv_grid,
             prov TYPE REF TO lif_data_provider,
           END OF ty_grid_map.
    TYPES: BEGIN OF ty_chart_cell,
             area     TYPE string,
             area_txt TYPE string,
             skipped  TYPE abap_bool,
             cell     TYPE REF TO cl_gui_container,
             chart    TYPE REF TO cl_gui_chart_engine,   " IGS 차트 엔진
           END OF ty_chart_cell.
    CONSTANTS: c_persp_topn TYPE i VALUE 1,
               c_persp_time TYPE i VALUE 2.
    DATA: mo_ctrl        TYPE REF TO lcl_controller,
          ms_sel         TYPE ty_sel,
          mv_persp       TYPE i VALUE 1,
          mv_refresh_dt  TYPE d,                              " 마지막 조회 일자
          mv_refresh_tm  TYPE t,                              " 마지막 조회 시각
          mv_area_cols   TYPE i VALUE 3,                      " 선택 영역 수(동적 분할)
          mo_cont        TYPE REF TO cl_gui_custom_container,
          mo_split       TYPE REF TO cl_gui_splitter_container,
          mo_split_chart TYPE REF TO cl_gui_splitter_container,  " 중간 차트 N분할
          mo_split_alv   TYPE REF TO cl_gui_splitter_container,  " 하단 ALV N분할
          mo_cell_sum    TYPE REF TO cl_gui_container,           " 상단 요약(텍스트) 셀
          mo_dd_sum      TYPE REF TO cl_dd_document,             " 상단 KPI 요약
          mo_timer       TYPE REF TO cl_gui_timer,              " 자동 새로고침 타이머
          mt_grid        TYPE STANDARD TABLE OF ty_grid_map,
          mt_chart_cell  TYPE STANDARD TABLE OF ty_chart_cell,   " 영역별 차트 셀/엔진
          mt_summary     TYPE ty_summary_tab,
          mt_chart_topn  TYPE ty_chart_topn_tab,
          mt_chart_time  TYPE ty_chart_time_tab.
    METHODS build_containers.
    METHODS build_summary.
    METHODS build_area_grids.
    METHODS build_chart_data.
    METHODS build_chart_cells.
    METHODS render_chart.
    METHODS start_timer.
    METHODS navigate_row
      IMPORTING io_grid TYPE REF TO cl_gui_alv_grid
                iv_row  TYPE lvc_index.
    METHODS on_double_click FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row sender.
    METHODS on_hotspot FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id sender.
    METHODS on_timer FOR EVENT finished OF cl_gui_timer.
ENDCLASS.

CLASS lcl_ui_dashboard IMPLEMENTATION.
  METHOD constructor.
    mo_ctrl  = io_ctrl.
    ms_sel   = is_sel.
    mv_persp = c_persp_topn.
    mv_area_cols = mo_ctrl->selected_count( ).
  ENDMETHOD.

  METHOD display.
    mv_refresh_dt = sy-datum.
    mv_refresh_tm = sy-uzeit.
    build_containers( ).
    build_summary( ).
    build_area_grids( ).
    build_chart_data( ).
    build_chart_cells( ).
    render_chart( ).
    start_timer( ).
  ENDMETHOD.

  METHOD build_containers.
    IF mo_cont IS BOUND.
      RETURN.
    ENDIF.
    " Dynpro 0100 의 Custom Control 이름 = 'CC_DASH' (SE51 에서 생성)
    CREATE OBJECT mo_cont
      EXPORTING  container_name              = 'CC_DASH'
      EXCEPTIONS cntl_error                  = 1
                 cntl_system_error           = 2
                 create_error                = 3
                 lifetime_error              = 4
                 lifetime_dynpro_dynpro_link = 5
                 OTHERS                      = 6.
    IF sy-subrc <> 0.
      MESSAGE |CC_DASH 컨테이너 생성 실패 (subrc={ sy-subrc }). 화면 0100 의 Custom Control 이름을 확인하세요.| TYPE 'I'. "#EC NOTEXT
      RETURN.
    ENDIF.

    " 세로 3단: (1)KPI 요약 (2)차트 (3)ALV — 차트/ALV 는 선택 영역 수만큼 동적 분할
    CREATE OBJECT mo_split
      EXPORTING  parent            = mo_cont
                 rows              = 3
                 columns           = 1
      EXCEPTIONS cntl_error        = 1
                 cntl_system_error = 2
                 OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE |스플리터 생성 실패 (subrc={ sy-subrc }).| TYPE 'I'. "#EC NOTEXT
      RETURN.
    ENDIF.
    mo_split->set_row_height( id = 1 height = 14 ).   " 상단 KPI 14%
    mo_split->set_row_height( id = 2 height = 43 ).   " 중간 차트 43%
    mo_split->set_row_height( id = 3 height = 43 ).   " 하단 ALV  43%

    mo_cell_sum = mo_split->get_container( row = 1 column = 1 ).

    DATA(lo_chart_cell) = mo_split->get_container( row = 2 column = 1 ).
    CREATE OBJECT mo_split_chart
      EXPORTING  parent            = lo_chart_cell
                 rows              = 1
                 columns           = mv_area_cols
      EXCEPTIONS cntl_error        = 1
                 cntl_system_error = 2
                 OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE |차트 스플리터 생성 실패 (subrc={ sy-subrc }).| TYPE 'I'. "#EC NOTEXT
      RETURN.
    ENDIF.

    DATA(lo_alv_cell) = mo_split->get_container( row = 3 column = 1 ).
    CREATE OBJECT mo_split_alv
      EXPORTING  parent            = lo_alv_cell
                 rows              = 1
                 columns           = mv_area_cols
      EXCEPTIONS cntl_error        = 1
                 cntl_system_error = 2
                 OTHERS            = 3.
    IF sy-subrc <> 0.
      MESSAGE |ALV 스플리터 생성 실패 (subrc={ sy-subrc }).| TYPE 'I'. "#EC NOTEXT
      RETURN.
    ENDIF.
  ENDMETHOD.

  METHOD build_summary.
    " 상단 KPI: 헬스 배너 + 신호등 영역건수 + 조회기간/시각/소요/자동갱신
    CLEAR mt_summary.
    DATA: lv_total     TYPE i,
          lv_max_level TYPE i,
          lv_active    TYPE i,
          lv_skipped   TYPE i.

    DATA(lt_prov) = mo_ctrl->providers( ).
    LOOP AT lt_prov INTO DATA(lo_prov).
      IF lo_prov->is_selected( ) = abap_false.
        CONTINUE.
      ENDIF.
      IF lo_prov->is_skipped( ) = abap_true.
        lv_skipped = lv_skipped + 1.
        APPEND VALUE ty_summary(
          area     = lo_prov->area_id( )
          area_txt = lo_prov->area_text( )
          count    = 0
          level    = 0 ) TO mt_summary.
      ELSE.
        DATA(ls_sum0) = lo_prov->summary( ).
        APPEND ls_sum0 TO mt_summary.
        lv_total = lv_total + ls_sum0-count.
        lv_active = lv_active + 1.
        IF ls_sum0-level > lv_max_level.
          lv_max_level = ls_sum0-level.
        ENDIF.
      ENDIF.
    ENDLOOP.

    CREATE OBJECT mo_dd_sum.

    " --- 헬스 헤드라인 ---
    DATA(lv_health) = COND string(
      WHEN lv_active = 0 AND lv_skipped > 0
        THEN |권한 부족 — 선택 영역 조회 불가 (권한 없음 { lv_skipped })|
      WHEN lv_total = 0
        THEN |시스템 정상 — 조회 기간 내 이상 없음 (ALL CLEAR)|
      WHEN lv_max_level >= 3
        THEN |장애 주의 — 적색 임계 도달, 즉시 확인 (총 { lv_total }건)|
      WHEN lv_max_level = 2
        THEN |주의 — 황색 임계 도달 영역 있음 (총 { lv_total }건)|
      ELSE |모니터링 중 — 경미한 이상 감지 (총 { lv_total }건)| ).

    DATA(lv_health_icon) = COND string(
      WHEN lv_total = 0 AND lv_active > 0 THEN `ICON_GREEN_LIGHT`
      WHEN lv_max_level >= 3 THEN `ICON_RED_LIGHT`
      WHEN lv_max_level = 2 THEN `ICON_YELLOW_LIGHT`
      WHEN lv_active = 0 THEN `ICON_LED_INACTIVE`
      ELSE `ICON_GREEN_LIGHT` ).

    mo_dd_sum->add_icon( sap_icon = CONV #( lv_health_icon ) ).
    mo_dd_sum->add_gap( width = 5 ).
    mo_dd_sum->add_text( text = CONV #( lv_health ) ).
    mo_dd_sum->new_line( ).

    " --- 영역별 신호등 ---
    LOOP AT mt_summary INTO DATA(ls_sum).
      DATA lv_iconname TYPE string.
      CASE ls_sum-level.
        WHEN 3.       lv_iconname = 'ICON_RED_LIGHT'.
        WHEN 2.       lv_iconname = 'ICON_YELLOW_LIGHT'.
        WHEN 1.       lv_iconname = 'ICON_GREEN_LIGHT'.
        WHEN OTHERS.  lv_iconname = 'ICON_LED_INACTIVE'.
      ENDCASE.
      mo_dd_sum->add_icon( sap_icon = CONV #( lv_iconname ) ).

      DATA(lv_txt) = COND string(
        WHEN ls_sum-level = 0 THEN |{ ls_sum-area_txt } 권한없음|
        ELSE |{ ls_sum-area_txt } { ls_sum-count }건| ).
      mo_dd_sum->add_text( text = CONV #( lv_txt ) ).
      mo_dd_sum->add_gap( width = 24 ).
    ENDLOOP.

    mo_dd_sum->new_line( ).

    " --- 메타: 기간 / 조회시각 / 소요 / 자동갱신 / 관점 ---
    DATA(lv_elapsed) = mo_ctrl->elapsed_sec( ).
    DATA(lv_persp) = COND string(
      WHEN mv_persp = c_persp_topn THEN `차트=Top-N`
      ELSE `차트=시간추이` ).
    DATA(lv_auto) = COND string(
      WHEN ms_sel-autorf > 0 THEN |자동갱신 { ms_sel-autorf }초|
      ELSE `자동갱신 OFF` ).

    mo_dd_sum->add_text( text = |기간 { ms_sel-from_date DATE = USER } { ms_sel-from_time TIME = USER } ~ { ms_sel-to_date DATE = USER } { ms_sel-to_time TIME = USER }| ).
    mo_dd_sum->add_gap( width = 12 ).
    mo_dd_sum->add_text( text = |조회 { mv_refresh_dt DATE = USER } { mv_refresh_tm TIME = USER }| ).
    mo_dd_sum->add_gap( width = 12 ).
    mo_dd_sum->add_text( text = |소요 { lv_elapsed }초| ).
    mo_dd_sum->add_gap( width = 12 ).
    mo_dd_sum->add_text( text = CONV #( lv_auto ) ).
    mo_dd_sum->add_gap( width = 12 ).
    mo_dd_sum->add_text( text = CONV #( lv_persp ) ).
    mo_dd_sum->new_line( ).
    mo_dd_sum->add_text( text = |핫스팟/더블클릭=상세 · REFRESH=재조회 · TOGGLE=차트전환 · STATS=KPI · HELP=도움말| ). "#EC NOTEXT

    mo_dd_sum->merge_document( ).
    mo_dd_sum->display_document( EXPORTING reuse_control = abap_true
                                           parent        = mo_cell_sum ).
  ENDMETHOD.

  METHOD build_area_grids.
    CLEAR mt_grid.
    DATA lv_col TYPE i VALUE 1.
    DATA(lt_prov) = mo_ctrl->providers( ).
    LOOP AT lt_prov INTO DATA(lo_prov).
      IF lo_prov->is_selected( ) = abap_false.
        CONTINUE.
      ENDIF.

      DATA(lo_cell) = mo_split_alv->get_container( row = 1 column = lv_col ).
      DATA lo_grid TYPE REF TO cl_gui_alv_grid.
      CREATE OBJECT lo_grid EXPORTING i_parent = lo_cell.

      DATA(lt_fcat) = lo_prov->fieldcat( ).
      DATA(lr_data) = lo_prov->alv_data( ).
      ASSIGN lr_data->* TO FIELD-SYMBOL(<tab>).

      " 제목 = 영역명 + 상태(권한없음/이상없음/상한초과 안내)
      DATA(lv_total) = lo_prov->count( ).
      DATA(lv_disp)  = COND i( WHEN ms_sel-maxrow > 0 AND lv_total > ms_sel-maxrow
                               THEN ms_sel-maxrow ELSE lv_total ).
      DATA lv_title TYPE lvc_title.
      IF lo_prov->is_skipped( ) = abap_true.
        lv_title = |{ lo_prov->area_text( ) } (권한 없음)|.
      ELSEIF lv_total = 0.
        lv_title = |{ lo_prov->area_text( ) } (이상 없음)|.
      ELSEIF lv_total > lv_disp.
        lv_title = |{ lo_prov->area_text( ) } (상위 { lv_disp } / 전체 { lv_total }건)|.
      ELSE.
        lv_title = |{ lo_prov->area_text( ) } ({ lv_total }건)|.
      ENDIF.

      DATA ls_layo TYPE lvc_s_layo.
      ls_layo-cwidth_opt = abap_true.
      ls_layo-zebra      = abap_true.       " 가독성(얼룩무늬)
      ls_layo-sel_mode   = 'A'.             " 행 선택 하이라이트
      ls_layo-info_fname = 'LINE_COLOR'.    " 영역 고정색 행 강조
      ls_layo-grid_title = lv_title.
      ls_layo-smalltitle = abap_true.
      ls_layo-no_toolbar = abap_false.      " 툴바 ON — 검색/정렬/필터만 유지

      " 합계·인쇄·엑셀/내보내기·레이아웃·정보 등 제외 (검색/정렬/필터 유지)
      DATA(lt_excl) = lcl_util=>alv_toolbar_exclude( ).

      lo_grid->set_table_for_first_display(
        EXPORTING is_layout            = ls_layo
                  it_toolbar_excluding = lt_excl
        CHANGING  it_fieldcatalog = lt_fcat it_outtab = <tab> ).

      SET HANDLER on_double_click FOR lo_grid.
      SET HANDLER on_hotspot FOR lo_grid.
      APPEND VALUE ty_grid_map( grid = lo_grid prov = lo_prov ) TO mt_grid.

      lv_col = lv_col + 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD build_chart_data.
    CLEAR: mt_chart_topn, mt_chart_time.
    DATA(lt_prov) = mo_ctrl->providers( ).

    " (1) 영역별 Top-N (전체 건수 기준)
    LOOP AT lt_prov INTO DATA(lo_prov).
      IF lo_prov->is_selected( ) = abap_false OR lo_prov->is_skipped( ) = abap_true.
        CONTINUE.
      ENDIF.
      DATA(lt_topn) = lcl_aggregator=>build_topn(
                        it_keys = lo_prov->topn_source( )
                        iv_topn = ms_sel-topn ).
      LOOP AT lt_topn INTO DATA(ls_tn).
        APPEND VALUE ty_chart_topn(
          area  = lo_prov->area_id( )
          key   = ls_tn-key
          count = ls_tn-count ) TO mt_chart_topn.
      ENDLOOP.
    ENDLOOP.
    SORT mt_chart_topn BY area count DESCENDING.

    " (2) 시간대별 추이 (적응형 버킷)
    DATA(lv_size) = lcl_aggregator=>bucket_size_hours(
      iv_from_date = ms_sel-from_date iv_from_time = ms_sel-from_time
      iv_to_date   = ms_sel-to_date   iv_to_time   = ms_sel-to_time ).

    LOOP AT lt_prov INTO lo_prov.
      IF lo_prov->is_selected( ) = abap_false OR lo_prov->is_skipped( ) = abap_true.
        CONTINUE.
      ENDIF.
      DATA(lv_area) = lo_prov->area_id( ).
      LOOP AT lo_prov->time_points( ) INTO DATA(ls_tp).
        DATA(lv_bucket) = lcl_aggregator=>bucket_label(
          iv_d = ls_tp-d iv_t = ls_tp-t iv_size_hours = lv_size ).
        READ TABLE mt_chart_time ASSIGNING FIELD-SYMBOL(<b>) WITH KEY bucket = lv_bucket.
        IF sy-subrc <> 0.
          APPEND VALUE ty_chart_time( bucket = lv_bucket ) TO mt_chart_time
            ASSIGNING <b>.
        ENDIF.
        CASE lv_area.
          WHEN 'SM37'. <b>-sm37 = <b>-sm37 + 1.
          WHEN 'ST22'. <b>-st22 = <b>-st22 + 1.
          WHEN 'SXI'.  <b>-sxi  = <b>-sxi  + 1.
        ENDCASE.
        <b>-total = <b>-total + 1.
      ENDLOOP.
    ENDLOOP.
    SORT mt_chart_time BY bucket.
  ENDMETHOD.

  METHOD build_chart_cells.
    " 중간 차트를 영역별(선택된 프로바이더)로 좌->우 배치하고 IGS 차트 엔진 생성
    CLEAR mt_chart_cell.
    DATA lv_col TYPE i VALUE 1.
    DATA(lt_prov) = mo_ctrl->providers( ).
    LOOP AT lt_prov INTO DATA(lo_prov).
      IF lo_prov->is_selected( ) = abap_false.
        CONTINUE.
      ENDIF.
      DATA(lo_cell) = mo_split_chart->get_container( row = 1 column = lv_col ).
      DATA lo_chart TYPE REF TO cl_gui_chart_engine.
      CREATE OBJECT lo_chart EXPORTING parent = lo_cell.
      APPEND VALUE ty_chart_cell(
        area     = lo_prov->area_id( )
        area_txt = lo_prov->area_text( )
        skipped  = lo_prov->is_skipped( )
        cell     = lo_cell
        chart    = lo_chart ) TO mt_chart_cell.
      lv_col = lv_col + 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD render_chart.
    " 중간 = 영역별 개별 그래픽 차트 (CL_GUI_CHART_ENGINE, IGS). XML(데이터+커스터마이징) 전달.
    " 관점 토글로 Top-N <-> 시간추이. 설계 6.2a / O-9(IGS 가용).
    "TODO: 대상 시스템 IGS 설정 확인(SM59 IGS_RFC_DEST / GRAPHICS_IGS_ADMIN). XML 스키마는 필요 시 미세조정.
    LOOP AT mt_chart_cell ASSIGNING FIELD-SYMBOL(<cc>).

      DATA: lv_title TYPE string,
            lv_cat   TYPE string,   " <Categories> 내부
            lv_pts   TYPE string,   " <Point> 반복
            lv_cnt   TYPE i.
      CLEAR: lv_cat, lv_pts.

      IF mv_persp = c_persp_topn.
        lv_title = |{ <cc>-area_txt } Top-{ ms_sel-topn }|.
        LOOP AT mt_chart_topn INTO DATA(ls_t) WHERE area = <cc>-area.
          lv_cat = lv_cat && |<Category>{ escape( val = CONV string( ls_t-key )
                                                   format = cl_abap_format=>e_xml_text ) }</Category>|.
          lv_pts = lv_pts && |<Point><Value>{ ls_t-count }</Value></Point>|.
        ENDLOOP.
      ELSE.
        lv_title = |{ <cc>-area_txt } 시간추이|.
        LOOP AT mt_chart_time INTO DATA(ls_b).
          lv_cnt = COND #( WHEN <cc>-area = 'SM37' THEN ls_b-sm37
                           WHEN <cc>-area = 'ST22' THEN ls_b-st22
                           ELSE ls_b-sxi ).
          lv_cat = lv_cat && |<Category>{ escape( val = CONV string( ls_b-bucket )
                                                   format = cl_abap_format=>e_xml_text ) }</Category>|.
          lv_pts = lv_pts && |<Point><Value>{ lv_cnt }</Value></Point>|.
        ENDLOOP.
      ENDIF.

      " 데이터가 없으면(권한없음/이상없음) 안내용 단일 카테고리로 대체
      IF lv_cat IS INITIAL.
        DATA(lv_note) = COND string( WHEN <cc>-skipped = abap_true THEN `권한 없음` ELSE `이상 없음` ).
        lv_cat = |<Category>{ escape( val = lv_note format = cl_abap_format=>e_xml_text ) }</Category>|.
        lv_pts = |<Point><Value>0</Value></Point>|.
      ENDIF.

      " 데이터 XML (SAP Chart Engine ChartData)
      DATA(lv_data) = |<?xml version="1.0" encoding="utf-8"?>|
        && |<ChartData>|
        && |<Categories>{ lv_cat }</Categories>|
        && |<Series>{ lv_pts }</Series>|
        && |</ChartData>|.

      " Top-N=가로막대, 시간추이=세로컬럼 — 관점 전환 시 시각 차별화
      DATA(lv_ctype) = COND string(
        WHEN mv_persp = c_persp_topn THEN `Bars` ELSE `Columns` ).

      DATA(lv_cust) = |<?xml version="1.0" encoding="utf-8"?>|
        && |<SAPChartCustomizing version="2.0">|
        && |<GlobalSettings><Defaults><ChartType>{ lv_ctype }</ChartType></Defaults></GlobalSettings>|
        && |<Elements><ChartElements><Title><Caption>|
        && escape( val = lv_title format = cl_abap_format=>e_xml_text )
        && |</Caption></Title></ChartElements></Elements>|
        && |</SAPChartCustomizing>|.

      <cc>-chart->set_customizing( data = lv_cust ).
      <cc>-chart->set_data( data = lv_data ).
      <cc>-chart->render( ).
    ENDLOOP.
  ENDMETHOD.

  METHOD toggle_perspective.
    IF mv_persp = c_persp_topn.
      mv_persp = c_persp_time.
    ELSE.
      mv_persp = c_persp_topn.
    ENDIF.
    render_chart( ).
    build_summary( ).   " 상단 관점 라벨 동기화
  ENDMETHOD.

  METHOD refresh.
    " 화면에서 재조회 (읽기 전용). 데이터/요약/차트/그리드 갱신.
    mo_ctrl->run( ms_sel ).
    mv_refresh_dt = sy-datum.
    mv_refresh_tm = sy-uzeit.

    build_summary( ).            " 상단 요약(조회시각 포함) 재구성
    build_chart_data( ).
    render_chart( ).             " 영역별 차트 재렌더

    " 하단 ALV 데이터 갱신
    LOOP AT mt_grid INTO DATA(ls).
      ls-grid->refresh_table_display( ).
    ENDLOOP.
  ENDMETHOD.

  METHOD start_timer.
    " 자동 새로고침(선택): P_AUTORF 초 주기
    IF ms_sel-autorf <= 0.
      RETURN.
    ENDIF.
    IF mo_timer IS NOT BOUND.
      CREATE OBJECT mo_timer.
      SET HANDLER on_timer FOR mo_timer.
    ENDIF.
    mo_timer->interval = ms_sel-autorf.
    mo_timer->run( ).
  ENDMETHOD.

  METHOD on_timer.
    refresh( ).
    " 다음 주기 재가동
    IF mo_timer IS BOUND AND ms_sel-autorf > 0.
      mo_timer->interval = ms_sel-autorf.
      mo_timer->run( ).
    ENDIF.
  ENDMETHOD.

  METHOD navigate_row.
    READ TABLE mt_grid INTO DATA(ls) WITH KEY grid = io_grid.
    IF sy-subrc = 0 AND iv_row > 0.
      " lif_data_provider~navigate 는 TYPE i — lvc_index 를 명시 변환
      ls-prov->navigate( iv_row = CONV i( iv_row ) ).
    ENDIF.
  ENDMETHOD.

  METHOD on_double_click.
    navigate_row( io_grid = sender iv_row = e_row-index ).
  ENDMETHOD.

  METHOD on_hotspot.
    navigate_row( io_grid = sender iv_row = e_row_id-index ).
  ENDMETHOD.

  METHOD show_stats.
    " 데모용 KPI 팝업 — 읽기 전용 집계만 표시
    DATA: lv_total TYPE i,
          lv_line  TYPE string,
          lv_msg   TYPE string.

    LOOP AT mt_summary INTO DATA(ls).
      lv_total = lv_total + ls-count.
      DATA(lv_lv) = SWITCH string( ls-level
        WHEN 3 THEN `적색`
        WHEN 2 THEN `황색`
        WHEN 1 THEN `녹색`
        ELSE `권한없음` ).
      lv_line = |{ ls-area_txt }: { ls-count }건 ({ lv_lv })|.
      IF lv_msg IS INITIAL.
        lv_msg = lv_line.
      ELSE.
        lv_msg = |{ lv_msg } / { lv_line }|.
      ENDIF.
    ENDLOOP.

    DATA(lv_persp) = COND string(
      WHEN mv_persp = c_persp_topn THEN `Top-N` ELSE `시간추이` ).

    MESSAGE |[Ops Monitor KPI] 총이상 { lv_total }건 | &&
            |{ lv_msg } | &&
            |조회 { mv_refresh_dt DATE = USER } { mv_refresh_tm TIME = USER } | &&
            |소요 { mo_ctrl->elapsed_sec( ) }초 | &&
            |차트 { lv_persp } | &&
            |영역 { mv_area_cols }분할|
      TYPE 'I'.                                             "#EC NOTEXT
  ENDMETHOD.

  METHOD show_help.
    MESSAGE |[사용법] | &&
            |1) 핫스팟(밑줄) 클릭 또는 행 더블클릭 → 표준 상세(표시전용) | &&
            |2) REFRESH → 현재 조건 재조회 | &&
            |3) TOGGLE → Top-N ↔ 시간추이 차트 전환 | &&
            |4) STATS → KPI 요약 팝업 | &&
            |5) P_AUTORF>0 → 자동 새로고침 | &&
            |6) ALV 툴바 → 정렬/필터/엑셀 다운로드 | &&
            |※ 본 프로그램은 읽기전용(재처리/재실행 없음)|
      TYPE 'I'.                                             "#EC NOTEXT
  ENDMETHOD.
ENDCLASS.

*&---------------------------------------------------------------------*
*&  전역 데이터
*&---------------------------------------------------------------------*
DATA: go_ctrl      TYPE REF TO lcl_controller,
      go_dashboard TYPE REF TO lcl_ui_dashboard,
      gs_sel       TYPE ty_sel,
      gv_ok_code   TYPE sy-ucomm.

*&---------------------------------------------------------------------*
*&  INITIALIZATION - 기본 조회기간(현재 -P_HOURS)
*&---------------------------------------------------------------------*
INITIALIZATION.
  txt_bnr = 'Cursor AI 기반 | 읽기전용 통합 운영 모니터링 대시보드 (SM37 / ST22 / SXI)'. "#EC NOTEXT
  PERFORM calc_default_period.
  gv_hours_last = p_hours.

*&---------------------------------------------------------------------*
*&  AT SELECTION-SCREEN
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
  IF txt_bnr IS INITIAL.
    txt_bnr = 'Cursor AI 기반 | 읽기전용 통합 운영 모니터링 대시보드 (SM37 / ST22 / SXI)'. "#EC NOTEXT
  ENDIF.

AT SELECTION-SCREEN.
  " 기간 역전 검증
  IF p_todat < p_frdat
     OR ( p_todat = p_frdat AND p_totim < p_frtim ).
    MESSAGE '조회 종료가 시작보다 빠릅니다.' TYPE 'E'.     "#EC NOTEXT
  ENDIF.

AT SELECTION-SCREEN ON p_hours.
  " P_HOURS 값이 바뀐 경우에만 FROM/TO 자동 재계산 (수동 기간 입력 보존)
  IF p_hours > 0 AND p_hours <> gv_hours_last.
    PERFORM calc_default_period.
    gv_hours_last = p_hours.
  ENDIF.

AT SELECTION-SCREEN ON p_topn.
  " 차트 Top-N 은 1~5 만 허용
  IF p_topn < 1 OR p_topn > 5.
    MESSAGE '차트 Top-N 은 1 ~ 5 만 입력 가능합니다.' TYPE 'E'.  "#EC NOTEXT
  ENDIF.

*&---------------------------------------------------------------------*
*&  START-OF-SELECTION
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  PERFORM build_selection.

  CREATE OBJECT go_ctrl.
  go_ctrl->run( gs_sel ).

  IF cb_sm37 = abap_false AND cb_st22 = abap_false AND cb_sxi = abap_false.
    MESSAGE '조회할 영역을 하나 이상 선택하세요.' TYPE 'S' DISPLAY LIKE 'W'. "#EC NOTEXT
    RETURN.
  ENDIF.

  CALL SCREEN 0100.

*&---------------------------------------------------------------------*
*&  Form  CALC_DEFAULT_PERIOD
*&---------------------------------------------------------------------*
FORM calc_default_period.
  DATA: lv_hours TYPE i,
        lv_now   TYPE timestampl,
        lv_from  TYPE timestampl.

  lv_hours = COND i( WHEN p_hours > 0 THEN p_hours ELSE 24 ).

  p_todat = sy-datum.
  p_totim = sy-uzeit.

  lv_now  = lcl_util=>local_to_utc( iv_date = sy-datum iv_time = sy-uzeit ).
  lv_from = cl_abap_tstmp=>subtractsecs( tstmp = lv_now secs = lv_hours * 3600 ).

  lcl_util=>utc_to_local( EXPORTING iv_ts = lv_from
                          IMPORTING ev_date = p_frdat ev_time = p_frtim ).
ENDFORM.

*&---------------------------------------------------------------------*
*&  Form  BUILD_SELECTION
*&---------------------------------------------------------------------*
FORM build_selection.
  CLEAR gs_sel.
  gs_sel-from_date = p_frdat.
  gs_sel-from_time = p_frtim.
  gs_sel-to_date   = p_todat.
  gs_sel-to_time   = p_totim.
  gs_sel-job_rng   = so_job[].
  gs_sel-user_rng  = so_user[].
  gs_sel-iface_rng = so_iface[].
  gs_sel-mandt     = p_mand.
  gs_sel-topn      = p_topn.
  gs_sel-maxrow    = p_maxrow.
  gs_sel-autorf    = p_autorf.
ENDFORM.

*&---------------------------------------------------------------------*
*&  MODULE STATUS_0100 OUTPUT  (PBO)
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  " GUI Status 'S0100' (SE41): REFRESH / TOGGLE / STATS / HELP / BACK / EXIT / CANCEL
  SET PF-STATUS 'S0100'.
  SET TITLEBAR  'T0100'.

  IF go_dashboard IS NOT BOUND.
    CREATE OBJECT go_dashboard
      EXPORTING io_ctrl = go_ctrl is_sel = gs_sel.
    go_dashboard->display( ).
  ENDIF.
ENDMODULE.

*&---------------------------------------------------------------------*
*&  MODULE USER_COMMAND_0100 INPUT  (PAI)
*&---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  DATA lv_ucomm TYPE sy-ucomm.
  lv_ucomm = gv_ok_code.
  CLEAR gv_ok_code.

  CASE lv_ucomm.
    WHEN 'TOGGLE'.
      IF go_dashboard IS BOUND.
        go_dashboard->toggle_perspective( ).
      ENDIF.
    WHEN 'REFRESH'.
      IF go_dashboard IS BOUND.
        go_dashboard->refresh( ).
      ENDIF.
    WHEN 'STATS'.
      IF go_dashboard IS BOUND.
        go_dashboard->show_stats( ).
      ENDIF.
    WHEN 'HELP'.
      IF go_dashboard IS BOUND.
        go_dashboard->show_help( ).
      ENDIF.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
