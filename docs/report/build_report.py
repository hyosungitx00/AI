# -*- coding: utf-8 -*-
"""통합 운영 모니터링 - 경영진 발표자료(PPTX, 5슬라이드, 디자인 강화).
   비중: Cursor(AI) 활용 효율성 중심 / 정성 위주(추정)."""
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR

KOR   = 'Malgun Gothic'
NAVY  = RGBColor(0x14, 0x2A, 0x54)
BLUE  = RGBColor(0x2E, 0x5B, 0xFF)
SKY   = RGBColor(0xEA, 0xF0, 0xFF)
GOLD  = RGBColor(0xE8, 0xA3, 0x1C)
TEAL  = RGBColor(0x14, 0x9E, 0x8A)
GREY  = RGBColor(0x5A, 0x5A, 0x5A)
DARK  = RGBColor(0x22, 0x28, 0x33)
LINEC = RGBColor(0xDD, 0xE3, 0xEF)
BG    = RGBColor(0xF6, 0xF8, 0xFC)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)
SW, SH = prs.slide_width, prs.slide_height


def _f(run, size=14, bold=False, color=DARK):
    run.font.name = KOR; run.font.size = Pt(size); run.font.bold = bold
    run.font.color.rgb = color


def _noshadow(shp):
    try: shp.shadow.inherit = False
    except Exception: pass


def blank():
    return prs.slides.add_slide(prs.slide_layouts[6])


def bg_fill(slide, color=BG):
    r = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, SW, SH)
    r.fill.solid(); r.fill.fore_color.rgb = color; r.line.fill.background(); _noshadow(r)
    return r


def rect(slide, shp, x, y, w, h, fill=None, line=None, line_w=1.0):
    s = slide.shapes.add_shape(shp, x, y, w, h)
    if fill is None: s.fill.background()
    else: s.fill.solid(); s.fill.fore_color.rgb = fill
    if line is None: s.line.fill.background()
    else: s.line.color.rgb = line; s.line.width = Pt(line_w)
    _noshadow(s)
    return s


def textbox(slide, x, y, w, h, anchor=None):
    tb = slide.shapes.add_textbox(x, y, w, h)
    tf = tb.text_frame; tf.word_wrap = True
    if anchor is not None: tf.vertical_anchor = anchor
    return tf


def para(tf, text, size=14, bold=False, color=DARK, first=False, level=0,
         before=6, align=None):
    p = tf.paragraphs[0] if first else tf.add_paragraph()
    p.level = level; p.space_before = Pt(before)
    if align is not None: p.alignment = align
    r = p.add_run(); r.text = text; _f(r, size, bold, color)
    return p


def header(slide, kicker, title):
    bg_fill(slide)
    tf = textbox(slide, Inches(0.7), Inches(0.45), Inches(12.0), Inches(0.4))
    para(tf, kicker, 13, True, BLUE, first=True, before=0)
    tf2 = textbox(slide, Inches(0.7), Inches(0.8), Inches(12.0), Inches(0.7))
    para(tf2, title, 26, True, NAVY, first=True, before=0)
    rect(slide, MSO_SHAPE.RECTANGLE, Inches(0.72), Inches(1.5), Inches(1.5), Pt(4), fill=GOLD)


def card(slide, x, y, w, h, title, desc, accent=BLUE, num=None,
         title_size=15, desc_size=11.5):
    box = rect(slide, MSO_SHAPE.ROUNDED_RECTANGLE, x, y, w, h, fill=WHITE, line=LINEC, line_w=1)
    rect(slide, MSO_SHAPE.ROUNDED_RECTANGLE, x, y, Inches(0.13), h, fill=accent)
    tf = box.text_frame; tf.word_wrap = True
    tf.margin_left = Inches(0.30); tf.margin_top = Inches(0.16)
    tf.margin_right = Inches(0.18); tf.margin_bottom = Inches(0.12)
    p = tf.paragraphs[0]; p.space_before = Pt(0)
    if num is not None:
        rn = p.add_run(); rn.text = num + '   '; _f(rn, title_size, True, accent)
    rt = p.add_run(); rt.text = title; _f(rt, title_size, True, NAVY)
    if desc:
        for i, d in enumerate(desc if isinstance(desc, list) else [desc]):
            pd = tf.add_paragraph(); pd.space_before = Pt(4)
            rd = pd.add_run(); rd.text = d; _f(rd, desc_size, False, DARK)
    return box


# =====================================================================
# Slide 1 - Title
# =====================================================================
s = blank(); bg_fill(s, WHITE)
rect(s, MSO_SHAPE.RECTANGLE, 0, 0, Inches(0.35), SH, fill=NAVY)
rect(s, MSO_SHAPE.RECTANGLE, Inches(0.35), 0, Inches(0.08), SH, fill=GOLD)
tf = textbox(s, Inches(0.9), Inches(1.5), Inches(11.6), Inches(0.5))
para(tf, 'AI 활용 개발 성과 보고', 15, True, BLUE, first=True, before=0)
tf = textbox(s, Inches(0.9), Inches(2.05), Inches(11.8), Inches(2.2))
para(tf, 'Cursor(AI)로 개발한', 40, True, NAVY, first=True, before=0)
para(tf, '통합 운영 모니터링 대시보드', 40, True, NAVY, before=4)
rect(s, MSO_SHAPE.RECTANGLE, Inches(0.95), Inches(4.15), Inches(2.2), Pt(5), fill=GOLD)
tf = textbox(s, Inches(0.9), Inches(4.4), Inches(11.6), Inches(1.0))
para(tf, 'SM37(배치) · ST22(런타임 덤프) · SXI(인터페이스) 3개 점검을 하나로 통합',
     16, False, GREY, first=True, before=0)
para(tf, 'AI 페어프로그래밍을 통한 설계·구현·검증 생산성 검증', 16, False, GREY, before=4)
# chips
chips = ['통합 대시보드', '읽기 전용(안전)', 'AI 페어프로그래밍']
cx = Inches(0.9)
for c in chips:
    ch = rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, cx, Inches(5.7), Inches(2.7), Inches(0.55),
              fill=SKY)
    ctf = ch.text_frame; ctf.vertical_anchor = MSO_ANCHOR.MIDDLE
    para(ctf, c, 12.5, True, NAVY, first=True, before=0, align=PP_ALIGN.CENTER)
    cx = Emu(cx + Inches(2.9))
tf = textbox(s, Inches(0.9), Inches(6.7), Inches(11.6), Inches(0.4))
para(tf, 'SAP S/4HANA · ABAP  |  개발도구: Cursor(AI)  |  경영진 보고용',
     11, False, GREY, first=True, before=0)

# =====================================================================
# Slide 2 - 개요 (Before/After 구성도)
# =====================================================================
s = blank()
header(s, '01  PROJECT OVERVIEW', '3개 점검 화면을 1개 통합 대시보드로')
# AS-IS
asis = rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.8), Inches(2.15), Inches(4.7), Inches(3.4),
            fill=WHITE, line=LINEC)
tf = asis.text_frame; tf.margin_left = Inches(0.3); tf.margin_top = Inches(0.2); tf.word_wrap = True
para(tf, 'AS-IS  (현행)', 15, True, GREY, first=True, before=0)
para(tf, '매일 3개 트랜잭션을 개별 실행·확인', 12.5, False, DARK, before=8)
para(tf, '•  SM37  배치 잡 에러', 13, False, DARK, before=10)
para(tf, '•  ST22  런타임 덤프', 13, False, DARK, before=6)
para(tf, '•  SXI_MONITOR  인터페이스 에러', 13, False, DARK, before=6)
para(tf, '→ 화면 전환 잦음 · 점검 누락/지연 위험', 12, True, RGBColor(0xC0,0x39,0x2B), before=12)
# arrow
ar = rect(s, MSO_SHAPE.RIGHT_ARROW, Inches(5.7), Inches(3.4), Inches(1.35), Inches(0.95), fill=GOLD)
# TO-BE
tobe = rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, Inches(7.25), Inches(2.15), Inches(5.25), Inches(3.4),
            fill=NAVY)
tf = tobe.text_frame; tf.margin_left = Inches(0.3); tf.margin_top = Inches(0.2); tf.word_wrap = True
para(tf, 'TO-BE  (개선)', 15, True, GOLD, first=True, before=0)
para(tf, '단일 트랜잭션 통합 대시보드 (읽기 전용)', 13, True, WHITE, before=8)
para(tf, '•  상단 : 영역별 신호등 + 건수 요약', 12.5, False, WHITE, before=10)
para(tf, '•  중간 : 영역별 에러 집중도 차트', 12.5, False, WHITE, before=6)
para(tf, '•  하단 : 상세 목록 + 더블클릭 상세 이동', 12.5, False, WHITE, before=6)
para(tf, '→ 한눈에 파악 · 점검시간 단축 · 누락 방지', 12, True, RGBColor(0xFF,0xD9,0x7A), before=12)
# bottom note
nb = rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.8), Inches(5.75), Inches(11.7), Inches(1.15),
          fill=SKY)
tf = nb.text_frame; tf.margin_left = Inches(0.3); tf.vertical_anchor = MSO_ANCHOR.MIDDLE; tf.word_wrap = True
para(tf, '본 보고의 초점', 13, True, BLUE, first=True, before=0)
para(tf, '개발 결과물 자체보다, 개발 전 과정(설계·구현·검증)에 AI(Cursor)를 활용해 얻은 생산성·품질 효과에 있습니다.',
     13, False, DARK, before=4)

# =====================================================================
# Slide 3 - Cursor 활용 (HERO, 카드 그리드)
# =====================================================================
s = blank()
header(s, '02  HOW WE USED AI (CURSOR)', 'AI(Cursor)를 개발 전 과정에 활용')
cw, ch = Inches(3.78), Inches(1.95)
gx, gy = Inches(0.7), Inches(1.95)
gapx, gapy = Inches(0.30), Inches(0.28)
x2 = Emu(gx + cw + gapx); x3 = Emu(x2 + cw + gapx)
row2y = Emu(gy + ch + gapy)
card(s, gx, gy, cw, ch, '설계 문서 자동화',
     ['설계서 작성·개정과 결정/미결과제', '이력 관리를 대화로 진행'], BLUE, '①')
card(s, x2, gy, cw, ch, '자료 분석 자동화',
     ['권한 추적(STAUTHTRACE) 엑셀을', '직접 분석 → 필요 권한 자동 도출'], TEAL, '②')
card(s, x3, gy, cw, ch, '표준 기능 조사 자동화',
     ['SAP 표준 기능·사용법을 즉시', '조사·확인(수작업 탐색 대체)'], GOLD, '③')
card(s, gx, row2y, cw, ch, '개발–검증 반복 루프',
     ['코드 생성 → 오류 진단 → 즉시', '수정을 빠르게 반복'], BLUE, '④')
card(s, x2, row2y, cw, ch, '표준·규칙 자동 준수',
     ['“읽기 전용”·명명규칙 등 사내', '표준을 규칙으로 상시 적용'], TEAL, '⑤')
# takeaway box (3rd col row2)
tk = rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, x3, row2y, cw, ch, fill=NAVY)
tf = tk.text_frame; tf.margin_left = Inches(0.28); tf.vertical_anchor = MSO_ANCHOR.MIDDLE; tf.word_wrap = True
para(tf, 'AI가 “조사–초안–수정”을', 13.5, True, WHITE, first=True, before=0)
para(tf, '대신하고, 개발자는 검토·의사결정에 집중', 13.5, True, GOLD, before=4)

# =====================================================================
# Slide 4 - AI 규칙·스킬(.md) 표준화
# =====================================================================
s = blank()
header(s, '03  STANDARDS AS CODE (RULES / SKILLS)', 'AI 규칙·스킬(.md)로 개발 표준 내재화')
# left card - 상시 규칙(Rules)
lc = rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.7), Inches(1.95), Inches(5.85), Inches(3.15),
          fill=WHITE, line=LINEC)
rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.7), Inches(1.95), Inches(5.85), Inches(0.62), fill=NAVY)
ttf = textbox(s, Inches(0.7), Inches(1.95), Inches(5.85), Inches(0.62), anchor=MSO_ANCHOR.MIDDLE)
para(ttf, '상시 규칙  Rules  ·  항상 자동 적용', 14, True, WHITE, first=True, before=0, align=PP_ALIGN.CENTER)
tf = lc.text_frame; tf.margin_left = Inches(0.3); tf.margin_top = Inches(0.8); tf.word_wrap = True
para(tf, '.cursor/rules/abap-project-conventions', 12, True, BLUE, first=True, before=6)
para(tf, '•  읽기 전용(변경·COMMIT·LOCK 금지) 불변식', 12, False, DARK, before=8)
para(tf, '•  SAP 표준 테이블/FM 만 사용', 12, False, DARK, before=6)
para(tf, '•  명명규칙 · 인터페이스 기반 OO 구조', 12, False, DARK, before=6)
para(tf, '→ 매 작업마다 자동 준수(재지시 불필요)', 12, True, TEAL, before=8)
# right card - 온디맨드 스킬(Skills)
rcx = Inches(6.75)
rc = rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, rcx, Inches(1.95), Inches(5.85), Inches(3.15),
          fill=WHITE, line=LINEC)
rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, rcx, Inches(1.95), Inches(5.85), Inches(0.62), fill=GOLD)
ttf = textbox(s, rcx, Inches(1.95), Inches(5.85), Inches(0.62), anchor=MSO_ANCHOR.MIDDLE)
para(ttf, '온디맨드 스킬  Skills  ·  필요 시 호출', 14, True, WHITE, first=True, before=0, align=PP_ALIGN.CENTER)
tf = rc.text_frame; tf.margin_left = Inches(0.3); tf.margin_top = Inches(0.8); tf.word_wrap = True
para(tf, '.cursor/skills  (작업 유형별 검증 플레이북)', 12, True, GOLD, first=True, before=6)
para(tf, '•  읽기전용 모니터링 · 클린 OO ABAP', 12, False, DARK, before=8)
para(tf, '•  코드리뷰 · 성능 튜닝 · 체계적 디버깅', 12, False, DARK, before=6)
para(tf, '•  설계서 작성 · 커밋 메시지 · PR 작성', 12, False, DARK, before=6)
para(tf, '→ 검증된 절차 재사용(품질 균일화)', 12, True, TEAL, before=8)
# bottom banner - 효율 효과
eb = rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.7), Inches(5.4), Inches(11.9), Inches(1.35),
          fill=SKY)
tf = eb.text_frame; tf.margin_left = Inches(0.35); tf.margin_top = Inches(0.18); tf.word_wrap = True
para(tf, 'md 파일 활용 효율 효과', 13.5, True, BLUE, first=True, before=0)
para(tf, '표준을 매번 설명할 필요 없이 일관 적용 → 재작업·휴먼에러 감소 · 리뷰/문서 품질 균일화 · 신규 인력 온보딩 가속.',
     13, False, DARK, before=6)
para(tf, '규칙/스킬을 코드처럼 버전관리(.md) → 팀 전체가 동일 기준으로 재사용·개선.',
     11.5, False, GREY, before=5)

# =====================================================================
# Slide 5 - 효율성 · 성과
# =====================================================================
s = blank()
header(s, '04  EFFICIENCY & OUTCOME', '효율성 · 성과 (정성 위주 · 추정)')
bw = Inches(3.78)
bx1 = Inches(0.7); bx2 = Emu(bx1 + bw + Inches(0.30)); bx3 = Emu(bx2 + bw + Inches(0.30))
by = Inches(1.95); bh = Inches(2.35)
def kpi(x, title, lines, accent):
    b = rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, x, by, bw, bh, fill=WHITE, line=LINEC)
    rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, x, by, bw, Inches(0.62), fill=accent)
    ttf = textbox(s, x, by, bw, Inches(0.62), anchor=MSO_ANCHOR.MIDDLE)
    para(ttf, title, 14.5, True, WHITE, first=True, before=0, align=PP_ALIGN.CENTER)
    tf = b.text_frame; tf.margin_left = Inches(0.26); tf.margin_top = Inches(0.85); tf.word_wrap = True
    first = True
    for ln in lines:
        para(tf, '•  ' + ln, 12, False, DARK, first=first, before=8); first = False
kpi(bx1, '개발 생산성', ['설계–구현–검토를 한 흐름으로 진행(맥락 유지)',
                        '요구 변경 즉시 반영 → 완성도 조기 확보'], BLUE)
kpi(bx2, '리서치 부담 감소', ['표준 기능/사용법 조사를 대화로 즉시 해결',
                           '문서 탐색 시간 절감'], TEAL)
kpi(bx3, '품질 · 표준 준수', ['사내 표준의 일관 적용',
                           '휴먼 에러 · 재작업 감소'], GOLD)
# estimate band
eb = rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.7), Inches(4.6), Inches(11.93), Inches(1.7),
          fill=SKY)
tf = eb.text_frame; tf.margin_left = Inches(0.35); tf.margin_top = Inches(0.2); tf.word_wrap = True
para(tf, '효과 규모 (추정)', 14, True, BLUE, first=True, before=0)
para(tf, '설계 문서화 · 표준 API 조사 · 오류 수정 사이클 시간이 수작업 대비 크게 단축된 것으로 추정됩니다.',
     13, False, DARK, before=6)
para(tf, '※ 정량 수치는 향후 개발 소요시간 전/후 비교로 실측하여 보완 예정',
     11.5, False, GREY, before=6)

# =====================================================================
# Slide 6 - 기대효과 & 향후계획
# =====================================================================
s = blank()
header(s, '05  IMPACT & NEXT STEPS', '기대 효과 및 향후 계획')
lc = rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.7), Inches(1.95), Inches(5.85), Inches(3.2),
          fill=WHITE, line=LINEC)
rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.7), Inches(1.95), Inches(5.85), Inches(0.62), fill=NAVY)
ttf = textbox(s, Inches(0.7), Inches(1.95), Inches(5.85), Inches(0.62), anchor=MSO_ANCHOR.MIDDLE)
para(ttf, '기대 효과', 15, True, WHITE, first=True, before=0, align=PP_ALIGN.CENTER)
tf = lc.text_frame; tf.margin_left = Inches(0.3); tf.margin_top = Inches(0.85); tf.word_wrap = True
para(tf, '•  운영 점검 시간 단축 · 점검 누락 방지', 13, False, DARK, first=True, before=8)
para(tf, '•  읽기 전용 설계로 운영 안전성 확보', 13, False, DARK, before=10)
para(tf, '•  AI 페어프로그래밍의 사내 개발', 13, False, DARK, before=10)
para(tf, '    생산성 향상 가능성 확인', 13, False, DARK, before=2)

rcx = Inches(6.75)
rc = rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, rcx, Inches(1.95), Inches(5.85), Inches(3.2),
          fill=WHITE, line=LINEC)
rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, rcx, Inches(1.95), Inches(5.85), Inches(0.62), fill=GOLD)
ttf = textbox(s, rcx, Inches(1.95), Inches(5.85), Inches(0.62), anchor=MSO_ANCHOR.MIDDLE)
para(ttf, '향후 계획', 15, True, WHITE, first=True, before=0, align=PP_ALIGN.CENTER)
tf = rc.text_frame; tf.margin_left = Inches(0.3); tf.margin_top = Inches(0.85); tf.word_wrap = True
para(tf, '•  검증본 정식 오브젝트화 및 기능 고도화', 13, False, DARK, first=True, before=8)
para(tf, '•  정량 효과 실측(개발 소요시간 전/후 비교)', 13, False, DARK, before=10)
para(tf, '•  타 개발 과제로 AI 활용 확대 적용 검토', 13, False, DARK, before=10)

msg = rect(s, MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.7), Inches(5.5), Inches(11.9), Inches(1.15),
           fill=NAVY)
tf = msg.text_frame; tf.vertical_anchor = MSO_ANCHOR.MIDDLE; tf.margin_left = Inches(0.35); tf.word_wrap = True
para(tf, '핵심 메시지', 12.5, True, GOLD, first=True, before=0)
para(tf, '운영 점검의 통합·자동화 + AI 페어프로그래밍으로 개발 생산성을 높였습니다.',
     15, True, WHITE, before=3)

prs.save('docs/report/Y_OPS_MONITOR_V2_발표자료.pptx')
print('saved pptx (6 slides, designed)')
