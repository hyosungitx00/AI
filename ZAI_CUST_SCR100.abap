*&---------------------------------------------------------------------*
*& 파일 위치 : SE51 → 프로그램명 ZAI_CUST → Screen Number 100
*&             → Flow Logic 탭에 아래 내용 입력
*&
*& [Screen 100 설정]
*& - Screen Type    : Normal
*& - Next Screen    : 0
*&
*& [Element List 설정] SE51 → Screen 100 → Element List
*& - OK_CODE 필드 추가 (함수 코드 수신용)
*&   Field Name : OK_CODE
*&   Type       : OK  (Function Code 선택)
*&
*& [Layout 설정] SE51 → Screen 100 → Layout
*& - Custom Control 추가
*&   이름 : CUSTOM_CONTAINER
*&   영역 : 화면 전체 (상단 여백 제외)
*&---------------------------------------------------------------------*

PROCESS BEFORE OUTPUT.
  MODULE pbo_0100.

PROCESS AFTER INPUT.
  MODULE pai_0100 AT EXIT-COMMAND.    "← BACK/EXIT/CANC 등 Exit Command 타입 처리
  MODULE pai_0100.
