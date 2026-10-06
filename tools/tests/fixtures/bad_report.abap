REPORT ztest_bad.

SELECT-OPTIONS s_erdat FOR vbak-erdat.

START-OF-SELECTION.
  SELECT * FROM vbak INTO TABLE @DATA(lt_head)
    WHERE vkorg = '1000'.

  LOOP AT lt_head INTO DATA(ls_head).
    SELECT SINGLE netwr FROM vbap INTO @DATA(lv_netwr)
      WHERE vbeln = @ls_head-vbeln.
  ENDLOOP.

  SELECT vbeln FROM vbap
    INTO TABLE @DATA(lt_item)
    FOR ALL ENTRIES IN lt_head
    WHERE vbeln = @lt_head-vbeln.

  AUTHORITY-CHECK OBJECT 'V_VBAK_VKO'
    ID 'VKORG' FIELD '1000'
    ID 'ACTVT' FIELD '03'.

  COMMIT WORK.
  MESSAGE s001(zsd_msg).
  " 이하 동일
