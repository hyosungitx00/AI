*&---------------------------------------------------------------------*
*& Report ZSD_FIXTURE_ALV01
*&---------------------------------------------------------------------*
*& 점검기 통과 기준 샘플 / Checker baseline fixture
*& 기준: SAP_BASIS 750 / S/4HANA, 모던 ABAP 허용
*&      / Baseline: SAP_BASIS 750 / S/4HANA, modern ABAP allowed
*& 복사 순서 / Copy order: ① SE38 생성 → ② 전체 붙여넣기 → ③ Ctrl+F2
*&---------------------------------------------------------------------*
REPORT zsd_fixture_alv01.

"! 테이블 선언 / Table declaration (SELECT-OPTIONS FOR dict-field에 필수)
TABLES vbak.

TYPES: BEGIN OF ty_head,
         vbeln TYPE vbak-vbeln,   " 판매문서 / Sales document
         erdat TYPE vbak-erdat,   " 생성일 / Created on
       END OF ty_head.

DATA gt_head TYPE STANDARD TABLE OF ty_head.
DATA gt_item TYPE STANDARD TABLE OF ty_head.

PARAMETERS p_vkorg TYPE vbak-vkorg OBLIGATORY.
SELECT-OPTIONS s_erdat FOR vbak-erdat.

"! 입력 검증 / Input validation
AT SELECTION-SCREEN.
  IF s_erdat-low > s_erdat-high AND s_erdat-high IS NOT INITIAL.
    MESSAGE '시작일이 종료일보다 큽니다. / Start date later than end date.' TYPE 'E'.
  ENDIF.

START-OF-SELECTION.
  "! 권한 체크 / Authority check
  AUTHORITY-CHECK OBJECT 'V_VBAK_VKO'
    ID 'VKORG' FIELD p_vkorg
    ID 'ACTVT' FIELD '03'.
  IF sy-subrc <> 0.
    MESSAGE '권한이 없습니다. / No authority.' TYPE 'E'.
    RETURN.
  ENDIF.

  "! 헤더 조회 / Select headers
  SELECT vbeln, erdat
    INTO TABLE @gt_head
    FROM vbak
    WHERE vkorg = @p_vkorg
      AND erdat IN @s_erdat.
  IF sy-subrc <> 0.
    MESSAGE '조건에 맞는 데이터가 없습니다. / No data found.' TYPE 'S'.
    RETURN.
  ENDIF.

  "! 품목 조회 / Select items
  IF gt_head IS NOT INITIAL.
    SELECT vbeln, erdat
      INTO TABLE @gt_item
      FROM vbap
      FOR ALL ENTRIES IN @gt_head
      WHERE vbeln = @gt_head-vbeln.
    IF sy-subrc <> 0.
      CLEAR gt_item.
    ENDIF.
  ENDIF.

"!----------------------------------------------------------------------
"! DDIC 정의서 / DDIC appendix: VBAK-VBELN CHAR 10, VBAK-ERDAT DATS 8
"! 테스트 절차 / Test procedure
"! T1: VKORG=1000 → ALV 표시 / T2: VKORG=9999 → S 메시지 / T3: 권한 없음 → E 메시지
"!----------------------------------------------------------------------
