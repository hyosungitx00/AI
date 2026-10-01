# AI
AI연구과제 활동

---

# SAP ABAP ALV 조회 화면 — Cursor AI 프롬프트 구성 조건

Cursor AI에게 SAP ABAP ALV 조회 화면 설계 및 코드 개발을 요청할 때 사용하는 프롬프트 템플릿입니다.
필수 항목(1~6번)을 모두 채우면 Selection Screen, DB 조회 로직, ALV 출력 코드까지 생성 가능합니다.

---

## 필수 항목

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[1. 기본 정보]
기능명      :
프로그램명  :
프로그램 개요 : (예: 구매오더 번호/공급업체/생성일 조건으로 구매오더 Header+Item을
               조회하여 ALV로 출력)
SAP 환경    : [ ] ECC (Classic ABAP)
              [ ] S/4HANA On-Premise
              [ ] S/4HANA Cloud / BTP

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[2. 화면 유형]
화면 유형 : ALV 조회 화면 (Selection Screen + ALV 결과)
ALV 구현 방식:
  [✓] CL_GUI_ALV_GRID             ← 기본, OOP 방식 (별도 Screen 100 필요)
  [ ] REUSE_ALV_GRID_DISPLAY_LVC  ← Function Module 방식
  [ ] CL_SALV_TABLE               ← OOP 방식, 별도 Screen 불필요

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[3. Selection Screen 필드 정의]

[필드 목록]
변수명     | 한글 레이블 | 입력 유형(PARAMETERS/SELECT-OPTIONS) | 필수 | F4 | 범위체크 | 참조 테이블.필드 | 초기값
----------|------------|-------------------------------------|-----|----|---------|--------------|---------
예)S_EBELN | 발주번호   | SELECT-OPTIONS                      | N   | N  | N       | EKKO-EBELN   |
          |            |                                     |     |    |         |              |

  * 범위체크 Y : SELECT-OPTIONS 날짜 필드에서 FROM > TO 입력 시 오류 처리 자동 생성

[입력 조건 / Validation]
① 필드 단위 필수 입력 체크 (필드 목록 필수=Y 외, 조건부 필수 등 추가 체크 필요 시):
   -

② 기타 값 범위 / 조합 체크:
   (예: 특정 필드 조합 필수, 값 범위 제한, DB 존재 여부 검증 등)
   -

③ F4 검색도움말(SEARCH HELP) 매핑 (F4=Y 필드 대상):
   변수명      | 검색도움말 이름
   -----------|---------------
   예) S_LIFNR | KREDITOR

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[4. 레이아웃 구조]
HEADER 영역 (BLOCK 이름 / 타이틀 텍스트 / 포함 필드):
BODY   영역 (BLOCK 이름 / 타이틀 텍스트 / 포함 필드):
TABLE  영역 (ALV 타이틀):
FOOTER 영역 (합계 행 Y/N / 건수 표시 Y/N):

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[5. DB / 테이블 정의]

메인 테이블 (별칭):

JOIN 테이블:
순번 | 테이블 | 별칭 | JOIN 유형(INNER/LEFT) | JOIN 조건           | 추가 조건
-----|-------|-----|---------------------|--------------------|----------
예)1 | EKPO  | B   | INNER               | A~EBELN = B~EBELN  | B~LOEKZ = ''
예)2 | LFA1  | C   | LEFT                | A~LIFNR = C~LIFNR  |
    |       |     |                     |                    |

WHERE 조건:
변수명       | DB 필드   | 연산자 | 조건 유형   | 고정값
------------|----------|-------|-----------|-------
예) S_EBELN  | A~EBELN  | IN    | 사용자입력  |
예) P_EKORG  | A~EKORG  | =     | 사용자입력  |
예)          | A~BSTYP  | =     | 고정조건   | 'F'
예)          | B~LOEKZ  | =     | 고정조건   | ''
            |          |       |           |

  * 조건 유형
    - 사용자입력 : Selection Screen 변수를 WHERE 절에 연결
    - 고정조건   : 코드에 하드코딩되는 필터 (변수명 없음)

정렬 기준 :  (예: BEDAT 내림차순, EBELN 오름차순)
정렬 방식 :  [ ] DB ORDER BY   [ ] SORT (LEFT JOIN 포함 시 권장)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[6. ALV 출력 / 내부 테이블 통합 정의]

[컬럼 정의]
순서 | 내부테이블 필드명 | SELECT 원본(테이블~필드) | 컬럼 헤더(한글) | 너비 | 정렬(L/C/R) | 합계(Y/N)
----|----------------|----------------------|------------|-----|-----------|--------
예)1 | EBELN          | A~EBELN              | 발주번호    | 10  | L         | N
    |                |                      |            |     |           |

[이벤트 동작 정의] (더블클릭 / 핫스팟 사용 시 기재)
이벤트 유형     | 대상 필드  | 동작 설명                        | 전달 파라미터
--------------|----------|--------------------------------|-------------
예) 더블클릭    | 행 전체   | 상세 팝업 화면 호출 (SCREEN 200)   | EBELN
예) 핫스팟     | EBELN    | 트랜잭션 ME23N 호출               | EBELN
              |          |                                |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 추가 항목

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[B. ALV 특수 기능]
  더블클릭 이벤트 : Y / N
    대상 : 행 전체 / 특정 컬럼명:
    동작 요약 : (상세는 [6. 이벤트 동작 정의]에 기재)

  핫스팟 컬럼 : Y / N
    대상 컬럼(필드명) :
    동작 요약 : (상세는 [6. 이벤트 동작 정의]에 기재)

  셀 색상 조건    :
  줄무늬(ZEBRA)   : Y / N
  ALV 레이아웃 저장 : Y / N
  엑셀 다운로드   : 기본 툴바 사용 / 커스텀 버튼 추가

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[C. GUI 커스텀 버튼]
  버튼명      | 기능키 | 아이콘      | 동작
  ----------|------|-----------|----------
  예) 엑셀   | F6   | ICON_XLS  | ALV 엑셀 다운로드

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[D. 메시지 처리]
  조회 결과 없을 때 처리 :  (예: '조회 결과가 없습니다' 메시지 후 종료)
  오류 발생 시 처리 방식 :  메시지 출력 / 팝업 / 로그 테이블 적재

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[E. 권한 (Authority Check)]
  권한 오브젝트명:
  체크 필드 및 값:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 코드 생성 규칙 (버전 무관 공통 적용)

```
1. TABLES 선언
   SELECT-OPTIONS ... FOR table-field 구문을 사용하는 경우
   반드시 상단에 TABLES: 선언 필요.
   (HANA 여부와 무관한 ABAP 공통 규칙)
   예) TABLES: lfa1, lfb1.

2. TEXT-001 등 텍스트 심볼
   INITIALIZATION에서 TEXT-xxx = '값' 직접 할당 방식 사용 안 함.
   SE38 → Goto → Text Elements → Text Symbols에 등록하는 방식으로 안내.
   (모든 ABAP 버전 공통 권장 방식)

3. sy-ucomm 기능 코드 4자리 제한
   CASE sy-ucomm 에서 사용하는 기능 코드는 반드시 4자리 이하로 작성.
   예) CANCEL(6자리) → CANC(4자리)
       BACK(4자리) → 그대로 사용 가능
       EXIT(4자리) → 그대로 사용 가능

4. CL_GUI_ALV_GRID 사용 시 Module Pool 필수 규칙
   (버전 무관, ALV 방식으로 CL_GUI_ALV_GRID 선택 시 항상 적용)

   ① ok_code 전역 선언 필수
      DATA: ok_code TYPE sy-ucomm.
      PAI 모듈에서 sy-ucomm 대신 ok_code 사용.
      SE51 Element List에 OK_CODE 필드(Type: OK) 등록 필요.

   ② CREATE OBJECT 예외 처리 필수
      go_container / go_grid 생성 시 EXCEPTIONS 절 추가.
      예외 발생 시 명확한 오류 메시지 출력 후 RETURN 처리.

      [S/4HANA 특이 동작]
      S/4HANA 환경에서는 SE51 Screen에 Custom Control이 없어도
      CL_GUI_CUSTOM_CONTAINER 생성 시 예외가 발생하지 않고
      화면 전체를 기본 컨테이너 영역으로 사용하는 경우가 있음.
      ECC 환경에서는 Custom Control이 없으면 create_error 예외 발생.
      → SE51 Custom Control 정의는 ECC 필수 / S/4HANA 선택적

   ③ Flow Logic에 AT EXIT-COMMAND 추가 필수
      GUI Status에서 Exit Command 타입(E)으로 설정된 버튼(BACK/EXIT/CANC)은
      일반 MODULE ... INPUT 으로 잡히지 않음.
      PROCESS AFTER INPUT.
        MODULE pai_xxxx AT EXIT-COMMAND.
        MODULE pai_xxxx.
```

---

## 항목별 설명

### 3번 — Selection Screen 필드 목록 컬럼 설명

| 컬럼 | 설명 |
|------|------|
| 변수명 | ABAP 변수명 (예: S_EBELN, P_BUKRS) |
| 입력 유형 | PARAMETERS: 단일 값 / SELECT-OPTIONS: 범위·복수 값 |
| 필수 | Y: 미입력 시 오류 처리 / N: 선택 입력 |
| F4 | Y: 검색도움말 팝업 연결 (③ 매핑 테이블에 도움말명 기재) |
| 범위체크 | Y: 날짜 SELECT-OPTIONS에서 FROM > TO 입력 시 오류 자동 생성 |
| 참조 테이블.필드 | DDIC 참조 (타입, F4, 도움말 자동 연결) |
| 초기값 | INITIALIZATION 블록에서 자동 설정할 기본값 |

### 3번 — Validation 항목 설명

| 항목 | 설명 |
|------|------|
| ① 필드 단위 필수 체크 | 조건부 필수처럼 필수=Y 만으로 표현이 안 되는 경우 |
| ② 기타 범위/조합 체크 | 두 필드 이상의 조합 규칙, 값 범위 제한, DB 존재 여부 검증 등 |
| ③ F4 검색도움말 매핑 | F4=Y 필드에 연결할 SAP 검색도움말(SEARCH HELP) 이름 |

### 5번 — WHERE 조건 유형 설명

| 조건 유형 | 설명 |
|---------|------|
| 사용자입력 | Selection Screen 변수를 WHERE 절에 연결 (동적 조건) |
| 고정조건 | 코드에 하드코딩되는 필터, 변수명 없음 (예: BSTYP = 'F') |

### 6번 — ALV 구현 방식별 차이

| 방식 | 특징 |
|------|------|
| CL_GUI_ALV_GRID | OOP 방식, 이벤트 핸들러 풍부, 별도 Screen(Dynpro) 필요 |
| REUSE_ALV_GRID_DISPLAY_LVC | Function Module 호출, 가장 간단, REPORT 바로 사용 |
| CL_SALV_TABLE | OOP 방식, REPORT 바로 사용, 커스터마이징 제한 있음 |
