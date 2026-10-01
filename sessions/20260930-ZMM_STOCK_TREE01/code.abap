*&---------------------------------------------------------------------*
*& Report ZMM_STOCK_TREE01
*&---------------------------------------------------------------------*
*& 법인/플랜트별 재고 현황 트리 조회
*& Stock overview tree by company code and plant
*&
*& 작성일 / Created  : 2026-10-01
*& 세션  / Session   : 20260930-ZMM_STOCK_TREE01
*& 기준  / Baseline  : SAP_BASIS 750 / S/4HANA, 모던 ABAP 허용
*& TR                : TODO(GUI) 이송 요청번호 기입 / enter transport request
*&
*& 기능 / Function
*&   1) 법인 → 플랜트 → 재고구분 → 저장위치·특별재고유형 → 자재 5단 트리
*&      5-level tree: company → plant → stock kind → storage loc/special type → material
*&   2) 노드별 수량 소계 — 하위 단위가 모두 같을 때만 합산, 혼재 시 금액만 합산 (A안)
*&      Subtotal only when all child base units are identical (option A)
*&   3) 가용 / 품질검사 / 보류 재고 구분 표시
*&      Unrestricted / quality inspection / blocked stock
*&   4) 자재 노드 더블클릭 → MM03 자재 마스터 조회
*&      Double-click on material node → MM03
*&   5) 재고 평가액 표시 (선택화면 옵션)  6) 재고 0 자재 숨기기 (선택화면 옵션)
*&
*& DDIC 근거 / DDIC source
*&   ZMM_DDIC_PROBE01 실행 결과(2026-10-01)로 확정된 필드만 사용한다.
*&   Only fields confirmed by the DDIC probe run are used.
*&     MARD : LABST / INSME / SPEME
*&     MSKA : KALAB / KAINS / KASPE , 참조 VBELN+POSNR
*&     MSPR : PRLAB / PRINS / PRSPE , 참조 PSPNR
*&     MSKU : KULAB / KUINS       , 참조 KUNNR , 보류필드 없음 / no blocked field
*&     MKOL : SLABS / SINSM / SSPEM, 참조 LIFNR
*&     MSLB : LBLAB / LBINS       , 참조 LIFNR , 보류필드 없음 / no blocked field
*&     MBEW : LBKUM / SALK3 (BWTAR = space)
*&---------------------------------------------------------------------*
REPORT zmm_stock_tree01.

*----------------------------------------------------------------------*
* 선택화면 참조용 테이블 선언 / Tables for SELECT-OPTIONS references
* ERR-006 선반영: DDIC 필드를 참조하는 SELECT-OPTIONS 는 TABLES 선언 필수
* Pre-applied: SELECT-OPTIONS on dictionary fields require TABLES
*----------------------------------------------------------------------*
TABLES: t001, t001w, t001l, mara.

*----------------------------------------------------------------------*
* 상수 / Constants
*----------------------------------------------------------------------*
CONSTANTS:
  c_kind_loc  TYPE c LENGTH 1 VALUE 'L',   "! 저장위치 재고 / location stock
  c_kind_spc  TYPE c LENGTH 1 VALUE 'S',   "! 특별재고 / special stock
  c_sep       TYPE c LENGTH 1 VALUE '|'.   "! 집계 경로 구분자 / path separator

*----------------------------------------------------------------------*
* 타입 / Types
*----------------------------------------------------------------------*
TYPES:
  "! 플랜트 레인지 — FORM 파라미터 타입 지정용 / typed range for FORM parameters
  ty_werks_range TYPE RANGE OF t001w-werks,

  "! 자재 키 목록 (FOR ALL ENTRIES 용) / material key list for FOR ALL ENTRIES
  BEGIN OF ty_matkey,
    matnr TYPE mara-matnr,
  END OF ty_matkey,

  "! 플랜트·법인 조직정보 / plant and company code
  BEGIN OF ty_plant,
    werks TYPE t001w-werks,
    name1 TYPE t001w-name1,
    bwkey TYPE t001w-bwkey,
    bukrs TYPE t001-bukrs,
    butxt TYPE t001-butxt,
    waers TYPE t001-waers,
  END OF ty_plant,

  "! 재고 수집 중간 테이블 / staging table for collected stock
  BEGIN OF ty_stock,
    werks     TYPE t001w-werks,
    lgort     TYPE mard-lgort,
    matnr     TYPE mara-matnr,
    kind      TYPE c LENGTH 1,
    sobkz     TYPE mska-sobkz,
    refkey    TYPE c LENGTH 40,
    qty_free  TYPE p LENGTH 13 DECIMALS 3,
    qty_qi    TYPE p LENGTH 13 DECIMALS 3,
    qty_block TYPE p LENGTH 13 DECIMALS 3,
  END OF ty_stock,

  "! 트리 말단 행 / tree leaf row
  BEGIN OF ty_row,
    bukrs     TYPE t001-bukrs,
    butxt     TYPE t001-butxt,
    waers     TYPE t001-waers,
    werks     TYPE t001w-werks,
    wname     TYPE t001w-name1,
    bwkey     TYPE t001w-bwkey,
    kind      TYPE c LENGTH 1,
    sobkz     TYPE mska-sobkz,
    l4key     TYPE c LENGTH 10,
    l4text    TYPE c LENGTH 60,
    lgort     TYPE mard-lgort,
    matnr     TYPE mara-matnr,
    maktx     TYPE makt-maktx,
    mtart     TYPE mara-mtart,
    matkl     TYPE mara-matkl,
    meins     TYPE mara-meins,
    refkey    TYPE c LENGTH 40,
    qty_free  TYPE p LENGTH 13 DECIMALS 3,
    qty_qi    TYPE p LENGTH 13 DECIMALS 3,
    qty_block TYPE p LENGTH 13 DECIMALS 3,
    qty_total TYPE p LENGTH 13 DECIMALS 3,
    amount    TYPE p LENGTH 15 DECIMALS 2,
  END OF ty_row,

  "! 노드 소계 / node subtotal
  BEGIN OF ty_sum,
    path      TYPE c LENGTH 40,
    qty_free  TYPE p LENGTH 13 DECIMALS 3,
    qty_qi    TYPE p LENGTH 13 DECIMALS 3,
    qty_block TYPE p LENGTH 13 DECIMALS 3,
    qty_total TYPE p LENGTH 13 DECIMALS 3,
    amount    TYPE p LENGTH 15 DECIMALS 2,
    meins     TYPE mara-meins,
    unit_mix  TYPE abap_bool,
    waers     TYPE t001-waers,
    waers_mix TYPE abap_bool,
  END OF ty_sum,

  "! ALV 트리 표시행 — 전부 문자형 / display row, all character
  "! 숫자를 미리 편집해 넣으므로 단위·통화 변환 문제가 발생하지 않는다.
  "! Numbers are pre-formatted, so no unit/currency conversion issues occur.
  BEGIN OF ty_disp,
    qty_free  TYPE c LENGTH 20,
    qty_qi    TYPE c LENGTH 20,
    qty_block TYPE c LENGTH 20,
    qty_total TYPE c LENGTH 20,
    unit      TYPE c LENGTH 10,
    amount    TYPE c LENGTH 24,
    waers     TYPE c LENGTH 5,
    refkey    TYPE c LENGTH 40,
    mtart     TYPE c LENGTH 4,
    matkl     TYPE c LENGTH 9,
  END OF ty_disp,

  "! 노드키 ↔ 자재 연결 (더블클릭용) / node key to material map
  BEGIN OF ty_nodemap,
    nkey  TYPE lvc_nkey,
    matnr TYPE mara-matnr,
  END OF ty_nodemap.

*----------------------------------------------------------------------*
* 전역 데이터 / Global data
*----------------------------------------------------------------------*
DATA:
  gt_plant   TYPE STANDARD TABLE OF ty_plant WITH EMPTY KEY,
  gt_stock   TYPE STANDARD TABLE OF ty_stock WITH EMPTY KEY,
  gt_row     TYPE STANDARD TABLE OF ty_row   WITH EMPTY KEY,
  gt_sum     TYPE HASHED TABLE OF ty_sum WITH UNIQUE KEY path,
  gt_nodemap TYPE SORTED TABLE OF ty_nodemap WITH UNIQUE KEY nkey,
  gt_disp    TYPE STANDARD TABLE OF ty_disp WITH EMPTY KEY,
  go_dock    TYPE REF TO cl_gui_docking_container,
  go_tree    TYPE REF TO cl_gui_alv_tree,
  gv_bukrs   TYPE t001-bukrs.

*----------------------------------------------------------------------*
* 더블클릭 처리 클래스 / Event handler for double click
*----------------------------------------------------------------------*
CLASS lcl_handler DEFINITION.
  PUBLIC SECTION.
    "! 노드 영역 더블클릭 / double click on the hierarchy node
    CLASS-METHODS on_node_double_click
      FOR EVENT node_double_click OF cl_gui_alv_tree
      IMPORTING node_key.

    "! 셀(아이템) 영역 더블클릭 — 선택 모드에 따라 이 이벤트가 대신 발생한다
    "! Item event is raised instead, depending on the selection mode
    CLASS-METHODS on_item_double_click
      FOR EVENT item_double_click OF cl_gui_alv_tree
      IMPORTING node_key.

  PRIVATE SECTION.
    CLASS-METHODS jump_to_mm03 IMPORTING iv_nkey TYPE lvc_nkey.
ENDCLASS.

CLASS lcl_handler IMPLEMENTATION.

  METHOD on_node_double_click.
    jump_to_mm03( node_key ).
  ENDMETHOD.

  METHOD on_item_double_click.
    jump_to_mm03( node_key ).
  ENDMETHOD.

  METHOD jump_to_mm03.
    "! 자재 노드일 때만 MM03 으로 이동 / jump to MM03 only for material nodes
    READ TABLE gt_nodemap INTO DATA(ls_map) WITH TABLE KEY nkey = iv_nkey.
    IF sy-subrc <> 0 OR ls_map-matnr IS INITIAL.
      RETURN.
    ENDIF.
    SET PARAMETER ID 'MAT' FIELD ls_map-matnr.
    CALL TRANSACTION 'MM03' AND SKIP FIRST SCREEN.
  ENDMETHOD.

ENDCLASS.

*----------------------------------------------------------------------*
* 선택화면 / Selection screen
* 블록 제목은 텍스트 요소(TEXT-xxx) 대신 변수로 넣는다.
* 복붙만으로 동작하도록 SE38 텍스트 요소 등록을 요구하지 않는다.
* Frame titles use variables instead of text symbols, so a plain paste works.
*----------------------------------------------------------------------*
DATA: gv_tit1 TYPE c LENGTH 60,
      gv_tit2 TYPE c LENGTH 60.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE gv_tit1.
SELECT-OPTIONS:
  s_bukrs FOR t001-bukrs,                  "! 회사코드(법인) / company code
  s_werks FOR t001w-werks,                 "! 플랜트 / plant
  s_lgort FOR t001l-lgort,                 "! 저장위치 / storage location
  s_matnr FOR mara-matnr,                  "! 자재번호 / material
  s_mtart FOR mara-mtart,                  "! 자재유형 / material type
  s_matkl FOR mara-matkl.                  "! 자재그룹 / material group
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE gv_tit2.
PARAMETERS:
  p_hide0 AS CHECKBOX DEFAULT 'X',         "! 재고 0 자재 숨기기 / hide zero stock
  p_spec  AS CHECKBOX DEFAULT 'X',         "! 특별재고 포함 / include special stock
  p_val   AS CHECKBOX DEFAULT ' '.         "! 금액 표시 / show valuation amount
SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------------*
INITIALIZATION.
  gv_tit1 = '조회 조건 / Selection criteria'.
  gv_tit2 = '표시 옵션 / Display options'.

  "! 사용자 개인설정(SU3) 파라미터 BUK 를 회사코드 기본값으로 / default from SU3
  GET PARAMETER ID 'BUK' FIELD gv_bukrs.
  IF gv_bukrs IS NOT INITIAL.
    s_bukrs-sign   = 'I'.
    s_bukrs-option = 'EQ'.
    s_bukrs-low    = gv_bukrs.
    APPEND s_bukrs.
  ENDIF.

*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
  "! ERR-005 선반영: 조건 없는 전사 조회 차단 / block company-wide full scan
  IF s_bukrs[] IS INITIAL.
    SET CURSOR FIELD 'S_BUKRS-LOW'.
    MESSAGE '회사코드를 입력하십시오. / Please enter a company code.' TYPE 'E'.
  ENDIF.

*----------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM f_check_authority.
  PERFORM f_get_plant.
  IF gt_plant IS INITIAL.
    MESSAGE '조회 조건에 해당하는 플랜트가 없습니다. / No plant found.'
            TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  PERFORM f_get_location_stock.
  IF p_spec = abap_true.
    PERFORM f_get_special_stock.
  ENDIF.

  IF gt_stock IS INITIAL.
    MESSAGE '조회 조건에 해당하는 재고가 없습니다. / No stock found.'
            TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  PERFORM f_build_row.
  IF gt_row IS INITIAL.
    MESSAGE '조회 조건에 해당하는 재고가 없습니다. / No stock found.'
            TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  PERFORM f_aggregate.
  PERFORM f_display_tree.

  "! 컨트롤을 유지하기 위해 빈 리스트 화면을 띄운다 / keep the control alive
  WRITE space.

*&---------------------------------------------------------------------*
*& Form F_CHECK_AUTHORITY
*&   권한 체크 / authority check
*&   TODO(SU21/SU53): 권한 오브젝트 미확정. 활성화 후 SU53 TRACE 결과로 확정한다.
*&   Authorization object not yet determined; confirm via SU53 trace.
*&---------------------------------------------------------------------*
FORM f_check_authority.

  "! ① 재고 조회 권한 / stock display authority
  "! TODO(SU21/SU53): 예) AUTHORITY-CHECK OBJECT 'M_MSEG_WWA'
  "!                        ID 'ACTVT' FIELD '03'
  "!                        ID 'WERKS' FIELD <플랜트>.
  "!   실패 시 아래 메시지를 사용한다 / use the message below on failure
  "!   MESSAGE '해당 회사코드/플랜트 조회 권한이 없습니다.' TYPE 'E'.

  "! ② 평가액 조회 권한 / valuation display authority (금액 표시 옵션 ON일 때만)
  IF p_val = abap_true.
    "! TODO(SU21/SU53): 평가액 조회용 오브젝트 확정 후 체크 추가
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_PLANT
*&   회사코드 → 평가영역 → 플랜트 / company code to plant
*&---------------------------------------------------------------------*
FORM f_get_plant.

  SELECT w~werks, w~name1, w~bwkey,
         k~bukrs, c~butxt, c~waers
    FROM t001w AS w
    INNER JOIN t001k AS k ON k~bwkey = w~bwkey
    INNER JOIN t001  AS c ON c~bukrs = k~bukrs
    WHERE c~bukrs IN @s_bukrs
      AND w~werks IN @s_werks
    INTO CORRESPONDING FIELDS OF TABLE @gt_plant.

  IF sy-subrc <> 0.
    CLEAR gt_plant.
  ENDIF.

  SORT gt_plant BY bukrs werks.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_LOCATION_STOCK
*&   저장위치 재고 / storage location stock (MARD)
*&---------------------------------------------------------------------*
FORM f_get_location_stock.

  DATA lr_werks TYPE ty_werks_range.

  PERFORM f_build_werks_range CHANGING lr_werks.
  IF lr_werks IS INITIAL.
    RETURN.
  ENDIF.

  "! MARD 의 위탁재고 필드(KLABS 등)는 MKOL 과 이중 계상되므로 쓰지 않는다
  "! Consignment fields of MARD are not used (would double count with MKOL)
  SELECT d~werks, d~lgort, d~matnr,
         d~labst AS qty_free, d~insme AS qty_qi, d~speme AS qty_block
    FROM mard AS d
    INNER JOIN mara AS a ON a~matnr = d~matnr
    WHERE d~werks IN @lr_werks
      AND d~lgort IN @s_lgort
      AND d~matnr IN @s_matnr
      AND a~mtart IN @s_mtart
      AND a~matkl IN @s_matkl
    INTO TABLE @DATA(lt_mard).

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  LOOP AT lt_mard INTO DATA(ls_mard).
    APPEND VALUE #( werks     = ls_mard-werks
                    lgort     = ls_mard-lgort
                    matnr     = ls_mard-matnr
                    kind      = c_kind_loc
                    qty_free  = ls_mard-qty_free
                    qty_qi    = ls_mard-qty_qi
                    qty_block = ls_mard-qty_block ) TO gt_stock.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_SPECIAL_STOCK
*&   특별재고 5종 / five kinds of special stock
*&---------------------------------------------------------------------*
FORM f_get_special_stock.

  DATA: lr_werks TYPE ty_werks_range,
        lv_posid TYPE ps_posid,
        lv_ref   TYPE c LENGTH 40.

  PERFORM f_build_werks_range CHANGING lr_werks.
  IF lr_werks IS INITIAL.
    RETURN.
  ENDIF.

*--- E 판매오더 재고 / sales order stock (MSKA) -----------------------*
  SELECT s~werks, s~lgort, s~matnr, s~sobkz, s~vbeln, s~posnr,
         SUM( s~kalab ) AS qty_free,
         SUM( s~kains ) AS qty_qi,
         SUM( s~kaspe ) AS qty_block
    FROM mska AS s
    INNER JOIN mara AS a ON a~matnr = s~matnr
    WHERE s~werks IN @lr_werks
      AND s~lgort IN @s_lgort
      AND s~matnr IN @s_matnr
      AND a~mtart IN @s_mtart
      AND a~matkl IN @s_matkl
    GROUP BY s~werks, s~lgort, s~matnr, s~sobkz, s~vbeln, s~posnr
    INTO TABLE @DATA(lt_mska).

  IF sy-subrc <> 0.
    CLEAR lt_mska.
  ENDIF.

  LOOP AT lt_mska INTO DATA(ls_mska).
    CLEAR lv_ref.
    CONCATENATE '수주' ls_mska-vbeln '/' ls_mska-posnr INTO lv_ref SEPARATED BY space.
    APPEND VALUE #( werks     = ls_mska-werks
                    lgort     = ls_mska-lgort
                    matnr     = ls_mska-matnr
                    kind      = c_kind_spc
                    sobkz     = ls_mska-sobkz
                    refkey    = lv_ref
                    qty_free  = ls_mska-qty_free
                    qty_qi    = ls_mska-qty_qi
                    qty_block = ls_mska-qty_block ) TO gt_stock.
  ENDLOOP.

*--- Q 프로젝트 재고 / project stock (MSPR) --------------------------*
  SELECT s~werks, s~lgort, s~matnr, s~sobkz, s~pspnr,
         SUM( s~prlab ) AS qty_free,
         SUM( s~prins ) AS qty_qi,
         SUM( s~prspe ) AS qty_block
    FROM mspr AS s
    INNER JOIN mara AS a ON a~matnr = s~matnr
    WHERE s~werks IN @lr_werks
      AND s~lgort IN @s_lgort
      AND s~matnr IN @s_matnr
      AND a~mtart IN @s_mtart
      AND a~matkl IN @s_matkl
    GROUP BY s~werks, s~lgort, s~matnr, s~sobkz, s~pspnr
    INTO TABLE @DATA(lt_mspr).

  IF sy-subrc <> 0.
    CLEAR lt_mspr.
  ENDIF.

  LOOP AT lt_mspr INTO DATA(ls_mspr).
    CLEAR: lv_ref, lv_posid.
    "! [확인필요] WBS 요소 내부번호 → 외부표시 표준 변환 exit (SE37에서 존재 확인)
    "! Standard conversion exit for WBS element number; verify in SE37
    "! 구문검사에서 "함수모듈 없음" 이 나오면 아래 2줄로 대체한다
    "! If the syntax check reports a missing function module, replace with:
    "!   lv_posid = ls_mspr-pspnr.
    CALL FUNCTION 'CONVERSION_EXIT_ABPSP_OUTPUT'
      EXPORTING
        input  = ls_mspr-pspnr
      IMPORTING
        output = lv_posid.
    CONCATENATE 'WBS' lv_posid INTO lv_ref SEPARATED BY space.
    APPEND VALUE #( werks     = ls_mspr-werks
                    lgort     = ls_mspr-lgort
                    matnr     = ls_mspr-matnr
                    kind      = c_kind_spc
                    sobkz     = ls_mspr-sobkz
                    refkey    = lv_ref
                    qty_free  = ls_mspr-qty_free
                    qty_qi    = ls_mspr-qty_qi
                    qty_block = ls_mspr-qty_block ) TO gt_stock.
  ENDLOOP.

*--- K·M 공급업체 위탁·포장재 / vendor consignment (MKOL) ------------*
  SELECT s~werks, s~lgort, s~matnr, s~sobkz, s~lifnr,
         SUM( s~slabs ) AS qty_free,
         SUM( s~sinsm ) AS qty_qi,
         SUM( s~sspem ) AS qty_block
    FROM mkol AS s
    INNER JOIN mara AS a ON a~matnr = s~matnr
    WHERE s~werks IN @lr_werks
      AND s~lgort IN @s_lgort
      AND s~matnr IN @s_matnr
      AND a~mtart IN @s_mtart
      AND a~matkl IN @s_matkl
    GROUP BY s~werks, s~lgort, s~matnr, s~sobkz, s~lifnr
    INTO TABLE @DATA(lt_mkol).

  IF sy-subrc <> 0.
    CLEAR lt_mkol.
  ENDIF.

  LOOP AT lt_mkol INTO DATA(ls_mkol).
    CLEAR lv_ref.
    CONCATENATE '공급업체' ls_mkol-lifnr INTO lv_ref SEPARATED BY space.
    APPEND VALUE #( werks     = ls_mkol-werks
                    lgort     = ls_mkol-lgort
                    matnr     = ls_mkol-matnr
                    kind      = c_kind_spc
                    sobkz     = ls_mkol-sobkz
                    refkey    = lv_ref
                    qty_free  = ls_mkol-qty_free
                    qty_qi    = ls_mkol-qty_qi
                    qty_block = ls_mkol-qty_block ) TO gt_stock.
  ENDLOOP.

  "! MSKU·MSLB 는 저장위치 키가 없다. 선택화면에 저장위치 조건이 있으면 제외한다.
  "! MSKU and MSLB have no storage location key; skip them if LGORT was entered.
  IF s_lgort[] IS NOT INITIAL.
    RETURN.
  ENDIF.

*--- V·W 고객 특별재고 / customer special stock (MSKU) ---------------*
  "! 보류 재고 필드가 없다 → 0 / no blocked stock field, left as zero
  SELECT s~werks, s~matnr, s~sobkz, s~kunnr,
         SUM( s~kulab ) AS qty_free,
         SUM( s~kuins ) AS qty_qi
    FROM msku AS s
    INNER JOIN mara AS a ON a~matnr = s~matnr
    WHERE s~werks IN @lr_werks
      AND s~matnr IN @s_matnr
      AND a~mtart IN @s_mtart
      AND a~matkl IN @s_matkl
    GROUP BY s~werks, s~matnr, s~sobkz, s~kunnr
    INTO TABLE @DATA(lt_msku).

  IF sy-subrc <> 0.
    CLEAR lt_msku.
  ENDIF.

  LOOP AT lt_msku INTO DATA(ls_msku).
    CLEAR lv_ref.
    CONCATENATE '고객' ls_msku-kunnr INTO lv_ref SEPARATED BY space.
    APPEND VALUE #( werks    = ls_msku-werks
                    matnr    = ls_msku-matnr
                    kind     = c_kind_spc
                    sobkz    = ls_msku-sobkz
                    refkey   = lv_ref
                    qty_free = ls_msku-qty_free
                    qty_qi   = ls_msku-qty_qi ) TO gt_stock.
  ENDLOOP.

*--- O 공급업체 보유 재고 / stock with vendor (MSLB) -----------------*
  "! 보류 재고 필드가 없다 → 0 / no blocked stock field, left as zero
  SELECT s~werks, s~matnr, s~sobkz, s~lifnr,
         SUM( s~lblab ) AS qty_free,
         SUM( s~lbins ) AS qty_qi
    FROM mslb AS s
    INNER JOIN mara AS a ON a~matnr = s~matnr
    WHERE s~werks IN @lr_werks
      AND s~matnr IN @s_matnr
      AND a~mtart IN @s_mtart
      AND a~matkl IN @s_matkl
    GROUP BY s~werks, s~matnr, s~sobkz, s~lifnr
    INTO TABLE @DATA(lt_mslb).

  IF sy-subrc <> 0.
    CLEAR lt_mslb.
  ENDIF.

  LOOP AT lt_mslb INTO DATA(ls_mslb).
    CLEAR lv_ref.
    CONCATENATE '공급업체' ls_mslb-lifnr INTO lv_ref SEPARATED BY space.
    APPEND VALUE #( werks    = ls_mslb-werks
                    matnr    = ls_mslb-matnr
                    kind     = c_kind_spc
                    sobkz    = ls_mslb-sobkz
                    refkey   = lv_ref
                    qty_free = ls_mslb-qty_free
                    qty_qi   = ls_mslb-qty_qi ) TO gt_stock.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_BUILD_WERKS_RANGE
*&   플랜트 목록 → 레인지 / plant list to range table
*&---------------------------------------------------------------------*
FORM f_build_werks_range CHANGING ct_range TYPE ty_werks_range.

  CLEAR ct_range.
  LOOP AT gt_plant INTO DATA(ls_plant).
    APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_plant-werks ) TO ct_range.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_BUILD_ROW
*&   수집 재고 + 마스터 텍스트 + 평가액 → 트리 말단 행
*&   Collected stock + texts + valuation → tree leaf rows
*&---------------------------------------------------------------------*
FORM f_build_row.

  DATA: lv_price TYPE p LENGTH 15 DECIMALS 4,
        ls_row   TYPE ty_row,
        ls_pl    TYPE ty_plant,
        lv_blank TYPE mbew-bwtar.   "! 평가유형 공란 = 총 평가분 / blank valuation type

  CLEAR lv_blank.

*--- 자재 마스터 / material master -----------------------------------*
  DATA lt_matkey TYPE STANDARD TABLE OF ty_matkey WITH EMPTY KEY.
  LOOP AT gt_stock INTO DATA(ls_stk).
    APPEND VALUE #( matnr = ls_stk-matnr ) TO lt_matkey.
  ENDLOOP.
  SORT lt_matkey BY matnr.
  DELETE ADJACENT DUPLICATES FROM lt_matkey COMPARING matnr.

  "! FOR ALL ENTRIES 앞 빈 체크 / empty check before FOR ALL ENTRIES
  IF lt_matkey IS INITIAL.
    RETURN.
  ENDIF.

  SELECT matnr, mtart, matkl, meins
    FROM mara
    FOR ALL ENTRIES IN @lt_matkey
    WHERE matnr = @lt_matkey-matnr
    INTO TABLE @DATA(lt_mara).

  IF sy-subrc <> 0.
    CLEAR lt_mara.
  ENDIF.
  SORT lt_mara BY matnr.

  SELECT matnr, maktx
    FROM makt
    FOR ALL ENTRIES IN @lt_matkey
    WHERE matnr = @lt_matkey-matnr
      AND spras = @sy-langu
    INTO TABLE @DATA(lt_makt).

  IF sy-subrc <> 0.
    CLEAR lt_makt.
  ENDIF.
  SORT lt_makt BY matnr.

*--- 저장위치 명칭 / storage location text ---------------------------*
  DATA lt_locinfo TYPE STANDARD TABLE OF t001l WITH EMPTY KEY.
  DATA lt_lockey  TYPE STANDARD TABLE OF ty_stock WITH EMPTY KEY.
  lt_lockey = gt_stock.
  DELETE lt_lockey WHERE lgort IS INITIAL.
  SORT lt_lockey BY werks lgort.
  DELETE ADJACENT DUPLICATES FROM lt_lockey COMPARING werks lgort.

  "! FOR ALL ENTRIES 앞 빈 체크 / empty check before FOR ALL ENTRIES
  IF lt_lockey IS NOT INITIAL.
    SELECT werks, lgort, lgobe
      FROM t001l
      FOR ALL ENTRIES IN @lt_lockey
      WHERE werks = @lt_lockey-werks
        AND lgort = @lt_lockey-lgort
      INTO CORRESPONDING FIELDS OF TABLE @lt_locinfo.

    IF sy-subrc <> 0.
      CLEAR lt_locinfo.
    ENDIF.
    SORT lt_locinfo BY werks lgort.
  ENDIF.

*--- 평가 데이터 / valuation data ------------------------------------*
  TYPES: BEGIN OF ty_valkey,
           matnr TYPE mara-matnr,
           bwkey TYPE t001w-bwkey,
         END OF ty_valkey.
  DATA: lt_valkey TYPE STANDARD TABLE OF ty_valkey WITH EMPTY KEY,
        lt_mbew   TYPE STANDARD TABLE OF mbew WITH EMPTY KEY.

  IF p_val = abap_true.
    LOOP AT gt_stock INTO ls_stk.
      READ TABLE gt_plant INTO ls_pl WITH KEY werks = ls_stk-werks.
      IF sy-subrc = 0.
        APPEND VALUE #( matnr = ls_stk-matnr bwkey = ls_pl-bwkey ) TO lt_valkey.
      ENDIF.
    ENDLOOP.
    SORT lt_valkey BY matnr bwkey.
    DELETE ADJACENT DUPLICATES FROM lt_valkey COMPARING matnr bwkey.

    "! FOR ALL ENTRIES 앞 빈 체크 / empty check before FOR ALL ENTRIES
    IF lt_valkey IS NOT INITIAL.
      "! BWTAR = space 레코드가 총 평가분이다 / header record of split valuation
      SELECT matnr, bwkey, lbkum, salk3
        FROM mbew
        FOR ALL ENTRIES IN @lt_valkey
        WHERE matnr = @lt_valkey-matnr
          AND bwkey = @lt_valkey-bwkey
          AND bwtar = @lv_blank
        INTO CORRESPONDING FIELDS OF TABLE @lt_mbew.

      IF sy-subrc <> 0.
        CLEAR lt_mbew.
      ENDIF.
      SORT lt_mbew BY matnr bwkey.
    ENDIF.
  ENDIF.

*--- 행 조립 / assemble rows -----------------------------------------*
  LOOP AT gt_stock INTO ls_stk.

    CLEAR ls_row.

    READ TABLE gt_plant INTO ls_pl WITH KEY werks = ls_stk-werks.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    ls_row-bukrs  = ls_pl-bukrs.
    ls_row-butxt  = ls_pl-butxt.
    ls_row-waers  = ls_pl-waers.
    ls_row-werks  = ls_pl-werks.
    ls_row-wname  = ls_pl-name1.
    ls_row-bwkey  = ls_pl-bwkey.
    ls_row-kind   = ls_stk-kind.
    ls_row-sobkz  = ls_stk-sobkz.
    ls_row-lgort  = ls_stk-lgort.
    ls_row-matnr  = ls_stk-matnr.
    ls_row-refkey = ls_stk-refkey.

    ls_row-qty_free  = ls_stk-qty_free.
    ls_row-qty_qi    = ls_stk-qty_qi.
    ls_row-qty_block = ls_stk-qty_block.
    ls_row-qty_total = ls_stk-qty_free + ls_stk-qty_qi + ls_stk-qty_block.

    "! 재고 0 자재 숨기기 / hide materials with zero stock
    IF p_hide0 = abap_true AND ls_row-qty_total IS INITIAL.
      CONTINUE.
    ENDIF.

    READ TABLE lt_mara INTO DATA(ls_mara) WITH KEY matnr = ls_stk-matnr BINARY SEARCH.
    IF sy-subrc = 0.
      ls_row-mtart = ls_mara-mtart.
      ls_row-matkl = ls_mara-matkl.
      ls_row-meins = ls_mara-meins.
    ENDIF.

    READ TABLE lt_makt INTO DATA(ls_makt) WITH KEY matnr = ls_stk-matnr BINARY SEARCH.
    IF sy-subrc = 0.
      ls_row-maktx = ls_makt-maktx.
    ENDIF.

    "! 4단 노드 키·명칭 / level-4 node key and text
    IF ls_stk-kind = c_kind_loc.
      ls_row-l4key = ls_stk-lgort.
      READ TABLE lt_locinfo INTO DATA(ls_loc)
           WITH KEY werks = ls_stk-werks lgort = ls_stk-lgort BINARY SEARCH.
      IF sy-subrc = 0.
        CONCATENATE ls_stk-lgort ls_loc-lgobe INTO ls_row-l4text SEPARATED BY space.
      ELSE.
        ls_row-l4text = ls_stk-lgort.
      ENDIF.
    ELSE.
      ls_row-l4key = ls_stk-sobkz.
      PERFORM f_sobkz_text USING ls_stk-sobkz CHANGING ls_row-l4text.
    ENDIF.

    "! 평가액 = (평가재고총액 ÷ 총평가재고) × 조회수량
    "! Amount = (total value / total valuated stock) * displayed quantity
    IF p_val = abap_true.
      CLEAR lv_price.
      READ TABLE lt_mbew INTO DATA(ls_mbew)
           WITH KEY matnr = ls_stk-matnr bwkey = ls_pl-bwkey BINARY SEARCH.
      IF sy-subrc = 0 AND ls_mbew-lbkum <> 0.
        lv_price = ls_mbew-salk3 / ls_mbew-lbkum.
        ls_row-amount = lv_price * ls_row-qty_total.
      ENDIF.
    ENDIF.

    APPEND ls_row TO gt_row.

  ENDLOOP.

  "! 정렬: 법인 → 플랜트 → 재고구분(L 먼저) → 4단 → 자재 → 참조
  SORT gt_row BY bukrs werks kind l4key matnr refkey.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_SOBKZ_TEXT
*&   특별재고 지시자 → 명칭 / special stock indicator to text
*&---------------------------------------------------------------------*
FORM f_sobkz_text USING iv_sobkz TYPE c
               CHANGING cv_text  TYPE c.

  CASE iv_sobkz.
    WHEN 'E'. cv_text = 'E 판매오더 재고 / Sales order stock'.
    WHEN 'Q'. cv_text = 'Q 프로젝트 재고 / Project stock'.
    WHEN 'V'. cv_text = 'V 고객 위탁재고 / Customer consignment'.
    WHEN 'W'. cv_text = 'W 고객 반환포장 / Returnable packaging at customer'.
    WHEN 'K'. cv_text = 'K 공급업체 위탁재고 / Vendor consignment'.
    WHEN 'M'. cv_text = 'M 공급업체 반환포장 / Returnable packaging from vendor'.
    WHEN 'O'. cv_text = 'O 공급업체 보유 사급재고 / Stock with vendor'.
    WHEN OTHERS.
      "! 알 수 없는 지시자는 코드를 그대로 표시 / show the raw code
      CONCATENATE iv_sobkz '특별재고 / Special stock' INTO cv_text SEPARATED BY space.
  ENDCASE.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_AGGREGATE
*&   1~4단 노드 소계 (A안) / subtotals for levels 1-4 (option A)
*&---------------------------------------------------------------------*
FORM f_aggregate.

  DATA: lv_path TYPE c LENGTH 40.

  CLEAR gt_sum.

  LOOP AT gt_row INTO DATA(ls_row).

    "! 1단 / level 1
    lv_path = ls_row-bukrs.
    PERFORM f_add_sum USING lv_path ls_row.

    "! 2단 / level 2
    CONCATENATE ls_row-bukrs ls_row-werks INTO lv_path SEPARATED BY c_sep.
    PERFORM f_add_sum USING lv_path ls_row.

    "! 3단 / level 3
    CONCATENATE ls_row-bukrs ls_row-werks ls_row-kind INTO lv_path SEPARATED BY c_sep.
    PERFORM f_add_sum USING lv_path ls_row.

    "! 4단 / level 4
    CONCATENATE ls_row-bukrs ls_row-werks ls_row-kind ls_row-l4key
           INTO lv_path SEPARATED BY c_sep.
    PERFORM f_add_sum USING lv_path ls_row.

  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_ADD_SUM
*&   소계 누적 + 단위·통화 혼재 판정 / accumulate and detect mixed unit
*&---------------------------------------------------------------------*
FORM f_add_sum USING iv_path TYPE c
                     is_row  TYPE ty_row.

  DATA ls_sum TYPE ty_sum.

  READ TABLE gt_sum INTO ls_sum WITH TABLE KEY path = iv_path.
  IF sy-subrc <> 0.
    CLEAR ls_sum.
    ls_sum-path  = iv_path.
    ls_sum-meins = is_row-meins.
    ls_sum-waers = is_row-waers.
    INSERT ls_sum INTO TABLE gt_sum.
    READ TABLE gt_sum INTO ls_sum WITH TABLE KEY path = iv_path.
  ENDIF.

  "! 단위 혼재 판정 / mixed base unit detection
  IF ls_sum-meins <> is_row-meins.
    ls_sum-unit_mix = abap_true.
  ENDIF.
  "! 통화 혼재 판정 / mixed currency detection
  IF ls_sum-waers <> is_row-waers.
    ls_sum-waers_mix = abap_true.
  ENDIF.

  ls_sum-qty_free  = ls_sum-qty_free  + is_row-qty_free.
  ls_sum-qty_qi    = ls_sum-qty_qi    + is_row-qty_qi.
  ls_sum-qty_block = ls_sum-qty_block + is_row-qty_block.
  ls_sum-qty_total = ls_sum-qty_total + is_row-qty_total.
  ls_sum-amount    = ls_sum-amount    + is_row-amount.

  MODIFY TABLE gt_sum FROM ls_sum.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_FILL_DISP_SUM
*&   소계 → 표시행 (A안: 단위 혼재면 수량 공란) / subtotal to display row
*&---------------------------------------------------------------------*
FORM f_fill_disp_sum USING iv_path TYPE c
                  CHANGING cs_disp TYPE ty_disp.

  DATA ls_sum TYPE ty_sum.

  CLEAR cs_disp.

  READ TABLE gt_sum INTO ls_sum WITH TABLE KEY path = iv_path.
  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  IF ls_sum-unit_mix = abap_true.
    "! A안: 단위가 섞인 노드는 수량을 비우고 "혼재"만 표시한다
    "! Option A: blank quantities and show "mixed" for mixed-unit nodes
    cs_disp-unit = '혼재'.
  ELSE.
    PERFORM f_num_to_char USING ls_sum-qty_free  CHANGING cs_disp-qty_free.
    PERFORM f_num_to_char USING ls_sum-qty_qi    CHANGING cs_disp-qty_qi.
    PERFORM f_num_to_char USING ls_sum-qty_block CHANGING cs_disp-qty_block.
    PERFORM f_num_to_char USING ls_sum-qty_total CHANGING cs_disp-qty_total.
    cs_disp-unit = ls_sum-meins.
  ENDIF.

  IF p_val = abap_true.
    IF ls_sum-waers_mix = abap_true.
      cs_disp-waers = '혼재'.
    ELSE.
      PERFORM f_amt_to_char USING ls_sum-amount CHANGING cs_disp-amount.
      cs_disp-waers = ls_sum-waers.
    ENDIF.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_FILL_DISP_ROW
*&   말단 행 → 표시행 / leaf row to display row
*&---------------------------------------------------------------------*
FORM f_fill_disp_row USING is_row  TYPE ty_row
                  CHANGING cs_disp TYPE ty_disp.

  CLEAR cs_disp.

  PERFORM f_num_to_char USING is_row-qty_free  CHANGING cs_disp-qty_free.
  PERFORM f_num_to_char USING is_row-qty_qi    CHANGING cs_disp-qty_qi.
  PERFORM f_num_to_char USING is_row-qty_block CHANGING cs_disp-qty_block.
  PERFORM f_num_to_char USING is_row-qty_total CHANGING cs_disp-qty_total.

  cs_disp-unit   = is_row-meins.
  cs_disp-refkey = is_row-refkey.
  cs_disp-mtart  = is_row-mtart.
  cs_disp-matkl  = is_row-matkl.

  IF p_val = abap_true.
    PERFORM f_amt_to_char USING is_row-amount CHANGING cs_disp-amount.
    cs_disp-waers = is_row-waers.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_NUM_TO_CHAR
*&   수량 편집 — 0은 공란, 정수는 소수점 없이 / quantity formatting
*&---------------------------------------------------------------------*
FORM f_num_to_char USING iv_val TYPE p
                CHANGING cv_out TYPE c.

  DATA: lv_val  TYPE p LENGTH 13 DECIMALS 3,
        lv_frac TYPE p LENGTH 13 DECIMALS 3.

  CLEAR cv_out.
  lv_val = iv_val.

  IF lv_val IS INITIAL.
    RETURN.
  ENDIF.

  lv_frac = lv_val - trunc( lv_val ).
  IF lv_frac IS INITIAL.
    WRITE lv_val TO cv_out DECIMALS 0.
  ELSE.
    WRITE lv_val TO cv_out DECIMALS 3.
  ENDIF.

  CONDENSE cv_out.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_AMT_TO_CHAR
*&   금액 편집 — 0은 공란 / amount formatting
*&   통화별 소수점은 반영하지 않고 정수로 표시한다(KRW 기준).
*&   Shown as integer; currency-specific decimals are not applied.
*&---------------------------------------------------------------------*
FORM f_amt_to_char USING iv_val TYPE p
                CHANGING cv_out TYPE c.

  DATA lv_val TYPE p LENGTH 15 DECIMALS 2.

  CLEAR cv_out.
  lv_val = iv_val.

  IF lv_val IS INITIAL.
    RETURN.
  ENDIF.

  WRITE lv_val TO cv_out DECIMALS 0.
  CONDENSE cv_out.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_DISPLAY_TREE
*&   도킹 컨테이너 + ALV 트리 / docking container and ALV tree
*&---------------------------------------------------------------------*
FORM f_display_tree.

  DATA: lt_fcat  TYPE lvc_t_fcat,
        ls_hhdr  TYPE lvc_s_hhdr,
        ls_layn  TYPE lvc_s_layn,
        ls_disp  TYPE ty_disp,
        lv_path  TYPE c LENGTH 40,
        lv_text  TYPE lvc_value,
        lv_k1    TYPE lvc_nkey,
        lv_k2    TYPE lvc_nkey,
        lv_k3    TYPE lvc_nkey,
        lv_k4    TYPE lvc_nkey,
        lv_k5    TYPE lvc_nkey,
        lv_bukrs TYPE t001-bukrs,
        lv_werks TYPE t001w-werks,
        lv_kind  TYPE c LENGTH 1,
        lv_l4key TYPE c LENGTH 10.

  PERFORM f_build_fieldcat CHANGING lt_fcat.

  "! 계층 머리글은 짧게 — 필드 길이가 짧아 잘릴 수 있다 / keep the heading short
  ls_hhdr-heading = '법인/플랜트/재고/자재'.
  ls_hhdr-width   = 55.

*--- 컨테이너 / container --------------------------------------------*
  CREATE OBJECT go_dock
    EXPORTING
      repid = sy-repid
      dynnr = sy-dynnr
      side  = cl_gui_docking_container=>dock_at_left
      ratio = 95
    EXCEPTIONS
      OTHERS = 1.
  IF sy-subrc <> 0.
    MESSAGE '화면 컨테이너 생성에 실패했습니다. / Container creation failed.' TYPE 'E'.
  ENDIF.

  "! item_selection = false → 행 전체 더블클릭이 노드 이벤트로 들어온다
  "! With item_selection off, a double click anywhere in the row is a node event
  CREATE OBJECT go_tree
    EXPORTING
      i_parent            = go_dock
      node_selection_mode = cl_gui_column_tree=>node_sel_mode_single
      item_selection      = abap_false
      no_html_header      = abap_true
    EXCEPTIONS
      OTHERS              = 1.
  IF sy-subrc <> 0.
    MESSAGE 'ALV 트리 생성에 실패했습니다. / ALV tree creation failed.' TYPE 'E'.
  ENDIF.

  go_tree->set_table_for_first_display(
    EXPORTING
      is_hierarchy_header = ls_hhdr
    CHANGING
      it_fieldcatalog     = lt_fcat
      it_outtab           = gt_disp ).

  "! 선택 모드에 따라 둘 중 하나가 발생하므로 양쪽 모두 등록한다
  "! Register both, since only one of them fires depending on the selection mode
  SET HANDLER lcl_handler=>on_node_double_click FOR go_tree.
  SET HANDLER lcl_handler=>on_item_double_click FOR go_tree.

*--- 노드 생성 / build nodes -----------------------------------------*
  CLEAR: lv_bukrs, lv_werks, lv_kind, lv_l4key.

  LOOP AT gt_row INTO DATA(ls_row).

    "! 1단 법인 / level 1 company code
    IF ls_row-bukrs <> lv_bukrs.
      lv_bukrs = ls_row-bukrs.
      CLEAR: lv_werks, lv_kind, lv_l4key.

      lv_path = ls_row-bukrs.
      PERFORM f_fill_disp_sum USING lv_path CHANGING ls_disp.
      CONCATENATE ls_row-bukrs ls_row-butxt INTO lv_text SEPARATED BY space.

      CLEAR ls_layn.
      ls_layn-isfolder = abap_true.
      go_tree->add_node(
        EXPORTING
          i_relat_node_key = ''
          i_relationship   = cl_gui_column_tree=>relat_last_child
          i_node_text      = lv_text
          is_node_layout   = ls_layn
          is_outtab_line   = ls_disp
        IMPORTING
          e_new_node_key   = lv_k1 ).
    ENDIF.

    "! 2단 플랜트 / level 2 plant
    IF ls_row-werks <> lv_werks.
      lv_werks = ls_row-werks.
      CLEAR: lv_kind, lv_l4key.

      CONCATENATE ls_row-bukrs ls_row-werks INTO lv_path SEPARATED BY c_sep.
      PERFORM f_fill_disp_sum USING lv_path CHANGING ls_disp.
      CONCATENATE ls_row-werks ls_row-wname INTO lv_text SEPARATED BY space.

      CLEAR ls_layn.
      ls_layn-isfolder = abap_true.
      go_tree->add_node(
        EXPORTING
          i_relat_node_key = lv_k1
          i_relationship   = cl_gui_column_tree=>relat_last_child
          i_node_text      = lv_text
          is_node_layout   = ls_layn
          is_outtab_line   = ls_disp
        IMPORTING
          e_new_node_key   = lv_k2 ).
    ENDIF.

    "! 3단 재고 구분 / level 3 stock kind
    IF ls_row-kind <> lv_kind.
      lv_kind = ls_row-kind.
      CLEAR lv_l4key.

      CONCATENATE ls_row-bukrs ls_row-werks ls_row-kind INTO lv_path SEPARATED BY c_sep.
      PERFORM f_fill_disp_sum USING lv_path CHANGING ls_disp.
      IF ls_row-kind = c_kind_loc.
        lv_text = '저장위치 재고 / Storage location stock'.
      ELSE.
        lv_text = '특별재고 / Special stock'.
      ENDIF.

      CLEAR ls_layn.
      ls_layn-isfolder = abap_true.
      go_tree->add_node(
        EXPORTING
          i_relat_node_key = lv_k2
          i_relationship   = cl_gui_column_tree=>relat_last_child
          i_node_text      = lv_text
          is_node_layout   = ls_layn
          is_outtab_line   = ls_disp
        IMPORTING
          e_new_node_key   = lv_k3 ).
    ENDIF.

    "! 4단 저장위치 또는 특별재고 유형 / level 4
    IF ls_row-l4key <> lv_l4key.
      lv_l4key = ls_row-l4key.

      CONCATENATE ls_row-bukrs ls_row-werks ls_row-kind ls_row-l4key
             INTO lv_path SEPARATED BY c_sep.
      PERFORM f_fill_disp_sum USING lv_path CHANGING ls_disp.
      lv_text = ls_row-l4text.

      CLEAR ls_layn.
      ls_layn-isfolder = abap_true.
      go_tree->add_node(
        EXPORTING
          i_relat_node_key = lv_k3
          i_relationship   = cl_gui_column_tree=>relat_last_child
          i_node_text      = lv_text
          is_node_layout   = ls_layn
          is_outtab_line   = ls_disp
        IMPORTING
          e_new_node_key   = lv_k4 ).
    ENDIF.

    "! 5단 자재 / level 5 material
    PERFORM f_fill_disp_row USING ls_row CHANGING ls_disp.
    CONCATENATE ls_row-matnr ls_row-maktx INTO lv_text SEPARATED BY space.

    CLEAR ls_layn.
    ls_layn-isfolder = abap_false.
    go_tree->add_node(
      EXPORTING
        i_relat_node_key = lv_k4
        i_relationship   = cl_gui_column_tree=>relat_last_child
        i_node_text      = lv_text
        is_node_layout   = ls_layn
        is_outtab_line   = ls_disp
      IMPORTING
        e_new_node_key   = lv_k5 ).

    "! 더블클릭 시 MM03 으로 보낼 자재를 기억한다 / remember material per node
    INSERT VALUE #( nkey = lv_k5 matnr = ls_row-matnr ) INTO TABLE gt_nodemap.

  ENDLOOP.

  go_tree->frontend_update( ).

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_BUILD_FIELDCAT
*&   필드카탈로그 수동 구성 (DDIC 구조 생성 없음)
*&   Field catalog built manually; no DDIC structure is created
*&---------------------------------------------------------------------*
FORM f_build_fieldcat CHANGING ct_fcat TYPE lvc_t_fcat.

  CLEAR ct_fcat.

  PERFORM f_add_fcat USING 'QTY_FREE'  '가용재고'  20 'R' CHANGING ct_fcat.
  PERFORM f_add_fcat USING 'QTY_QI'    '품질검사'  20 'R' CHANGING ct_fcat.
  PERFORM f_add_fcat USING 'QTY_BLOCK' '보류'      20 'R' CHANGING ct_fcat.
  PERFORM f_add_fcat USING 'QTY_TOTAL' '합계'      20 'R' CHANGING ct_fcat.
  PERFORM f_add_fcat USING 'UNIT'      '단위'      10 'C' CHANGING ct_fcat.
  PERFORM f_add_fcat USING 'AMOUNT'    '평가액'    24 'R' CHANGING ct_fcat.
  PERFORM f_add_fcat USING 'WAERS'     '통화'       5 'C' CHANGING ct_fcat.
  PERFORM f_add_fcat USING 'REFKEY'    '참조'      40 'L' CHANGING ct_fcat.
  PERFORM f_add_fcat USING 'MTART'     '자재유형'   4 'C' CHANGING ct_fcat.
  PERFORM f_add_fcat USING 'MATKL'     '자재그룹'   9 'C' CHANGING ct_fcat.

  "! 금액 표시 옵션이 꺼져 있으면 평가액·통화 열을 숨긴다
  "! Hide amount and currency columns when the option is off
  IF p_val <> abap_true.
    LOOP AT ct_fcat ASSIGNING FIELD-SYMBOL(<fc>)
         WHERE fieldname = 'AMOUNT' OR fieldname = 'WAERS'.
      <fc>-no_out = abap_true.
    ENDLOOP.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_ADD_FCAT
*&   필드카탈로그 1행 추가 / append one field catalog entry
*&---------------------------------------------------------------------*
FORM f_add_fcat USING iv_field TYPE c
                      iv_text  TYPE c
                      iv_len   TYPE i
                      iv_just  TYPE c
             CHANGING ct_fcat  TYPE lvc_t_fcat.

  DATA ls_fcat TYPE lvc_s_fcat.

  CLEAR ls_fcat.
  ls_fcat-fieldname = iv_field.
  ls_fcat-inttype   = 'C'.
  ls_fcat-datatype  = 'CHAR'.
  ls_fcat-intlen    = iv_len.
  ls_fcat-outputlen = iv_len.
  ls_fcat-just      = iv_just.
  ls_fcat-coltext   = iv_text.
  ls_fcat-scrtext_l = iv_text.
  ls_fcat-scrtext_m = iv_text.
  ls_fcat-scrtext_s = iv_text.
  APPEND ls_fcat TO ct_fcat.

ENDFORM.
