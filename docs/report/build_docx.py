# -*- coding: utf-8 -*-
"""AI 활용 효율성 · 향후 방향 — 사내 보고용 DOCX (발표자료와 동일 축)."""
from docx import Document
from docx.shared import Pt, RGBColor, Cm
from docx.oxml.ns import qn
from docx.enum.text import WD_ALIGN_PARAGRAPH

KOR = 'Malgun Gothic'
NIGHT = RGBColor(0x0B, 0x12, 0x20)
SLATE = RGBColor(0x5A, 0x66, 0x78)


def _kor(run, size=None, bold=None, color=None):
    run.font.name = KOR
    run.element.rPr.rFonts.set(qn('w:eastAsia'), KOR)
    if size is not None:
        run.font.size = Pt(size)
    if bold is not None:
        run.font.bold = bold
    if color is not None:
        run.font.color.rgb = color


def base(doc):
    st = doc.styles['Normal']
    st.font.name = KOR
    st.font.size = Pt(11)
    st.element.rPr.rFonts.set(qn('w:eastAsia'), KOR)
    for section in doc.sections:
        section.top_margin = Cm(2.0)
        section.bottom_margin = Cm(2.0)
        section.left_margin = Cm(2.2)
        section.right_margin = Cm(2.2)


def h(doc, text, level=1):
    p = doc.add_heading(level=level)
    r = p.add_run(text)
    _kor(r, color=NIGHT)
    return p


def b(doc, text, level=0):
    style = 'List Bullet' if level == 0 else 'List Bullet 2'
    p = doc.add_paragraph(style=style)
    r = p.add_run(text)
    _kor(r)
    return p


def para(doc, text, size=11, bold=False, color=None):
    p = doc.add_paragraph()
    r = p.add_run(text)
    _kor(r, size=size, bold=bold, color=color)
    return p


doc = Document()
base(doc)

t = doc.add_paragraph()
t.alignment = WD_ALIGN_PARAGRAPH.CENTER
tr = t.add_run('AI를 쓰는 것과 AI를 잘 쓰는 것은 다릅니다')
_kor(tr, 18, True, NIGHT)

s = doc.add_paragraph()
s.alignment = WD_ALIGN_PARAGRAPH.CENTER
sr = s.add_run(
    '개발 업무에서의 AI 활용 효율과 조직이 가져가야 할 방향\n'
    '사례: SAP 통합 운영 모니터링 개발 (Cursor)  ·  약 10분 브리핑'
)
_kor(sr, 11, False, SLATE)
doc.add_paragraph()

h(doc, '1. 논의의 축', 1)
para(doc, '본 보고의 주목적은 특정 프로그램의 기능 설명이 아니다. '
          'AI를 어디에 어떻게 붙일 때 생산성이 올라가는지, '
          '그리고 개인 역량이 아닌 조직 역량으로 남기려면 무엇이 필요한지를 다룬다.')
b(doc, '효율: 조사·초안·반복 수정·표준 적용을 AI에 맡기는 구조')
b(doc, '방향: 규칙·스킬·재사용·측정으로 조직화')

h(doc, '2. AI를 도입해도 효율이 안 나는 경우', 1)
b(doc, '매번 다른 지시 — 같은 표준을 대화마다 다시 설명 → 결과 편차')
b(doc, '조사 없는 생성 — 근거 없이 코드만 생성 → 검증·재작업 비용 증가')
b(doc, '개인 의존 — 잘하는 사람만 잘 씀 → 조직 생산성으로 전이되지 않음')
b(doc, '결과물 중심 평가 — 산출물 유무만 보고 재사용·표준화는 남지 않음')

h(doc, '3. 효율이 나는 AI 활용의 조건', 1)
b(doc, '범위 고정: AI(조사·초안·반복 수정) / 사람(판단·책임·운영 확정)')
b(doc, '표준 선반영: Rules(상시) · Skills(작업별 절차)를 저장소에 고정')
b(doc, '검증 루프: 생성으로 끝내지 않고 진단–수정–확인을 짧게 반복')

h(doc, '4. 적용 사례에서 확인한 것', 1)
para(doc, 'SAP 통합 운영 모니터링 개발은 목적물이 아니라 검증 무대였다. '
          '설계–분석–구현–표준 적용을 한 과제로 관통하며 아래를 확인했다.')
b(doc, 'AI는 “대신 코딩”보다 “조사–초안–수정의 가속기”로 쓸 때 효과가 큼')
b(doc, '표준을 .md로 고정하지 않으면 같은 실수를 세션마다 반복함')
b(doc, '사람이 판단과 검증에 집중할수록 전체 리드타임이 줄어듦')

h(doc, '5. 효율을 재현 가능하게 만드는 장치', 1)
b(doc, 'Rules: 불변식을 상시 자동 적용 → 재지시·재작업 감소')
b(doc, 'Skills: 구현·리뷰·성능·디버깅·문서 절차를 재실행 → 품질 편차 축소')
para(doc, 'AI 효율은 “누가 더 잘 물어보느냐”가 아니라 '
          '“조직이 무엇을 규칙으로 고정해 두었느냐”에서 갈린다.', bold=True)

h(doc, '6. 앞으로 가져가야 할 방향', 1)
b(doc, '단기: 검증된 과제에 AI+Rules를 기본 세트로 적용')
b(doc, '중기: 팀 공통 Rules를 자산으로 관리, Skills를 리뷰 기준으로 사용')
b(doc, '측정: 동일 난이도 과제 기준 전/후 소요시간 비교')
b(doc, '확산: 개인 성공을 조직 가이드(재사용 절차)로 전환')

h(doc, '7. 핵심 메시지', 1)
para(doc, 'AI는 도입하는 순간이 아니라, 쓰는 구조를 만들 때 효율이 난다. '
          '우리가 할 일은 범위 고정 · 표준(.md) 자산화 · 검증 루프 · 전/후 측정이다.',
     bold=True, color=NIGHT)

out = 'docs/report/Y_OPS_MONITOR_V2_성과보고서.docx'
doc.save(out)
print('saved', out)
