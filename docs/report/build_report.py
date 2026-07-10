# -*- coding: utf-8 -*-
"""
AI 활용 효율성 · 향후 방향 — 사내 발표자료 (PPTX)
대상: 상무님 포함 동료 | 약 10분 | 8슬라이드
메인: AI를 어떻게 써야 효율적인가 / 우리는 어디로 가야 하는가
사례: 통합 운영 모니터링(부차)
"""
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.oxml.ns import qn

KOR = 'Malgun Gothic'
# Deep charcoal / steel — executive, not "startup purple"
NIGHT = RGBColor(0x0B, 0x12, 0x20)
INK   = RGBColor(0x1C, 0x24, 0x33)
STEEL = RGBColor(0x2C, 0x3E, 0x50)
BLUE  = RGBColor(0x1A, 0x56, 0x8A)
TEAL  = RGBColor(0x1A, 0x7A, 0x6A)
GOLD  = RGBColor(0xB8, 0x8A, 0x2E)
SLATE = RGBColor(0x5A, 0x66, 0x78)
MUTED = RGBColor(0x8B, 0x95, 0xA5)
LINE  = RGBColor(0xE2, 0xE6, 0xED)
PAPER = RGBColor(0xF7, 0xF8, 0xFA)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)
SW, SH = prs.slide_width, prs.slide_height


def _f(run, size=14, bold=False, color=INK):
    run.font.name = KOR
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.color.rgb = color
    try:
        rPr = run._r.get_or_add_rPr()
        rFonts = rPr.get_or_add_rFonts()
        rFonts.set(qn('w:eastAsia'), KOR)
    except Exception:
        pass


def _ns(shp):
    try:
        shp.shadow.inherit = False
    except Exception:
        pass


def blank():
    return prs.slides.add_slide(prs.slide_layouts[6])


def rect(slide, x, y, w, h, fill=None, line=None, lw=1.0, rounded=False):
    kind = MSO_SHAPE.ROUNDED_RECTANGLE if rounded else MSO_SHAPE.RECTANGLE
    s = slide.shapes.add_shape(kind, x, y, w, h)
    if fill is None:
        s.fill.background()
    else:
        s.fill.solid()
        s.fill.fore_color.rgb = fill
    if line is None:
        s.line.fill.background()
    else:
        s.line.color.rgb = line
        s.line.width = Pt(lw)
    _ns(s)
    return s


def bg(slide, color=PAPER):
    return rect(slide, 0, 0, SW, SH, fill=color)


def tb(slide, x, y, w, h, anchor=None):
    box = slide.shapes.add_textbox(x, y, w, h)
    tf = box.text_frame
    tf.word_wrap = True
    if anchor is not None:
        tf.vertical_anchor = anchor
    return tf


def P(tf, text, size=14, bold=False, color=INK, first=False,
      before=0, align=None):
    p = tf.paragraphs[0] if first else tf.add_paragraph()
    p.space_before = Pt(before)
    p.space_after = Pt(0)
    if align is not None:
        p.alignment = align
    r = p.add_run()
    r.text = text
    _f(r, size, bold, color)
    return p


def notes(slide, text):
    slide.notes_slide.notes_text_frame.text = text


def footer(slide, page, total=8):
    rect(slide, 0, Inches(7.2), SW, Inches(0.3), fill=NIGHT)
    tf = tb(slide, Inches(0.65), Inches(7.22), Inches(9), Inches(0.26),
            anchor=MSO_ANCHOR.MIDDLE)
    P(tf, 'AI 활용 효율성  ·  향후 방향', 9, False, MUTED, first=True)
    tf = tb(slide, Inches(11.3), Inches(7.22), Inches(1.4), Inches(0.26),
            anchor=MSO_ANCHOR.MIDDLE)
    P(tf, f'{page}  /  {total}', 9, False, MUTED, first=True,
      align=PP_ALIGN.RIGHT)


def header(slide, eyebrow, title, subtitle=None):
    """Clean content header — no amateur section numbers in the title."""
    bg(slide, PAPER)
    rect(slide, 0, 0, SW, Inches(0.06), fill=NIGHT)
    tf = tb(slide, Inches(0.65), Inches(0.35), Inches(12), Inches(0.28))
    P(tf, eyebrow.upper(), 10, True, BLUE, first=True)
    tf = tb(slide, Inches(0.65), Inches(0.65), Inches(12), Inches(0.55))
    P(tf, title, 26, True, NIGHT, first=True)
    if subtitle:
        tf = tb(slide, Inches(0.65), Inches(1.2), Inches(12), Inches(0.35))
        P(tf, subtitle, 13, False, SLATE, first=True)
    rect(slide, Inches(0.65), Inches(1.55) if subtitle else Inches(1.25),
         Inches(0.9), Pt(3), fill=GOLD)


# =====================================================================
# 1. Title
# =====================================================================
s = blank()
bg(s, NIGHT)
# left accent
rect(s, 0, 0, Inches(0.18), SH, fill=GOLD)

tf = tb(s, Inches(0.9), Inches(1.8), Inches(11.5), Inches(0.35))
P(tf, 'INTERNAL BRIEFING', 11, True, GOLD, first=True)

tf = tb(s, Inches(0.9), Inches(2.3), Inches(11.8), Inches(1.5))
P(tf, 'AI를 쓰는 것과', 34, True, WHITE, first=True)
P(tf, 'AI를 잘 쓰는 것은 다릅니다', 34, True, WHITE, before=8)

tf = tb(s, Inches(0.9), Inches(4.1), Inches(11.5), Inches(0.8))
P(tf, '개발 업무에서의 AI 활용 효율과, 조직이 가져가야 할 방향',
  16, False, MUTED, first=True)
P(tf, '사례: SAP 통합 운영 모니터링 개발 (Cursor 적용)',
  14, False, SLATE, before=8)

# bottom meta strip
rect(s, 0, Inches(6.35), SW, Inches(1.15), fill=RGBColor(0x12, 0x1C, 0x2E))
metas = [
    ('Audience', '상무님 포함 동료'),
    ('Duration', '약 10분'),
    ('Focus', '효율 · 방향'),
    ('Tool', 'Cursor'),
]
mx = Inches(0.9)
for lab, val in metas:
    tf = tb(s, mx, Inches(6.5), Inches(2.8), Inches(0.8))
    P(tf, lab, 9, True, GOLD, first=True)
    P(tf, val, 13, False, WHITE, before=4)
    mx = Emu(mx + Inches(3.05))

notes(s,
      '【0:00–0:45】\n'
      '인사 후 한 문장으로 프레임을 고정합니다.\n'
      '“오늘은 프로그램 기능 설명이 아닙니다. '
      'AI를 어떻게 써야 일이 빨라지고 품질이 유지되는지, '
      '그리고 우리가 어떤 방향으로 가야 하는지를 말씀드리겠습니다.”')


# =====================================================================
# 2. 오늘 논의의 축
# =====================================================================
s = blank()
header(s, 'Frame', '오늘 논의의 두 가지 질문',
       '프로그램 소개가 아니라, 일하는 방식에 대한 이야기입니다')
footer(s, 2)

questions = [
    ('01', '효율',
     'AI를 어디에, 어떻게 붙일 때\n실제 생산성이 올라가는가',
     '조사 · 초안 · 반복 수정 · 표준 적용'),
    ('02', '방향',
     '개인 역량에 맡기지 않고\n조직 역량으로 남기려면 무엇이 필요한가',
     '규칙 · 스킬 · 재사용 · 측정'),
]
qx = Inches(0.65)
for num, tag, q, hint in questions:
    box = rect(s, qx, Inches(2.1), Inches(5.9), Inches(4.2),
               fill=WHITE, line=LINE, rounded=True)
    tf = tb(s, Emu(qx + Inches(0.4)), Inches(2.4), Inches(5.1), Inches(0.35))
    P(tf, f'{num}   {tag}', 12, True, BLUE, first=True)
    tf = tb(s, Emu(qx + Inches(0.4)), Inches(3.0), Inches(5.1), Inches(1.6))
    for i, line in enumerate(q.split('\n')):
        P(tf, line, 20, True, NIGHT, first=(i == 0), before=(0 if i == 0 else 6))
    tf = tb(s, Emu(qx + Inches(0.4)), Inches(5.2), Inches(5.1), Inches(0.6))
    P(tf, hint, 12, False, SLATE, first=True)
    qx = Emu(qx + Inches(6.15))

notes(s,
      '【0:45–1:30】\n'
      '두 질문만 남기고 넘어갑니다. '
      '“기능 데모는 필요하시면 별도로 드리겠습니다.”')


# =====================================================================
# 3. 관찰 — AI를 써도 효율이 안 나는 패턴
# =====================================================================
s = blank()
header(s, 'Observation', 'AI를 도입해도 효율이 안 나는 경우',
       '도구 문제가 아니라, 사용 방식의 문제입니다')
footer(s, 3)

rows = [
    ('매번 다른 지시', '같은 표준을 대화마다 다시 설명 → 결과 편차 발생'),
    ('조사 없는 생성', '근거 없이 코드만 생성 → 검증·재작업 비용 증가'),
    ('개인 의존', '잘하는 사람만 잘 씀 → 조직 전체 생산성으로 전이되지 않음'),
    ('결과물 중심 평가', '산출물 유무만 보고, 재사용·표준화는 남지 않음'),
]
y = Inches(2.0)
for title, desc in rows:
    rect(s, Inches(0.65), y, Inches(12.0), Inches(1.05),
         fill=WHITE, line=LINE, rounded=True)
    rect(s, Inches(0.65), y, Inches(0.12), Inches(1.05), fill=GOLD)
    tf = tb(s, Inches(1.1), Emu(y + Inches(0.18)), Inches(11), Inches(0.35))
    P(tf, title, 15, True, NIGHT, first=True)
    tf = tb(s, Inches(1.1), Emu(y + Inches(0.52)), Inches(11), Inches(0.35))
    P(tf, desc, 13, False, SLATE, first=True)
    y = Emu(y + Inches(1.2))

notes(s,
      '【1:30–2:40】\n'
      '비판이 아니라 공통 함정입니다. '
      '“우리는 이 네 가지를 피하기 위해 규칙을 먼저 고정했습니다.”')


# =====================================================================
# 4. 원칙 — 효율이 나는 사용법
# =====================================================================
s = blank()
header(s, 'Principle', '효율이 나는 AI 활용의 세 가지 조건',
       '프롬프트 요령이 아니라, 일하는 구조입니다')
footer(s, 4)

principles = [
    ('범위 고정',
     'AI가 해도 되는 일과\n사람이 해야 하는 일을 나눕니다',
     '조사·초안·반복 수정 → AI\n판단·책임·운영 확정 → 사람'),
    ('표준 선반영',
     '매번 지시하지 않도록\n규칙을 저장소에 둡니다',
     'Rules: 상시 자동 적용\nSkills: 작업별 절차 재사용'),
    ('검증 루프',
     '생성으로 끝내지 않고\n진단–수정–확인을 짧게 돕니다',
     '오류·권한·성능 이슈를\n같은 맥락에서 즉시 처리'),
]
px = Inches(0.65)
for title, lead, detail in principles:
    rect(s, px, Inches(2.0), Inches(3.95), Inches(4.5),
         fill=WHITE, line=LINE, rounded=True)
    rect(s, px, Inches(2.0), Inches(3.95), Inches(0.1), fill=BLUE)
    tf = tb(s, Emu(px + Inches(0.35)), Inches(2.25), Inches(3.4), Inches(0.4))
    P(tf, title, 16, True, BLUE, first=True)
    tf = tb(s, Emu(px + Inches(0.35)), Inches(2.85), Inches(3.4), Inches(1.3))
    for i, line in enumerate(lead.split('\n')):
        P(tf, line, 15, True, NIGHT, first=(i == 0), before=(0 if i == 0 else 4))
    tf = tb(s, Emu(px + Inches(0.35)), Inches(4.5), Inches(3.4), Inches(1.5))
    for i, line in enumerate(detail.split('\n')):
        P(tf, line, 12, False, SLATE, first=(i == 0), before=(0 if i == 0 else 4))
    px = Emu(px + Inches(4.15))

notes(s,
      '【2:40–4:10】 핵심 슬라이드.\n'
      '“효율의 본질은 모델 성능이 아니라, '
      '범위·표준·검증이 고정되어 있는 구조입니다.”')


# =====================================================================
# 5. 사례 — 짧게 (증거)
# =====================================================================
s = blank()
header(s, 'Case', '적용 사례로 확인한 것',
       'SAP 통합 운영 모니터링 — 목적물이 아니라 검증 무대')
footer(s, 5)

# left narrative
rect(s, Inches(0.65), Inches(2.0), Inches(6.2), Inches(4.5),
     fill=WHITE, line=LINE, rounded=True)
tf = tb(s, Inches(1.0), Inches(2.25), Inches(5.5), Inches(0.35))
P(tf, '한 과제로 전 과정을 관통', 14, True, BLUE, first=True)
steps = [
    ('설계', '설계서·결정사항 이력을 대화로 유지'),
    ('분석', '권한 추적 자료를 AI가 읽어 필요 권한 도출'),
    ('구현', '생성–오류진단–수정을 짧은 사이클로 반복'),
    ('표준', '읽기전용·명명·구조를 Rules로 상시 강제'),
]
yy = Inches(2.8)
for k, v in steps:
    tf = tb(s, Inches(1.0), yy, Inches(1.2), Inches(0.35))
    P(tf, k, 13, True, NIGHT, first=True)
    tf = tb(s, Inches(2.3), yy, Inches(4.2), Inches(0.35))
    P(tf, v, 13, False, SLATE, first=True)
    yy = Emu(yy + Inches(0.7))

# right callout
rect(s, Inches(7.15), Inches(2.0), Inches(5.5), Inches(4.5), fill=NIGHT, rounded=True)
tf = tb(s, Inches(7.55), Inches(2.4), Inches(4.7), Inches(0.4))
P(tf, '이 사례에서 얻은 결론', 12, True, GOLD, first=True)
points = [
    'AI는 “대신 코딩하는 도구”가 아니라\n“조사–초안–수정의 가속기”로 쓸 때 효과가 큼',
    '표준을 .md로 고정하지 않으면\n같은 실수를 세션마다 반복함',
    '사람은 판단과 검증에 집중할수록\n전체 리드타임이 줄어듦',
]
yy = Inches(3.1)
for pt in points:
    lines = pt.split('\n')
    tf = tb(s, Inches(7.55), yy, Inches(4.7), Inches(1.0))
    for i, line in enumerate(lines):
        P(tf, line, 13, False, WHITE, first=(i == 0), before=(0 if i == 0 else 3))
    yy = Emu(yy + Inches(1.05))

notes(s,
      '【4:10–5:30】\n'
      '프로그램 기능을 길게 설명하지 않습니다. '
      '“사례는 증거일 뿐, 메시지는 사용 구조입니다.”')


# =====================================================================
# 6. 효율의 실체 — Rules / Skills
# =====================================================================
s = blank()
header(s, 'Mechanism', '효율을 재현 가능하게 만드는 장치',
       '개인 프롬프트 → 조직 자산으로')
footer(s, 6)

# two columns
rect(s, Inches(0.65), Inches(2.0), Inches(5.9), Inches(3.35),
     fill=WHITE, line=LINE, rounded=True)
tf = tb(s, Inches(1.0), Inches(2.25), Inches(5.2), Inches(0.35))
P(tf, 'Rules  —  항상 켜져 있는 기준', 15, True, NIGHT, first=True)
tf = tb(s, Inches(1.0), Inches(2.85), Inches(5.2), Inches(2.2))
for i, t in enumerate([
    '읽기 전용, 표준 객체만 사용 등 불변식',
    '매 대화마다 다시 설명하지 않음',
    '위반을 사전에 차단 → 재작업 감소',
]):
    P(tf, '–  ' + t, 13, False, SLATE, first=(i == 0), before=(0 if i == 0 else 10))

rect(s, Inches(6.8), Inches(2.0), Inches(5.9), Inches(3.35),
     fill=WHITE, line=LINE, rounded=True)
tf = tb(s, Inches(7.15), Inches(2.25), Inches(5.2), Inches(0.35))
P(tf, 'Skills  —  필요할 때 꺼내는 절차', 15, True, NIGHT, first=True)
tf = tb(s, Inches(7.15), Inches(2.85), Inches(5.2), Inches(2.2))
for i, t in enumerate([
    '구현 · 리뷰 · 성능 · 디버깅 · 문서/PR',
    '검증된 순서를 그대로 재실행',
    '담당자·세션이 바뀌어도 품질 편차 축소',
]):
    P(tf, '–  ' + t, 13, False, SLATE, first=(i == 0), before=(0 if i == 0 else 10))

# bottom insight
rect(s, Inches(0.65), Inches(5.55), Inches(12.05), Inches(1.2), fill=NIGHT, rounded=True)
tf = tb(s, Inches(1.0), Inches(5.75), Inches(11.3), Inches(0.85),
        anchor=MSO_ANCHOR.MIDDLE)
P(tf, '핵심', 11, True, GOLD, first=True)
P(tf, 'AI 효율은 “누가 더 잘 물어보느냐”가 아니라, '
      '“조직이 무엇을 규칙으로 고정해 두었느냐”에서 갈립니다.',
  15, True, WHITE, before=6)

notes(s,
      '【5:30–7:00】\n'
      '상무님께 가장 전달하고 싶은 슬라이드. '
      '“도구 도입만으로는 부족하고, 규칙 자산화가 필요합니다.”')


# =====================================================================
# 7. 방향 — 우리가 가야 할 곳
# =====================================================================
s = blank()
header(s, 'Direction', '앞으로 가져가야 할 방향',
       '도입 여부를 넘어, 운영 방식으로')
footer(s, 7)

dirs = [
    ('단기', '검증된 과제에 AI+Rules를 기본 세트로 적용',
     '새 과제 착수 시 규칙/스킬을 함께 준비'),
    ('중기', '팀 공통 Rules를 자산으로 관리',
     '영역별 Skills를 축적하고 리뷰 기준으로 사용'),
    ('측정', '체감이 아닌 전/후 소요시간으로 확인',
     '동일 난이도 과제 기준의 리드타임 비교'),
    ('확산', '개인 성공 사례를 조직 가이드로 전환',
     '잘한 프롬프트가 아니라, 재사용 가능한 절차를 공유'),
]
y = Inches(2.0)
for tag, title, desc in dirs:
    rect(s, Inches(0.65), y, Inches(12.0), Inches(1.1),
         fill=WHITE, line=LINE, rounded=True)
    rect(s, Inches(0.65), y, Inches(1.35), Inches(1.1), fill=NIGHT)
    tf = tb(s, Inches(0.65), y, Inches(1.35), Inches(1.1),
            anchor=MSO_ANCHOR.MIDDLE)
    P(tf, tag, 13, True, WHITE, first=True, align=PP_ALIGN.CENTER)
    tf = tb(s, Inches(2.25), Emu(y + Inches(0.2)), Inches(10), Inches(0.35))
    P(tf, title, 15, True, NIGHT, first=True)
    tf = tb(s, Inches(2.25), Emu(y + Inches(0.55)), Inches(10), Inches(0.35))
    P(tf, desc, 12, False, SLATE, first=True)
    y = Emu(y + Inches(1.2))

notes(s,
      '【7:00–8:40】\n'
      '방향은 네 줄로만. '
      '“다음 과제는 기능이 아니라, 이 네 가지를 조직 습관으로 만드는 일입니다.”')


# =====================================================================
# 8. Closing
# =====================================================================
s = blank()
bg(s, NIGHT)
rect(s, 0, 0, Inches(0.18), SH, fill=GOLD)

tf = tb(s, Inches(0.9), Inches(1.6), Inches(11.5), Inches(0.35))
P(tf, 'TAKEAWAY', 11, True, GOLD, first=True)

tf = tb(s, Inches(0.9), Inches(2.15), Inches(11.8), Inches(1.8))
P(tf, 'AI는 도입하는 순간이 아니라', 28, True, WHITE, first=True)
P(tf, '쓰는 구조를 만들 때 효율이 납니다', 28, True, WHITE, before=8)

tf = tb(s, Inches(0.9), Inches(4.3), Inches(11.5), Inches(1.2))
P(tf, '우리가 할 일:  범위 고정  ·  표준(.md) 자산화  ·  검증 루프  ·  전/후 측정',
  15, False, MUTED, first=True)
P(tf, '사례는 이미 한 번 확인했습니다. 다음은 조직 습관으로 옮기는 단계입니다.',
  14, False, SLATE, before=10)

rect(s, Inches(0.9), Inches(5.9), Inches(2.0), Pt(3), fill=GOLD)
tf = tb(s, Inches(0.9), Inches(6.2), Inches(11.5), Inches(0.4))
P(tf, '질의응답', 14, True, WHITE, first=True)

notes(s,
      '【8:40–10:00】\n'
      '핵심 메시지 한 번 반복 후 Q&A.\n'
      '예상 질문: 보안/데이터, 정량 수치, 적용 범위, 교육 방식.')

OUT = 'docs/report/Y_OPS_MONITOR_V2_발표자료.pptx'
prs.save(OUT)
print(f'saved {OUT} ({len(prs.slides)} slides)')
