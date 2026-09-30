*&---------------------------------------------------------------------*
*& Function Module Z_SD_GET_SALES (함수그룹 ZFGSD01)
*&---------------------------------------------------------------------*
*& 판매조직별 판매 집계 조회 (샘플) / Sample FM: sales total by org
*& 기준: SAP_BASIS 750 / S/4HANA, 모던 ABAP 허용
*&      / Baseline: SAP_BASIS 750 / S/4HANA, modern ABAP allowed
*& 복사 순서 / Copy order:
*&   ① SE11 — 구조 ZSSD_SALES_S01 생성 (아래 DDIC 정의 참조)
*&   ② SE37 — 함수그룹 ZFGSD01 생성(없으면) → 함수 Z_SD_GET_SALES 생성
*&   ③ Import/Export/Tables/Exceptions 탭을 아래 파라미터표대로 등록
*&   ④ 본 소스 붙여넣기 → Ctrl+F2 → SE37 단위 테스트(F8)
*&---------------------------------------------------------------------*
FUNCTION z_sd_get_sales.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(iv_vkorg) TYPE  vbak-vkorg
*"     VALUE(iv_erdat_fm) TYPE  datum OPTIONAL
*"     VALUE(iv_erdat_to) TYPE  datum OPTIONAL
*"  EXPORTING
*"     VALUE(ev_netwr) TYPE  vbap-netwr
*"  TABLES
*"      et_items STRUCTURE  zssd_sales_s01
*"  EXCEPTIONS
*"      no_data
*"      no_auth
*"----------------------------------------------------------------------

  "! 권한 체크 / Authority check
  AUTHORITY-CHECK OBJECT 'V_VBAK_VKO'
    ID 'VKORG' FIELD iv_vkorg
    ID 'ACTVT' FIELD '03'.
  IF sy-subrc <> 0.
    " TODO(GUI): SU53에서 실제 오브젝트 확인 후 조정
    RAISE no_auth.
  ENDIF.

  "! 판매문서 조회 / Select sales documents
  SELECT a~vbeln, a~erdat, a~kunnr, c~name1, b~netwr, a~waerk
    INTO TABLE @et_items
    FROM vbak AS a
    INNER JOIN vbap AS b ON a~vbeln = b~vbeln
    LEFT OUTER JOIN kna1 AS c ON a~kunnr = c~kunnr
    WHERE a~vkorg = @iv_vkorg
      AND a~erdat BETWEEN @iv_erdat_fm AND @iv_erdat_to.

  IF sy-subrc <> 0.
    RAISE no_data.
  ENDIF.

  "! 합계 계산 / Total calculation (DB 집계 대신 ABAP 합산 — 소규모 샘플 기준)
  CLEAR ev_netwr.
  LOOP AT et_items ASSIGNING FIELD-SYMBOL(<ls_item>).
    ev_netwr = ev_netwr + <ls_item>-netwr.
  ENDLOOP.

ENDFUNCTION.

"!----------------------------------------------------------------------
"! DDIC 정의서 — 구조 ZSSD_SALES_S01 (SE11, Structure) / DDIC appendix
"! VBELN (VBAK-VBELN, CHAR 10), ERDAT (VBAK-ERDAT, DATS 8),
"! KUNNR (VBAK-KUNNR, CHAR 10), NAME1 (KNA1-NAME1, CHAR 35),
"! NETWR (VBAP-NETWR, CURR 15,2), WAERK (VBAK-WAERK, CUKY 5)
"!----------------------------------------------------------------------
"! SE37 테스트 절차 / Unit test (SE37 → F8 단위 테스트)
"! T1: IV_VKORG=1000, IV_ERDAT_FM=20240101, IV_ERDAT_TO=20240131
"!     → SY-SUBRC=0, ET_ITEMS 100행 내외, EV_NETWR=합계
"! T2: IV_VKORG=9999 → NO_DATA (SY-SUBRC=1)
"! T3: 권한 없는 유저 → NO_AUTH (SY-SUBRC=2)
"! 오류 회수: 함수명 + 입력값(T1/T2/T3) + SY-SUBRC + ST22 덤프명 + 메시지 전문
