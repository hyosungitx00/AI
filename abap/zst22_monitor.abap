REPORT zst22_monitor.

*-----------------------------------------------------------------------
* ST22 short dump monitor
*
* Reads the ST22 overview data from projection view SNAP_BEG for a recent
* time window, displays the result as ALV, and optionally sends an e-mail
* alert when dumps are found. Schedule this report as a periodic background
* job for continuous monitoring.
*-----------------------------------------------------------------------

TABLES snap_beg.

CONSTANTS:
  c_seqno_first TYPE snap_beg-seqno VALUE '000',
  c_true        TYPE c LENGTH 1 VALUE 'X'.

TYPES:
  BEGIN OF ty_dump,
    datum   TYPE snap_beg-datum,
    uzeit   TYPE snap_beg-uzeit,
    ahost   TYPE snap_beg-ahost,
    uname   TYPE snap_beg-uname,
    mandt   TYPE snap_beg-mandt,
    modno   TYPE snap_beg-modno,
    seqno   TYPE snap_beg-seqno,
    xhold   TYPE snap_beg-xhold,
    flist   TYPE snap_beg-flist,
    flist02 TYPE snap_beg-flist02,
    flist03 TYPE snap_beg-flist03,
    flist04 TYPE snap_beg-flist04,
    flist05 TYPE snap_beg-flist05,
    flist06 TYPE snap_beg-flist06,
    flist07 TYPE snap_beg-flist07,
    flist08 TYPE snap_beg-flist08,
  END OF ty_dump,
  tt_dump TYPE STANDARD TABLE OF ty_dump WITH DEFAULT KEY.

TYPES:
  BEGIN OF ty_monitor,
    datum         TYPE snap_beg-datum,
    uzeit         TYPE snap_beg-uzeit,
    mandt         TYPE snap_beg-mandt,
    uname         TYPE snap_beg-uname,
    ahost         TYPE snap_beg-ahost,
    modno         TYPE snap_beg-modno,
    xhold         TYPE snap_beg-xhold,
    runtime_error TYPE string,
    raw_text      TYPE string,
  END OF ty_monitor,
  tt_monitor TYPE STANDARD TABLE OF ty_monitor WITH DEFAULT KEY.

DATA:
  gt_dump      TYPE tt_dump,
  gt_monitor   TYPE tt_monitor,
  gv_from_date TYPE sy-datum,
  gv_from_time TYPE sy-uzeit.

SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME.
PARAMETERS:
  p_mins TYPE i DEFAULT 60 OBLIGATORY.

SELECT-OPTIONS:
  s_mandt FOR snap_beg-mandt DEFAULT sy-mandt,
  s_uname FOR snap_beg-uname,
  s_ahost FOR snap_beg-ahost,
  s_xhold FOR snap_beg-xhold.
SELECTION-SCREEN END OF BLOCK b01.

SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME.
PARAMETERS:
  p_mail AS CHECKBOX DEFAULT space,
  p_rec  TYPE ad_smtpadr LOWER CASE,
  p_subj TYPE so_obj_des DEFAULT 'ST22 Short Dump Alert'.
SELECTION-SCREEN END OF BLOCK b02.

AT SELECTION-SCREEN.
  IF p_mins LE 0.
    MESSAGE 'Monitoring interval must be greater than zero.' TYPE 'E'.
  ENDIF.

  IF p_mail = c_true AND p_rec IS INITIAL.
    MESSAGE 'Enter an e-mail recipient when e-mail alert is selected.' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  PERFORM calculate_start_time
    USING    p_mins
    CHANGING gv_from_date
             gv_from_time.

  PERFORM read_short_dumps.
  PERFORM build_monitor_table.

  IF p_mail = c_true AND gt_monitor IS NOT INITIAL.
    PERFORM send_alert_mail.
  ENDIF.

  PERFORM display_result.

FORM calculate_start_time
  USING    iv_minutes TYPE i
  CHANGING cv_date    TYPE sy-datum
           cv_time    TYPE sy-uzeit.

  DATA:
    lv_now      TYPE timestampl,
    lv_from     TYPE timestampl,
    lv_seconds  TYPE i,
    lv_timezone TYPE timezone.

  lv_timezone = sy-zonlo.
  IF lv_timezone IS INITIAL.
    lv_timezone = 'UTC'.
  ENDIF.

  CONVERT DATE sy-datum TIME sy-uzeit
    INTO TIME STAMP lv_now
    TIME ZONE lv_timezone.

  lv_seconds = iv_minutes * 60.

  lv_from = cl_abap_tstmp=>subtractsecs(
              tstmp = lv_now
              secs  = lv_seconds ).

  CONVERT TIME STAMP lv_from
    TIME ZONE lv_timezone
    INTO DATE cv_date TIME cv_time.

ENDFORM.

FORM read_short_dumps.

  CLEAR gt_dump.

  SELECT datum
         uzeit
         ahost
         uname
         mandt
         modno
         seqno
         xhold
         flist
         flist02
         flist03
         flist04
         flist05
         flist06
         flist07
         flist08
    FROM snap_beg
    INTO TABLE gt_dump
    WHERE seqno = c_seqno_first
      AND mandt IN s_mandt
      AND uname IN s_uname
      AND ahost IN s_ahost
      AND xhold IN s_xhold
      AND ( datum > gv_from_date
         OR ( datum = gv_from_date AND uzeit >= gv_from_time ) )
    ORDER BY datum DESCENDING uzeit DESCENDING.

ENDFORM.

FORM build_monitor_table.

  DATA:
    ls_dump    TYPE ty_dump,
    ls_monitor TYPE ty_monitor,
    lv_text    TYPE string.

  CLEAR gt_monitor.

  LOOP AT gt_dump INTO ls_dump.
    CLEAR: ls_monitor, lv_text.

    CONCATENATE ls_dump-flist
                ls_dump-flist02
                ls_dump-flist03
                ls_dump-flist04
                ls_dump-flist05
                ls_dump-flist06
                ls_dump-flist07
                ls_dump-flist08
           INTO lv_text
           SEPARATED BY space.
    CONDENSE lv_text.

    ls_monitor-datum = ls_dump-datum.
    ls_monitor-uzeit = ls_dump-uzeit.
    ls_monitor-mandt = ls_dump-mandt.
    ls_monitor-uname = ls_dump-uname.
    ls_monitor-ahost = ls_dump-ahost.
    ls_monitor-modno = ls_dump-modno.
    ls_monitor-xhold = ls_dump-xhold.
    ls_monitor-raw_text = lv_text.

    PERFORM shorten_text
      USING    lv_text
               120
      CHANGING ls_monitor-runtime_error.

    APPEND ls_monitor TO gt_monitor.
  ENDLOOP.

ENDFORM.

FORM shorten_text
  USING    iv_text TYPE string
           iv_len  TYPE i
  CHANGING cv_text TYPE string.

  cv_text = iv_text.

  IF strlen( cv_text ) > iv_len.
    cv_text = cv_text(iv_len).
  ENDIF.

ENDFORM.

FORM send_alert_mail.

  DATA:
    lo_send_request TYPE REF TO cl_bcs,
    lo_document     TYPE REF TO cl_document_bcs,
    lo_recipient    TYPE REF TO if_recipient_bcs,
    lx_bcs          TYPE REF TO cx_bcs,
    lt_text         TYPE bcsy_text,
    ls_monitor      TYPE ty_monitor,
    lv_line         TYPE string,
    lv_count        TYPE i,
    lv_sent         TYPE os_boolean.

  DESCRIBE TABLE gt_monitor LINES lv_count.

  PERFORM append_mail_line USING p_subj CHANGING lt_text.
  PERFORM append_mail_line USING '' CHANGING lt_text.

  CONCATENATE 'Period start:'
              gv_from_date
              gv_from_time
         INTO lv_line
         SEPARATED BY space.
  PERFORM append_mail_line USING lv_line CHANGING lt_text.

  CONCATENATE 'Detected ST22 short dumps:'
              lv_count
         INTO lv_line
         SEPARATED BY space.
  PERFORM append_mail_line USING lv_line CHANGING lt_text.
  PERFORM append_mail_line USING '' CHANGING lt_text.

  LOOP AT gt_monitor INTO ls_monitor.
    CONCATENATE ls_monitor-datum
                ls_monitor-uzeit
                'Client'
                ls_monitor-mandt
                'User'
                ls_monitor-uname
                'Host'
                ls_monitor-ahost
                ls_monitor-runtime_error
           INTO lv_line
           SEPARATED BY space.
    PERFORM append_mail_line USING lv_line CHANGING lt_text.
  ENDLOOP.

  TRY.
      lo_send_request = cl_bcs=>create_persistent( ).

      lo_document = cl_document_bcs=>create_document(
                      i_type    = 'RAW'
                      i_text    = lt_text
                      i_subject = p_subj ).

      lo_send_request->set_document( lo_document ).

      lo_recipient = cl_cam_address_bcs=>create_internet_address( p_rec ).
      lo_send_request->add_recipient( lo_recipient ).

      lv_sent = lo_send_request->send( i_with_error_screen = c_true ).
      COMMIT WORK.

      IF lv_sent = c_true.
        WRITE: / 'Alert e-mail was sent to', p_rec.
      ELSE.
        WRITE: / 'Alert e-mail was not accepted by SAPconnect.'.
      ENDIF.

    CATCH cx_bcs INTO lx_bcs.
      WRITE: / 'E-mail alert failed:', lx_bcs->get_text( ).
  ENDTRY.

ENDFORM.

FORM append_mail_line
  USING    iv_line TYPE string
  CHANGING ct_text TYPE bcsy_text.

  DATA:
    ls_text TYPE soli,
    lv_line TYPE string.

  lv_line = iv_line.

  WHILE strlen( lv_line ) > 255.
    CLEAR ls_text.
    ls_text-line = lv_line(255).
    APPEND ls_text TO ct_text.
    SHIFT lv_line LEFT BY 255 PLACES.
  ENDWHILE.

  CLEAR ls_text.
  ls_text-line = lv_line.
  APPEND ls_text TO ct_text.

ENDFORM.

FORM display_result.

  DATA:
    lo_alv     TYPE REF TO cl_salv_table,
    lx_salv    TYPE REF TO cx_salv_msg,
    ls_monitor TYPE ty_monitor,
    lv_header  TYPE lvc_title,
    lv_count   TYPE i,
    lv_count_c TYPE c LENGTH 10.

  DESCRIBE TABLE gt_monitor LINES lv_count.

  IF gt_monitor IS INITIAL.
    WRITE: / 'No ST22 short dumps found since',
             gv_from_date,
             gv_from_time.
    RETURN.
  ENDIF.

  lv_count_c = lv_count.
  CONDENSE lv_count_c.
  CONCATENATE 'ST22 short dumps found:'
              lv_count_c
         INTO lv_header
         SEPARATED BY space.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_alv
        CHANGING  t_table      = gt_monitor ).

      lo_alv->get_functions( )->set_all( c_true ).
      lo_alv->get_display_settings( )->set_list_header( lv_header ).
      lo_alv->get_columns( )->set_optimize( c_true ).
      lo_alv->display( ).

    CATCH cx_salv_msg INTO lx_salv.
      WRITE: / lv_header.
      WRITE: / lx_salv->get_text( ).
      ULINE.

      LOOP AT gt_monitor INTO ls_monitor.
        WRITE: / ls_monitor-datum,
                 ls_monitor-uzeit,
                 ls_monitor-mandt,
                 ls_monitor-uname,
                 ls_monitor-ahost,
                 ls_monitor-runtime_error.
      ENDLOOP.
  ENDTRY.

ENDFORM.
