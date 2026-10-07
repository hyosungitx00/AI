# report/ — AI 연구과제 결과 리포트

> Cursor AI를 활용한 SAP GUI ABAP 바이브 코딩 과제의 제출용 산출물이다.
> Markdown 원본이 단일 진실 공급원이고, Word·PPT는 빌더로 생성한다.

## 파일 구성

| 파일 | 용도 | 제출물 |
|---|---|---|
| `ai-abap-result-report.md` | 상세 리포트 본문 (5개 필수 항목 + 부록 A~D) | → Word |
| `ai-abap-result-deck.md` | 발표용 축약 덱 (16개 슬라이드 구성) | → PPT |
| `effect-worksheet.md` | 정량 효과 측정 워크시트 (부록 B) | 내부 작성용 |
| `demo-video-script.md` | 시연 영상 3분 시나리오 (부록 C) | 촬영 대본 |
| `build_report.py` | Markdown → `.docx` / `.pptx` 변환 | — |
| `dist/ai-abap-result-report.docx` | 제출용 Word (문단 98 · 표 14) | **제출** |
| `dist/ai-abap-result-deck.pptx` | 제출용 PPT (18슬라이드, 16:9) | **제출** |

## 제출 전 필수 작업 — 실측값 기입

리포트에는 저장소에서 재현되는 수치는 채워져 있고, **사내 업무 수치만 비어 있다.**
`[실측 기입]` 으로 표시된 칸을 채워야 평가 기준의 효과성(40점) 근거가 완성된다.

| 기입 위치 | 항목 |
|---|---|
| 리포트 머리글 | 작성자명·소속 |
| §2.1 기존 업무 방식 | 담당자 수, 수행 빈도, 1건 평균 공수, 단계별 비중, 활성화 재시도 횟수, 시간당 인건비 |
| §4.3 절감 측정 | As-Is 공수, To-Be 공수, 연간 건수, 인건비 |
| `effect-worksheet.md` §1·§2 | As-Is 3건 실측, To-Be 세션 실측 |

작성 절차는 `effect-worksheet.md`를 따른다. 측정 시 **To-Be 공수에 인터뷰 응답 시간을 반드시
포함**한다 — 이 체계는 담당자의 문서 작성 시간을 질문 응답 시간으로 바꾼 것이므로, 응답 시간을
빼면 절감이 과대 계상된다.

`effect-worksheet.md` §3의 "계산 예시"는 **계산 방식을 보여 주는 가정값**이다. 제출 전 실측값으로
교체하거나 삭제한다.

## 문서 재생성

```bash
pip install python-docx python-pptx
python3 report/build_report.py
```

Word·PPT를 직접 편집하지 말고 `.md` 를 고친 뒤 다시 빌드한다 (직접 편집분은 덮어쓰인다).
제출 직전 서식 미세 조정만 필요하면, 빌드 후 생성물에서 조정하고 그 사실을 기록한다.

## 리포트가 인용하는 근거

리포트의 모든 저장소 기반 수치는 아래 명령으로 재현된다 (리포트 부록 D와 동일).

```bash
python3 tools/abap_check.py                    # ABAP 산출물 6개 오류 0건
python3 tools/tests/test_abap_check.py         # 점검기 테스트 32항목
grep -oE 'CHK-0[0-9]{2}' tools/README.md | sort -u | wc -l   # 점검 규칙 17건
grep -cE '^\| (ERR|MSG|PROC)-[0-9]+' practice/error-patterns.md  # 오류 패턴 10건
cat sessions/20260928-ZMM_PR_LINK_ALV01/README.md            # 실전 적용 세션 기록
```

## 평가 기준 대응 위치

| 평가 기준 | 배점 | 리포트 위치 |
|---|---|---|
| 효과성 | 40 | §4.1 검증된 정량 지표 · §4.3 절감 측정 · §4.4 오류 감소 |
| 실제 적용도 | 30 | §4.2 실전 적용 사례 (`sessions/` 원본 기록) |
| 확산 가능성 | 20 | §5.1 확산 축 5개 · §5.2 향후 계획 |
| 완성도 | 10 | Word·PPT 동시 제공 · 부록 C 영상 시나리오 · 부록 D 재현 명령 |
