*----------------------------------------------------------------------*
* Screen 100 Flow Logic (SE51 입력용)
* 프로그램: ZAI_VEND / Screen Number: 100
*----------------------------------------------------------------------*
* [SE51 설정 가이드]
* 1. SE51 → 프로그램명: ZAI_VEND / Screen Number: 100 → Create
* 2. Attributes 탭:
*    - Short Description: 고객 데이터 조회 ALV
*    - Screen Type: Normal
* 3. Element List 탭:
*    - Name: OK_CODE / Type: OK 추가
* 4. Layout 탭:
*    - Custom Control 생성 → Name: CUSTOM_CONTAINER (전체 화면 크기로 설정)
* 5. Flow Logic 탭에 아래 내용 입력:
*----------------------------------------------------------------------*

PROCESS BEFORE OUTPUT.
  MODULE pbo_0100.

PROCESS AFTER INPUT.
  MODULE pai_0100 AT EXIT-COMMAND.
  MODULE pai_0100.
