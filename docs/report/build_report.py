# -*- coding: utf-8 -*-
"""통합 운영 모니터링 - 경영진 보고용 발표자료(PPTX, 5슬라이드).
   비중: Cursor(AI) 활용 효율성 중심 / 정성 위주(추정)."""
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor

KOR_FONT = 'Malgun Gothic'
NAVY  = RGBColor(0x1F, 0x35, 0x64)
BLUE  = RGBColor(0x2E, 0x5B, 0xFF)
GREY  = RGBColor(0x55, 0x55, 0x55)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
ACCENT = RGBColor(0xE8, 0xA3, 0x1C)


def _f(run, size=16, bold=False, color=None):
    run.font.size = Pt(size); run.font.bold = bold; run.font.name = KOR_FONT
    if color is not None:
        run.font.color.rgb = color


def title_slide(prs, title, subtitle, foot):
    s = prs.slides.add_slide(prs.slide_layouts[6])
    band = s.shapes.add_shape(1, 0, Inches(2.3), prs.slide_width, Inches(2.5))
    band.fill.solid(); band.fill.fore_color.rgb = NAVY; band.line.fill.background()
    tb = s.shapes.add_textbox(Inches(0.8), Inches(2.6), Inches(11.7), Inches(1.6))
    tf = tb.text_frame; tf.word_wrap = True
    r = tf.paragraphs[0].add_run(); r.text = title; _f(r, 34, True, WHITE)
    r2 = tf.add_paragraph().add_run(); r2.text = subtitle; _f(r2, 17, False, RGBColor(0xD5, 0xDE, 0xF5))
    fb = s.shapes.add_textbox(Inches(0.8), Inches(6.7), Inches(11.7), Inches(0.5))
    fr = fb.text_frame.paragraphs[0].add_run(); fr.text = foot; _f(fr, 12, False, GREY)


def content_slide(prs, no, title, blocks):
    """blocks: list of (heading, [bullets])"""
    s = prs.slides.add_slide(prs.slide_layouts[6])
    bar = s.shapes.add_shape(1, 0, 0, prs.slide_width, Inches(0.95))
    bar.fill.solid(); bar.fill.fore_color.rgb = NAVY; bar.line.fill.background()
    tb = s.shapes.add_textbox(Inches(0.6), Inches(0.16), Inches(12.1), Inches(0.65))
    r = tb.text_frame.paragraphs[0].add_run(); r.text = f'{no}. {title}'; _f(r, 24, True, WHITE)

    body = s.shapes.add_textbox(Inches(0.7), Inches(1.2), Inches(11.9), Inches(6.0))
    tf = body.text_frame; tf.word_wrap = True
    first = True
    for heading, bullets in blocks:
        p = tf.paragraphs[0] if first else tf.add_paragraph(); first = False
        p.space_before = Pt(10)
        rh = p.add_run(); rh.text = '▸ ' + heading; _f(rh, 17, True, BLUE)
        for bt in bullets:
            bp = tf.add_paragraph(); bp.level = 1; bp.space_before = Pt(2)
            rb = bp.add_run(); rb.text = bt; _f(rb, 14, False, RGBColor(0x22, 0x22, 0x22))
    return s


prs = Presentation()
prs.slide_width = Inches(13.333); prs.slide_height = Inches(7.5)

# 1. 표지
title_slide(
    prs,
    'AI(Cursor) 활용 개발 성과 보고',
    '통합 운영 모니터링(SM37·ST22·SXI) 개발을 통한 AI 페어프로그래밍 효율성 검증',
    'SAP S/4HANA · ABAP  |  개발도구: Cursor(AI)  |  경영진 보고용')

# 2. 개요 (간략)
content_slide(prs, 1, '프로젝트 개요', [
    ('무엇을', [
        '운영자가 매일 개별 확인하던 3개 점검 화면(배치/런타임덤프/인터페이스)을 '
        '단일 대시보드로 통합(읽기 전용).']),
    ('왜', [
        '점검 시간 단축·누락 방지, 반복 원인 신속 식별.']),
    ('보고의 초점', [
        '결과물 자체보다, AI(Cursor)를 개발 전 과정에 활용해 얻은 '
        '생산성·품질 효과를 보고.']),
])

# 3. Cursor 활용 방식 (핵심)
content_slide(prs, 2, 'AI(Cursor) 활용 방식', [
    ('설계 문서 자동화', [
        '설계서 작성·개정, 결정사항/미결과제 이력 관리를 대화로 진행.']),
    ('자료 분석 자동화', [
        '권한 추적 결과(STAUTHTRACE 엑셀)를 직접 분석해 필요한 권한을 자동 도출.']),
    ('표준 기능 조사 자동화', [
        '개발에 필요한 SAP 표준 기능/사용법을 즉시 조사·확인(수작업 문서 탐색 대체).']),
    ('개발-검증 반복 루프', [
        '코드 생성 → 오류 진단 → 즉시 수정을 빠르게 반복하여 완성도 향상.']),
    ('표준·규칙 자동 준수', [
        '“읽기 전용”·명명규칙 등 사내 개발 표준을 규칙으로 상시 자동 적용.']),
])

# 4. 효율성 · 성과 (핵심, 정성+추정)
content_slide(prs, 3, '효율성 · 성과', [
    ('개발 생산성 (정성)', [
        '설계–구현–검토를 하나의 흐름으로 진행(맥락 유지) → 진행 속도 향상.',
        '반복 개선(요구 변경 즉시 반영) 회수 증가로 완성도 조기 확보.']),
    ('리서치 부담 감소 (정성)', [
        '표준 기능/사용법 조사를 대화로 즉시 해결 → 탐색 시간 절감.']),
    ('품질·표준 준수 (정성)', [
        '사내 표준의 일관 적용으로 휴먼 에러·재작업 감소.']),
    ('효과 규모 (추정)', [
        '설계 문서화·표준 조사·오류 수정 사이클 시간이 수작업 대비 크게 단축(추정).',
        '※ 정량 수치는 향후 실측하여 보완 예정.']),
])

# 5. 기대효과 & 향후계획 (간략)
content_slide(prs, 4, '기대 효과 및 향후 계획', [
    ('기대 효과', [
        '운영 점검 시간 단축·누락 방지, 운영 안전성(읽기 전용) 확보.',
        'AI 페어프로그래밍의 사내 개발 생산성 향상 가능성 확인.']),
    ('향후 계획', [
        '검증본 정식 오브젝트화 및 기능 고도화.',
        '정량 효과 실측(개발 소요시간 전/후 비교) 및 타 과제 확대 적용 검토.']),
])

out = 'docs/report/Y_OPS_MONITOR_V2_발표자료.pptx'
prs.save(out)
print('saved', out)
