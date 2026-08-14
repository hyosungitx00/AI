# -*- coding: utf-8 -*-
"""논의 정리 HTML — images/ 8장을 HTML에 base64로 넣음.

폴더 구조:
  make_report_html.py
  Cursor_ABAP_Skills_Parity_논의정리_보고서.html
  images/
    session-a-01-dashboard.png
    session-a-02-kpi.png
    session-a-03-toggle.png
    session-a-04-help.png
    session-b-01-dashboard.png
    session-b-02-kpi.png
    session-b-03-toggle.png
    session-b-04-help.png

실행:
  python make_report_html.py

성공 시:
  이미지 8장 base64 포함 완료
  HTML 크기: 수 MB
"""
from __future__ import annotations

import argparse
import base64
import mimetypes
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT_NAME = "Cursor_ABAP_Skills_Parity_논의정리_보고서.html"
IMG_DIR = HERE / "images"

SHOTS = [
    ("session-a-01-dashboard", "A-1. 초기 전체 화면 (대시보드 · Top-N)",
     "Session A 초기 전체 화면 Top-N",
     "상단 KPI/TOGGLE/REFRESH/HELP · 장애 주의 배너 · 3분할 ALV + Top-N 가로 막대"),
    ("session-a-02-kpi", "A-2. KPI → STATS 팝업",
     "Session A KPI 팝업",
     "Ops Monitor · KPI 요약 · CRITICAL · 영역별 건수/비중 · HTML dialog"),
    ("session-a-03-toggle", "A-3. TOGGLE → 시간추이",
     "Session A TOGGLE 시간추이",
     "영역별 시간추이(1칸=1시간) 세로 막대 · ALV 유지"),
    ("session-a-04-help", "A-4. HELP → 사용 가이드",
     "Session A HELP 팝업",
     "상세조회 / REFRESH / TOGGLE / STATS / P_AUTORF / ALV 툴바 안내"),
    ("session-b-01-dashboard", "B-1. 초기 전체 화면 (대시보드 · Top-N)",
     "Session B 초기 전체 화면 Top-N",
     "위험 총 438건 헤더 · 영역별 Top-N · 3분할 ALV · TOGGLE=시간추이"),
    ("session-b-02-kpi", "B-2. KPI → STATS 팝업",
     "Session B KPI 팝업",
     "다크 테마 · 위험·총438건 · SM37/ST22/SXI 카드 · 우상단 X 닫기"),
    ("session-b-03-toggle", "B-3. TOGGLE → 시간대별 추이",
     "Session B TOGGLE 시간추이",
     "통합 스택 막대(SM37/ST22/SXI) · TOGGLE=Top-N 복귀"),
    ("session-b-04-help", "B-4. HELP → 사용 안내",
     "Session B HELP 팝업",
     "F8/REFRESH/TOGGLE/STATS/더블클릭 · 읽기전용 경고"),
]
EXTS = (".png", ".jpg", ".jpeg", ".webp", ".gif")
SRC_RE = re.compile(
    r'src="(images/session-[ab]-\d{2}-[a-z0-9.-]+\.(?:png|jpg|jpeg|webp|gif))"',
    re.IGNORECASE,
)


def find_image(stem: str) -> Path | None:
    for ext in EXTS:
        p = IMG_DIR / f"{stem}{ext}"
        if p.is_file():
            return p
    return None


def to_data_uri(path: Path) -> str:
    mime = mimetypes.guess_type(path.name)[0] or "image/png"
    b64 = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:{mime};base64,{b64}"


def build_shots_section() -> str:
    parts = [
        '<section id="shots-section">',
        "  <h2>9. 화면 캡처 (Session A → B)</h2>",
        "  <p>실기 화면 A → B. 이미지는 생성 스크립트가 base64로 포함합니다.</p>",
        "  <h3>9.1 Session A</h3>",
    ]
    for i, (stem, title, alt, cap) in enumerate(SHOTS):
        if i == 4:
            parts.append("  <h3>9.2 Session B</h3>")
        parts.append(f'  <div class="shot" data-shot="{stem}">')
        parts.append(f"    <h4>{title}</h4>")
        parts.append(
            f'    <img src="images/{stem}.png" alt="{alt}" '
            f'style="max-width:100%;height:auto;border:1px solid #ccc;"/>'
        )
        parts.append(f'    <p class="cap">{cap}</p>')
        parts.append("  </div>")
    parts.append("</section>")
    return "\n".join(parts) + "\n"


def ensure_shot_slots(html: str) -> str:
    """구버전 HTML에 img src=images/session-... 가 없으면 §9 슬롯을 삽입."""
    if SRC_RE.search(html):
        print("HTML: 기존 캡처 슬롯 8개 패턴 감지")
        return html

    print("HTML: 캡처 슬롯 없음 → §9 화면 캡처 섹션을 자동 삽입")
    section = build_shots_section()

    # </body> 앞에 삽입 (없으면 끝에 append)
    m = re.search(r"</body\s*>", html, flags=re.IGNORECASE)
    if m:
        return html[: m.start()] + section + html[m.start() :]
    m = re.search(r"</html\s*>", html, flags=re.IGNORECASE)
    if m:
        return html[: m.start()] + section + html[m.start() :]
    return html + "\n" + section


def embed_images(html: str) -> str:
    missing = []
    embedded = 0

    def repl_src(m: re.Match) -> str:
        nonlocal embedded
        stem = Path(m.group(1)).stem
        img = find_image(stem)
        if not img:
            missing.append(m.group(1))
            return m.group(0)
        embedded += 1
        return f'src="{to_data_uri(img)}"'

    out = SRC_RE.sub(repl_src, html)

    if embedded:
        out = out.replace('class="is-empty"', 'class=""')
        out = re.sub(
            r'(<div class="missing" data-miss)(?![^>]*\bhidden\b)',
            r"\1 hidden",
            out,
            count=min(embedded, 8),
        )
        print(f"이미지 {embedded}장 base64 포함 완료")
        print("※ HTML 크기가 수 MB로 커져야 정상입니다.")
    else:
        print("경고: base64 치환 0건")
    for x in missing:
        print("  없음:", x)
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--no-embed", action="store_true")
    ap.add_argument("--embed", action="store_true")  # 호환용
    args = ap.parse_args()

    found = sum(1 for s, *_ in SHOTS if find_image(s))
    print("images 폴더:", IMG_DIR)
    print(f"캡처 파일 {found}/{len(SHOTS)} 발견")
    if found < len(SHOTS):
        for s, *_ in SHOTS:
            if not find_image(s):
                print(f"  없음: images/{s}.png")

    html_path = HERE / OUT_NAME
    if not html_path.is_file():
        raise SystemExit("HTML 없음: " + str(html_path))

    html = html_path.read_text(encoding="utf-8")
    html = ensure_shot_slots(html)

    if not args.no_embed:
        if found == 0:
            print("경고: images/ 파일 없음 — embed 생략")
        else:
            html = embed_images(html)
    else:
        print("※ --no-embed: 상대경로만 유지")

    html_path.write_text(html if html.endswith("\n") else html + "\n", encoding="utf-8")
    mb = html_path.stat().st_size / (1024 * 1024)
    print("생성 완료:", html_path)
    print(f"HTML 크기: {mb:.2f} MB")
    if not args.no_embed and found > 0 and mb < 0.2:
        print("경고: 파일이 너무 작음 → 사진 미포함 가능")


if __name__ == "__main__":
    main()
