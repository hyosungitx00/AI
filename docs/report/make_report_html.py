# -*- coding: utf-8 -*-
"""논의 정리 HTML 보고서 생성 (+ 화면 캡처 포함).

사용:
  1) 이 스크립트와 같은 폴더에 HTML 템플릿이 있거나,
     아래 TEMPLATE_NAME 파일을 둡니다.
  2) images/ 에 캡처 8장을 저장 (파일명은 SHOTS 참고)
  3) 실행:
       python make_report_html.py
         -> 상대경로 이미지 HTML 생성
       python make_report_html.py --embed
         -> 이미지를 base64로 넣어 단일 HTML 생성 (권장, 오프라인)

결과: Cursor_ABAP_Skills_Parity_논의정리_보고서.html
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
    """src=\"images/<stem>.ext\" 를 data URI 로 치환."""
    missing = []

    def repl(m: re.Match) -> str:
        rel = m.group(1)
        stem = Path(rel).stem
        # stem may already include session-a-01-dashboard
        img = find_image(stem)
        if not img:
            missing.append(rel)
            return m.group(0)
        return f'src="{to_data_uri(img)}"'

    out = re.sub(
        r'src="(images/session-[ab]-\d{2}-[a-z0-9.-]+\.(?:png|jpg|jpeg|webp|gif))"',
        repl,
        html,
        flags=re.IGNORECASE,
    )
    if missing:
        print("경고: 이미지 없음 (상대경로 유지):")
        for x in missing:
            print("  -", x)
    else:
        print("이미지 8장 base64 포함 완료")
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--embed",
        action="store_true",
        help="images/ 파일을 HTML에 base64로 넣어 단일 파일 생성",
    )
    args = ap.parse_args()

    html = load_template()
    if args.embed:
        html = embed_images(html)

    out = HERE / OUT_NAME
    out.write_text(html if html.endswith("\n") else html + "\n", encoding="utf-8")
    print("생성 완료:", out)
    print("images 폴더:", IMG_DIR)
    found = sum(1 for s in SHOTS if find_image(s))
    print(f"캡처 파일 {found}/{len(SHOTS)} 발견")
    if found < len(SHOTS):
        print("없는 파일:")
        for s in SHOTS:
            if not find_image(s):
                print(f"  images/{s}.png")


if __name__ == "__main__":
    main()
