*&---------------------------------------------------------------------*
*& Report ZSD_SALES_ALV01
*&---------------------------------------------------------------------*
*& 판매조직별 판매실적 ALV (샘플) / Sample ALV by sales org
*& 기준: SAP_BASIS 750 / S/4HANA, 모던 ABAP 허용
*&      / Baseline: SAP_BASIS 750 / S/4HANA, modern ABAP allowed
*& 패키지 / Package: ZSD01, 메시지 클래스 / Message class: ZSD_MSG(SE91 별도 생성)
*& 복사 순서 / Copy order:
*&   ① SE91 — 메시지 클래스 ZSD_MSG 001/002 등록 (아래 메시지 정의서 참조)
*&   ② SE38 — 프로그램 ZSD_SALES_ALV01 생성 (Type=Executable), 본 파일 전체 붙여넣기
*&   ③ Ctrl+F2 Syntax Check → Extended Check → F8 실행
*&---------------------------------------------------------------------*
REPORT zsd_sales_alv01 NO STANDARD PAGE HEADING
  LINE-SIZE 220 LINE-COUNT 65.

"! 타입 정의 / Type definitions
TYPES: BEGIN OF ty_sales,
         vbeln TYPE vbak-vbeln,
         erdat TYPE vbak-erdat,
         kunnr TYPE vbak-kunnr,
         name1 TYPE kna1-name1,
         netwr TYPE vbap-netwr,
         waerk TYPE vbak-waerk,
       END OF ty_sales.

DATA gt_sales TYPE STANDARD TABLE OF ty_sales.

"! 선택화면 / Selection screen
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS p_vkorg TYPE vbak-vkorg OBLIGATORY DEFAULT '1000'.
  SELECT-OPTIONS s_erdat FOR vbak-erdat DEFAULT '20240101' TO '20241231'.
SELECTION-SCREEN END OF BLOCK b1.

START-OF-SELECTION.
  PERFORM frm_get_data.
  PERFORM frm_show_alv.

*&---------------------------------------------------------------------*
*& Form FRM_GET_DATA — 데이터 조회 / Data selection
*&---------------------------------------------------------------------*
FORM frm_get_data.
  "! 판매문서 조회 / Select sales documents
  SELECT a~vbeln, a~erdat, a~kunnr, c~name1, b~netwr, a~waerk
    INTO TABLE @gt_sales
    FROM vbak AS a
    INNER JOIN vbap AS b ON a~vbeln = b~vbeln
    LEFT OUTER JOIN kna1 AS c ON a~kunnr = c~kunnr
    WHERE a~vkorg = @p_vkorg
      AND a~erdat IN @s_erdat.

  IF sy-subrc <> 0.
    MESSAGE s001(zsd_msg) DISPLAY LIKE 'S'.
    " TODO(GUI): SE91 ZSD_MSG 001 = '조건에 맞는 데이터가 없습니다. / No data found.'
    RETURN.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form FRM_SHOW_ALV — ALV 표시 / ALV display
*&---------------------------------------------------------------------*
FORM frm_show_alv.
  DATA lo_salv TYPE REF TO cl_salv_table.
  DATA lx_msg  TYPE REF TO cx_salv_msg.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_salv
        CHANGING  t_table      = gt_sales ).
      lo_salv->get_functions( )->set_all( abap_true ).
      lo_salv->get_display_settings( )->set_list_header( 'Sales by org'(002) ).
      lo_salv->display( ).
    CATCH cx_salv_msg INTO lx_msg.
      MESSAGE e002(zsd_msg) DISPLAY LIKE 'E'.
      " TODO(GUI): SE91 ZSD_MSG 002 = 'ALV 표시 중 오류가 발생했습니다. / ALV display error.'
  ENDTRY.
ENDFORM.

"!----------------------------------------------------------------------
"! DDIC 정의서 (SE11 확인용) / DDIC appendix
"! VBAK-VBELN CHAR 10 (판매문서 / Sales doc), VBAK-ERDAT DATS 8 (생성일 / Created on),
"! VBAK-KUNNR CHAR 10 → KNA1-NAME1 CHAR 35 (고객명 / Customer name),
"! VBAP-NETWR CURR 15,2 (순매출 / Net value), VBAK-WAERK CUKY 5 (통화 / Currency)
"!----------------------------------------------------------------------
"! 메시지 클래스 정의서 (SE91 ZSD_MSG) / Message definitions
"! 001(S): 조건에 맞는 데이터가 없습니다. / No data found for the selection.
"! 002(E): ALV 표시 중 오류가 발생했습니다. / Error while displaying ALV.
"!----------------------------------------------------------------------
"! 테스트 절차 / Test procedure (SE38 F8)
"! T1: VKORG=1000, ERDAT=20240101~20240131 → 100건 내외 ALV + 합계 표시
"! T2: VKORG=9999 → s001 '데이터가 없습니다'
"! T3: 권한 없는 유저 → e002 또는 AUTHORITY-CHECK 메시지
"! 오류 회수: 프로그램명 + 입력값(T1/T2/T3) + 메시지 전문 + ST22 덤프명 + SY-SUBRC
