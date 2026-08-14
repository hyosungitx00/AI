# -*- coding: utf-8 -*-
"""논의 정리 HTML 보고서 생성 (+ 화면 캡처 base64 포함).

폴더:
  make_report_html.py
  Cursor_ABAP_Skills_Parity_논의정리_보고서.html
  images/session-a-01-dashboard.png ... session-b-04-help.png

실행 (권장):
  python make_report_html.py
      -> 기본으로 이미지를 HTML에 넣어 단일 파일 생성

  python make_report_html.py --no-embed
      -> 상대경로만 유지 (HTML과 images/를 항상 같이 열 때만)

성공 시 반드시 이 문구가 보여야 합니다:
  이미지 8장 base64 포함 완료
"""
from __future__ import annotations

import argparse
import base64
import mimetypes
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
OUT_NAME = "Cursor_ABAP_Skills_Parity_논의정리_보고서.html"
TEMPLATE_CANDIDATES = [
    HERE / OUT_NAME,
    HERE / "Cursor_ABAP_Skills_Parity_논의정리_보고서.template.html",
]
IMG_DIR = HERE / "images"

SHOTS = [
    "session-a-01-dashboard",
    "session-a-02-kpi",
    "session-a-03-toggle",
    "session-a-04-help",
    "session-b-01-dashboard",
    "session-b-02-kpi",
    "session-b-03-toggle",
    "session-b-04-help",
]
EXTS = (".png", ".jpg", ".jpeg", ".webp", ".gif")


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


def load_template() -> str:
    for p in TEMPLATE_CANDIDATES:
        if p.is_file():
            return p.read_text(encoding="utf-8")
    raise SystemExit("HTML 템플릿을 찾을 수 없습니다: " + OUT_NAME)


def embed_images(html: str) -> str:
    """src=\"images/<stem>.ext\" 를 data URI 로 치환하고 is-empty 클래스 제거."""
    missing = []
    embedded = 0

    def repl_src(m: re.Match) -> str:
        nonlocal embedded
        rel = m.group(1)
        stem = Path(rel).stem
        img = find_image(stem)
        if not img:
            missing.append(rel)
            return m.group(0)
        embedded += 1
        return f'src="{to_data_uri(img)}"'

    out = re.sub(
        r'src="(images/session-[ab]-\d{2}-[a-z0-9.-]+\.(?:png|jpg|jpeg|webp|gif))"',
        repl_src,
        html,
        flags=re.IGNORECASE,
    )

    # data URI 넣은 이미지는 처음부터 보이게 (is-empty 숨김 해제)
    if embedded:
        out = re.sub(
            r'(<img\b[^>]*\bclass=")([^"]*\bis-empty\b)([^"]*")([^>]*\bsrc="data:)',
            lambda m: m.group(1)
            + re.sub(r"\bis-empty\b", "", m.group(2)).replace("  ", " ").strip()
            + m.group(3)
            + m.group(4),
            out,
            flags=re.IGNORECASE,
        )
        # class="is-empty" only (order: class after src)
        out = re.sub(
            r'(<img\b[^>]*\bsrc="data:[^"]+")([^>]*\bclass=")([^"]*\bis-empty\b)([^"]*")',
            lambda m: m.group(1)
            + m.group(2)
            + re.sub(r"\bis-empty\b", "", m.group(3)).replace("  ", " ").strip()
            + m.group(4),
            out,
            flags=re.IGNORECASE,
        )
        # missing 안내 숨김
        out = re.sub(
            r'(<div class="missing" data-miss)(>)',
            r'\1 hidden\2',
            out,
            count=embedded,
        )

    if missing:
        print("경고: 이미지 없음 (상대경로 유지):")
        for x in missing:
            print("  -", x)
    if embedded:
        print(f"이미지 {embedded}장 base64 포함 완료")
        # 대략 파일 커졌는지 힌트
        print("※ HTML 파일 크기가 수 MB로 커져야 정상입니다. 작으면 embed 실패.")
    else:
        print("경고: base64 치환 0건 — HTML의 img src=images/... 패턴을 못 찾았습니다.")
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--no-embed",
        action="store_true",
        help="이미지를 넣지 않고 상대경로만 유지",
    )
    # 하위 호환: 예전 안내의 --embed 도 허용 (기본이 embed라 무시해도 됨)
    ap.add_argument(
        "--embed",
        action="store_true",
        help="(기본 동작) 이미지를 base64로 포함",
    )
    args = ap.parse_args()

    found = sum(1 for s in SHOTS if find_image(s))
    print("images 폴더:", IMG_DIR)
    print(f"캡처 파일 {found}/{len(SHOTS)} 발견")
    if found < len(SHOTS):
        print("없는 파일:")
        for s in SHOTS:
            if not find_image(s):
                print(f"  images/{s}.png")

    html = load_template()
    do_embed = not args.no_embed
    if do_embed:
        if found == 0:
            print("경고: images/에 파일이 없어 embed를 건너뜁니다.")
        else:
            html = embed_images(html)
    else:
        print("※ --no-embed: HTML에 사진을 넣지 않았습니다. 상대경로만 유지.")
        print("  → 브라우저에서 사진이 안 보이면 embed로 다시 실행하세요.")

    out = HERE / OUT_NAME
    out.write_text(html if html.endswith("\n") else html + "\n", encoding="utf-8")
    size_mb = out.stat().st_size / (1024 * 1024)
    print("생성 완료:", out)
    print(f"HTML 크기: {size_mb:.2f} MB")
    if do_embed and found > 0 and size_mb < 0.2:
        print("경고: 파일이 너무 작습니다. 사진이 HTML에 안 들어갔을 수 있습니다.")


if __name__ == "__main__":
    main()
