# 코드 리뷰 체크리스트 (AI 자가검증 + 동료 리뷰용)

## A. 정확성 (Activation 전에 AI가 자가점검)

- [ ] DDIC 필드명이 수집값(`ddic-collect`)과 일치한다 (추측 필드에는 `[확인필요]` 표기)
- [ ] 조인 조건·WHERE가 스펙 §1과 일치한다
- [ ] 메시지 클래스·번호가 SE91 정의서와 일치한다 (하드코딩 `e001` 단독 사용 없음)
- [ ] `SY-SUBRC`가 모든 DB I/O·BAPI·RFC 호출 직후 체크된다

## B. 안정성·성능

- [ ] `SELECT *`·루프 내 `SELECT`·`COMMIT` 남용 없음
- [ ] `FOR ALL ENTRIES` 앞 `IS NOT INITIAL` 체크 있음
- [ ] 대량(1만건+)는 `PACKAGE SIZE`·배치잡·잡 로그 고려됨
- [ ] `AUTHORITY-CHECK` 누락 없음 (없으면 TODO 명시)

## C. 운영성

- [ ] 상단 헤더(프로그램명·TR·변경이력) 있음
- [ ] `TODO(GUI)` (SE91·SE93·SU21·SM59에서 할 일) 목록화됨
- [ ] 테스트 절차(T1~T3) + 오류 회수 양식 동봉됨
- [ ] 개인정보·하드코딩(회사코드·경로·PW) 없음
