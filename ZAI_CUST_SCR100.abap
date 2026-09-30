*&---------------------------------------------------------------------*
*& 파일 위치 : SE51 → 프로그램명 ZAI_CUST → Screen Number 100
*&             → Flow Logic 탭에 아래 내용 입력
*&
*& [Screen 100 설정]
*& - Screen Type    : Normal
*& - Next Screen    : 0
*& - Custom Control : 이름 = CUSTOM_CONTAINER, 화면 전체 영역 차지
*&---------------------------------------------------------------------*

PROCESS BEFORE OUTPUT.
  MODULE pbo_0100.

PROCESS AFTER INPUT.
  MODULE pai_0100.
