*&---------------------------------------------------------------------*
*& Function Module Z_SD_SAMPLE_GET (함수그룹 / Function group ZFGSD01)
*&---------------------------------------------------------------------*
*& [템플릿] Function Module 골격 — 조회·집계 재사용 로직
*&      / [Template] Function Module skeleton for reusable read logic
*& 기준: SAP_BASIS 750 / S/4HANA, 모던 ABAP 허용
*&      / Baseline: SAP_BASIS 750 / S/4HANA, modern ABAP allowed
*&
*& 사용법 / How to use:
*&   아래 Local Interface 블록은 SE37 Import/Export/Tables/Exceptions 탭 입력값과
*&   1:1로 일치해야 한다. 탭에 먼저 등록한 뒤 소스를 붙여넣는다.
*&   / Register the interface on the SE37 tabs first, then paste the source.
*&
*& 복사 순서 / Copy order:
*&   ① SE11 — 구조 ZSSD_SAMPLE_S01 생성 (아래 DDIC 정의서 참조)
*&   ② SE37 — 함수그룹 ZFGSD01 생성(없으면) → 함수 Z_SD_SAMPLE_GET 생성
*&   ③ Import/Export/Tables/Exceptions 탭을 아래 파라미터표대로 등록
*&   ④ 본 소스 붙여넣기 → Ctrl+F2 → SE37 단위 테스트(F8)
*&---------------------------------------------------------------------*
FUNCTION z_sd_sample_get.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(iv_vkorg) TYPE  vbak-vkorg
*"     VALUE(iv_date_from) TYPE  datum OPTIONAL
*"     VALUE(iv_date_to) TYPE  datum OPTIONAL
*"  EXPORTING
*"     VALUE(ev_total) TYPE  vbap-netwr
*"     VALUE(ev_rows) TYPE  i
*"  TABLES
*"      et_items STRUCTURE  zssd_sample_s01
*"  EXCEPTIONS
*"      invalid_input
*"      no_auth
*"      no_data
*"----------------------------------------------------------------------

  CONSTANTS lc_actvt_display TYPE c LENGTH 2 VALUE '03'.

  DATA lt_head TYPE STANDARD TABLE OF vbak-vbeln.

  CLEAR: ev_total, ev_rows, et_items[].

  "! 입력 검증 / Input validation (FM은 선택화면이 없으므로 코드에서 막는다)
  IF iv_vkorg IS INITIAL.
    RAISE invalid_input.
  ENDIF.
  IF iv_date_from IS NOT INITIAL AND iv_date_to IS NOT INITIAL
     AND iv_date_from > iv_date_to.
    RAISE invalid_input.
  ENDIF.

  "! 권한 체크 / Authority check
  " TODO(교체): SU53 TRACE로 실제 권한 오브젝트 확인 / Confirm the object via SU53
  AUTHORITY-CHECK OBJECT 'V_VBAK_VKO'
    ID 'VKORG' FIELD iv_vkorg
    ID 'ACTVT' FIELD lc_actvt_display.
  IF sy-subrc <> 0.
    RAISE no_auth.
  ENDIF.

  "! 1차 조회 — 헤더 키 / Step 1: header keys
  " TODO(교체): 테이블·WHERE를 승인된 스펙대로 교체 / Replace per the approved spec
  SELECT vbeln
    INTO TABLE @lt_head
    FROM vbak
    WHERE vkorg = @iv_vkorg
      AND erdat BETWEEN @iv_date_from AND @iv_date_to.
  IF sy-subrc <> 0.
    RAISE no_data.
  ENDIF.

  "! 2차 조회 — FOR ALL ENTRIES 앞 빈 테이블 체크 필수
  "! / Step 2: FOR ALL ENTRIES requires a non-initial driver table
  IF lt_head IS NOT INITIAL.
    SELECT b~vbeln, a~erdat, a~kunnr, b~netwr, a~waerk
      INTO CORRESPONDING FIELDS OF TABLE @et_items
      FROM vbak AS a
      INNER JOIN vbap AS b ON a~vbeln = b~vbeln
      FOR ALL ENTRIES IN @lt_head
      WHERE a~vbeln = @lt_head-table_line.
    IF sy-subrc <> 0.
      RAISE no_data.
    ENDIF.
  ENDIF.

  "! 집계 / Aggregation
  LOOP AT et_items ASSIGNING FIELD-SYMBOL(<ls_item>).
    ev_total = ev_total + <ls_item>-netwr.
  ENDLOOP.
  ev_rows = lines( et_items ).

ENDFUNCTION.

"!----------------------------------------------------------------------
"! 파라미터표 (SE37 탭 등록값) / Parameter table — TODO(교체)
"! IMPORTING  IV_VKORG     VBAK-VKORG   필수 / mandatory
"! IMPORTING  IV_DATE_FROM DATUM        선택 / optional
"! IMPORTING  IV_DATE_TO   DATUM        선택 / optional
"! EXPORTING  EV_TOTAL     VBAP-NETWR   합계 / total
"! EXPORTING  EV_ROWS      I            건수 / row count
"! TABLES     ET_ITEMS     ZSSD_SAMPLE_S01
"! EXCEPTIONS INVALID_INPUT(1) NO_AUTH(2) NO_DATA(3)
"!----------------------------------------------------------------------
"! DDIC 정의서 — 구조 ZSSD_SAMPLE_S01 (SE11, Structure) / DDIC appendix
"! VBELN (VBAK-VBELN, CHAR 10), ERDAT (VBAK-ERDAT, DATS 8),
"! KUNNR (VBAK-KUNNR, CHAR 10), NETWR (VBAP-NETWR, CURR 15,2),
"! WAERK (VBAK-WAERK, CUKY 5)
"!----------------------------------------------------------------------
"! SE37 테스트 절차 / Unit test (SE37 → F8)
"! T1: 대표 입력 → SY-SUBRC=0, ET_ITEMS 다건, EV_TOTAL·EV_ROWS 확인
"! T2: 결과 0건 입력 → NO_DATA / empty result → NO_DATA
"! T3: 미입력 또는 권한 없는 유저 → INVALID_INPUT / NO_AUTH
"! 오류 회수: 함수명 + 입력값(T1/T2/T3) + SY-SUBRC + ST22 덤프명 + 메시지 전문
"!----------------------------------------------------------------------
