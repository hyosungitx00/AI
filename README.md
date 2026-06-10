# AI
AI연구과제 활동

## ABAP 통합 에러 모니터링 화면 코드

화면 설계 기반 ABAP 소스는 다음 파일에 있습니다.

- `src/zerr_monitor_dashboard.abap`

이 소스는 S/4HANA, ABAP 7.50 기준의 실행 리포트 골격입니다.
Selection Screen, 탭스트립 기반 출력 화면, 전체 요약 HTML 대시보드, ST22/SM37/SXI 탭별 ALV 리스트 구성을 포함합니다.

SAP GUI에서 사용하려면 소스 상단 주석의 SE51/SE41 메모에 따라 Screen 0100, Subscreen 0110~0140, GUI Status `MAIN`, Text Symbol을 함께 생성해야 합니다.
