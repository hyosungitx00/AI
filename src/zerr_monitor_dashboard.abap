*&---------------------------------------------------------------------*
*& Report ZERR_MONITOR_DASHBOARD
*&---------------------------------------------------------------------*
*& 목적:
*&   ST22 / SM37 / SXI_MONITOR 오류를 한 화면에서 확인하는 통합 모니터링
*&   프로그램의 Selection Screen 및 탭스트립 출력 화면 골격입니다.
*&
*& 기준:
*&   - SAP 버전      : S/4HANA
*&   - ABAP 릴리즈   : 7.50
*&   - 네임스페이스  : Z
*&   - 코딩 스타일   : 인라인 선언 허용
*&   - 명명 규칙     : GV_/GS_/GT_, LV_/LS_/LT_
*&   - 주석 언어     : 한국어
*&
*& 화면 객체 생성 메모(SE51/SE41):
*&   1) Screen 0100 - Normal Screen
*&      - Tabstrip Control : TS_MAIN
*&        · Tab Function Code : TAB_SUM  / Label : 전체 요약
*&        · Tab Function Code : TAB_ST22 / Label : ST22 덤프
*&        · Tab Function Code : TAB_SM37 / Label : SM37 배치잡
*&        · Tab Function Code : TAB_SXI  / Label : SXI 메시지
*&      - Subscreen Area   : SUB_AREA
*&      - OK Code Field    : GV_OK_CODE
*&      - Flow Logic
*&        PROCESS BEFORE OUTPUT.
*&          MODULE status_0100.
*&          CALL SUBSCREEN sub_area INCLUDING sy-repid gv_subscreen.
*&        PROCESS AFTER INPUT.
*&          CALL SUBSCREEN sub_area.
*&          MODULE user_command_0100.
*&
*&   2) Screen 0110 - Subscreen, 전체 요약
*&      - Custom Control : CC_DASH_HTML
*&      - Flow Logic
*&        PROCESS BEFORE OUTPUT.
*&          MODULE init_0110.
*&
*&   3) Screen 0120 - Subscreen, ST22 덤프
*&      - Custom Control : CC_ST22_ALV
*&      - Flow Logic
*&        PROCESS BEFORE OUTPUT.
*&          MODULE init_0120.
*&
*&   4) Screen 0130 - Subscreen, SM37 배치잡
*&      - Custom Control : CC_SM37_ALV
*&      - Flow Logic
*&        PROCESS BEFORE OUTPUT.
*&          MODULE init_0130.
*&
*&   5) Screen 0140 - Subscreen, SXI 메시지
*&      - Custom Control : CC_SXI_ALV
*&      - Flow Logic
*&        PROCESS BEFORE OUTPUT.
*&          MODULE init_0140.
*&
*&   6) GUI Status MAIN(SE41)
*&      - BACK, EXIT, CANC
*&      - TAB_SUM, TAB_ST22, TAB_SM37, TAB_SXI
*&
*&   7) Text Symbol
*&      - TEXT-001 : 조회 기간/사용자
*&      - TEXT-002 : 오류 유형
*&      - TEXT-003 : 심각도
*&      - TEXT-004 : 상세 필터
*&      - TITLE T01: Z 통합 에러 모니터링 대시보드
*&
*& TODO:
*&   - ST22 RS_ST22_API 인터페이스는 시스템 릴리즈별 차이가 있으므로
*&     대상 시스템에서 파라미터 확인 후 FORM collect_st22를 완성하세요.
*&   - SXMB_GET_MESSAGE_LIST 인터페이스와 SXMS* 테이블 필드는 PI/XI 설치
*&     구성에 따라 차이가 있으므로 FORM collect_sxi를 완성하세요.
*&   - 권한 오브젝트 필드는 고객 시스템 보안 정책에 맞춰 보강하세요.
*&---------------------------------------------------------------------*
REPORT zerr_monitor_dashboard.

TYPE-POOLS: abap.

CONTROLS ts_main TYPE TABSTRIP.

CONSTANTS:
  gc_tab_sum  TYPE syucomm VALUE 'TAB_SUM',
  gc_tab_st22 TYPE syucomm VALUE 'TAB_ST22',
  gc_tab_sm37 TYPE syucomm VALUE 'TAB_SM37',
  gc_tab_sxi  TYPE syucomm VALUE 'TAB_SXI'.

CONSTANTS:
  gc_sev_error TYPE char10 VALUE 'ERROR',
  gc_sev_warn  TYPE char10 VALUE 'WARNING',
  gc_sev_info  TYPE char10 VALUE 'INFO'.

TYPES:
  BEGIN OF ty_st22,
    occurred_on TYPE dats,
    occurred_at TYPE tims,
    severity    TYPE char10,
    dump_id     TYPE char40,
    program     TYPE progname,
    user_name   TYPE syuname,
    error_class TYPE char30,
    message     TYPE char120,
    detail      TYPE char120,
  END OF ty_st22.

TYPES:
  BEGIN OF ty_sm37,
    occurred_on TYPE dats,
    occurred_at TYPE tims,
    severity    TYPE char10,
    jobname     TYPE tbtco-jobname,
    jobcount    TYPE tbtco-jobcount,
    user_name   TYPE syuname,
    status      TYPE tbtco-status,
    message     TYPE char120,
    detail      TYPE char120,
  END OF ty_sm37.

TYPES:
  BEGIN OF ty_sxi,
    occurred_on TYPE dats,
    occurred_at TYPE tims,
    severity    TYPE char10,
    msg_id      TYPE char40,
    interface   TYPE char60,
    sender      TYPE char60,
    receiver    TYPE char60,
    status      TYPE char20,
    message     TYPE char120,
    detail      TYPE char120,
  END OF ty_sxi.

TYPES:
  BEGIN OF ty_tbtco,
    jobname   TYPE tbtco-jobname,
    jobcount  TYPE tbtco-jobcount,
    sdlstrtdt TYPE tbtco-sdlstrtdt,
    sdlstrttm TYPE tbtco-sdlstrttm,
    enddate   TYPE tbtco-enddate,
    endtime   TYPE tbtco-endtime,
    status    TYPE tbtco-status,
    authcknam TYPE tbtco-authcknam,
  END OF ty_tbtco.

DATA:
  gt_st22 TYPE STANDARD TABLE OF ty_st22 WITH DEFAULT KEY,
  gt_sm37 TYPE STANDARD TABLE OF ty_sm37 WITH DEFAULT KEY,
  gt_sxi  TYPE STANDARD TABLE OF ty_sxi  WITH DEFAULT KEY.

DATA:
  gv_ok_code    TYPE syucomm,
  gv_save_ok    TYPE syucomm,
  gv_subscreen  TYPE sy-dynnr VALUE '0110',
  gv_active_tab TYPE syucomm  VALUE gc_tab_sum.

DATA:
  go_dash_cont TYPE REF TO cl_gui_custom_container,
  go_dash_html TYPE REF TO cl_gui_html_viewer,
  go_st22_cont TYPE REF TO cl_gui_custom_container,
  go_st22_alv  TYPE REF TO cl_gui_alv_grid,
  go_sm37_cont TYPE REF TO cl_gui_custom_container,
  go_sm37_alv  TYPE REF TO cl_gui_alv_grid,
  go_sxi_cont  TYPE REF TO cl_gui_custom_container,
  go_sxi_alv   TYPE REF TO cl_gui_alv_grid.

DATA:
  gv_sel_date TYPE sy-datum,
  gv_sel_time TYPE sy-uzeit,
  gv_sel_user TYPE syuname,
  gv_sel_job  TYPE tbtco-jobname,
  gv_sel_msg  TYPE symsgid.

SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-001.
SELECT-OPTIONS:
  s_date FOR gv_sel_date,
  s_time FOR gv_sel_time,
  s_user FOR gv_sel_user.
PARAMETERS:
  p_max  TYPE i DEFAULT 500,
  p_demo AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b01.

SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-002.
PARAMETERS:
  p_st22 AS CHECKBOX DEFAULT 'X',
  p_sm37 AS CHECKBOX DEFAULT 'X',
  p_sxi  AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b02.

SELECTION-SCREEN BEGIN OF BLOCK b03 WITH FRAME TITLE TEXT-003.
PARAMETERS:
  p_err  AS CHECKBOX DEFAULT 'X',
  p_warn AS CHECKBOX DEFAULT 'X',
  p_info AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK b03.

SELECTION-SCREEN BEGIN OF BLOCK b04 WITH FRAME TITLE TEXT-004.
SELECT-OPTIONS:
  s_job FOR gv_sel_job,
  s_msg FOR gv_sel_msg.
SELECTION-SCREEN END OF BLOCK b04.

INITIALIZATION.
  s_date-sign   = 'I'.
  s_date-option = 'BT'.
  s_date-low    = sy-datum.
  s_date-high   = sy-datum.
  APPEND s_date.

  s_time-sign   = 'I'.
  s_time-option = 'BT'.
  s_time-low    = '000000'.
  s_time-high   = '235959'.
  APPEND s_time.

AT SELECTION-SCREEN.
  PERFORM validate_selection.

START-OF-SELECTION.
  PERFORM check_authority.
  PERFORM collect_data.
  CALL SCREEN 0100.

*&---------------------------------------------------------------------*
*& Selection Screen 처리
*&---------------------------------------------------------------------*
FORM validate_selection.
  IF p_st22 IS INITIAL AND p_sm37 IS INITIAL AND p_sxi IS INITIAL.
    MESSAGE '최소 하나 이상의 오류 유형을 선택하세요.' TYPE 'E'.
  ENDIF.

  IF p_err IS INITIAL AND p_warn IS INITIAL AND p_info IS INITIAL.
    MESSAGE '최소 하나 이상의 심각도를 선택하세요.' TYPE 'E'.
  ENDIF.

  IF p_max <= 0.
    MESSAGE '최대 조회 건수는 1 이상이어야 합니다.' TYPE 'E'.
  ENDIF.
ENDFORM.

FORM check_authority.
  IF p_sm37 = abap_true.
    AUTHORITY-CHECK OBJECT 'S_BATCH_ADM'
      ID 'BTCADMIN' FIELD 'Y'.
    IF sy-subrc <> 0.
      MESSAGE 'SM37 배치잡 조회 권한(S_BATCH_ADM)을 확인하세요.' TYPE 'S' DISPLAY LIKE 'W'.
    ENDIF.
  ENDIF.

  " TODO: ST22/SXI 권한 오브젝트와 필드는 고객 시스템 보안 정책에 맞춰 확정하세요.
ENDFORM.

*&---------------------------------------------------------------------*
*& 데이터 수집
*&---------------------------------------------------------------------*
FORM collect_data.
  CLEAR:
    gt_st22,
    gt_sm37,
    gt_sxi.

  IF p_st22 = abap_true.
    PERFORM collect_st22.
  ENDIF.

  IF p_sm37 = abap_true.
    PERFORM collect_sm37.
  ENDIF.

  IF p_sxi = abap_true.
    PERFORM collect_sxi.
  ENDIF.
ENDFORM.

FORM collect_st22.
  " TODO: RS_ST22_API의 실제 인터페이스를 대상 S/4HANA 시스템에서 확인 후 연결하세요.
  " SNAP은 클러스터 성격과 릴리즈 차이가 있으므로 직접 SELECT를 기본 전략으로 두지 않습니다.

  IF p_demo = abap_true AND p_err = abap_true.
    APPEND VALUE ty_st22(
      occurred_on = sy-datum
      occurred_at = sy-uzeit
      severity    = gc_sev_error
      dump_id     = 'ASSERTION_FAILED'
      program     = 'ZFI_POSTING_BATCH'
      user_name   = sy-uname
      error_class = 'ABAP Runtime Error'
      message     = '전표 배치 처리 중 ASSERTION_FAILED 덤프 발생'
      detail      = 'ST22 탭에서 덤프 상세 트랜잭션 연계 검토 필요' ) TO gt_st22.
  ENDIF.

  IF p_demo = abap_true AND p_warn = abap_true.
    APPEND VALUE ty_st22(
      occurred_on = sy-datum
      occurred_at = sy-uzeit
      severity    = gc_sev_warn
      dump_id     = 'TIME_OUT'
      program     = 'ZMM_STOCK_SYNC'
      user_name   = sy-uname
      error_class = 'Performance'
      message     = '재고 동기화 프로그램 장시간 실행 감지'
      detail      = '선택 조건 축소 또는 배치 분할 검토' ) TO gt_st22.
  ENDIF.
ENDFORM.

FORM collect_sm37.
  DATA lt_status TYPE RANGE OF tbtco-status.
  DATA lt_jobs   TYPE STANDARD TABLE OF ty_tbtco.

  IF p_err = abap_true.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = 'A' ) TO lt_status.
  ENDIF.

  IF p_info = abap_true.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = 'F' ) TO lt_status.
  ENDIF.

  IF lt_status IS INITIAL.
    RETURN.
  ENDIF.

  SELECT jobname
         jobcount
         sdlstrtdt
         sdlstrttm
         enddate
         endtime
         status
         authcknam
    FROM tbtco
    INTO TABLE lt_jobs
    UP TO p_max ROWS
    WHERE jobname   IN s_job
      AND sdlstrtdt IN s_date
      AND sdlstrttm IN s_time
      AND status    IN lt_status
    ORDER BY sdlstrtdt DESCENDING sdlstrttm DESCENDING.

  LOOP AT lt_jobs INTO DATA(ls_job).
    IF s_user[] IS NOT INITIAL AND ls_job-authcknam NOT IN s_user.
      CONTINUE.
    ENDIF.

    DATA(lv_severity) = COND char10(
      WHEN ls_job-status = 'A' THEN gc_sev_error
      ELSE gc_sev_info ).

    IF lv_severity = gc_sev_error AND p_err IS INITIAL.
      CONTINUE.
    ENDIF.

    IF lv_severity = gc_sev_info AND p_info IS INITIAL.
      CONTINUE.
    ENDIF.

    APPEND VALUE ty_sm37(
      occurred_on = ls_job-sdlstrtdt
      occurred_at = ls_job-sdlstrttm
      severity    = lv_severity
      jobname     = ls_job-jobname
      jobcount    = ls_job-jobcount
      user_name   = ls_job-authcknam
      status      = ls_job-status
      message     = COND char120(
                      WHEN ls_job-status = 'A'
                      THEN '배치잡이 취소 상태로 종료되었습니다.'
                      ELSE '배치잡이 정상 종료되었습니다.' )
      detail      = |종료일시 { ls_job-enddate } { ls_job-endtime }| ) TO gt_sm37.
  ENDLOOP.

  IF gt_sm37 IS INITIAL AND p_demo = abap_true AND p_err = abap_true.
    APPEND VALUE ty_sm37(
      occurred_on = sy-datum
      occurred_at = sy-uzeit
      severity    = gc_sev_error
      jobname     = 'ZDEMO_FAILED_JOB'
      jobcount    = '00000001'
      user_name   = sy-uname
      status      = 'A'
      message     = '데모 배치잡 취소 건입니다.'
      detail      = '실제 TBTCO 조회 결과가 없을 때 화면 검증용으로 표시' ) TO gt_sm37.
  ENDIF.
ENDFORM.

FORM collect_sxi.
  " TODO: SXMB_GET_MESSAGE_LIST 또는 SXMSPMAST/SXMSPHDR 조회 방식을 대상 시스템에서 확정하세요.
  " SXI 시간 필드는 UTC 기준일 수 있으므로 최종 구현 시 사용자 로컬 시간 변환이 필요합니다.

  IF p_demo = abap_true AND p_err = abap_true.
    APPEND VALUE ty_sxi(
      occurred_on = sy-datum
      occurred_at = sy-uzeit
      severity    = gc_sev_error
      msg_id      = '005056AABBCC1EDFAABBCC000001'
      interface   = 'SI_VENDOR_INBOUND'
      sender      = 'ERP'
      receiver    = 'PI'
      status      = 'ERROR'
      message     = '벤더 마스터 인터페이스 메시지 오류'
      detail      = 'SXI_MONITOR 상세 메시지 연계 필요' ) TO gt_sxi.
  ENDIF.

  IF p_demo = abap_true AND p_warn = abap_true.
    APPEND VALUE ty_sxi(
      occurred_on = sy-datum
      occurred_at = sy-uzeit
      severity    = gc_sev_warn
      msg_id      = '005056AABBCC1EDFAABBCC000002'
      interface   = 'SI_STOCK_OUTBOUND'
      sender      = 'ERP'
      receiver    = 'MES'
      status      = 'RETRY'
      message     = '재처리 대기 중인 인터페이스 메시지'
      detail      = '재처리 횟수와 큐 상태 확인 필요' ) TO gt_sxi.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Screen 0100 PBO/PAI
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  SET TITLEBAR 'T01'.

  ts_main-activetab = gv_active_tab.

  CASE gv_active_tab.
    WHEN gc_tab_st22.
      gv_subscreen = '0120'.
    WHEN gc_tab_sm37.
      gv_subscreen = '0130'.
    WHEN gc_tab_sxi.
      gv_subscreen = '0140'.
    WHEN OTHERS.
      gv_subscreen = '0110'.
      gv_active_tab = gc_tab_sum.
  ENDCASE.
ENDMODULE.

MODULE user_command_0100 INPUT.
  gv_save_ok = gv_ok_code.
  CLEAR gv_ok_code.

  CASE gv_save_ok.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      PERFORM free_controls.
      LEAVE TO SCREEN 0.
    WHEN gc_tab_sum.
      gv_active_tab = gc_tab_sum.
    WHEN gc_tab_st22.
      gv_active_tab = gc_tab_st22.
    WHEN gc_tab_sm37.
      gv_active_tab = gc_tab_sm37.
    WHEN gc_tab_sxi.
      gv_active_tab = gc_tab_sxi.
  ENDCASE.
ENDMODULE.

MODULE init_0110 OUTPUT.
  PERFORM display_dashboard.
ENDMODULE.

MODULE init_0120 OUTPUT.
  PERFORM display_st22.
ENDMODULE.

MODULE init_0130 OUTPUT.
  PERFORM display_sm37.
ENDMODULE.

MODULE init_0140 OUTPUT.
  PERFORM display_sxi.
ENDMODULE.

*&---------------------------------------------------------------------*
*& 대시보드 HTML 출력
*&---------------------------------------------------------------------*
FORM display_dashboard.
  IF go_dash_cont IS INITIAL.
    CREATE OBJECT go_dash_cont
      EXPORTING
        container_name = 'CC_DASH_HTML'.

    CREATE OBJECT go_dash_html
      EXPORTING
        parent = go_dash_cont.
  ENDIF.

  DATA lt_html TYPE w3htmltab.
  DATA lv_url  TYPE c LENGTH 255.

  PERFORM build_dashboard_html CHANGING lt_html.

  go_dash_html->load_data(
    EXPORTING
      type         = 'text'
      subtype      = 'html'
    IMPORTING
      assigned_url = lv_url
    CHANGING
      data_table   = lt_html ).

  go_dash_html->show_url( url = lv_url ).
ENDFORM.

FORM build_dashboard_html CHANGING ct_html TYPE w3htmltab.
  DATA(lv_st22)  = lines( gt_st22 ).
  DATA(lv_sm37)  = lines( gt_sm37 ).
  DATA(lv_sxi)   = lines( gt_sxi ).
  DATA(lv_total) = lv_st22 + lv_sm37 + lv_sxi.

  DATA(lv_error) = 0.
  DATA(lv_warn)  = 0.
  DATA(lv_info)  = 0.

  PERFORM count_severity USING gc_sev_error CHANGING lv_error.
  PERFORM count_severity USING gc_sev_warn  CHANGING lv_warn.
  PERFORM count_severity USING gc_sev_info  CHANGING lv_info.

  DATA(lv_base) = COND i( WHEN lv_total = 0 THEN 1 ELSE lv_total ).
  DATA(lv_st22_pct) = lv_st22 * 100 / lv_base.
  DATA(lv_sm37_pct) = lv_sm37 * 100 / lv_base.
  DATA(lv_sxi_pct)  = lv_sxi  * 100 / lv_base.

  PERFORM append_html USING '<html><head><meta charset="utf-8">' CHANGING ct_html.
  PERFORM append_html USING '<style>' CHANGING ct_html.
  PERFORM append_html USING 'body{font-family:Arial,sans-serif;background:#f5f7fa;color:#1f2d3d;margin:0;padding:16px;}' CHANGING ct_html.
  PERFORM append_html USING '.title{font-size:22px;font-weight:bold;margin-bottom:12px;}' CHANGING ct_html.
  PERFORM append_html USING '.kpis{display:flex;gap:12px;margin-bottom:18px;}' CHANGING ct_html.
  PERFORM append_html USING '.kpi{background:white;border-radius:8px;padding:14px 18px;box-shadow:0 1px 4px #ccd;min-width:140px;}' CHANGING ct_html.
  PERFORM append_html USING '.kpi .label{font-size:12px;color:#637381;}.kpi .value{font-size:28px;font-weight:bold;margin-top:4px;}' CHANGING ct_html.
  PERFORM append_html USING '.grid{display:grid;grid-template-columns:1fr 1fr;gap:14px;}' CHANGING ct_html.
  PERFORM append_html USING '.card{background:white;border-radius:8px;padding:16px;box-shadow:0 1px 4px #ccd;}' CHANGING ct_html.
  PERFORM append_html USING '.barbox{margin:10px 0;}.barlabel{display:flex;justify-content:space-between;font-size:13px;}' CHANGING ct_html.
  PERFORM append_html USING '.bar{height:14px;background:#e6edf5;border-radius:7px;overflow:hidden;}.bar span{display:block;height:14px;background:#2f7ed8;}' CHANGING ct_html.
  PERFORM append_html USING '.sev{display:flex;gap:10px;margin-top:12px;}.pill{padding:8px 12px;border-radius:20px;color:white;font-weight:bold;}' CHANGING ct_html.
  PERFORM append_html USING '.err{background:#d93025;}.warn{background:#f9ab00;}.info{background:#188038;}' CHANGING ct_html.
  PERFORM append_html USING '</style></head><body>' CHANGING ct_html.
  PERFORM append_html USING '<div class="title">Z 통합 에러 모니터링 대시보드</div>' CHANGING ct_html.

  PERFORM append_html USING '<div class="kpis">' CHANGING ct_html.
  PERFORM append_html USING |<div class="kpi"><div class="label">전체 건수</div><div class="value">{ lv_total }</div></div>| CHANGING ct_html.
  PERFORM append_html USING |<div class="kpi"><div class="label">ST22 덤프</div><div class="value">{ lv_st22 }</div></div>| CHANGING ct_html.
  PERFORM append_html USING |<div class="kpi"><div class="label">SM37 배치잡</div><div class="value">{ lv_sm37 }</div></div>| CHANGING ct_html.
  PERFORM append_html USING |<div class="kpi"><div class="label">SXI 메시지</div><div class="value">{ lv_sxi }</div></div>| CHANGING ct_html.
  PERFORM append_html USING |<div class="kpi"><div class="label">Critical</div><div class="value">{ lv_error }</div></div>| CHANGING ct_html.
  PERFORM append_html USING '</div>' CHANGING ct_html.

  PERFORM append_html USING '<div class="grid">' CHANGING ct_html.
  PERFORM append_html USING '<div class="card"><h3>트랜잭션별 오류 분포</h3>' CHANGING ct_html.
  PERFORM append_html USING |<div class="barbox"><div class="barlabel"><span>ST22</span><span>{ lv_st22 }</span></div><div class="bar"><span style="width:{ lv_st22_pct }%"></span></div></div>| CHANGING ct_html.
  PERFORM append_html USING |<div class="barbox"><div class="barlabel"><span>SM37</span><span>{ lv_sm37 }</span></div><div class="bar"><span style="width:{ lv_sm37_pct }%"></span></div></div>| CHANGING ct_html.
  PERFORM append_html USING |<div class="barbox"><div class="barlabel"><span>SXI</span><span>{ lv_sxi }</span></div><div class="bar"><span style="width:{ lv_sxi_pct }%"></span></div></div>| CHANGING ct_html.
  PERFORM append_html USING '</div>' CHANGING ct_html.

  PERFORM append_html USING '<div class="card"><h3>심각도 요약</h3><div class="sev">' CHANGING ct_html.
  PERFORM append_html USING |<div class="pill err">ERROR { lv_error }</div>| CHANGING ct_html.
  PERFORM append_html USING |<div class="pill warn">WARNING { lv_warn }</div>| CHANGING ct_html.
  PERFORM append_html USING |<div class="pill info">INFO { lv_info }</div>| CHANGING ct_html.
  PERFORM append_html USING '</div><p>상세 내역은 ST22 / SM37 / SXI 탭에서 확인하세요.</p></div>' CHANGING ct_html.
  PERFORM append_html USING '</div></body></html>' CHANGING ct_html.
ENDFORM.

FORM append_html USING iv_line TYPE string CHANGING ct_html TYPE w3htmltab.
  APPEND VALUE #( line = iv_line ) TO ct_html.
ENDFORM.

FORM count_severity USING iv_severity TYPE char10 CHANGING cv_count TYPE i.
  CLEAR cv_count.

  LOOP AT gt_st22 INTO DATA(ls_st22) WHERE severity = iv_severity.
    cv_count = cv_count + 1.
  ENDLOOP.

  LOOP AT gt_sm37 INTO DATA(ls_sm37) WHERE severity = iv_severity.
    cv_count = cv_count + 1.
  ENDLOOP.

  LOOP AT gt_sxi INTO DATA(ls_sxi) WHERE severity = iv_severity.
    cv_count = cv_count + 1.
  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& ALV 출력
*&---------------------------------------------------------------------*
FORM display_st22.
  DATA lt_fcat   TYPE lvc_t_fcat.
  DATA ls_layout TYPE lvc_s_layo.

  IF go_st22_cont IS INITIAL.
    CREATE OBJECT go_st22_cont
      EXPORTING
        container_name = 'CC_ST22_ALV'.

    CREATE OBJECT go_st22_alv
      EXPORTING
        i_parent = go_st22_cont.

    PERFORM build_st22_fcat CHANGING lt_fcat.
    ls_layout-zebra      = abap_true.
    ls_layout-cwidth_opt = abap_true.

    go_st22_alv->set_table_for_first_display(
      EXPORTING
        is_layout       = ls_layout
      CHANGING
        it_outtab       = gt_st22
        it_fieldcatalog = lt_fcat ).
  ELSE.
    go_st22_alv->refresh_table_display( ).
  ENDIF.
ENDFORM.

FORM display_sm37.
  DATA lt_fcat   TYPE lvc_t_fcat.
  DATA ls_layout TYPE lvc_s_layo.

  IF go_sm37_cont IS INITIAL.
    CREATE OBJECT go_sm37_cont
      EXPORTING
        container_name = 'CC_SM37_ALV'.

    CREATE OBJECT go_sm37_alv
      EXPORTING
        i_parent = go_sm37_cont.

    PERFORM build_sm37_fcat CHANGING lt_fcat.
    ls_layout-zebra      = abap_true.
    ls_layout-cwidth_opt = abap_true.

    go_sm37_alv->set_table_for_first_display(
      EXPORTING
        is_layout       = ls_layout
      CHANGING
        it_outtab       = gt_sm37
        it_fieldcatalog = lt_fcat ).
  ELSE.
    go_sm37_alv->refresh_table_display( ).
  ENDIF.
ENDFORM.

FORM display_sxi.
  DATA lt_fcat   TYPE lvc_t_fcat.
  DATA ls_layout TYPE lvc_s_layo.

  IF go_sxi_cont IS INITIAL.
    CREATE OBJECT go_sxi_cont
      EXPORTING
        container_name = 'CC_SXI_ALV'.

    CREATE OBJECT go_sxi_alv
      EXPORTING
        i_parent = go_sxi_cont.

    PERFORM build_sxi_fcat CHANGING lt_fcat.
    ls_layout-zebra      = abap_true.
    ls_layout-cwidth_opt = abap_true.

    go_sxi_alv->set_table_for_first_display(
      EXPORTING
        is_layout       = ls_layout
      CHANGING
        it_outtab       = gt_sxi
        it_fieldcatalog = lt_fcat ).
  ELSE.
    go_sxi_alv->refresh_table_display( ).
  ENDIF.
ENDFORM.

FORM build_st22_fcat CHANGING ct_fcat TYPE lvc_t_fcat.
  PERFORM add_fcat USING 'OCCURRED_ON' '발생일'       10 CHANGING ct_fcat.
  PERFORM add_fcat USING 'OCCURRED_AT' '발생시간'     10 CHANGING ct_fcat.
  PERFORM add_fcat USING 'SEVERITY'    '심각도'       10 CHANGING ct_fcat.
  PERFORM add_fcat USING 'DUMP_ID'     '덤프 ID'      24 CHANGING ct_fcat.
  PERFORM add_fcat USING 'PROGRAM'     '프로그램'     30 CHANGING ct_fcat.
  PERFORM add_fcat USING 'USER_NAME'   '사용자'       12 CHANGING ct_fcat.
  PERFORM add_fcat USING 'ERROR_CLASS' '오류 분류'    20 CHANGING ct_fcat.
  PERFORM add_fcat USING 'MESSAGE'     '메시지 요약'  60 CHANGING ct_fcat.
  PERFORM add_fcat USING 'DETAIL'      '상세'         60 CHANGING ct_fcat.
ENDFORM.

FORM build_sm37_fcat CHANGING ct_fcat TYPE lvc_t_fcat.
  PERFORM add_fcat USING 'OCCURRED_ON' '시작일'       10 CHANGING ct_fcat.
  PERFORM add_fcat USING 'OCCURRED_AT' '시작시간'     10 CHANGING ct_fcat.
  PERFORM add_fcat USING 'SEVERITY'    '심각도'       10 CHANGING ct_fcat.
  PERFORM add_fcat USING 'JOBNAME'     '잡 이름'      32 CHANGING ct_fcat.
  PERFORM add_fcat USING 'JOBCOUNT'    '잡 번호'      12 CHANGING ct_fcat.
  PERFORM add_fcat USING 'USER_NAME'   '사용자'       12 CHANGING ct_fcat.
  PERFORM add_fcat USING 'STATUS'      '상태'         8  CHANGING ct_fcat.
  PERFORM add_fcat USING 'MESSAGE'     '메시지 요약'  60 CHANGING ct_fcat.
  PERFORM add_fcat USING 'DETAIL'      '상세'         60 CHANGING ct_fcat.
ENDFORM.

FORM build_sxi_fcat CHANGING ct_fcat TYPE lvc_t_fcat.
  PERFORM add_fcat USING 'OCCURRED_ON' '발생일'       10 CHANGING ct_fcat.
  PERFORM add_fcat USING 'OCCURRED_AT' '발생시간'     10 CHANGING ct_fcat.
  PERFORM add_fcat USING 'SEVERITY'    '심각도'       10 CHANGING ct_fcat.
  PERFORM add_fcat USING 'MSG_ID'      '메시지 ID'    30 CHANGING ct_fcat.
  PERFORM add_fcat USING 'INTERFACE'   '인터페이스'   30 CHANGING ct_fcat.
  PERFORM add_fcat USING 'SENDER'      '송신자'       20 CHANGING ct_fcat.
  PERFORM add_fcat USING 'RECEIVER'    '수신자'       20 CHANGING ct_fcat.
  PERFORM add_fcat USING 'STATUS'      '상태'         12 CHANGING ct_fcat.
  PERFORM add_fcat USING 'MESSAGE'     '메시지 요약'  60 CHANGING ct_fcat.
  PERFORM add_fcat USING 'DETAIL'      '상세'         60 CHANGING ct_fcat.
ENDFORM.

FORM add_fcat
  USING
    iv_fieldname TYPE lvc_fname
    iv_coltext   TYPE lvc_txtcol
    iv_outputlen TYPE i
  CHANGING
    ct_fcat      TYPE lvc_t_fcat.

  APPEND VALUE lvc_s_fcat(
    fieldname = iv_fieldname
    coltext   = iv_coltext
    outputlen = iv_outputlen ) TO ct_fcat.
ENDFORM.

FORM free_controls.
  IF go_st22_alv IS BOUND.
    go_st22_alv->free( ).
  ENDIF.

  IF go_sm37_alv IS BOUND.
    go_sm37_alv->free( ).
  ENDIF.

  IF go_sxi_alv IS BOUND.
    go_sxi_alv->free( ).
  ENDIF.

  IF go_dash_html IS BOUND.
    go_dash_html->free( ).
  ENDIF.

  FREE:
    go_dash_html,
    go_dash_cont,
    go_st22_alv,
    go_st22_cont,
    go_sm37_alv,
    go_sm37_cont,
    go_sxi_alv,
    go_sxi_cont.
ENDFORM.
