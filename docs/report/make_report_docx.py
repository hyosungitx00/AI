# -*- coding: utf-8 -*-
"""로컬에서 Word 문서 생성.
필요: pip install python-docx
실행: python make_report_docx.py
"""
from pathlib import Path
from docx import Document
from docx.shared import Pt, Cm

MD = r"""
# Cursor × ABAP Ops Monitor — 논의 정리 보고서

| 항목 | 내용 |
|------|------|
| 문서 성격 | 지금까지의 대화·실험을 **발표/보고용으로 자세히** 정리한 문서 (PPT 아님) |
| 대상 프로그램 | 읽기 전용 통합 운영 모니터 `Y_OPS_MONITOR_V2` (SM37 / ST22 / SXI) |
| 비교 세션 | **A** Awesome skills automation / **B** 통합 운영 모니터링 대시보드 |
| 작성 기준일 | 2026-08-13 |
| 정리 원칙 | 기승전결보다 **논의가 진행된 순서** · 수치와 한계를 생략하지 않음 |

---

## 0. 이 문서가 다루는 것 / 다루지 않는 것

### 다루는 것
1. 이 AI 저장소(폴더)에서 사용자가 주로 한 질문의 유형과 개수  
2. 집계에 **포함된 세션**과 **포함하지 못한 세션**(접근 한계)  
3. Session A에서 Skills를 만들고 Session B에서 재현한 **인과 관계**  
4. Skills/Rules에 **구체적으로 무엇이 들어갔는지**  
5. “만족할 때까지 질문 수”·DoD만으로 품질을 말하는 것의 **객관성 문제**  
6. 품질을 재기 위한 **Parity 채점표(56점)** 와 **Hard Gate**  
7. 최종 점수(A=54, B=55)와 **질문 수에 따른 점수 향상 곡선**  
8. “동일 프로그램 특화라서 효과가 컸다 / 다른 유형이면 다시 늘 것”이라는 **추정과 수치화**

### 다루지 않는 것
- SAP 실기 화면 캡처의 재현·재실행 절차  
- 회사 보안·GitHub 차단 정책 자체  
- SELECT-OPTIONS 등 **전사를 열 수 없었던 세션의 질문 전문** (개수에 못 넣음)

---

## 1. 배경: 무엇을 만들고 있었는가

대상은 SAP GUI 기반 **읽기 전용** 통합 운영 모니터링 프로그램이다.

- 배치 에러: SM37 (`TBTCO` 등)  
- 런타임 에러: ST22 (`RS_ST22_GET_DUMPS` 등)  
- 인터페이스 에러: SXI (`SXMSPERROR` 등)  

설계서(`docs/design/integrated-ops-monitor-design.md`)에 FR/NFR/확정 Open Issues가 정리되어 있고, 회사 노트북에서는 GitHub·원격 경로 접근이 어려워 SE38에 소스를 붙여 넣는 환경이었다. (전달 채널 자체에 대한 질문·`계속` 이어받기는 **본 문서 질문 집계에서 제외**한다. Delivery Rule·Preflight의 배경으로만 언급한다.)

---

## 2. 사용자가 주로 한 질문 — 유형

전사(transcript)를 기준으로 보면, 질문은 아래 유형에 반복적으로 모인다.  
(**제외:** 통짜/전체 소스·채팅 원문 요청, 잘린 출력에 대한 `계속`, GitHub·경로 대신 붙여 달라는 전달 전용 턴.)

### 2.1 컴파일·활성화·타입 오류
실기 SE38 활성화 후 오류 문구를 붙여 “고쳐달라”는 요청이 많다. 대표 패턴:

| 패턴 | 예시 |
|------|------|
| 선언 누락 | `MO_STATS_HTML` unknown 등 |
| ECC/버전 API | `MC_FC_EXPORT`, IGS `SET_CUSTOMIZING_*` |
| 타입·구조 | `E_ROW-INDEX`, `LS-DATUM`, ICON/TEXT |
| 문자열 템플릿 | CSS `{` vs `\|…\|` |
| Open SQL·포맷 | `MANDT` WHERE, `WRITE DD/MM` |
| 부분 붙여넣기 잔재 | `GV_T_B1` already declared |

### 2.2 UX·차트·레이아웃
- 비율·스크롤·“한눈에 보이게”  
- Top-N / 시간추이, 영역별 색·스케일  
- ALV 툴바 축소, 컬럼 축소  
- STATS/HELP를 MESSAGE가 아니라 HTML 팝업으로  

초기는 IGS 차트 시도 → 색/방향이 기대와 달라 **HTML/CSS 차트**로 수렴한다. 이 합의가 `abap-ops-monitor-ux`가 된다.

### 2.3 실기 동작 이상
- 빈 화면  
- 팝업 X(닫기) 미동작  
- ST22 목록이 비어 있음  
- 더블클릭 시 ST22 트랜잭션만 열리고 상세가 안 보임  

“코드에 기능이 있다”와 “실기에서 된다”가 다르다는 점이 나중에 **Hard Gate**의 근거가 된다.

### 2.4 화면·선택화면 설정 가이드
- Screen 0100, PF-STATUS, Selection texts / 텍스트심볼  

에이전트 VM에는 SAP GUI가 없으므로, **사용자 PC의 수작업**이 남는 영역이다.

### 2.5 후반 메타 논의 (본 문서의 직접 계기)
- 이 폴더에서 주로 한 질문 요약  
- 질문 개수 / 오류·기능수정 중복 제거 집계  
- 집계 범위(폴더만인지, SELECT-OPTIONS 세션 누락)  
- A vs B 차이·Skills 효과  
- DoD 신뢰성, 동일 프로그램 특화 가설  
- 객관적 채점표, Q별 Parity 곡선, Hard Gate 보정  

메타 질문 자체는 “프로그램 품질”이 아니므로, 효율 집계에서는 제외하는 것이 맞다.

---

## 3. 질문 개수 — 어떻게 셌고, 얼마인가

### 3.1 집계에 들어간 세션
Cloud Agent 전사를 **실제로 열 수 있었던** 것은 다음 두 개이다.

| 세션 | 역할 |
|------|------|
| **A** Awesome skills automation | 장기 구현 + 후반 Skills 정착 |
| **B** 통합 운영 모니터링 대시보드 | Skills+설계서 Greenfield 재현 |

### 3.2 집계에서 빠진 세션 (중요)
사용자 UI에는 대략 5개 전후의 관련 세션이 보일 수 있다. 예:

- SELECT-OPTIONS 수정·설계 보강 (PR #6 등)  
- 초기 프로토타입 / ST22 모니터 / 설계서 초안 세션  

그러나 이 환경의 transcript API로는 **만료·접근 불가(`not found or not accessible`)** 로 조회되지 않았다.  
따라서 아래 숫자는:

> **“이 AI 폴더의 모든 과거 대화”가 아니라,  
> “지금 전사를 읽을 수 있는 대화만”** 센 값이다.

SELECT-OPTIONS 세션이 프로그램 관련인 것은 맞다. **못 넣었다**는 것이 정직한 표현이다.

### 3.3 제외한 메시지
- “질문 요약해줘 / 개수 세어줘 / 다시 집계해줘” 등 **집계 메타**  
- 시스템·서브에이전트 완료 알림  
- **소스 복붙·전달 전용**: 통짜/전체 로직·채팅 원문·경로 대신 붙여 달라는 요청, 잘린 출력에 대한 `계속`  
- (효율·공정 비교 시) PPT 제작 턴은 `cum_Q_program`에서도 제외  

### 3.4 숫자 (2세션 합산, 메타·소스복붙 제외 후)

| 항목 | 개수 | 설명 |
|------|-----:|------|
| 총 질문 | **약 105** | A+B에서 메타·시스템·소스복붙/`계속` 제외 (재집계) |
| 오류 관련 (**중복 제거**) | **23** | 같은 오류 재보고는 1건 |
| 단순 기능 수정 (**중복 제거**) | **13~15** | UX·컬럼·색·팝업 polish 등 |
| 오류 raw (중복 포함, 참고) | 약 34 | |
| 기능수정 raw (참고) | 약 24 | |

이전 초안의 “총 질문 약 124~126”에는 소스 복붙·`계속` 등 전달 전용 턴(약 28건)이 포함되어 있었다. **본 문서에서는 제거**한다.  
오류·기능수정 버킷에는 원래부터 넣지 않았고, 발표자료·권한·설계 확정·단순 설명 등은 총 질문에만 남을 수 있다.

### 3.5 세션별 공정(프로그램 관련) 질문 — 이후 곡선용

| 세션 | `cum_Q_program` (대략) |
|------|------------------------:|
| A | **63** |
| B | **16** |

A의 raw user 메시지(~110)에는 발표자료·다운로드 마찰이 섞여 있어, **공정 비교는 63 vs 16**을 쓰는 것이 맞다. (가이드에도 “107과 단순 나눗셈 금지”가 명시되어 있다.)

---

## 4. Session A와 B의 관계 — 인과

### 4.1 한 줄
**A에서 프로그램을 만들며 오류·UX 왕복을 겪었고, 그 패턴을 Skill/Rule로 고착한 뒤, B에서 동일 설계서를 Skills만으로 다시 구현(재현)했다.**  
사용자가 말한 인과 인식은 이 구조와 일치한다.

### 4.2 Session A (Awesome skills automation)
1. 초반: 설계·권한·범위 확정, 로컬 리포트 `Y_OPS_MONITOR_V2` 방향  
2. 중반: 구현 ↔ 활성화 오류 ↔ UX 수정이 길게 반복  
   - IGS 차트 API 불일치  
   - ALV fcode / 타입 / 선언 누락  
   - 툴바·색·스케일·팝업을 “있어보이게” 다듬는 루프  
3. 곁가지: 발표자료(PPT/DOCX) 제작 — 프로그램 Parity와는 별도 비용  
4. 후반: “질문이 너무 많다 → skill화” 논의 후  
   - `abap-activation-preflight`  
   - `abap-ops-monitor-ux`  
   - `abap-requirement-intake`  
   - `abap-delivery-preferences`  
   등이 정착  

### 4.3 Session B (통합 운영 모니터링 대시보드)
1. Greenfield: 기존 구현을 복사하지 말고 설계서+skills로 새로 작성  
2. 첫 납품에 이미 HTML 차트·STATS/HELP·최소 툴바 등 **A에서 합의된 UX 바**를 반영하려는 방향  
3. 이후에도 실기에서 막힘:  
   - 문법(`CLIENT SPECIFIED`, `WRITE` 포맷)  
   - Dynpro/Selection texts 가이드  
   - 부분 붙여넣기 잔재  
   - 팝업 X  
   - ST22 목록 공백  
   - ST22 더블클릭 상세(인앱 HTML) 요구  
4. Skills가 **모든 실기 문제를 없앤 것은 아님**. 다만 A에 있던 **장시간 정적 오류 루프·IGS 탐색**은 크게 줄었다.

---

## 5. Skills / Rules에 들어간 내용 (구체)

### 5.1 Always-on Rules
- **읽기전용**: DML / COMMIT / Enqueue / Update Task / 재처리 금지  
- **Delivery**: GitHub URL만이 아니라 **채팅 붙여넣기**, 잘리면 `계속`, **선언부+구현 동시**  
- **Preflight 강제**: 붙여넣기 전 정적 점검, “일단 활성화해 보고 오류 달라”를 1차 검증으로 두지 않음  

### 5.2 `abap-activation-preflight` (P1~P10)
A에서 **실제로 난 실패**를 표로 고정한 것이다.

| ID | 세션에서 본 실패 | 점검 |
|----|------------------|------|
| P1 | `MO_*` unknown | DEFINITION에 멤버 선언 |
| P2 | 메서드/핸들러 unknown | 선언+구현 동시 |
| P3 | `MC_FC_EXPORT` 등 | ECC-safe fcode |
| P4 | IGS 커스터마이징 API | HTML viewer 패턴 우선 |
| P5 | CSS `{` vs string template | HTML은 `&&` 연결 |
| P6 | `LS-DATUM` 등 | `ty_dump` 등 명시 타입 |
| P7 | row index 타입 | `lvc_index` 등 |
| P8 | private REFRESH 호출 | public API만 |
| P9 | FM/DDIC 시그니처 | 프로그램 내 검증 타입 |
| P10 | 부분 붙여넣기 형제 누락 | 헬퍼·선언 함께 |

### 5.3 `abap-ops-monitor-ux`
“멋지게”의 합의안을 고정: HTML 차트, 영역색, 독립 스케일, Top-N/시간축 라벨, STATS/HELP HTML dialog, ALV 툴바 최소.

### 5.4 `abap-requirement-intake`
모호한 요청 시 ≤8 선택지로 **한 번** 계약을 맺고, Brief가 있으면 질문 생략.

### 5.5 전이성 (나중에 일반화 논의와 연결)
- Preflight·Delivery: **상대적으로 일반** (다른 ALV/HTML OO 리포트에도 유효한 항목 다수, Preflight 기준 약 70%를 전이 가능으로 평가)  
- Ops Monitor UX·read-only 도메인(SM37/ST22/SXI FM·테이블): **특화 비중 큼** (약 80%+)  

즉 Skills 효과 = **일반 층 + 이 프로그램 특화 층**의 합이다. “전부 암기”도 “전부 일반 AI 능력”도 아니다.

---

## 6. 객관성 문제 — 질문 수와 DoD

### 6.1 “만족하면 중단하고 Q를 센다”의 문제
- 중단 시점이 사람마다·상황마다 다름  
- 발표·다운로드·설명 턴이 섞이면 Q가 커 보임  
- Q가 줄었다고 **품질이 같다**고 말할 수 없음  

### 6.2 DoD(Definition of Done)란 무엇인가
DoD는 “이 체크리스트를 다 만족하면 유사 품질로 본다”는 **프로젝트 내부 합격선**이다.  
외부 표준·SAP 공식 지표가 아니다. B가 DoD 13/13이어도, 그것은:

- 같은 목표물을 다시 맞췄다는 뜻에 가깝고  
- **독립 심사·다른 프로그램 유형 검증**을 의미하지 않는다.

그래서 보고에서는 DoD를 “참고 체크”로만 쓰고, **품질 본문은 Parity 채점**으로 가는 것이 맞다.

### 6.3 분리 원칙 (합의된 측정 체계)

| 구분 | 무엇을 재나 | 무엇으로 재나 |
|------|-------------|---------------|
| **품질 동등성 (Parity)** | 최종 산출물이 설계·UX 바를 얼마나 충족하는가 | 56점 채점표 + Hard Gate |
| **과정 효율 (Cost)** | 그 수준에 도달하는 비용 | `cum_Q_program`, E_compile, E_runtime |

> 질문 수는 **효율**이지 **품질 점수**가 아니다.

---

## 7. Parity 채점표 — 어떻게 품질을 객관화했는가

### 7.1 점수 체계
- 항목마다 0 / 1 / 2  
- 섹션: S1 기능 20 + S2 안전 12 + S3 UX 16 + S4 전달 8 = **만점 56**  
- 증거: `C` 소스 / `R` 실기 / `A` 활성화 / `D` 설계 대조  
- `R`이 필요한 항목을 코드만 보고 2점 주지 않음 (최대 1)

### 7.2 Hard Gate (핵심 보정)
총점이 50을 넘어도, 아래가 **미해결**이면 **Parity PASS 불가**:

- SE38 활성화 실패·미해결 문법 오류 → `S2-06=0`  
- 메인 화면 미기동·빈 화면  
- 제공한 팝업이 안 열리거나 X로 안 닫힘  
- 필수 영역 조회가 버그로 항상 0건  
- 필수 드릴다운 불능  

또한 **코드만 있고 미실기**면 Total 상한 **40**.  
“소스에 HTML 차트 코드가 있다” ≠ PASS.

이 규칙은, 초기에 B를 ‘처음부터 거의 완성’처럼 그리던 곡선이 **잘못되었다**는 지적에 대한 직접 반영이다.

### 7.3 최종 채점 결과 (산출물 동등성)

| | Session A | Session B |
|--|----------:|----------:|
| S1 기능 | 20 | 20 |
| S2 안전 | 12 | 12 |
| S3 UX | 16 | 15 |
| S4 전달 | 6 | 8 |
| **총점** | **54** | **55** |
| 등급 | PASS | PASS |
| \|A−B\| | **1** → **품질 동등** | |

해석: **최종 품질은 비슷하다.** B의 질문이 적다고 품질을 깎아 본 것이 아니라, **같은 바를 더 짧은 과정으로 달성했는지**를 따로 본다.

---

## 8. 질문 수에 따른 Parity 향상 (Hard Gate 적용)

중간 점수는 transcript 마일스톤 기반 **사후 추정치(±2)** 이다. 최종행만 위 공식 채점과 맞춘다.

### 8.1 Session A (요약)
| cum_Q | 상태 | Total | 등급 |
|------:|------|------:|------|
| 1 | 착수 | 0 | FAIL |
| 9 | 스켈레톤·미기동 | 24 | FAIL |
| 15 | 첫 기동 | 31 | FAIL |
| 23~51 | IGS/타입/툴바/색 문제 지속 | 34~46 | FAIL~PARTIAL |
| **57** | HTML 차트+색 — 차단 해소 | **51** | **PASS** |
| 63 | HTML STATS/HELP | **54** | PASS |

첫 PASS: **약 57질문** 이후.

### 8.2 Session B (요약, 보정본)
| cum_Q | 상태 | Total | 등급 |
|------:|------|------:|------|
| 1 | 소스만·미실기 | **30** | FAIL |
| 3~5 | Dynpro/texts, 실기 미완 | 38~40 | FAIL |
| 6 | 붙여넣기 잔재 활성화 오류 | 37 | FAIL |
| 7 | 팝업 X 불능 → 수정 후에도 ST22 0건 | 39~45 | FAIL |
| 8~10 | UX polish, ST22 버그 잔존 | ~47 | PARTIAL |
| **12** | ST22 목록 복구, 차단 없음 | **53** | **PASS** |
| 16 | ST22 HTML 상세 등 | **55** | PASS |

첫 PASS: **약 12질문** 이후.  
예전의 “Q=3 PASS / 처음부터 완벽” 서술은 **철회**한다.

### 8.3 같은 질문 수에서 나란히 보기

| cum_Q | A | B |
|------:|--:|--:|
| 1 | 0 FAIL | 30 FAIL |
| 5 | ~2 FAIL | 40 FAIL |
| 10 | ~30 FAIL | 47 PARTIAL |
| 12 | ~31 FAIL | **53 PASS** |
| 16 | ~33 FAIL | **55 PASS** |
| 57 | **51 PASS** | — |
| 63 | **54 PASS** | — |

### 8.4 효율 (품질과 별개)

| | A | B |
|--|--:|--:|
| 첫 PASS까지 Q | 57 | 12 |
| 첫 PASS에서의 pt/Q | ≈0.89 | ≈4.4 |
| 최종까지 Q | 63 | 16 |
| 최종 pt/Q | ≈0.86 | ≈3.4 |

**말해야 할 것:** 최종 점수는 비슷하고, **PASS에 도달하는 속도**가 B에서 분명히 빠르다.  
**말하면 안 되는 것:** B는 첫 답부터 실기까지 완벽했다.

---

## 9. “동일 프로그램 특화라서 효과가 컸다” — 추정 검증

### 9.1 사용자 추정 (요지)
1. 동일 설계서·동일 프로그램에서 난 오류를 잡아둔 것이 큰 효과다.  
2. 형식이 다른 프로그램이면 다시 많은 오류가 날 것이다.  
3. 다양한 프로그램 대화가 쌓이면 그때 일반 효과가 커질 것이다.

### 9.2 데이터로 본 답: **대체로 맞다**
- B에서 **막힌** 정적 오류의 상당수는 A Preflight에 **이미 있던 유형**(IGS, MC_FC, LS-DATUM, 선언 누락 등)이다 → 목록화 효과.  
- B에서 **새로 난** 컴파일성 이슈(`MANDT`/`CLIENT SPECIFIED`, `WRITE` 포맷, 붙여넣기 잔재)는 Preflight 표 밖 또는 사용자 SE38 잔재다 → “암기 밖은 다시 나온다”를 지지.  
- UX/도메인 스킬은 Ops Monitor 특화가 크다. 다른 업무 프로그램이면 이 층의 효과가 약해진다.  
- 다만 Preflight·Delivery의 **일반 층(~70%)** 은 다른 ALV/HTML 리포트에도 일부 이월된다. “효과가 전부 특화”는 과장이다.

### 9.3 시나리오 수치 (유형 n=1이라 **추정**)
다른 도메인 리포트를 **현재 Skills만**으로 비슷한 규모로 돌린다고 가정:

| 시나리오 | 예상 오류 raw | 예상 공정 Q | 근거 |
|----------|-------------:|------------:|------|
| 스킬 없음 (A급) | ~25 | ~60 | A 실측 근방 |
| 현 Skills + **다른 도메인** | ~12–18 | ~30–45 | 특화 소실, 일반 층만 |
| 현 Skills + **같은 Ops 계열** | ~5–8 | ~12–20 | B 실측 |
| 다수 유형 축적 후 | ~6–10 | ~18–28 | 가설 |

보고 시 **S2(같은 계열)는 실측, S1/S3는 가설**이라고 명시해야 한다.

---

## 10. 한계 (정직하게)

1. **전사 접근 한계**: SELECT-OPTIONS 등 관련 세션이 숫자에 없음.  
2. **중간 Parity 곡선**: 턴마다 전수 재채점이 아니라 마일스톤 보간(±2).  
3. **실기 증거**: 일부 `R` 항목은 대화에 올라온 오류·화면 보고에 의존.  
4. **프로그램 유형 n=1**: 일반화는 가설. 두 번째 유형 실험이 필요.  
5. **ST22 드릴다운 형태**: A는 tcode, B는 후반 HTML 상세 — “표시 전용”으로 동점 처리했으나 형태는 다름.  
6. Cloud/Artifacts 경로(`/opt/cursor/...`)는 **사용자 PC 로컬이 아님**. 오프라인 전달은 채팅 복사·로컬 스크립트가 필요.

---

## 11. 보고용 결론 (문장)

1. **품질:** 동일 Parity 채점표(56점, Hard Gate)로 채점하면 최종 **A=54, B=55(Δ=1)** 로 **유사 수준**이다.  
2. **과정:** 공정 질문 **약 63→16**, 첫 PASS 도달 **약 57→12**, 활성화 오류 첨부 **~18+→2**.  
3. **방법:** Session A의 실패를 Skill/Rule로 고착하면, **같은 설계서·유사 유형**의 재현에서 왕복이 크게 줄어든다.  
4. **교정:** 에러·미동작이 있으면 PASS가 아니다. B를 처음부터 완벽했다고 쓰면 안 된다.  
5. **확장:** 효과가 커 보이는 이유의 상당 부분은 **동일 유형 오류 목록화**다. 다른 형식 프로그램에서는 효과가 줄 수 있으며, **다양한 유형의 실패를 다시 규칙으로 쌓아야** 일반화가 된다.

---

## 12. 부록 — 용어

| 용어 | 뜻 |
|------|-----|
| Session A | Awesome skills automation (장기 구현+Skills) |
| Session B | 통합 운영 모니터링 대시보드 (Greenfield 재현) |
| `cum_Q_program` | 프로그램 구현·오류·UX 관련 누적 질문 (PPT/`계속`/메타 제외 가능) |
| Parity | 설계·UX 바 대비 품질 동등성 점수 |
| Hard Gate | 활성화/미동작 결함이 있으면 PASS 금지 |
| DoD | 내부 완료 체크리스트 (외부 공인 지표 아님) |
| E_compile | 사용자가 활성화·문법 오류를 첨부한 횟수 |
| Preflight | 붙여넣기 전 정적 활성화 자가점검 (P1~P10) |

---

*본 문서는 해당 Cursor 대화에서 합의·보정된 수치와 채점 규칙을 기준으로 작성되었다.*

"""

def main():
    doc = Document()
    section = doc.sections[0]
    section.top_margin = Cm(2)
    section.bottom_margin = Cm(2)
    section.left_margin = Cm(2.2)
    section.right_margin = Cm(2.2)
    style = doc.styles["Normal"]
    style.font.name = "Malgun Gothic"
    style.font.size = Pt(11)

    table_buf = []

    def flush_table():
        nonlocal table_buf
        if not table_buf:
            return
        rows = []
        for line in table_buf:
            cells = [c.strip() for c in line.strip("|").split("|")]
            if all(set(c) <= set("-: ") for c in cells):
                continue
            rows.append(cells)
        table_buf = []
        if not rows:
            return
        cols = max(len(r) for r in rows)
        t = doc.add_table(rows=len(rows), cols=cols)
        t.style = "Table Grid"
        for i, row in enumerate(rows):
            for j in range(cols):
                cell = t.cell(i, j)
                cell.text = row[j] if j < len(row) else ""
                for p in cell.paragraphs:
                    for r in p.runs:
                        r.font.size = Pt(9)
                        r.font.name = "Malgun Gothic"
                        if i == 0:
                            r.bold = True
        doc.add_paragraph()

    def add_para(text, bold=False, size=11):
        p = doc.add_paragraph()
        run = p.add_run(text)
        run.bold = bold
        run.font.size = Pt(size)
        run.font.name = "Malgun Gothic"
        return p

    for line in MD.splitlines():
        if line.startswith("|"):
            table_buf.append(line)
            continue
        else:
            flush_table()
        if not line.strip() or line.strip() == "---":
            continue
        if line.startswith("# "):
            add_para(line[2:].strip(), bold=True, size=18)
        elif line.startswith("## "):
            add_para(line[3:].strip(), bold=True, size=14)
        elif line.startswith("### "):
            add_para(line[4:].strip(), bold=True, size=12)
        elif line.startswith("> "):
            p = add_para(line[2:].strip(), size=10)
            p.paragraph_format.left_indent = Cm(0.5)
        elif line.startswith("- "):
            p = doc.add_paragraph(style="List Bullet")
            run = p.add_run(line[2:])
            run.font.size = Pt(11)
            run.font.name = "Malgun Gothic"
        else:
            add_para(line)

    flush_table()
    out = Path(__file__).resolve().parent / "Cursor_ABAP_Skills_Parity_논의정리_보고서.docx"
    doc.save(out)
    print("생성 완료:", out)

if __name__ == "__main__":
    main()
