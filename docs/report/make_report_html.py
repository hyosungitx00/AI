# -*- coding: utf-8 -*-
"""논의 정리 HTML — A|B 비교 사진(축소)을 개요 다음에 넣고 base64 포함.

폴더:
  make_report_html.py
  Cursor_ABAP_Skills_Parity_논의정리_보고서.html
  images/session-a-01-dashboard.png ... session-b-04-help.png

실행:
  python make_report_html.py

권장(용량 축소):
  pip install pillow
  python make_report_html.py
  → 긴 변 960px · JPEG Q=72 로 줄여 embed

성공 시:
  이미지 8장 base64 포함 완료
  HTML 크기: 보통 1~4 MB
"""
from __future__ import annotations

import argparse
import base64
import io
import mimetypes
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT_NAME = "Cursor_ABAP_Skills_Parity_논의정리_보고서.html"
IMG_DIR = HERE / "images"

# (A stem, B stem, 비교 제목, A 캡션, B 캡션)
PAIRS = [
    (
        "session-a-01-dashboard",
        "session-b-01-dashboard",
        "대시보드 · Top-N",
        "KPI/TOGGLE/REFRESH/HELP · 주의 배너 · 3분할 ALV + Top-N",
        "위험 438건 헤더 · 영역별 Top-N · 3분할 ALV",
    ),
    (
        "session-a-02-kpi",
        "session-b-02-kpi",
        "KPI → STATS 팝업",
        "CRITICAL · 영역별 건수/비중/신호등 · HTML dialog",
        "다크 테마 · SM37/ST22/SXI 카드+비중 바",
    ),
    (
        "session-a-03-toggle",
        "session-b-03-toggle",
        "TOGGLE → 시간추이",
        "영역별 세로 막대(1칸=1시간) · ALV 유지",
        "통합 스택 막대(SM37/ST22/SXI)",
    ),
    (
        "session-a-04-help",
        "session-b-04-help",
        "HELP → 사용 안내",
        "상세조회 / REFRESH / TOGGLE / STATS / P_AUTORF",
        "F8/REFRESH/TOGGLE/STATS · 읽기전용 경고",
    ),
]
STEMS = [x for p in PAIRS for x in (p[0], p[1])]
EXTS = (".png", ".jpg", ".jpeg", ".webp", ".gif")
SRC_RE = re.compile(
    r'src="(images/session-[ab]-\d{2}-[a-z0-9.-]+\.(?:png|jpg|jpeg|webp|gif))"',
    re.IGNORECASE,
)

# embed 시 축소
MAX_SIDE = 960
JPEG_QUALITY = 72


def find_image(stem: str) -> Path | None:
    for ext in EXTS:
        p = IMG_DIR / f"{stem}{ext}"
        if p.is_file():
            return p
    return None


def load_pillow():
    try:
        from PIL import Image  # type: ignore

        return Image
    except Exception:
        return None


def to_data_uri(path: Path, Image=None) -> tuple[str, str]:
    """return (data_uri, note). JPEG로 축소 가능하면 축소."""
    raw = path.read_bytes()
    note = f"{path.name} {len(raw)//1024}KB"

    if Image is not None:
        try:
            im = Image.open(io.BytesIO(raw))
            im = im.convert("RGB")
            w, h = im.size
            scale = min(1.0, MAX_SIDE / float(max(w, h)))
            if scale < 1.0:
                im = im.resize((int(w * scale), int(h * scale)), Image.Resampling.LANCZOS)
            buf = io.BytesIO()
            im.save(buf, format="JPEG", quality=JPEG_QUALITY, optimize=True)
            data = buf.getvalue()
            note = f"{path.name} {len(raw)//1024}KB → JPEG {len(data)//1024}KB ({im.size[0]}x{im.size[1]})"
            b64 = base64.b64encode(data).decode("ascii")
            return f"data:image/jpeg;base64,{b64}", note
        except Exception as e:
            note = f"{path.name} 리사이즈 실패({e}), 원본 사용"

    mime = mimetypes.guess_type(path.name)[0] or "image/png"
    b64 = base64.b64encode(raw).decode("ascii")
    return f"data:{mime};base64,{b64}", note


def build_shots_section() -> str:
    blocks = [
        '<section id="shots-section">',
        "  <h2>2. 화면 비교 (Session A | B)</h2>",
        "  <p>동일 조회 조건(총 438건). 왼쪽 A · 오른쪽 B. 사진 클릭 시 확대.</p>",
    ]
    for a, b, title, ca, cb in PAIRS:
        blocks += [
            '  <div class="compare-block">',
            f"    <h3>{title}</h3>",
            '    <div class="compare-row">',
            f'      <div class="shot" data-shot="{a}">',
            '        <span class="badge a">Session A</span>',
            "        <h4>A</h4>",
            f'        <img src="images/{a}.png" alt="Session A {title}" data-img/>',
            f'        <p class="cap">{ca}</p>',
            "      </div>",
            f'      <div class="shot" data-shot="{b}">',
            '        <span class="badge b">Session B</span>',
            "        <h4>B</h4>",
            f'        <img src="images/{b}.png" alt="Session B {title}" data-img/>',
            f'        <p class="cap">{cb}</p>',
            "      </div>",
            "    </div>",
            "  </div>",
        ]
    blocks.append("</section>")
    return "\n".join(blocks) + "\n"


def strip_old_shots(html: str) -> str:
    """기존 화면 캡처/비교 섹션 제거."""
    # id="shots-section" 블록
    html2 = re.sub(
        r'<section\b[^>]*\bid=["\']shots-section["\'][^>]*>.*?</section\s*>',
        "",
        html,
        flags=re.IGNORECASE | re.DOTALL,
    )
    # 제목으로 잡히는 구버전
    html2 = re.sub(
        r'<section\b[^>]*>\s*<h2[^>]*>\s*\d+\.\s*화면\s*(?:캡처|비교)[^<]*</h2>.*?</section\s*>',
        "",
        html2,
        flags=re.IGNORECASE | re.DOTALL,
    )
    return html2


def insert_after_overview(html: str, section: str) -> str:
    """1. 핵심 수치 섹션 직후에 비교 섹션 삽입."""
    m = re.search(
        r'(<h2[^>]*>\s*1\.\s*핵심\s*수치[\s\S]*?</section\s*>)',
        html,
        flags=re.IGNORECASE,
    )
    if m:
        i = m.end()
        return html[:i] + "\n\n" + section + html[i:]
    # fallback: 첫 번째 </section> 뒤
    m = re.search(r"</section\s*>", html, flags=re.IGNORECASE)
    if m:
        i = m.end()
        return html[:i] + "\n\n" + section + html[i:]
    m = re.search(r"</body\s*>", html, flags=re.IGNORECASE)
    if m:
        return html[: m.start()] + section + html[m.start() :]
    return html + "\n" + section


def ensure_compare_layout(html: str) -> str:
    html = strip_old_shots(html)
    return insert_after_overview(html, build_shots_section())


def ensure_compare_css(html: str) -> str:
    """구버전 CSS에 비교 스타일이 없으면 최소 CSS 주입."""
    if "compare-row" in html and "max-height: 240px" in html:
        return html
    css = """
  .wrap { max-width: 1080px; }
  .compare-block { background:#fff; border:1px solid #d5dee7; border-radius:12px; padding:12px 14px; margin:14px 0; }
  .compare-row { display:grid; grid-template-columns:1fr 1fr; gap:12px; }
  @media (max-width:800px){ .compare-row{ grid-template-columns:1fr; } }
  .shot { background:#f4f7fa; border:1px solid #d5dee7; border-radius:10px; padding:8px; margin:0; min-width:0; }
  .shot .badge { display:inline-block; font-size:11px; font-weight:700; padding:2px 8px; border-radius:999px; margin-bottom:6px; }
  .shot .badge.a { background:#e5f3f8; color:#1f6f8b; }
  .shot .badge.b { background:#fceee6; color:#c45c26; }
  .shot img { display:block; width:100%; max-height:240px; height:auto; object-fit:contain; object-position:top center; border:1px solid #d5dee7; border-radius:6px; background:#111; cursor:zoom-in; }
  .shot .cap { margin:6px 0 0; font-size:11.5px; color:#5c6b7a; }
"""
    if re.search(r"</style\s*>", html, flags=re.IGNORECASE):
        return re.sub(r"</style\s*>", css + "</style>", html, count=1, flags=re.IGNORECASE)
    return html


def embed_images(html: str) -> str:
    Image = load_pillow()
    if Image is None:
        print("※ Pillow 없음 → 원본 해상도로 embed (표시는 CSS로 축소).")
        print("  용량을 줄이려면: pip install pillow 후 다시 실행")
    else:
        print(f"※ Pillow 사용: 긴 변 ≤{MAX_SIDE}px, JPEG Q={JPEG_QUALITY}")

    missing = []
    embedded = 0

    def repl_src(m: re.Match) -> str:
        nonlocal embedded
        stem = Path(m.group(1)).stem
        img = find_image(stem)
        if not img:
            missing.append(m.group(1))
            return m.group(0)
        uri, note = to_data_uri(img, Image)
        print("  ", note)
        embedded += 1
        return f'src="{uri}"'

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
    else:
        print("경고: base64 치환 0건")
    for x in missing:
        print("  없음:", x)
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--no-embed", action="store_true")
    ap.add_argument("--embed", action="store_true")
    ap.add_argument("--max-side", type=int, default=MAX_SIDE)
    ap.add_argument("--quality", type=int, default=JPEG_QUALITY)
    args = ap.parse_args()

    global MAX_SIDE, JPEG_QUALITY
    MAX_SIDE = args.max_side
    JPEG_QUALITY = args.quality

    found = sum(1 for s in STEMS if find_image(s))
    print("images 폴더:", IMG_DIR)
    print(f"캡처 파일 {found}/{len(STEMS)} 발견")
    if found < len(STEMS):
        for s in STEMS:
            if not find_image(s):
                print(f"  없음: images/{s}.png")

    html_path = HERE / OUT_NAME
    if not html_path.is_file():
        raise SystemExit("HTML 없음: " + str(html_path))

    html = html_path.read_text(encoding="utf-8")
    html = ensure_compare_css(html)
    html = ensure_compare_layout(html)
    print("HTML: 개요(§1) 다음에 A|B 비교(§2) 배치")

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
    if not args.no_embed and found > 0 and mb < 0.15:
        print("경고: 파일이 너무 작음 → 사진 미포함 가능")


if __name__ == "__main__":
    main()
