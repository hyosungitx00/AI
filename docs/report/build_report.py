# -*- coding: utf-8 -*-
"""
HYOSUNG ITX 공통템플릿(16x9) 기반 발표자료 생성
요청서: 같은 AI를 쓰는데 왜 생산성은 차이 날까?
"""
from __future__ import annotations

import copy
import shutil
from pathlib import Path

from pptx import Presentation
from pptx.enum.shapes import MSO_SHAPE_TYPE
from pptx.oxml.ns import qn
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from lxml import etree

TEMPLATE = Path('docs/report/templates/2025_공통템플릿_16x9.pptx')
OUT = Path('docs/report/AI_활용_생산성_발표자료.pptx')

NAVY = RGBColor(0x00, 0x20, 0x60)
BLUE = RGBColor(0x00, 0x27, 0x76)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
DARK = RGBColor(0x22, 0x22, 0x22)
GREY = RGBColor(0x66, 0x66, 0x66)


def duplicate_slide(prs: Presentation, index: int):
    """Duplicate an existing slide (keeps template chrome/layout)."""
    source = prs.slides[index]
    blank_layout = source.slide_layout
    dest = prs.slides.add_slide(blank_layout)

    # Remove default shapes added by layout (except placeholders we need sparingly)
    for shp in list(dest.shapes):
        sp = shp._element
        sp.getparent().remove(sp)

    # Copy all shapes from source
    for shp in source.shapes:
        el = copy.deepcopy(shp._element)
        dest.shapes._spTree.insert_element_before(el, 'p:extLst')

    # Copy slide number placeholder if present on source via layout
    return dest


def iter_all_shapes(shapes):
    for sh in shapes:
        yield sh
        if sh.shape_type == MSO_SHAPE_TYPE.GROUP:
            yield from iter_all_shapes(sh.shapes)


def set_runs_text(shape, text: str, keep_first_run_format=True):
    """Replace shape text while trying to preserve first run formatting."""
    if not shape.has_text_frame:
        return
    tf = shape.text_frame
    # flatten into first paragraph / first run
    paragraphs = list(tf.paragraphs)
    if not paragraphs:
        return
    # clear all paragraphs except first
    first = paragraphs[0]
    # clear runs in first
    if first.runs:
        first.runs[0].text = text
        for r in first.runs[1:]:
            r.text = ''
    else:
        run = first.add_run()
        run.text = text
    # remove extra paragraphs content
    for p in paragraphs[1:]:
        for r in p.runs:
            r.text = ''


def replace_text_everywhere(slide, mapping: dict[str, str]):
    """Exact-match or contains replacement for shape texts."""
    for sh in iter_all_shapes(slide.shapes):
        if not sh.has_text_frame:
            continue
        cur = sh.text_frame.text
        for old, new in mapping.items():
            if cur.strip() == old.strip() or cur == old:
                set_runs_text(sh, new)
                break


def find_shape_by_text(slide, text: str):
    for sh in iter_all_shapes(slide.shapes):
        if sh.has_text_frame and sh.text_frame.text.strip() == text.strip():
            return sh
    return None


def find_shapes_containing(slide, text: str):
    out = []
    for sh in iter_all_shapes(slide.shapes):
        if sh.has_text_frame and text in sh.text_frame.text:
            out.append(sh)
    return out


def clear_guide_labels(slide):
    """Hide template guide labels like 표지/목차/간지/내용A that sit off-slide."""
    guides = ('표지', '목차', '간지', '내용', '도식', 'A_타입', 'B_타입')
    for sh in list(slide.shapes):
        if not sh.has_text_frame:
            continue
        t = sh.text_frame.text.strip()
        if any(g in t for g in guides) and getattr(sh, 'left', 0) < 0:
            set_runs_text(sh, '')
    # clear leftover 'img' placeholders in diagram templates
    for sh in iter_all_shapes(slide.shapes):
        if sh.has_text_frame and sh.text_frame.text.strip() == 'img':
            set_runs_text(sh, '')


def add_textbox(slide, x, y, w, h, text, size=14, bold=False, color=DARK, align=None):
    box = slide.shapes.add_textbox(x, y, w, h)
    tf = box.text_frame
    tf.word_wrap = True
    p = tf.paragraphs[0]
    if align is not None:
        p.alignment = align
    r = p.add_run()
    r.text = text
    r.font.size = Pt(size)
    r.font.bold = bold
    r.font.color.rgb = color
    r.font.name = '맑은 고딕'
    try:
        rPr = r._r.get_or_add_rPr()
        rFonts = rPr.get_or_add_rFonts()
        rFonts.set(qn('w:eastAsia'), '맑은 고딕')
    except Exception:
        pass
    return box


def add_para(tf, text, size=14, bold=False, color=DARK, first=False, before=6):
    from pptx.enum.text import PP_ALIGN
    p = tf.paragraphs[0] if first else tf.add_paragraph()
    p.space_before = Pt(before)
    r = p.add_run()
    r.text = text
    r.font.size = Pt(size)
    r.font.bold = bold
    r.font.color.rgb = color
    r.font.name = '맑은 고딕'
    try:
        rPr = r._r.get_or_add_rPr()
        rFonts = rPr.get_or_add_rFonts()
        rFonts.set(qn('w:eastAsia'), '맑은 고딕')
    except Exception:
        pass
    return p


def delete_all_slides(prs):
    """Remove every slide from presentation (keep masters/layouts)."""
    sldIdLst = prs.slides._sldIdLst
    for sldId in list(sldIdLst):
        rId = sldId.get(qn('r:id'))
        prs.part.drop_rel(rId)
        sldIdLst.remove(sldId)


def build():
    # Work on a copy of template so masters/theme/logo remain intact
    OUT.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(TEMPLATE, OUT)
    prs = Presentation(str(OUT))

    # Template slide indices (0-based) we will clone from:
    # 1 = 표지, 2 = 목차, 3 = 간지, 4 = 내용A(빈), 15 = AS-IS/TO-BE,
    # 16 = 3 STEP, 17 = 3컬럼, 23 = End
    IDX_COVER = 1
    IDX_TOC = 2
    IDX_SECTION = 3
    IDX_CONTENT = 4   # 내용 A_타입 (blank canvas + chrome)
    IDX_ASIS = 15
    IDX_STEPS = 16
    IDX_COLS = 17
    IDX_END = 23

    # Collect XML of template slides we need BEFORE deleting
    def slide_xml(i):
        return copy.deepcopy(prs.slides[i]._element)

    def slide_layout(i):
        return prs.slides[i].slide_layout

    xmls = {
        'cover': (slide_xml(IDX_COVER), slide_layout(IDX_COVER)),
        'toc': (slide_xml(IDX_TOC), slide_layout(IDX_TOC)),
        'section': (slide_xml(IDX_SECTION), slide_layout(IDX_SECTION)),
        'content': (slide_xml(IDX_CONTENT), slide_layout(IDX_CONTENT)),
        'asis': (slide_xml(IDX_ASIS), slide_layout(IDX_ASIS)),
        'steps': (slide_xml(IDX_STEPS), slide_layout(IDX_STEPS)),
        'cols': (slide_xml(IDX_COLS), slide_layout(IDX_COLS)),
        'end': (slide_xml(IDX_END), slide_layout(IDX_END)),
    }

    delete_all_slides(prs)

    def add_from(key):
        xml, layout = xmls[key]
        slide = prs.slides.add_slide(layout)
        # wipe default shapes
        for shp in list(slide.shapes):
            el = shp._element
            el.getparent().remove(el)
        # insert cloned shapes
        for child in copy.deepcopy(xml):
            tag = etree.QName(child).localname
            if tag in ('cSld',):
                # copy shape tree children from cSld/spTree
                spTree = child.find(qn('p:spTree'))
                if spTree is not None:
                    for el in list(spTree):
                        lname = etree.QName(el).localname
                        if lname in ('nvGrpSpPr', 'grpSpPr'):
                            continue
                        slide.shapes._spTree.append(copy.deepcopy(el))
            # Also handle when xml IS the sld element - children include cSld
        # Better: xml is p:sld
        if etree.QName(xml).localname == 'sld':
            # already handled above if we iterate wrong — fix approach
            pass
        clear_guide_labels(slide)
        return slide

    # More reliable clone: use rId relationship approach
    # Re-open template and use known method
    return build_v2()


def clone_slide(prs, index):
    """Clone slide at index to end of presentation."""
    source = prs.slides[index]
    layout = source.slide_layout
    dest = prs.slides.add_slide(layout)

    # Remove shapes created by empty placeholders (keep only slide number if needed)
    spTree = dest.shapes._spTree
    for el in list(spTree):
        lname = etree.QName(el).localname
        if lname in ('sp', 'pic', 'grpSp', 'cxnSp', 'graphicFrame'):
            spTree.remove(el)

    for el in source.shapes._spTree:
        lname = etree.QName(el).localname
        if lname in ('sp', 'pic', 'grpSp', 'cxnSp', 'graphicFrame'):
            spTree.append(copy.deepcopy(el))
    return dest


def remove_slide(prs, index):
    sldIdLst = prs.slides._sldIdLst
    sldId = list(sldIdLst)[index]
    rId = sldId.get(qn('r:id'))
    prs.part.drop_rel(rId)
    sldIdLst.remove(sldId)


def set_shape_text_multiline(shape, lines, sizes=None, bolds=None, colors=None):
    if not shape.has_text_frame:
        return
    tf = shape.text_frame
    tf.clear()
    for i, line in enumerate(lines):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        r = p.add_run()
        r.text = line
        size = (sizes[i] if sizes and i < len(sizes) else 14)
        bold = (bolds[i] if bolds and i < len(bolds) else False)
        color = (colors[i] if colors and i < len(colors) else DARK)
        r.font.size = Pt(size)
        r.font.bold = bold
        r.font.color.rgb = color
        r.font.name = '맑은 고딕'
        try:
            rPr = r._r.get_or_add_rPr()
            rFonts = rPr.get_or_add_rFonts()
            rFonts.set(qn('w:eastAsia'), '맑은 고딕')
        except Exception:
            pass


def build_v2():
    shutil.copy(TEMPLATE, OUT)
    prs = Presentation(str(OUT))

    # Original template has 24 slides (0..23). We append our slides by cloning,
    # then delete the original 24.
    ORIG = 24

    # Indices in original template
    T_COVER, T_TOC, T_SEC, T_A = 1, 2, 3, 4
    T_ASIS, T_STEPS, T_COLS, T_END = 15, 16, 17, 23

    created = []

    def add(idx):
        s = clone_slide(prs, idx)
        clear_guide_labels(s)
        created.append(s)
        return s

    # ========== 1. 표지 ==========
    s = add(T_COVER)
    # HYOSUNG ITX / BUSINESS PROPOSAL in group
    for sh in iter_all_shapes(s.shapes):
        if not sh.has_text_frame:
            continue
        t = sh.text_frame.text.strip()
        if t == 'HYOSUNG ITX':
            set_runs_text(sh, 'HYOSUNG ITX')
        elif t == 'BUSINESS PROPOSAL':
            set_runs_text(sh, 'TECH SEMINAR')
        elif t == '20xx. 00. 00':
            set_runs_text(sh, '2026')

    # Add main title on cover (content area)
    from pptx.enum.text import PP_ALIGN
    add_textbox(s, Inches(2.4), Inches(4.1), Inches(10), Inches(0.7),
                '같은 AI를 쓰는데 왜 생산성은 차이 날까?',
                size=22, bold=True, color=NAVY)
    add_textbox(s, Inches(2.4), Inches(4.75), Inches(10), Inches(0.5),
                'AI 시대 SAP 개발자의 생존 전략과 업무 혁신 방법',
                size=14, bold=False, color=GREY)

    # ========== 2. 목차 ==========
    s = add(T_TOC)
    toc = find_shape_by_text(s, 'TITLE TEXT\nTITLE TEXT\nTITLE TEXT\nTITLE TEXT\nTITLE TEXT')
    if toc is None:
        # try rectangle 9 with multiline
        for sh in s.shapes:
            if sh.has_text_frame and 'TITLE TEXT' in sh.text_frame.text:
                toc = sh
                break
    if toc:
        set_shape_text_multiline(
            toc,
            [
                '01.  AI 시대, 개발 방식은 이미 변하고 있다',
                '02.  같은 AI, 다른 생산성 — 무엇을 다르게 하는가',
                '03.  방법 1. 질문하지 말고 업무를 맡겨라',
                '04.  방법 2. Prompt보다 Context가 중요하다',
                '05.  방법 3. AI를 개발 Workflow로 만들어라',
            ],
            sizes=[14, 14, 14, 14, 14],
            bolds=[True, True, True, True, True],
            colors=[NAVY, NAVY, NAVY, NAVY, NAVY],
        )

    # ========== 3. 간지 Part 1 ==========
    s = add(T_SEC)
    for sh in s.shapes:
        if sh.has_text_frame and 'TITLE' in sh.text_frame.text:
            set_shape_text_multiline(
                sh,
                ['PART 1', 'AI 시대,', '개발자는 사라질까?'],
                sizes=[14, 28, 28],
                bolds=[True, True, True],
                colors=[WHITE, WHITE, WHITE],
            )
            break

    # ========== 4. AI 대체 이야기 (내용 A) ==========
    s = add(T_A)
    for sh in s.shapes:
        if sh.has_text_frame and sh.text_frame.text.strip() in ('01. TEXT', '01.TEXT'):
            set_runs_text(sh, '01. AI가 개발자를 대체한다는 이야기')
    # body
    add_textbox(s, Inches(0.5), Inches(1.2), Inches(12.3), Inches(0.4),
                '최근 시장에서 반복되는 메시지', size=14, bold=True, color=BLUE)
    headlines = [
        ('“AI가 개발자를 대체할 것이다”', '산업·미디어에서 반복되는 대체 담론'),
        ('“주니어 개발자의 역할이 줄어든다”', '초급 코딩·반복 업무의 자동화 가속'),
        ('“개발자의 업무 방식이 바뀐다”', '도구·프로세스·협업 구조의 재정의'),
    ]
    y = 1.8
    for title, desc in headlines:
        add_textbox(s, Inches(0.5), Inches(y), Inches(12.3), Inches(0.35),
                    title, size=18, bold=True, color=NAVY)
        add_textbox(s, Inches(0.7), Inches(y + 0.35), Inches(12), Inches(0.3),
                    desc, size=13, bold=False, color=GREY)
        y += 1.15
    add_textbox(s, Inches(0.5), Inches(6.2), Inches(12.3), Inches(0.5),
                '완전 대체 여부는 논쟁의 영역이다.  다만 한 가지는 확실하다 —  개발 방식 자체는 이미 변하고 있다.',
                size=13, bold=True, color=BLUE)

    # ========== 5. 산업 변화 + 데이터 ==========
    s = add(T_A)
    for sh in s.shapes:
        if sh.has_text_frame and sh.text_frame.text.strip() in ('01. TEXT', '01.TEXT'):
            set_runs_text(sh, '02. AI는 선택이 아니라 산업 변화가 되었다')
    add_textbox(s, Inches(0.5), Inches(1.15), Inches(12.3), Inches(0.35),
                '기업들이 업무 프로세스에 AI를 포함시키고 있다', size=13, bold=False, color=GREY)

    # KPI boxes
    kpis = [
        ('$2.59T', '2026년 전 세계 AI 지출\n(Gartner, +47% YoY)'),
        ('$37B', '2025년 기업 GenAI 지출\n(Menlo, 전년 대비 3.2배)'),
        ('72%', '생성형 AI 사용 조직\n(McKinsey, ’24 33%→’25 72%)'),
        ('88%', '업무 기능에서 AI 상시 사용\n(McKinsey State of AI)'),
    ]
    x = 0.5
    for num, label in kpis:
        add_textbox(s, Inches(x), Inches(1.8), Inches(3.0), Inches(0.6),
                    num, size=28, bold=True, color=NAVY)
        add_textbox(s, Inches(x), Inches(2.5), Inches(3.0), Inches(0.8),
                    label, size=11, bold=False, color=GREY)
        x += 3.2

    add_textbox(s, Inches(0.5), Inches(3.6), Inches(12.3), Inches(0.35),
                '개발자가 마주하는 AI 도구 지형', size=14, bold=True, color=BLUE)
    tools = [
        ('GitHub Copilot', '코딩 보조'),
        ('Cursor', 'AI IDE'),
        ('Claude / ChatGPT', '분석·설계'),
        ('SAP Joule', 'SAP 업무 AI'),
        ('MS Copilot', '업무 전반'),
    ]
    x = 0.5
    for name, desc in tools:
        add_textbox(s, Inches(x), Inches(4.15), Inches(2.4), Inches(0.35),
                    name, size=13, bold=True, color=NAVY)
        add_textbox(s, Inches(x), Inches(4.5), Inches(2.4), Inches(0.3),
                    desc, size=11, bold=False, color=GREY)
        x += 2.5

    add_textbox(s, Inches(0.5), Inches(5.5), Inches(12.3), Inches(0.7),
                'AI를 사용할 것인가 말 것인가는 선택의 문제가 아니다.\n이미 많은 기업이 AI를 업무 프로세스에 포함시키고 있다.',
                size=15, bold=True, color=NAVY)
    add_textbox(s, Inches(0.5), Inches(6.45), Inches(12.3), Inches(0.3),
                '※ 수치는 공개 리포트 기준 인용 (Gartner / Menlo Ventures / McKinsey)',
                size=10, bold=False, color=GREY)

    # ========== 6. 중요한 질문 ==========
    s = add(T_A)
    for sh in s.shapes:
        if sh.has_text_frame and sh.text_frame.text.strip() in ('01. TEXT', '01.TEXT'):
            set_runs_text(sh, '03. 중요한 질문')
    add_textbox(s, Inches(0.8), Inches(2.0), Inches(11.5), Inches(0.5),
                'AI가 개발자를 대체할까?', size=24, bold=False, color=GREY)
    add_textbox(s, Inches(0.8), Inches(2.7), Inches(11.5), Inches(0.4),
                '보다 중요한 질문은 이것이다.', size=14, bold=False, color=GREY)
    add_textbox(s, Inches(0.8), Inches(3.4), Inches(11.5), Inches(1.0),
                'AI를 활용하는 개발자가\n그렇지 않은 개발자를 대체하지 않을까?',
                size=26, bold=True, color=NAVY)
    add_textbox(s, Inches(0.8), Inches(5.3), Inches(11.5), Inches(0.8),
                '같은 AI 도구를 쓰는데도,\n왜 어떤 개발자는 생산성이 크게 늘고, 어떤 개발자는 그대로일까?',
                size=15, bold=False, color=BLUE)

    # ========== 7. 간지 Part 2 ==========
    s = add(T_SEC)
    for sh in s.shapes:
        if sh.has_text_frame and 'TITLE' in sh.text_frame.text:
            set_shape_text_multiline(
                sh,
                ['PART 2', 'AI 생산성을', '극대화하는 방법 3가지'],
                sizes=[14, 26, 26],
                bolds=[True, True, True],
                colors=[WHITE, WHITE, WHITE],
            )
            break

    # ========== 8. Method 1 — AS-IS / TO-BE ==========
    s = add(T_ASIS)
    for sh in iter_all_shapes(s.shapes):
        if not sh.has_text_frame:
            continue
        t = sh.text_frame.text.strip()
        if t in ('01. TEXT', '01.TEXT'):
            set_runs_text(sh, 'METHOD 01')
        elif t == 'AS IS – TO BE':
            set_runs_text(sh, '질문하지 말고, 업무를 맡겨라')
        elif t == '핵심 내용을 입력하세요.':
            # first occurrence AS-IS, second TO-BE — handle by order
            pass
        elif '이 곳에 내용을 입력하세요' in t:
            pass

    # Fill AS-IS / TO-BE texts in order of appearance
    keys = []
    bodies = []
    for sh in iter_all_shapes(s.shapes):
        if not sh.has_text_frame:
            continue
        t = sh.text_frame.text.strip()
        if t == '핵심 내용을 입력하세요.':
            keys.append(sh)
        elif '이 곳에 내용을 입력하세요' in t:
            bodies.append(sh)
    if len(keys) >= 2:
        set_runs_text(keys[0], '일반적인 AI 활용')
        set_runs_text(keys[1], '생산성이 높은 AI 활용')
    if len(bodies) >= 2:
        set_shape_text_multiline(
            bodies[0],
            ['“SELECT 성능 개선해줘”', '', '→ 일반론적 조언', '→ 제한적인 코드 제안', '→ 맥락 없는 답변'],
            sizes=[13, 8, 12, 12, 12],
            bolds=[True, False, False, False, False],
            colors=[NAVY, GREY, GREY, GREY, GREY],
        )
        set_shape_text_multiline(
            bodies[1],
            [
                '환경·모듈·테이블·DB·목표를 정의하고',
                '영향도 / 개선방향 / 코드 / 테스트까지 요청',
                '',
                '→ 영향도 분석 + 개선안',
                '→ 수정 코드 + 검증 방법',
            ],
            sizes=[12, 12, 8, 12, 12],
            bolds=[True, True, False, False, False],
            colors=[NAVY, NAVY, GREY, GREY, GREY],
        )

    # ========== 9. Method 1 message + Method 2 start ==========
    s = add(T_A)
    for sh in s.shapes:
        if sh.has_text_frame and sh.text_frame.text.strip() in ('01. TEXT', '01.TEXT'):
            set_runs_text(sh, 'METHOD 01  ·  핵심')
    add_textbox(s, Inches(0.8), Inches(2.3), Inches(11.5), Inches(0.5),
                'AI 활용의 차이는 ‘질문의 수준’이 아니다.', size=20, bold=False, color=GREY)
    add_textbox(s, Inches(0.8), Inches(3.2), Inches(11.5), Inches(1.0),
                '업무를 얼마나 잘 정의해서\n맡기는가의 차이다.',
                size=28, bold=True, color=NAVY)
    add_textbox(s, Inches(0.8), Inches(5.0), Inches(11.5), Inches(0.8),
                '검색하듯 묻지 말고, 한 건의 업무(Task)를 통째로 위임하라.\n'
                'SAP 예: 환경 · 모듈 · 테이블 · DB · 영향도 · 코드 · 테스트까지 한 번에.',
                size=14, bold=False, color=BLUE)

    # ========== 10. Method 2 Context ==========
    s = add(T_COLS)
    for sh in iter_all_shapes(s.shapes):
        if not sh.has_text_frame:
            continue
        t = sh.text_frame.text.strip()
        if t in ('01. TEXT', '01.TEXT'):
            set_runs_text(sh, 'METHOD 02')
        elif t == '프로젝트 과정':
            set_runs_text(sh, 'Prompt보다 Context가 중요하다')
        elif t == '소제목 1':
            set_runs_text(sh, '모델보다 맥락')
        elif t == '소제목 2':
            set_runs_text(sh, 'SAP Context 예시')
        elif t == '소제목 3':
            set_runs_text(sh, '만드는 기술')
        elif '이 곳에 내용을 입력하세요' in t:
            # fill by order
            pass

    bodies = [sh for sh in iter_all_shapes(s.shapes)
              if sh.has_text_frame and '이 곳에 내용을 입력하세요' in sh.text_frame.text]
    if len(bodies) >= 3:
        set_shape_text_multiline(
            bodies[0],
            ['AI 성능은 모델보다', 'Context에 의해 결정된다.', '', '질문을 잘하는 사람이 아니라', '환경을 만드는 사람'],
            sizes=[13, 13, 8, 12, 12],
            bolds=[True, True, False, False, False],
            colors=[NAVY, NAVY, GREY, GREY, GREY],
        )
        set_shape_text_multiline(
            bodies[1],
            ['ECC / S/4HANA', 'Naming · 개발표준', '테이블 관계 · FM/Class', 'Git · 설계문서', '업무 프로세스'],
            sizes=[12, 12, 12, 12, 12],
            bolds=[False]*5,
            colors=[DARK]*5,
        )
        set_shape_text_multiline(
            bodies[2],
            ['Cursor Rules', 'Project Context', 'MCP', 'AI Memory', '저장소 표준(.md)'],
            sizes=[12, 12, 12, 12, 12],
            bolds=[True, True, True, True, True],
            colors=[NAVY]*5,
        )

    # ========== 11. Method 2 key ==========
    s = add(T_A)
    for sh in s.shapes:
        if sh.has_text_frame and sh.text_frame.text.strip() in ('01. TEXT', '01.TEXT'):
            set_runs_text(sh, 'METHOD 02  ·  핵심')
    add_textbox(s, Inches(0.8), Inches(2.5), Inches(11.5), Inches(1.2),
                'AI에게 정답을 요구하기 전에,\nAI가 문제를 이해할 수 있는\n환경을 만들어야 한다.',
                size=26, bold=True, color=NAVY)
    add_textbox(s, Inches(0.8), Inches(4.8), Inches(11.5), Inches(0.8),
                'Context Engineering > Prompt Engineering\n'
                'Rules / 프로젝트 맥락 / MCP / 문서를 먼저 고정하면, 같은 모델도 결과가 달라진다.',
                size=14, bold=False, color=BLUE)

    # ========== 12. Method 3 Workflow STEPS ==========
    s = add(T_STEPS)
    for sh in iter_all_shapes(s.shapes):
        if not sh.has_text_frame:
            continue
        t = sh.text_frame.text.strip()
        if t in ('01. TEXT', '01.TEXT'):
            set_runs_text(sh, 'METHOD 03')
        elif t == '프로젝트 과정':
            set_runs_text(sh, 'AI를 도구가 아닌 개발 Workflow로')
        elif t == 'STEP 1':
            set_runs_text(sh, 'STEP 1')
        elif t == 'STEP 2':
            set_runs_text(sh, 'STEP 2')
        elif t == 'STEP 3':
            set_runs_text(sh, 'STEP 3')
        elif t == '핵심 단어 1':
            set_runs_text(sh, '분석 · 설계')
        elif t == '핵심 단어 2':
            set_runs_text(sh, '구현 · 리뷰')
        elif t == '핵심 단어 3':
            set_runs_text(sh, '검증 · 문서')

    # subtitle boxes under keywords
    subs = [sh for sh in iter_all_shapes(s.shapes)
            if sh.has_text_frame and '더블클릭하여 텍스트' in sh.text_frame.text]
    bodies = [sh for sh in iter_all_shapes(s.shapes)
              if sh.has_text_frame and '이 곳에 내용을 입력하세요' in sh.text_frame.text]
    if len(subs) >= 3:
        set_shape_text_multiline(subs[0], ['요구사항 → 영향도 분석', '관련 프로그램/테이블 탐색'],
                                 sizes=[12, 12], bolds=[False, False], colors=[DARK, DARK])
        set_shape_text_multiline(subs[1], ['코드 작성', 'AI Code Review'],
                                 sizes=[12, 12], bolds=[False, False], colors=[DARK, DARK])
        set_shape_text_multiline(subs[2], ['Test Case 생성', '변경문서 · 배포 체크리스트'],
                                 sizes=[12, 12], bolds=[False, False], colors=[DARK, DARK])
    if len(bodies) >= 3:
        set_shape_text_multiline(bodies[0], ['한 번 묻고 끝내지 말고', '분석 단계부터 AI를 연결'],
                                 sizes=[12, 12], bolds=[True, False], colors=[NAVY, GREY])
        set_shape_text_multiline(bodies[1], ['생성과 리뷰를', '같은 루프로 반복'],
                                 sizes=[12, 12], bolds=[True, False], colors=[NAVY, GREY])
        set_shape_text_multiline(bodies[2], ['테스트·문서까지', '워크플로의 일부로'],
                                 sizes=[12, 12], bolds=[True, False], colors=[NAVY, GREY])

    # ========== 13. Role change ==========
    s = add(T_A)
    for sh in s.shapes:
        if sh.has_text_frame and sh.text_frame.text.strip() in ('01. TEXT', '01.TEXT'):
            set_runs_text(sh, 'METHOD 03  ·  역할의 변화')
    add_textbox(s, Inches(0.6), Inches(1.4), Inches(5.8), Inches(0.4),
                '기존', size=14, bold=True, color=GREY)
    add_textbox(s, Inches(0.6), Inches(2.0), Inches(5.8), Inches(2.5),
                '개발자가\n모든 작업을 직접 수행',
                size=22, bold=True, color=GREY)
    add_textbox(s, Inches(7.0), Inches(1.4), Inches(5.8), Inches(0.4),
                '변화', size=14, bold=True, color=BLUE)
    add_textbox(s, Inches(7.0), Inches(2.0), Inches(5.8), Inches(1.2),
                '개발자\n방향 설정 · 검증 · 의사결정',
                size=20, bold=True, color=NAVY)
    add_textbox(s, Inches(7.0), Inches(3.5), Inches(5.8), Inches(1.2),
                'AI\n반복 작업 · 초안 · 탐색 수행',
                size=20, bold=True, color=BLUE)
    add_textbox(s, Inches(0.6), Inches(5.5), Inches(12), Inches(0.7),
                '한 번 사용하는 도구가 아니라, 업무 프로세스 자체에 AI를 연결할 때\n생산성 격차가 벌어진다.',
                size=15, bold=True, color=NAVY)

    # ========== 14. Closing ==========
    s = add(T_A)
    for sh in s.shapes:
        if sh.has_text_frame and sh.text_frame.text.strip() in ('01. TEXT', '01.TEXT'):
            set_runs_text(sh, 'CLOSING')
    add_textbox(s, Inches(0.8), Inches(1.6), Inches(11.5), Inches(1.2),
                'AI 시대 개발자의 경쟁력은\n코드를 얼마나 빨리 작성하는지가 아니다.',
                size=22, bold=False, color=GREY)
    add_textbox(s, Inches(0.8), Inches(3.1), Inches(11.5), Inches(1.2),
                'AI가 얼마나 잘 일하도록\n환경을 만들 수 있는지가 경쟁력이다.',
                size=24, bold=True, color=NAVY)
    add_textbox(s, Inches(0.8), Inches(5.0), Inches(11.5), Inches(0.9),
                'AI를 사용하는 개발자가 아니라,\nAI와 함께 일하는 개발자가 되어야 한다.',
                size=18, bold=True, color=BLUE)
    add_textbox(s, Inches(0.8), Inches(6.2), Inches(11.5), Inches(0.5),
                '한 문장: AI는 개발자를 대체하는 기술이 아니라, '
                'AI를 잘 활용하는 개발자가 그렇지 않은 개발자를 대체하게 만드는 기술이다.',
                size=12, bold=False, color=GREY)

    # ========== 15. End ==========
    s = add(T_END)
    for sh in s.shapes:
        if sh.has_text_frame and 'End of Document' in sh.text_frame.text:
            set_runs_text(sh, 'Thank You')

    # Delete original template slides (first ORIG slides)
    for _ in range(ORIG):
        remove_slide(prs, 0)

    prs.save(str(OUT))
    print(f'saved {OUT} ({len(prs.slides)} slides)')


if __name__ == '__main__':
    build_v2()
