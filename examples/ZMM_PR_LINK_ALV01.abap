*&---------------------------------------------------------------------*
*& Report ZMM_PR_LINK_ALV01
*&---------------------------------------------------------------------*
*& PR 연결정보 일괄 조회 (샘플) / Sample: PR linkage inquiry
*& 기준: SAP_BASIS 750 / S/4HANA, 모던 ABAP 허용
*&      / Baseline: SAP_BASIS 750 / S/4HANA, modern ABAP allowed
*& 패키지 / Package: ZMM01, 메시지: 텍스트 리터럴 사용(SE91 생성 불필요)
*& 복사 순서 / Copy order:
*&   ① SE38 — 프로그램 ZMM_PR_LINK_ALV01 생성 후 본 파일 전체 붙여넣기(SE91 불필요)
*&   ② Ctrl+F2 Syntax Check → Extended Check → F8 실행
*&---------------------------------------------------------------------*
REPORT zmm_pr_link_alv01 NO STANDARD PAGE HEADING
  LINE-SIZE 250 LINE-COUNT 65.

"! 타입 정의 / Type definitions
"! [확인필요] EBKN(계정지정), 판매오더·입고·송장 연결 필드는 SE11 실재 확인 후 활성화하십시오.
TYPES: BEGIN OF ty_link,
         banfn TYPE eban-banfn,   " 구매요청번호 / PR number
         bnfpo TYPE eban-bnfpo,   " PR 품목번호 / PR item
         badat TYPE eban-badat,   " PR 생성일 / PR created on
         werks TYPE eban-werks,   " 플랜트 / Plant
         ekgrp TYPE eban-ekgrp,   " 구매그룹 / Purchasing group
         wbs   TYPE ps_psp_pnr,   " WBS 요소 / WBS element [확인필요]
         vbeln TYPE vbap-vbeln,   " 판매오더 / Sales order [확인필요]
         ebeln TYPE ekpo-ebeln,   " 구매오더 / Purchase order
         mblnr TYPE mseg-mblnr,   " 입고문서 / GR document [확인필요]
         belnr TYPE rseg-belnr,   " 송장문서 / Invoice document [확인필요]
       END OF ty_link.

DATA gt_link TYPE STANDARD TABLE OF ty_link.

"! 선택화면 / Selection screen (S1)
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS p_banfn TYPE eban-banfn MODIF ID sc1.
  SELECT-OPTIONS s_badat FOR sy-datum MODIF ID sc1.
  PARAMETERS p_werks TYPE eban-werks MODIF ID sc1.
  PARAMETERS p_ekgrp TYPE eban-ekgrp MODIF ID sc1.
SELECTION-SCREEN END OF BLOCK b1.

"! 선택화면 초기값 / Initial values (기본=당일, DDIC 무관)
INITIALIZATION.
  s_badat-sign = 'I'.
  s_badat-option = 'BT'.
  s_badat-low = sy-datum.
  s_badat-high = sy-datum.
  APPEND s_badat.

"! 입력 검증 / Input validation
AT SELECTION-SCREEN.
  IF s_badat-low > s_badat-high AND s_badat-high IS NOT INITIAL.
    MESSAGE '시작일이 종료일보다 큽니다. / Start date is later than end date.' TYPE 'E'.
  ENDIF.
  IF p_banfn IS INITIAL AND s_badat-low IS INITIAL
      AND p_werks IS INITIAL AND p_ekgrp IS INITIAL.
    MESSAGE '최소 1개 조건을 입력하십시오. / Enter at least one criterion.' TYPE 'E'.
  ENDIF.
  IF s_badat-high - s_badat-low > 90.
    MESSAGE '생성일 범위는 최대 90일입니다. / Date range limited to 90 days.' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  PERFORM frm_get_data.
  PERFORM frm_show_alv.

*&---------------------------------------------------------------------*
*& Form FRM_GET_DATA — 데이터 조회 / Data selection
*&---------------------------------------------------------------------*
FORM frm_get_data.
  "! 권한 체크 / Authority check
  " TODO(GUI): SU53에서 실제 오브젝트 확인 후 조정 (표준 예: M_BANF_WRK)
  AUTHORITY-CHECK OBJECT 'M_BANF_WRK'
    ID 'WERKS' FIELD p_werks
    ID 'ACTVT' FIELD '03'.
  IF sy-subrc <> 0 AND p_werks IS NOT INITIAL.
    MESSAGE '권한이 없습니다. / No authority.' TYPE 'E'.
    RETURN.
  ENDIF.

  "! PR 연결정보 조회 / Select PR linkage
  "! [확인필요] 아래 조인(EBKN·VBAP·MSEG·RSEG)은 SE11 확인 후 조정하십시오.
  SELECT a~banfn, a~bnfpo, a~badat, a~werks, a~ekgrp,
         k~ps_psp_pnr, v~vbeln, p~ebeln, g~mblnr, r~belnr
    INTO TABLE @gt_link
    FROM eban AS a
    LEFT OUTER JOIN ebkn AS k ON a~banfn = k~banfn AND a~bnfpo = k~bnfpo
    LEFT OUTER JOIN ekpo AS p ON p~banfn = a~banfn AND p~bnfpo = a~bnfpo
    LEFT OUTER JOIN vbap AS v ON v~vbeln = k~vbeln
    LEFT OUTER JOIN mseg AS g ON g~ebeln = p~ebeln AND g~ebelp = p~ebelp
    LEFT OUTER JOIN rseg AS r ON r~ebeln = p~ebeln AND r~ebelp = p~ebelp
    WHERE ( a~banfn = @p_banfn OR @p_banfn = @space )
      AND a~badat IN @s_badat
      AND ( a~werks = @p_werks OR @p_werks = @space )
      AND ( a~ekgrp = @p_ekgrp OR @p_ekgrp = @space ).

  IF sy-subrc <> 0.
    MESSAGE '조건에 맞는 데이터가 없습니다. / No data found.' TYPE 'S'.
    RETURN.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form FRM_SHOW_ALV — ALV 표시 / ALV display (S2)
*&---------------------------------------------------------------------*
FORM frm_show_alv.
  DATA lo_salv TYPE REF TO cl_salv_table.
  DATA lx_msg  TYPE REF TO cx_salv_msg.

  TRY.
      cl_salv_table=>factory(
        IMPORTING r_salv_table = lo_salv
        CHANGING  t_table      = gt_link ).
      lo_salv->get_functions( )->set_all( abap_true ).
      lo_salv->get_display_settings( )->set_list_header( 'PR Linkage'(002) ).
      PERFORM frm_set_hotspot USING lo_salv.
      lo_salv->display( ).
    CATCH cx_salv_msg INTO lx_msg.
      MESSAGE 'ALV 표시 중 오류가 발생했습니다. / ALV display error.' TYPE 'E'.
  ENDTRY.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form FRM_SET_HOTSPOT — 문서번호 핫스팟 / Hotspot for doc numbers
*&---------------------------------------------------------------------*
FORM frm_set_hotspot USING io_salv TYPE REF TO cl_salv_table.
  DATA lo_cols TYPE REF TO cl_salv_columns_table.
  DATA lo_col  TYPE REF TO cl_salv_column_table.
  lo_cols = io_salv->get_columns( ).
  TRY.
      lo_col ?= lo_cols->get_column( 'BANFN' ).
      lo_col->set_cell_type( if_salv_c_cell_type=>hotspot ).
      lo_col ?= lo_cols->get_column( 'EBELN' ).
      lo_col->set_cell_type( if_salv_c_cell_type=>hotspot ).
    CATCH cx_salv_not_found.
      RETURN.
  ENDTRY.
ENDFORM.

"!----------------------------------------------------------------------
"! DDIC 정의서 (SE11 확인용) / DDIC appendix
"! EBAN-BANFN CHAR 10 (PR번호), EBAN-BNFPO NUMC 5 (PR품목), EBAN-BADAT DATS 8 (생성일),
"! EBAN-WERKS CHAR 4 (플랜트), EBAN-EKGRP CHAR 3 (구매그룹),
"! EBKN [확인필요] (계정지정), EKPO-EBELN (구매오더), MSEG-MBLNR [확인필요] (입고),
"! RSEG-BELNR [확인필요] (송장), VBAP-VBELN [확인필요] (판매오더), WBS=PS_PSP_PNR [확인필요]
"!----------------------------------------------------------------------
"! 메시지: 텍스트 리터럴 사용 — SE91 생성 불필요 / Literals, no message class needed
"! S: 조건에 맞는 데이터가 없습니다. / No data found.
"! E: 권한 없음·ALV 오류·일자 역전·미입력·90일 초과 (코드 내 리터럴 참조)
"!----------------------------------------------------------------------
"! 테스트 절차 / Test procedure (SE38 F8)
"! T1: 생성일=오늘 → 당일 PR ALV 표시 (S2), 상태바 건수 확인
"! T2: 생성일=과거 무데이터 일자 → s001 '데이터가 없습니다'
"! T3: 전체 미입력 실행 → e004 + 중단 / 권한 없는 유저 → e002
"! 오류 회수: 프로그램명 + 입력값(T1/T2/T3) + 메시지 전문 + ST22 덤프명 + SY-SUBRC
