# -*- coding: utf-8 -*-
"""
통합 운영 모니터링 — 경영진/동료 대상 발표자료 (PPTX)
대상: 상무님 포함 사내 동료 | 발표 시간: 약 10분 | 슬라이드: 8장
초점: Cursor(AI) 활용을 통한 개발 생산성·품질 표준화 효과 (정성 위주)
"""
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.oxml.ns import qn

# ── Palette (corporate, restrained) ──────────────────────────────
KOR   = 'Malgun Gothic'
NAVY  = RGBColor(0x0F, 0x1F, 0x3D)
INK   = RGBColor(0x1A, 0x23, 0x32)
BLUE  = RGBColor(0x1E, 0x4D, 0x8C)
ACCENT = RGBColor(0xC4, 0x8A, 0x1A)   # muted gold
TEAL  = RGBColor(0x0E, 0x7C, 0x6B)
SLATE = RGBColor(0x5B, 0x67, 0x7A)
MUTED = RGBColor(0x8A, 0x93, 0xA6)
LINE  = RGBColor(0xD8, 0xDE, 0xE9)
SOFT  = RGBColor(0xF3, 0xF5, 0xF9)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
RED   = RGBColor(0xA6, 0x33, 0x2A)

prs = Presentation()
prs.slide_width  = Inches(13.333)
prs.slide_height = Inches(7.5)
SW, SH = prs.slide_width, prs.slide_height


# ── Helpers ──────────────────────────────────────────────────────
def _font(run, size=14, bold=False, color=INK):
    run.font.name = KOR
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.color.rgb = color
    # East-Asian font hint
    try:
        rPr = run._r.get_or_add_rPr()
        rFonts = rPr.get_or_add_rFonts()
        rFonts.set(qn('w:eastAsia'), KOR)
    except Exception:
        pass


def _noshadow(shp):
    try:
        shp.shadow.inherit = False
    except Exception:
        pass


def blank():
    return prs.slides.add_slide(prs.slide_layouts[6])


def fill_bg(slide, color=SOFT):
    s = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, SW, SH)
    s.fill.solid(); s.fill.fore_color.rgb = color
    s.line.fill.background(); _noshadow(s)
    return s


def shape(slide, kind, x, y, w, h, fill=None, line=None, lw=1.0):
    s = slide.shapes.add_shape(kind, x, y, w, h)
    if fill is None:
        s.fill.background()
    else:
        s.fill.solid(); s.fill.fore_color.rgb = fill
    if line is None:
        s.line.fill.background()
    else:
        s.line.color.rgb = line; s.line.width = Pt(lw)
    _noshadow(s)
    return s


def tb(slide, x, y, w, h, anchor=None):
    box = slide.shapes.add_textbox(x, y, w, h)
    tf = box.text_frame
    tf.word_wrap = True
    if anchor is not None:
        tf.vertical_anchor = anchor
    return tf


def P(tf, text, size=14, bold=False, color=INK, first=False,
      before=4, after=0, align=None, level=0):
    p = tf.paragraphs[0] if first else tf.add_paragraph()
    p.level = level
    p.space_before = Pt(before)
    p.space_after = Pt(after)
    if align is not None:
        p.alignment = align
    r = p.add_run(); r.text = text; _font(r, size, bold, color)
    return p


def notes(slide, text):
    """Speaker notes for ~10-min pacing."""
    ns = slide.notes_slide.notes_text_frame
    ns.text = text


def page_chrome(slide, section, title, page, total=8):
    """Standard content-slide header + footer."""
    fill_bg(slide, SOFT)
    # top navy bar
    shape(slide, MSO_SHAPE.RECTANGLE, 0, 0, SW, Inches(0.08), fill=NAVY)
    # section label
    tf = tb(slide, Inches(0.7), Inches(0.28), Inches(10), Inches(0.32))
    P(tf, section, 11, True, BLUE, first=True, before=0)
    # title
    tf = tb(slide, Inches(0.7), Inches(0.55), Inches(11.5), Inches(0.55))
    P(tf, title, 24, True, NAVY, first=True, before=0)
    # gold underline
    shape(slide, MSO_SHAPE.RECTANGLE, Inches(0.72), Inches(1.15),
          Inches(1.2), Pt(3.5), fill=ACCENT)
    # footer
    shape(slide, MSO_SHAPE.RECTANGLE, 0, Inches(7.15), SW, Inches(0.35), fill=NAVY)
    tf = tb(slide, Inches(0.7), Inches(7.18), Inches(9), Inches(0.28),
            anchor=MSO_ANCHOR.MIDDLE)
    P(tf, '통합 운영 모니터링  ·  AI 활용 개발 성과 보고', 9, False, WHITE,
      first=True, before=0)
    tf = tb(slide, Inches(11.2), Inches(7.18), Inches(1.5), Inches(0.28),
            anchor=MSO_ANCHOR.MIDDLE)
    P(tf, f'{page} / {total}', 9, False, WHITE, first=True, before=0,
      align=PP_ALIGN.RIGHT)


def card(slide, x, y, w, h, fill=WHITE, line=LINE):
    return shape(slide, MSO_SHAPE.ROUNDED_RECTANGLE, x, y, w, h,
                 fill=fill, line=line, lw=1.0)


# =====================================================================
# 01 표지
# =====================================================================
s = blank()
fill_bg(s, WHITE)
shape(s, MSO_SHAPE.RECTANGLE, 0, 0, Inches(0.28), SH, fill=NAVY)
shape(s, MSO_SHAPE.RECTANGLE, Inches(0.28), 0, Inches(0.06), SH, fill=ACCENT)

tf = tb(s, Inches(0.85), Inches(1.55), Inches(11.5), Inches(0.4))
P(tf, 'AI 활용 개발 성과 보고', 13, True, BLUE, first=True, before=0)

tf = tb(s, Inches(0.85), Inches(2.1), Inches(11.8), Inches(1.6))
P(tf, 'Cursor 기반 AI 페어프로그래밍으로', 32, True, NAVY, first=True, before=0)
P(tf, '구축한 통합 운영 모니터링', 32, True, NAVY, before=6)

shape(s, MSO_SHAPE.RECTANGLE, Inches(0.9), Inches(3.95),
      Inches(1.8), Pt(4), fill=ACCENT)

tf = tb(s, Inches(0.85), Inches(4.25), Inches(11.5), Inches(0.9))
P(tf, 'SM37 · ST22 · SXI_MONITOR 점검을 단일 대시보드로 통합하고,',
  15, False, SLATE, first=True, before=0)
P(tf, '개발 전 과정에 AI를 적용해 생산성·품질 표준화 효과를 검증한 사례입니다.',
  15, False, SLATE, before=4)

# meta chips
meta = [
    ('대상', '상무님 포함 사내 동료'),
    ('시간', '약 10분'),
    ('범위', 'SAP S/4HANA · ABAP'),
    ('도구', 'Cursor (AI)'),
]
mx = Inches(0.85)
for label, val in meta:
    box = card(s, mx, Inches(5.55), Inches(2.85), Inches(0.85), fill=SOFT, line=LINE)
    tf = box.text_frame
    tf.margin_left = Inches(0.18); tf.margin_top = Inches(0.12)
    P(tf, label, 10, True, BLUE, first=True, before=0)
    P(tf, val, 12, True, NAVY, before=2)
    mx = Emu(mx + Inches(3.0))

tf = tb(s, Inches(0.85), Inches(6.7), Inches(11.5), Inches(0.35))
P(tf, 'Confidential  ·  Internal Use Only', 10, False, MUTED, first=True, before=0)

notes(s,
      '【0:00–0:40】 인사 및 목적 한 문장.\n'
      '“오늘은 결과물 데모보다, AI를 개발 전 과정에 적용해 얻은 '
      '생산성·품질 효과를 중심으로 보고드리겠습니다.”')


# =====================================================================
# 02 Agenda
# =====================================================================
s = blank()
page_chrome(s, '01  AGENDA', '오늘 말씀드릴 내용', 2)

items = [
    ('01', '왜 이 과제인가', '운영 점검의 분산과 누락 리스크'),
    ('02', '무엇을 만들었는가', '읽기 전용 통합 모니터링 대시보드'),
    ('03', '어떻게 개발했는가', 'Cursor AI 페어프로그래밍 적용 방식'),
    ('04', '표준을 어떻게 고정했는가', 'Rules / Skills(.md) 기반 내재화'),
    ('05', '어떤 효과가 있었는가', '생산성·품질 효과와 향후 계획'),
]
y = Inches(1.55)
for num, title, desc in items:
    row = card(s, Inches(0.7), y, Inches(11.9), Inches(0.9))
    # number block
    shape(s, MSO_SHAPE.ROUNDED_RECTANGLE, Inches(0.7), y,
          Inches(1.1), Inches(0.9), fill=NAVY)
    tf = tb(s, Inches(0.7), y, Inches(1.1), Inches(0.9),
            anchor=MSO_ANCHOR.MIDDLE)
    P(tf, num, 18, True, WHITE, first=True, before=0, align=PP_ALIGN.CENTER)
    tf = tb(s, Inches(2.05), Emu(y + Inches(0.18)), Inches(10), Inches(0.35))
    P(tf, title, 16, True, NAVY, first=True, before=0)
    tf = tb(s, Inches(2.05), Emu(y + Inches(0.48)), Inches(10), Inches(0.3))
    P(tf, desc, 12, False, SLATE, first=True, before=0)
    y = Emu(y + Inches(1.02))

notes(s, '【0:40–1:10】 아젠다를 한 줄씩 짚고, 오늘은 데모보다 방법론·효과에 비중을 둔다고 안내.')


# =====================================================================
# 03 문제 인식
# =====================================================================
s = blank()
page_chrome(s, '02  PROBLEM', '운영 점검은 왜 비효율적인가', 3)

# AS-IS three boxes
areas = [
    ('SM37', '배치 잡 에러', '잡 실패·로그 확인'),
    ('ST22', '런타임 덤프', 'ABAP 단기 덤프 점검'),
    ('SXI_MONITOR', '인터페이스 에러', 'PI/PO 메시지 오류'),
]
ax = Inches(0.7)
for code, name, desc in areas:
    box = card(s, ax, Inches(1.55), Inches(3.7), Inches(2.0))
    tf = box.text_frame
    tf.margin_left = Inches(0.25); tf.margin_top = Inches(0.3)
    P(tf, code, 14, True, BLUE, first=True, before=0)
    P(tf, name, 16, True, NAVY, before=6)
    P(tf, desc, 11, False, SLATE, before=4)
    ax = Emu(ax + Inches(3.95))

# pain points
pain = card(s, Inches(0.7), Inches(3.85), Inches(11.9), Inches(2.7), fill=WHITE)
tf = pain.text_frame
tf.margin_left = Inches(0.4); tf.margin_top = Inches(0.25)
P(tf, '현행 운영의 구조적 한계', 14, True, RED, first=True, before=0)
pains = [
    '점검 채널이 3개로 분산되어 매일 트랜잭션을 개별 실행해야 함',
    '화면 전환이 잦아 점검 누락·지연 리스크가 상존',
    '현황 파악에 시간이 소요되어 “이상 징후 조기 인지”가 어려움',
    '동일 점검을 반복하면서도 표준화된 점검 뷰가 부재',
]
for t in pains:
    P(tf, '▸  ' + t, 13, False, INK, before=10)

notes(s,
      '【1:10–2:20】 운영자가 매일 겪는 현실을 짧게.\n'
      '“기능이 없어서가 아니라, 정보가 흩어져 있어 점검 비용이 큽니다.”')


# =====================================================================
# 04 솔루션
# =====================================================================
s = blank()
page_chrome(s, '03  SOLUTION', '단일 화면으로 운영 현황을 한눈에', 4)

# left: architecture layers
left = card(s, Inches(0.7), Inches(1.5), Inches(6.0), Inches(5.1))
tf = left.text_frame
tf.margin_left = Inches(0.35); tf.margin_top = Inches(0.25)
P(tf, '대시보드 구성', 14, True, BLUE, first=True, before=0)

layers = [
    ('상단 요약', '영역별 건수 · 신호등 · 조회 기간 · 최종 갱신'),
    ('중간 차트', '영역별 Top-N 에러 집중도 (IGS Chart)'),
    ('하단 목록', '상세 ALV · 더블클릭 시 표준 상세 화면 이동'),
]
for title, desc in layers:
    P(tf, title, 15, True, NAVY, before=16)
    P(tf, desc, 12, False, SLATE, before=4)

P(tf, '설계 원칙', 14, True, BLUE, before=20)
for t in ['읽기 전용 — 데이터 변경·COMMIT·LOCK 금지',
          'SAP 표준 테이블/FM만 사용',
          '영역별 권한 격리 — 일부 권한 없어도 나머지 동작']:
    P(tf, '•  ' + t, 12, False, INK, before=6)

# right: value props
rights = [
    ('한눈에 파악', '3개 점검을 한 트랜잭션에서 동시 확인'),
    ('빠른 드릴다운', '목록 → 표준 상세(로그/덤프/메시지) 직행'),
    ('운영 안전성', '조회 전용으로 운영계 영향 최소화'),
    ('확장 가능 구조', '영역 추가 시 Provider만 등록'),
]
ry = Inches(1.5)
for title, desc in rights:
    box = card(s, Inches(7.0), ry, Inches(5.6), Inches(1.15))
    tf = box.text_frame
    tf.margin_left = Inches(0.25); tf.margin_top = Inches(0.22)
    P(tf, title, 14, True, NAVY, first=True, before=0)
    P(tf, desc, 12, False, SLATE, before=4)
    ry = Emu(ry + Inches(1.25))

notes(s,
      '【2:20–3:40】 솔루션은 1분 내로 압축.\n'
      '“핵심은 통합 뷰 + 읽기 전용 안전장치입니다. 데모는 필요 시 별도.”')


# =====================================================================
# 05 Cursor 활용
# =====================================================================
s = blank()
page_chrome(s, '04  APPROACH', '개발 전 과정에 AI(Cursor)를 적용', 5)

phases = [
    ('설계', '설계서 초안·개정,\n결정/미결 이력 관리', BLUE),
    ('분석', '권한추적(STAUTHTRACE)\n엑셀 분석 → 권한 도출', TEAL),
    ('조사', 'SAP 표준 FM·화면\n사용법 즉시 확인', ACCENT),
    ('구현', '코드 생성 → 오류 진단\n→ 수정 루프 가속', BLUE),
    ('검증', '리뷰·표준 준수 점검\n문서/PR 품질 균일화', TEAL),
]
px = Inches(0.7)
for title, desc, color in phases:
    box = card(s, px, Inches(1.55), Inches(2.3), Inches(2.55))
    shape(s, MSO_SHAPE.RECTANGLE, px, Inches(1.55), Inches(2.3), Inches(0.12), fill=color)
    tf = box.text_frame
    tf.margin_left = Inches(0.18); tf.margin_top = Inches(0.35)
    P(tf, title, 16, True, NAVY, first=True, before=0, align=PP_ALIGN.CENTER)
    for i, line in enumerate(desc.split('\n')):
        P(tf, line, 11, False, SLATE, before=6 if i == 0 else 2,
          align=PP_ALIGN.CENTER)
    px = Emu(px + Inches(2.45))

# role split
role = card(s, Inches(0.7), Inches(4.4), Inches(11.9), Inches(2.2), fill=NAVY)
tf = role.text_frame
tf.margin_left = Inches(0.4); tf.margin_top = Inches(0.3)
P(tf, '역할 분담의 재정의', 14, True, ACCENT, first=True, before=0)
P(tf, 'AI  :  조사 · 초안 작성 · 반복 수정 · 표준 체크리스트 적용',
  14, False, WHITE, before=12)
P(tf, '개발자  :  요구 확정 · 설계 의사결정 · 결과 검증 · 운영 책임',
  14, False, WHITE, before=8)
P(tf, '→  “사람이 모든 것을 타이핑”하는 방식에서 “사람이 판단하고 AI가 실행”하는 방식으로 전환',
  13, True, RGBColor(0xFF, 0xD9, 0x7A), before=12)

notes(s,
      '【3:40–5:20】 핵심 슬라이드. 5개 단계별로 실제 사례 한 문장씩.\n'
      '예: “권한은 STAUTHTRACE 엑셀을 AI가 읽어 객체를 도출했고, '
      '사람은 최종 값만 확정했습니다.”')


# =====================================================================
# 06 Rules / Skills
# =====================================================================
s = blank()
page_chrome(s, '05  STANDARDS AS CODE', '규칙·스킬(.md)로 개발 표준을 내재화', 6)

# Rules
rbox = card(s, Inches(0.7), Inches(1.5), Inches(5.85), Inches(3.6))
shape(s, MSO_SHAPE.RECTANGLE, Inches(0.7), Inches(1.5),
      Inches(5.85), Inches(0.55), fill=NAVY)
tf = tb(s, Inches(0.7), Inches(1.5), Inches(5.85), Inches(0.55),
        anchor=MSO_ANCHOR.MIDDLE)
P(tf, 'Rules  ·  상시 자동 적용', 14, True, WHITE, first=True, before=0,
  align=PP_ALIGN.CENTER)
tf = rbox.text_frame
tf.margin_left = Inches(0.3); tf.margin_top = Inches(0.75)
P(tf, '.cursor/rules/abap-project-conventions', 11, True, BLUE, first=True, before=0)
for t in [
    '읽기 전용 불변식 (변경·COMMIT·LOCK 금지)',
    '표준 테이블 / 표준 FM만 데이터 소스로 사용',
    '기간 제한 SELECT · SELECT * 금지',
    '인터페이스 기반 OO · 영역별 권한 격리',
]:
    P(tf, '•  ' + t, 12, False, INK, before=10)
P(tf, '→ 매 작업마다 재지시 없이 자동 준수', 12, True, TEAL, before=14)

# Skills
sbox = card(s, Inches(6.8), Inches(1.5), Inches(5.85), Inches(3.6))
shape(s, MSO_SHAPE.RECTANGLE, Inches(6.8), Inches(1.5),
      Inches(5.85), Inches(0.55), fill=ACCENT)
tf = tb(s, Inches(6.8), Inches(1.5), Inches(5.85), Inches(0.55),
        anchor=MSO_ANCHOR.MIDDLE)
P(tf, 'Skills  ·  작업 유형별 플레이북', 14, True, WHITE, first=True, before=0,
  align=PP_ALIGN.CENTER)
tf = sbox.text_frame
tf.margin_left = Inches(0.3); tf.margin_top = Inches(0.75)
P(tf, '.cursor/skills/*/SKILL.md', 11, True, ACCENT, first=True, before=0)
for t in [
    '구현: 읽기전용 모니터링 · 클린 OO · 성능',
    '검증: 코드리뷰 · 체계적 디버깅',
    '문서: 설계서 · 커밋 메시지 · PR 작성',
    '검증된 절차를 재사용 → 품질 편차 축소',
]:
    P(tf, '•  ' + t, 12, False, INK, before=10)
P(tf, '→ 사람·세션이 바뀌어도 동일 기준 유지', 12, True, TEAL, before=14)

# efficiency band
band = card(s, Inches(0.7), Inches(5.35), Inches(11.95), Inches(1.3), fill=SOFT)
tf = band.text_frame
tf.margin_left = Inches(0.35); tf.margin_top = Inches(0.22)
P(tf, 'md 표준화의 실무 효과', 13, True, BLUE, first=True, before=0)
P(tf, '표준 설명 반복 제거  ·  재작업·휴먼에러 감소  ·  리뷰/문서 품질 균일화  ·  '
      '신규 인력 온보딩 가속  ·  규칙 자체를 버전관리하여 팀 단위 개선',
  12, False, INK, before=8)

notes(s,
      '【5:20–6:50】 “프롬프트를 잘 쓰는 것”이 아니라 '
      '“표준을 코드처럼 저장소에 고정”한 점이 차별점이라고 강조.')


# =====================================================================
# 07 효과
# =====================================================================
s = blank()
page_chrome(s, '06  OUTCOMES', '효율성 · 성과 (정성 중심 · 추정)', 7)

kpis = [
    ('개발 생산성', BLUE, [
        '설계–구현–검토를 단일 맥락으로 유지',
        '요구 변경의 즉시 반영으로 완성도 조기 확보',
        '조사·초안·수정의 대기시간 축소',
    ]),
    ('리서치 부담', TEAL, [
        '표준 FM/권한/화면 조사를 대화로 해결',
        '문서·트랜잭션 탐색 시간 절감',
        '의사결정에 필요한 근거를 빠르게 확보',
    ]),
    ('품질 · 표준', ACCENT, [
        'Rules/Skills로 사내 표준 일관 적용',
        '읽기 전용 위반·명명 오류 등 재작업 감소',
        '리뷰·문서 산출물의 편차 축소',
    ]),
]
kx = Inches(0.7)
for title, color, lines in kpis:
    box = card(s, kx, Inches(1.5), Inches(3.85), Inches(3.55))
    shape(s, MSO_SHAPE.RECTANGLE, kx, Inches(1.5), Inches(3.85), Inches(0.55), fill=color)
    tf = tb(s, kx, Inches(1.5), Inches(3.85), Inches(0.55),
            anchor=MSO_ANCHOR.MIDDLE)
    P(tf, title, 14, True, WHITE, first=True, before=0, align=PP_ALIGN.CENTER)
    tf = box.text_frame
    tf.margin_left = Inches(0.25); tf.margin_top = Inches(0.75)
    first = True
    for ln in lines:
        P(tf, '•  ' + ln, 12, False, INK, first=first, before=10)
        first = False
    kx = Emu(kx + Inches(4.05))

# estimate
est = card(s, Inches(0.7), Inches(5.3), Inches(11.95), Inches(1.35), fill=NAVY)
tf = est.text_frame
tf.margin_left = Inches(0.35); tf.margin_top = Inches(0.22)
P(tf, '효과 규모 (추정)  ·  정량 실측은 후속 과제', 13, True, ACCENT, first=True, before=0)
P(tf, '설계 문서화 · 표준 API 조사 · 오류 수정 사이클이 수작업 대비 유의미하게 단축된 것으로 판단합니다. '
      '향후 동일 난이도 과제에 대해 개발 소요시간 전/후를 비교해 수치화할 예정입니다.',
  12, False, WHITE, before=8)

notes(s,
      '【6:50–8:10】 숫자를 과장하지 말 것. “추정”임을 분명히 하고, '
      '실측 계획을 다음 슬라이드와 연결.')


# =====================================================================
# 08 기대효과 · 향후 ·  Closing
# =====================================================================
s = blank()
page_chrome(s, '07  NEXT', '기대 효과와 향후 계획', 8)

# two columns
left = card(s, Inches(0.7), Inches(1.5), Inches(5.85), Inches(3.3))
shape(s, MSO_SHAPE.RECTANGLE, Inches(0.7), Inches(1.5),
      Inches(5.85), Inches(0.55), fill=NAVY)
tf = tb(s, Inches(0.7), Inches(1.5), Inches(5.85), Inches(0.55),
        anchor=MSO_ANCHOR.MIDDLE)
P(tf, '기대 효과', 14, True, WHITE, first=True, before=0, align=PP_ALIGN.CENTER)
tf = left.text_frame
tf.margin_left = Inches(0.3); tf.margin_top = Inches(0.75)
for t in [
    '운영 점검 시간 단축 및 누락 방지',
    '읽기 전용 설계로 운영 안전성 확보',
    'AI 페어프로그래밍의 사내 적용 가능성 확인',
    'Rules/Skills를 통한 개발 표준 자산화',
]:
    P(tf, '•  ' + t, 13, False, INK, first=(t.startswith('운영')), before=10)

right = card(s, Inches(6.8), Inches(1.5), Inches(5.85), Inches(3.3))
shape(s, MSO_SHAPE.RECTANGLE, Inches(6.8), Inches(1.5),
      Inches(5.85), Inches(0.55), fill=ACCENT)
tf = tb(s, Inches(6.8), Inches(1.5), Inches(5.85), Inches(0.55),
        anchor=MSO_ANCHOR.MIDDLE)
P(tf, '향후 계획', 14, True, WHITE, first=True, before=0, align=PP_ALIGN.CENTER)
tf = right.text_frame
tf.margin_left = Inches(0.3); tf.margin_top = Inches(0.75)
for i, t in enumerate([
    '검증본의 정식 오브젝트화 및 기능 고도화',
    '개발 소요시간 전/후 비교로 정량 효과 실측',
    '유사 ABAP 과제에 Rules/Skills 확대 적용',
    '팀 단위 AI 활용 가이드라인 정리',
]):
    P(tf, '•  ' + t, 13, False, INK, first=(i == 0), before=10)

# closing message
msg = card(s, Inches(0.7), Inches(5.1), Inches(11.95), Inches(1.55), fill=NAVY)
tf = msg.text_frame
tf.margin_left = Inches(0.4); tf.margin_top = Inches(0.28)
P(tf, '핵심 메시지', 12, True, ACCENT, first=True, before=0)
P(tf, '운영 점검을 통합하는 동시에, AI와 표준(.md)을 결합해',
  16, True, WHITE, before=8)
P(tf, '개발 생산성과 품질을 함께 끌어올린 실행 사례입니다.',
  16, True, WHITE, before=4)

notes(s,
      '【8:10–9:40】 기대효과 → 향후계획 → 핵심메시지.\n'
      '【9:40–10:00】 Q&A 유도. '
      '예상 질문: 정량 수치, 보안/권한, 운영 적용 일정, 타 과제 확대.')


# ── Save ─────────────────────────────────────────────────────────
OUT = 'docs/report/Y_OPS_MONITOR_V2_발표자료.pptx'
prs.save(OUT)
print(f'saved {OUT} ({len(prs.slides)} slides)')
