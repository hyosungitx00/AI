# Cursor × ABAP Skills / Parity 실험 — 발표 핸드아웃

발표자료 PPTX: `docs/report/Cursor_ABAP_Skills_Parity_발표자료.pptx`  
(동일 파일: `/opt/cursor/artifacts/Cursor_ABAP_Skills_Parity_발표자료.pptx`)

## 핵심 메시지
실패를 Skill/Rule로 축적하면 **같은 설계서 목표**를 더 짧은 대화로 달성할 수 있다.  
단, **동작 검증(Hard Gate) 없는 점수는 신뢰하지 않는다.**

## 두 세션
| | A | B |
|--|--|--|
| 성격 | 장기 구현 → Skills 정착 | Greenfield 재현 |
| 공정 Q | ≈63 | ≈16 |
| 최종 Parity | 54/56 | 55/56 |
| 첫 PASS (Hard Gate) | Q≈57 | Q≈12 |

## Parity (품질) vs 질문 수 (과정)
- 품질: 56점 채점표 (기능20+안전12+UX16+전달8)
- PASS = ≥50 **그리고** 활성화 성공·차단 결함 없음
- 질문 수는 효율 지표로만 병기

## Hard Gate 예
활성화 실패, 빈 화면, 팝업 X 불능, 필수 영역 조회 버그, 드릴다운 불능

## 일반화
- Preflight ~70% 전이 가능 / UX·도메인 ~80%+ Ops Monitor 특화
- 다른 프로그램 유형 대화 축적 시 일반 효과 확대 기대 (현재 n=1)

## 참고 문서
- `docs/guides/ops-monitor-parity-scoring.md`
- `docs/report/parity-score-A-vs-B-2026-08.md`
- `docs/report/parity-score-evolution-vs-Q-2026-08.md`
