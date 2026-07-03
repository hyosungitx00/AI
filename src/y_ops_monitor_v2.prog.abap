*&---------------------------------------------------------------------*
*& Report  Y_OPS_MONITOR_V2
*&---------------------------------------------------------------------*
*& 통합 운영 모니터링 (SM37 / ST22 / SXI_MONITOR) - 로컬 우선(V2) 구현
*&
*& 설계서: docs/design/integrated-ops-monitor-design.md (v0.4)
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
*& [화면] Dynpro 0100 + GUI Status 'S0100' 은 SE51/SE41 로 별도 생성한다.
*&        생성 방법: docs/build/y_ops_monitor_v2-build-guide.md 참조.
*&---------------------------------------------------------------------*
REPORT y_ops_monitor_v2.

TYPE-POOLS: icon.

*&---------------------------------------------------------------------*
*&  선택 화면 필드용 전역 참조 변수
*&---------------------------------------------------------------------*
DATA: gv_jobname TYPE tbtco-jobname,
      gv_uname   TYPE tbtco-sdluname,
      gv_iface   TYPE sxmspemas-ob_name.

*&---------------------------------------------------------------------*
*&  선택 화면 (Selection Screen)
*&---------------------------------------------------------------------*
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
            p_topn   TYPE i DEFAULT 5.
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
       END OF ty_sel.

" 영역별 출력 구조 (DDIC ZMON_S_* 대체) ---------------------------------
TYPES: BEGIN OF ty_batch,           " SM37 (ZMON_S_BATCH 대체)
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
         icon     TYPE icon_d,
         datum    TYPE d,
         uzeit    TYPE t,
         uname    TYPE syuname,
         ahost    TYPE c LENGTH 32,
         rt_error TYPE c LENGTH 36,  " DUMPID (런타임 에러 유형)
         progname TYPE c LENGTH 40,
         include  TYPE c LENGTH 40,
         line     TYPE i,
       END OF ty_dump,
       ty_dump_tab TYPE STANDARD TABLE OF ty_dump WITH DEFAULT KEY.

TYPES: BEGIN OF ty_iface,           " SXI (ZMON_S_IFACE 대체)
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

" 차트(placeholder ALV)용 행 ------------------------------------------
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
      IMPORTING iv_field TYPE lvc_fname
                iv_text  TYPE string
                iv_icon  TYPE abap_bool DEFAULT abap_false
                iv_hide  TYPE abap_bool DEFAULT abap_false
      CHANGING  ct_fcat  TYPE lvc_t_fcat.
    CLASS-METHODS local_to_utc
      IMPORTING iv_date      TYPE d
                iv_time      TYPE t
      RETURNING VALUE(rv_ts) TYPE timestampl.
    CLASS-METHODS utc_to_local
      IMPORTING iv_ts   TYPE timestampl
      EXPORTING ev_date TYPE d
                ev_time TYPE t.
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
ENDCLASS.

*&---------------------------------------------------------------------*
*&  집계기 (ZCL_MON_AGGREGATOR 대체) - 차트 데이터 파생
*&---------------------------------------------------------------------*
CLASS lcl_aggregator DEFINITION.
  PUBLIC SECTION.
    " Top-N: 키 목록 -> (키,건수) 상위 N (전체 건수 기준)
    CLASS-METHODS build_topn
      IMPORTING it_keys      TYPE ty_str_tab
                iv_topn      TYPE i
      RETURNING VALUE(rt)    TYPE ty_key_count_tab.
    " 적응형 버킷 크기(시간) 결정
    CLASS-METHODS bucket_size_hours
      IMPORTING iv_from_date TYPE d
                iv_from_time TYPE t
                iv_to_date   TYPE d
                iv_to_time   TYPE t
      RETURNING VALUE(rv)    TYPE i.
    " 시간점 -> 버킷 라벨
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
    DATA(lv_n) = COND i( WHEN iv_topn > 0 THEN iv_topn ELSE 5 ).
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
    METHODS show_dump.
    METHODS show_message
      IMPORTING iv_msgguid TYPE sxmspmast-msgguid.
ENDCLASS.

CLASS lcl_navigator IMPLEMENTATION.
  METHOD show_joblog.
    " 표시 전용 - 잡 로그 조회 (읽기 전용)
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
    " 표시 전용 - ST22 표준 화면 (읽기 전용 진입)
    "TODO: 선택 행의 덤프 키(일자/시간/ID)를 전달하여 특정 덤프로 진입하도록 확장
    CALL TRANSACTION 'ST22'.                              "#EC CI_CALLTA
  ENDMETHOD.

  METHOD show_message.
    " 표시 전용 - SXI_MONITOR 표준 화면 (읽기 전용 진입)
    "TODO: 선택 행의 MSGGUID 를 전달하여 특정 메시지로 진입하도록 확장
    CALL TRANSACTION 'SXI_MONITOR'.                       "#EC CI_CALLTA
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
    lcl_util=>add_col( EXPORTING iv_field = 'ICON'      iv_text = '' iv_icon = abap_true CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'JOBNAME'   iv_text = '잡명'      CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'JOBCOUNT'  iv_text = '잡카운트'  CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'STATUS_TX' iv_text = '상태'      CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'PROGNAME'  iv_text = '프로그램'  CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'SDLUNAME'  iv_text = '사용자'    CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'STRTDATE'  iv_text = '시작일'    CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'STRTTIME'  iv_text = '시작시간'  CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'ENDDATE'   iv_text = '종료일'    CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'ENDTIME'   iv_text = '종료시간'  CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'STATUS'    iv_text = 'STATUS' iv_hide = abap_true CHANGING ct_fcat = rt ).
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
    READ TABLE mt_view INTO DATA(ls) INDEX iv_row.
    IF sy-subrc = 0.
      mo_nav->show_joblog( iv_jobname = ls-jobname iv_jobcount = ls-jobcount ).
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
              icon     = icon_red_light
              datum    = ls_d-sydate
              uzeit    = ls_d-sytime
              uname    = ls_d-syuser
              ahost    = |{ ls_d-syhost }|
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
    lcl_util=>add_col( EXPORTING iv_field = 'ICON'     iv_text = '' iv_icon = abap_true CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'DATUM'    iv_text = '발생일'    CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'UZEIT'    iv_text = '발생시간'  CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'UNAME'    iv_text = '사용자'    CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'AHOST'    iv_text = '서버'      CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'RT_ERROR' iv_text = '에러유형'  CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'PROGNAME' iv_text = '프로그램'  CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'INCLUDE'  iv_text = '인클루드'  CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'LINE'     iv_text = '라인'      CHANGING ct_fcat = rt ).
  ENDMETHOD.

  METHOD lif_data_provider~topn_source.
    " Top-N 키 = DUMPID (런타임 에러 유형)
    LOOP AT mt_all INTO DATA(ls).
      APPEND ls-rt_error TO rt.
    ENDLOOP.
  ENDMETHOD.

  METHOD lif_data_provider~time_points.
    LOOP AT mt_all INTO DATA(ls).
      APPEND VALUE #( d = ls-datum t = ls-uzeit ) TO rt.
    ENDLOOP.
  ENDMETHOD.

  METHOD lif_data_provider~navigate.
    READ TABLE mt_view INTO DATA(ls) INDEX iv_row.
    IF sy-subrc = 0.
      mo_nav->show_dump( ).
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
        icon    = icon_red_light
        errstat = ls_err-errstat
        msgguid = ls_err-msgguid ).

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

      " 인터페이스명 필터(옵션) - OB_NAME
      IF is_sel-iface_rng IS NOT INITIAL AND NOT ls_out-if_name IN is_sel-iface_rng.
        CONTINUE.
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
    lcl_util=>add_col( EXPORTING iv_field = 'ICON'      iv_text = '' iv_icon = abap_true CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'EXE_DATE'  iv_text = '발생일'      CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'EXE_TIME'  iv_text = '발생시간'    CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'IF_NAME'   iv_text = '인터페이스'  CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'OPERATION' iv_text = '오퍼레이션'  CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'SENDER'    iv_text = '송신'        CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'RECEIVER'  iv_text = '수신'        CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'MSGSTATE'  iv_text = '상태'        CHANGING ct_fcat = rt ).
    lcl_util=>add_col( EXPORTING iv_field = 'ERRSTAT'   iv_text = '에러상태'    CHANGING ct_fcat = rt ).
    " MSGGUID 는 드릴다운 키로만 사용(내부 보관), ALV 표시/필드카탈로그에서는 제외
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
      mo_nav->show_message( iv_msgguid = ls-msgguid ).
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
  PRIVATE SECTION.
    DATA: mo_nav      TYPE REF TO lcl_navigator,
          mt_provider TYPE ty_provider_tab.
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
  ENDMETHOD.

  METHOD providers.
    rt = mt_provider.
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
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_grid_map,
             grid TYPE REF TO cl_gui_alv_grid,
             prov TYPE REF TO lif_data_provider,
           END OF ty_grid_map.
    CONSTANTS: c_persp_topn TYPE i VALUE 1,
               c_persp_time TYPE i VALUE 2.
    DATA: mo_ctrl        TYPE REF TO lcl_controller,
          ms_sel         TYPE ty_sel,
          mv_persp       TYPE i VALUE 1,
          mo_cont        TYPE REF TO cl_gui_custom_container,
          mo_split       TYPE REF TO cl_gui_splitter_container,
          mo_split_alv   TYPE REF TO cl_gui_splitter_container,
          mo_grid_sum    TYPE REF TO cl_gui_alv_grid,
          mo_grid_chart  TYPE REF TO cl_gui_alv_grid,
          mt_grid        TYPE STANDARD TABLE OF ty_grid_map,
          mt_summary     TYPE ty_summary_tab,
          mt_chart_topn  TYPE ty_chart_topn_tab,
          mt_chart_time  TYPE ty_chart_time_tab.
    METHODS build_containers.
    METHODS build_summary.
    METHODS build_area_grids.
    METHODS build_chart_data.
    METHODS render_chart.
    METHODS on_double_click FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING e_row sender.
ENDCLASS.

CLASS lcl_ui_dashboard IMPLEMENTATION.
  METHOD constructor.
    mo_ctrl  = io_ctrl.
    ms_sel   = is_sel.
    mv_persp = c_persp_topn.
  ENDMETHOD.

  METHOD display.
    build_containers( ).
    build_summary( ).
    build_area_grids( ).
    build_chart_data( ).
    render_chart( ).
  ENDMETHOD.

  METHOD build_containers.
    IF mo_cont IS BOUND.
      RETURN.
    ENDIF.
    " Dynpro 0100 의 Custom Control 이름 = 'CC_DASH' (SE51 에서 생성)
    CREATE OBJECT mo_cont
      EXPORTING container_name = 'CC_DASH'.

    " 세로 3단: (1)요약 (2)차트 (3)3분할 ALV
    CREATE OBJECT mo_split
      EXPORTING parent = mo_cont rows = 3 columns = 1.
    mo_split->set_row_height( id = 1 height = 12 ).
    mo_split->set_row_height( id = 2 height = 30 ).

    " 3단 셀을 다시 좌/중/우 3분할
    DATA(lo_alv_cell) = mo_split->get_container( row = 3 column = 1 ).
    CREATE OBJECT mo_split_alv
      EXPORTING parent = lo_alv_cell rows = 1 columns = 3.
  ENDMETHOD.

  METHOD build_summary.
    CLEAR mt_summary.
    DATA(lt_prov) = mo_ctrl->providers( ).
    LOOP AT lt_prov INTO DATA(lo_prov).
      IF lo_prov->is_selected( ) = abap_false.
        CONTINUE.
      ENDIF.
      IF lo_prov->is_skipped( ) = abap_true.
        APPEND VALUE ty_summary(
          area     = lo_prov->area_id( )
          area_txt = lo_prov->area_text( )
          count    = 0
          icon     = icon_led_inactive
          level    = 0 ) TO mt_summary.
      ELSE.
        APPEND lo_prov->summary( ) TO mt_summary.
      ENDIF.
    ENDLOOP.

    DATA(lo_cell) = mo_split->get_container( row = 1 column = 1 ).
    CREATE OBJECT mo_grid_sum EXPORTING i_parent = lo_cell.

    DATA lt_fcat TYPE lvc_t_fcat.
    lcl_util=>add_col( EXPORTING iv_field = 'ICON'     iv_text = '' iv_icon = abap_true CHANGING ct_fcat = lt_fcat ).
    lcl_util=>add_col( EXPORTING iv_field = 'AREA_TXT' iv_text = '영역'  CHANGING ct_fcat = lt_fcat ).
    lcl_util=>add_col( EXPORTING iv_field = 'COUNT'    iv_text = '건수'  CHANGING ct_fcat = lt_fcat ).

    DATA ls_layo TYPE lvc_s_layo.
    ls_layo-cwidth_opt = abap_true.
    ls_layo-no_toolbar = abap_true.

    mo_grid_sum->set_table_for_first_display(
      EXPORTING is_layout = ls_layo
      CHANGING  it_fieldcatalog = lt_fcat it_outtab = mt_summary ).
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

      DATA ls_layo TYPE lvc_s_layo.
      ls_layo-cwidth_opt = abap_true.
      ls_layo-grid_title = |{ lo_prov->area_text( ) } ({ lo_prov->count( ) }건)|.

      lo_grid->set_table_for_first_display(
        EXPORTING is_layout = ls_layo
        CHANGING  it_fieldcatalog = lt_fcat it_outtab = <tab> ).

      SET HANDLER on_double_click FOR lo_grid.
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

  METHOD render_chart.
    "TODO: IGS 그래픽 차트(CL_GUI_CHART_ENGINE) 로 대체.
    "      현재는 활성화/실행 보증을 위해 집계 결과를 ALV(표) 로 표시한다.
    "      집계 로직(영역별 Top-N / 적응형 시간버킷)은 실제 동작한다.
    DATA(lo_cell) = mo_split->get_container( row = 2 column = 1 ).
    IF mo_grid_chart IS BOUND.
      mo_grid_chart->free( ).
      CLEAR mo_grid_chart.
    ENDIF.
    CREATE OBJECT mo_grid_chart EXPORTING i_parent = lo_cell.

    DATA: lt_fcat TYPE lvc_t_fcat,
          ls_layo TYPE lvc_s_layo.
    ls_layo-cwidth_opt = abap_true.

    IF mv_persp = c_persp_topn.
      ls_layo-grid_title = '차트: 영역별 Top-N 집중도'.       "#EC NOTEXT
      lcl_util=>add_col( EXPORTING iv_field = 'AREA'  iv_text = '영역'  CHANGING ct_fcat = lt_fcat ).
      lcl_util=>add_col( EXPORTING iv_field = 'KEY'   iv_text = '원인키' CHANGING ct_fcat = lt_fcat ).
      lcl_util=>add_col( EXPORTING iv_field = 'COUNT' iv_text = '건수'  CHANGING ct_fcat = lt_fcat ).
      mo_grid_chart->set_table_for_first_display(
        EXPORTING is_layout = ls_layo
        CHANGING  it_fieldcatalog = lt_fcat it_outtab = mt_chart_topn ).
    ELSE.
      ls_layo-grid_title = '차트: 시간대별 추이(적응형 버킷)'. "#EC NOTEXT
      lcl_util=>add_col( EXPORTING iv_field = 'BUCKET' iv_text = '시간버킷' CHANGING ct_fcat = lt_fcat ).
      lcl_util=>add_col( EXPORTING iv_field = 'SM37'   iv_text = 'SM37' CHANGING ct_fcat = lt_fcat ).
      lcl_util=>add_col( EXPORTING iv_field = 'ST22'   iv_text = 'ST22' CHANGING ct_fcat = lt_fcat ).
      lcl_util=>add_col( EXPORTING iv_field = 'SXI'    iv_text = 'SXI'  CHANGING ct_fcat = lt_fcat ).
      lcl_util=>add_col( EXPORTING iv_field = 'TOTAL'  iv_text = '합계' CHANGING ct_fcat = lt_fcat ).
      mo_grid_chart->set_table_for_first_display(
        EXPORTING is_layout = ls_layo
        CHANGING  it_fieldcatalog = lt_fcat it_outtab = mt_chart_time ).
    ENDIF.
  ENDMETHOD.

  METHOD toggle_perspective.
    IF mv_persp = c_persp_topn.
      mv_persp = c_persp_time.
    ELSE.
      mv_persp = c_persp_topn.
    ENDIF.
    render_chart( ).
  ENDMETHOD.

  METHOD on_double_click.
    READ TABLE mt_grid INTO DATA(ls) WITH KEY grid = sender.
    IF sy-subrc = 0.
      DATA lv_row TYPE i.
      lv_row = e_row-index.
      ls-prov->navigate( iv_row = lv_row ).
    ENDIF.
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
  PERFORM calc_default_period.

*&---------------------------------------------------------------------*
*&  AT SELECTION-SCREEN
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
  " P_HOURS 변경 편의: 값이 있으면 FROM/TO 재계산 힌트 (사용자 직접수정 우선)

AT SELECTION-SCREEN.
  " 기간 역전 검증
  IF p_todat < p_frdat
     OR ( p_todat = p_frdat AND p_totim < p_frtim ).
    MESSAGE '조회 종료가 시작보다 빠릅니다.' TYPE 'E'.     "#EC NOTEXT
    "TODO: 메시지 클래스(ZOPSMON) 전환
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
ENDFORM.

*&---------------------------------------------------------------------*
*&  MODULE STATUS_0100 OUTPUT  (PBO)
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  " GUI Status 'S0100' (SE41): 기능 TOGGLE(관점전환), BACK/EXIT/CANCEL
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
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
