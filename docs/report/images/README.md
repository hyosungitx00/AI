# 화면 캡처 (A|B 비교용)

보고서 구조: **1. 개요 → 2. 화면 비교(A|B) → 3~ 본문**

## 파일명
- `session-a-01-dashboard.png` / `session-b-01-dashboard.png`
- `session-a-02-kpi.png` / `session-b-02-kpi.png`
- `session-a-03-toggle.png` / `session-b-03-toggle.png`
- `session-a-04-help.png` / `session-b-04-help.png`

## 생성
```text
pip install pillow
python make_report_html.py
```
긴 변 960px · JPEG Q72로 줄여 HTML에 포함. 화면에서는 약 240px 높이로 나란히 표시.
