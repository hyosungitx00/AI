#!/usr/bin/env python3
"""결과 리포트 빌더 — Markdown 원본을 Word(.docx)·PowerPoint(.pptx)로 변환한다.

원본이 단일 진실 공급원이다. 문서를 고칠 때는 .md 를 고치고 이 스크립트를 다시 돌린다
(생성물을 직접 편집하면 다음 빌드에서 덮어쓰인다).

사용법:
    pip install python-docx python-pptx
    python3 report/build_report.py

입력:
    report/ai-abap-result-report.md  → dist/ai-abap-result-report.docx (상세 리포트)
    report/ai-abap-result-deck.md    → dist/ai-abap-result-deck.pptx   (발표용 축약 덱)

지원하는 Markdown 부분집합: 제목(#~####), 문단, 글머리(-), 표(|), 코드블록(```),
인용(>), 구분선(---), 인라인 **굵게**·`코드`.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

try:
    from docx import Document
    from docx.enum.table import WD_TABLE_ALIGNMENT
    from docx.enum.text import WD_ALIGN_PARAGRAPH
    from docx.shared import Pt, RGBColor
    from pptx import Presentation
    from pptx.dml.color import RGBColor as PptxColor
    from pptx.util import Inches, Pt as PptxPt
except ImportError:  # pragma: no cover
    print("의존성이 없습니다. 먼저 실행하십시오: pip install python-docx python-pptx", file=sys.stderr)
    raise SystemExit(2)

ROOT = Path(__file__).resolve().parent
DIST = ROOT / "dist"

ACCENT = (0x1F, 0x4E, 0x79)  # 본문 제목 색 (진한 청색)
MUTED = (0x59, 0x59, 0x59)

# ----------------------------------------------------------------------------- 파싱


@dataclass
class Block:
    kind: str  # heading | para | bullets | table | code | quote
    level: int = 0
    text: str = ""
    items: list[str] = field(default_factory=list)
    rows: list[list[str]] = field(default_factory=list)


def parse_markdown(path: Path) -> list[Block]:
    lines = path.read_text(encoding="utf-8").splitlines()
    blocks: list[Block] = []
    index = 0

    while index < len(lines):
        line = lines[index]
        stripped = line.strip()

        if not stripped or stripped == "---":
            index += 1
            continue

        if stripped.startswith("```"):
            body: list[str] = []
            index += 1
            while index < len(lines) and not lines[index].strip().startswith("```"):
                body.append(lines[index])
                index += 1
            index += 1
            blocks.append(Block(kind="code", text="\n".join(body)))
            continue

        heading = re.match(r"^(#{1,4})\s+(.*)$", stripped)
        if heading:
            blocks.append(Block(kind="heading", level=len(heading.group(1)), text=heading.group(2)))
            index += 1
            continue

        if stripped.startswith("|"):
            rows: list[list[str]] = []
            while index < len(lines) and lines[index].strip().startswith("|"):
                raw = lines[index].strip().strip("|")
                cells = [cell.strip() for cell in raw.split("|")]
                if not all(re.fullmatch(r":?-{2,}:?", cell) for cell in cells if cell):
                    rows.append(cells)
                index += 1
            if rows:
                blocks.append(Block(kind="table", rows=rows))
            continue

        if stripped.startswith("- "):
            items: list[str] = []
            while index < len(lines):
                current = lines[index]
                if current.strip().startswith("- "):
                    indent = len(current) - len(current.lstrip())
                    prefix = "· " if indent >= 2 else ""
                    items.append(prefix + current.strip()[2:])
                    index += 1
                elif current.strip() and not re.match(r"^(#{1,4}\s|\||```|>|-{3,})", current.strip()):
                    items[-1] += " " + current.strip()  # 이어지는 줄은 직전 항목에 붙인다
                    index += 1
                else:
                    break
            blocks.append(Block(kind="bullets", items=items))
            continue

        if stripped.startswith(">"):
            quote: list[str] = []
            while index < len(lines) and lines[index].strip().startswith(">"):
                quote.append(lines[index].strip().lstrip(">").strip())
                index += 1
            blocks.append(Block(kind="quote", text=" ".join(quote)))
            continue

        para: list[str] = []
        while index < len(lines):
            current = lines[index].strip()
            if not current or re.match(r"^(#{1,4}\s|\||```|>|-\s|-{3,})", current):
                break
            para.append(current)
            index += 1
        blocks.append(Block(kind="para", text=" ".join(para)))

    return blocks


def inline_runs(text: str) -> list[tuple[str, bool, bool]]:
    """인라인 서식을 (문자열, 굵게, 코드) 토큰으로 분해한다."""
    tokens: list[tuple[str, bool, bool]] = []
    for part in re.split(r"(\*\*[^*]+\*\*|`[^`]+`)", text):
        if not part:
            continue
        if part.startswith("**") and part.endswith("**"):
            tokens.append((part[2:-2], True, False))
        elif part.startswith("`") and part.endswith("`"):
            tokens.append((part[1:-1], False, True))
        else:
            tokens.append((part, False, False))
    return tokens


# ----------------------------------------------------------------------------- Word


def write_runs(paragraph, text: str, size: int = 10, bold: bool = False) -> None:
    for chunk, is_bold, is_code in inline_runs(text):
        run = paragraph.add_run(chunk)
        run.font.size = Pt(size)
        run.bold = bold or is_bold
        run.font.name = "Consolas" if is_code else "맑은 고딕"
        if is_code:
            run.font.color.rgb = RGBColor(0x8B, 0x24, 0x52)


def build_docx(blocks: list[Block], out: Path) -> None:
    doc = Document()
    base = doc.styles["Normal"]
    base.font.name = "맑은 고딕"
    base.font.size = Pt(10)

    for block in blocks:
        if block.kind == "heading":
            if block.level == 1:
                paragraph = doc.add_paragraph()
                paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
                run = paragraph.add_run(block.text)
                run.bold = True
                run.font.size = Pt(20)
                run.font.color.rgb = RGBColor(*ACCENT)
                doc.add_paragraph()
            else:
                heading = doc.add_heading(level=min(block.level, 4))
                run = heading.add_run(block.text)
                run.font.name = "맑은 고딕"
                run.font.color.rgb = RGBColor(*ACCENT)
                run.font.size = Pt({2: 15, 3: 12, 4: 11}[min(block.level, 4)])

        elif block.kind == "para":
            write_runs(doc.add_paragraph(), block.text)

        elif block.kind == "bullets":
            for item in block.items:
                paragraph = doc.add_paragraph(style="List Bullet")
                write_runs(paragraph, item)

        elif block.kind == "quote":
            paragraph = doc.add_paragraph()
            paragraph.paragraph_format.left_indent = Inches(0.25)
            for chunk, is_bold, is_code in inline_runs(block.text):
                run = paragraph.add_run(chunk)
                run.italic = True
                run.bold = is_bold
                run.font.size = Pt(9)
                run.font.color.rgb = RGBColor(*MUTED)
                run.font.name = "Consolas" if is_code else "맑은 고딕"

        elif block.kind == "code":
            paragraph = doc.add_paragraph()
            paragraph.paragraph_format.left_indent = Inches(0.15)
            run = paragraph.add_run(block.text)
            run.font.name = "Consolas"
            run.font.size = Pt(8)

        elif block.kind == "table":
            columns = max(len(row) for row in block.rows)
            table = doc.add_table(rows=0, cols=columns)
            table.style = "Light Grid Accent 1"
            table.alignment = WD_TABLE_ALIGNMENT.CENTER
            for position, row in enumerate(block.rows):
                cells = table.add_row().cells
                for column in range(columns):
                    value = row[column] if column < len(row) else ""
                    cell_paragraph = cells[column].paragraphs[0]
                    write_runs(cell_paragraph, value, size=9, bold=(position == 0))

    DIST.mkdir(exist_ok=True)
    doc.save(out)
    print(f"생성: {out.relative_to(ROOT.parent)}")


# ----------------------------------------------------------------------------- PowerPoint


def add_textbox(slide, left, top, width, height):
    box = slide.shapes.add_textbox(left, top, width, height)
    frame = box.text_frame
    frame.word_wrap = True
    return frame


def pptx_runs(paragraph, text: str, size: int, bold: bool = False) -> None:
    for chunk, is_bold, is_code in inline_runs(text):
        run = paragraph.add_run()
        run.text = chunk
        run.font.size = PptxPt(size)
        run.font.bold = bold or is_bold
        run.font.name = "Consolas" if is_code else "맑은 고딕"
        if is_code:
            run.font.color.rgb = PptxColor(0x8B, 0x24, 0x52)


def build_pptx(blocks: list[Block], out: Path) -> None:
    deck = Presentation()
    deck.slide_width = Inches(13.333)
    deck.slide_height = Inches(7.5)
    blank = deck.slide_layouts[6]

    # 표지
    title_block = next((b for b in blocks if b.kind == "heading" and b.level == 1), None)
    subtitle = next((b for b in blocks if b.kind == "para"), None)
    cover = deck.slides.add_slide(blank)
    frame = add_textbox(cover, Inches(1), Inches(2.6), Inches(11.3), Inches(2))
    paragraph = frame.paragraphs[0]
    pptx_runs(paragraph, title_block.text if title_block else "결과 리포트", 34, bold=True)
    paragraph.runs[0].font.color.rgb = PptxColor(*ACCENT)
    if subtitle:
        second = frame.add_paragraph()
        second.space_before = PptxPt(18)
        pptx_runs(second, subtitle.text, 14)
        second.runs[0].font.color.rgb = PptxColor(*MUTED)

    slides: list[tuple[str, list[Block]]] = []
    current: tuple[str, list[Block]] | None = None
    for block in blocks:
        if block.kind == "heading" and block.level == 2:
            current = (block.text, [])
            slides.append(current)
        elif current is not None:
            current[1].append(block)

    for heading, body in slides:
        slide = deck.slides.add_slide(blank)
        header = add_textbox(slide, Inches(0.6), Inches(0.35), Inches(12.1), Inches(0.9))
        pptx_runs(header.paragraphs[0], heading, 24, bold=True)
        header.paragraphs[0].runs[0].font.color.rgb = PptxColor(*ACCENT)

        top = Inches(1.35)
        for block in body:
            remaining = deck.slide_height - top - Inches(0.4)
            if remaining <= Inches(0.5):
                break

            if block.kind in {"bullets", "para", "quote", "heading"}:
                texts = block.items if block.kind == "bullets" else [block.text]
                height = Inches(0.36) * max(1, sum(1 + len(t) // 95 for t in texts))
                frame = add_textbox(slide, Inches(0.7), top, Inches(11.9), min(height, remaining))
                for position, text in enumerate(texts):
                    paragraph = frame.paragraphs[0] if position == 0 else frame.add_paragraph()
                    marker = "• " if block.kind == "bullets" and not text.startswith("· ") else ""
                    pptx_runs(paragraph, marker + text, 13, bold=(block.kind == "heading"))
                    if block.kind == "quote":
                        for run in paragraph.runs:
                            run.font.italic = True
                            run.font.color.rgb = PptxColor(*MUTED)
                top += min(height, remaining) + Inches(0.12)

            elif block.kind == "code":
                code_lines = block.text.splitlines() or [""]
                height = Inches(0.21) * len(code_lines) + Inches(0.2)
                frame = add_textbox(slide, Inches(0.7), top, Inches(11.9), min(height, remaining))
                for position, text in enumerate(code_lines):
                    paragraph = frame.paragraphs[0] if position == 0 else frame.add_paragraph()
                    run = paragraph.add_run()
                    run.text = text
                    run.font.size = PptxPt(10)
                    run.font.name = "Consolas"
                top += min(height, remaining) + Inches(0.12)

            elif block.kind == "table":
                columns = max(len(row) for row in block.rows)
                rows = len(block.rows)
                height = min(Inches(0.33) * rows, remaining)
                shape = slide.shapes.add_table(rows, columns, Inches(0.7), top, Inches(11.9), height)
                table = shape.table
                for row_index, row in enumerate(block.rows):
                    for column in range(columns):
                        cell = table.cell(row_index, column)
                        cell.text = ""
                        paragraph = cell.text_frame.paragraphs[0]
                        value = row[column] if column < len(row) else ""
                        pptx_runs(paragraph, value, 11, bold=(row_index == 0))
                top += height + Inches(0.15)

    DIST.mkdir(exist_ok=True)
    deck.save(out)
    print(f"생성: {out.relative_to(ROOT.parent)} (슬라이드 {len(deck.slides)}장)")


def main() -> int:
    report_src = ROOT / "ai-abap-result-report.md"
    deck_src = ROOT / "ai-abap-result-deck.md"
    for source in (report_src, deck_src):
        if not source.exists():
            print(f"원본을 찾을 수 없습니다: {source}", file=sys.stderr)
            return 1

    build_docx(parse_markdown(report_src), DIST / "ai-abap-result-report.docx")
    build_pptx(parse_markdown(deck_src), DIST / "ai-abap-result-deck.pptx")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
