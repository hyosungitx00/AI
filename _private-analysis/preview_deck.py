#!/usr/bin/env python3
"""생성된 .pptx 의 도형 좌표·텍스트를 읽어 근사 미리보기 PNG 로 렌더링한다.

LibreOffice 가 없는 환경에서 레이아웃(넘침·겹침·여백)을 눈으로 검증하기 위한 용도다.
PowerPoint 의 실제 렌더링과 자간·줄바꿈이 완전히 같지는 않으므로 참고용이다.
실행: python3 preview_deck.py
"""

from pptx import Presentation
from pptx.util import Emu
from PIL import Image, ImageDraw, ImageFont

DPI = 110
REG = "/usr/share/fonts/truetype/nanum/NanumBarunGothic.ttf"
BOLD = "/usr/share/fonts/truetype/nanum/NanumBarunGothicBold.ttf"
_cache = {}


def font(size_pt, bold):
    px = max(7, int(round(size_pt * DPI / 72.0)))
    key = (px, bold)
    if key not in _cache:
        _cache[key] = ImageFont.truetype(BOLD if bold else REG, px)
    return _cache[key]


def px(emu):
    return int(round(Emu(emu).inches * DPI))


def rgb(color_obj, default=(31, 41, 51)):
    try:
        c = color_obj.rgb
        return (c[0], c[1], c[2])
    except Exception:
        return default


def wrap(draw, text, fnt, max_w):
    """글자 단위 줄바꿈 (한글은 단어 경계가 없어 글자 단위가 더 안전)."""
    if not text:
        return [""]
    lines, cur = [], ""
    for ch in text:
        trial = cur + ch
        if draw.textlength(trial, font=fnt) <= max_w or not cur:
            cur = trial
        else:
            lines.append(cur)
            cur = ch
    lines.append(cur)
    return lines


def render(slide, idx, w_px, h_px):
    img = Image.new("RGB", (w_px, h_px), (255, 255, 255))
    d = ImageDraw.Draw(img)
    overflow = []

    for sh in slide.shapes:
        x, y, w, h = px(sh.left), px(sh.top), px(sh.width), px(sh.height)

        if sh.shape_type is not None and sh.has_text_frame and sh.fill.type is not None:
            try:
                fill = rgb(sh.fill.fore_color, None)
            except Exception:
                fill = None
            if fill:
                d.rectangle([x, y, x + w, y + h], fill=fill)
            try:
                if sh.line.fill.type is not None and sh.line.color.rgb is not None:
                    d.rectangle([x, y, x + w, y + h], outline=rgb(sh.line.color), width=1)
            except Exception:
                pass

        if not sh.has_text_frame:
            continue
        tf = sh.text_frame
        if not tf.text.strip():
            continue

        # 단락 전체 높이 선계산 (수직 가운데 정렬 대응)
        blocks = []
        for p in tf.paragraphs:
            if not p.runs:
                continue
            r = p.runs[0]
            size = r.font.size.pt if r.font.size else 14
            fnt = font(size, bool(r.font.bold))
            lh = size * (p.line_spacing or 1.15) * DPI / 72.0
            sb = (p.space_before.pt if p.space_before else 0) * DPI / 72.0
            blocks.append((wrap(d, r.text, fnt, w), fnt, lh, sb, rgb(r.font.color), p.alignment))
        total = sum(sb + lh * len(ls) for ls, _, lh, sb, _, _ in blocks)

        anchor = str(tf.vertical_anchor)
        cy = y + (h - total) / 2 if "MIDDLE" in anchor else y
        start = cy
        for lines, fnt, lh, sb, color, align in blocks:
            cy += sb
            for ln in lines:
                tw = d.textlength(ln, font=fnt)
                tx = x + w - tw if (align is not None and "RIGHT" in str(align)) else x
                d.text((tx, cy + (lh - fnt.size) / 2), ln, font=fnt, fill=color)
                cy += lh
        if cy - start > h + 2:
            overflow.append((tf.text[:38].replace("\n", " "), round((cy - start) / DPI, 2), round(h / DPI, 2)))

    out = f"preview-slide{idx}.png"
    img.save(out)
    return out, overflow


def main():
    prs = Presentation("20261001-session-deck.pptx")
    w_px, h_px = px(prs.slide_width), px(prs.slide_height)
    issues = 0
    for i, slide in enumerate(prs.slides, 1):
        out, overflow = render(slide, i, w_px, h_px)
        print(f"{out}  ({w_px}x{h_px})  도형 {len(slide.shapes)}개")
        for text, need, have in overflow:
            issues += 1
            print(f"   [넘침] '{text}' 필요 {need}in > 상자 {have}in")
    print("넘침 없음" if issues == 0 else f"넘침 {issues}건 — 상자 높이 조정 필요")


if __name__ == "__main__":
    main()
