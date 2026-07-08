# -*- coding: utf-8 -*-
"""통합 운영 모니터링 - 경영진 보고용 성과보고서(DOCX, 간결).
   비중: Cursor(AI) 활용 효율성 중심 / 정성 위주(추정)."""
from docx import Document
from docx.shared import Pt, RGBColor
from docx.oxml.ns import qn
from docx.enum.text import WD_ALIGN_PARAGRAPH

KOR = 'Malgun Gothic'
NAVY = RGBColor(0x1F, 0x35, 0x64)


def _kor(run, size=None, bold=None, color=None):
    run.font.name = KOR
    run.element.rPr.rFonts.set(qn('w:eastAsia'), KOR)
    if size is not None:  run.font.size = Pt(size)
    if bold is not None:  run.font.bold = bold
    if color is not None: run.font.color.rgb = color


def base(doc):
    st = doc.styles['Normal']; st.font.name = KOR; st.font.size = Pt(10.5)
    st.element.rPr.rFonts.set(qn('w:eastAsia'), KOR)


def h(doc, text, level=1):
    p = doc.add_heading(level=level); r = p.add_run(text); _kor(r, color=NAVY); return p


def b(doc, text, level=0):
    p = doc.add_paragraph(style='List Bullet' if level == 0 else 'List Bullet 2')
    r = p.add_run(text); _kor(r); return p


def para(doc, text):
    p = doc.add_paragraph(); r = p.add_run(text); _kor(r); return p


doc = Document(); base(doc)

t = doc.add_paragraph(); t.alignment = WD_ALIGN_PARAGRAPH.CENTER
tr = t.add_run('AI(Cursor) 활용 개발 성과 보고서'); _kor(tr, 20, True, NAVY)
s = doc.add_paragraph(); s.alignment = WD_ALIGN_PARAGRAPH.CENTER
sr = s.add_run('통합 운영 모니터링(SM37·ST22·SXI) 개발을 통한 AI 페어프로그래밍 효율성 검증'); _kor(sr, 11)
doc.add_paragraph()

h(doc, '1. 개요', 1)
para(doc, '운영자가 매일 개별 확인하던 3개 점검 화면(배치 잡·런타임 덤프·인터페이스)을 '
          '단일 대시보드로 통합하는 읽기 전용 모니터링 프로그램을 개발하였다. 본 보고서는 '
          '개발 결과물 자체보다, 개발 전 과정에 AI 도구(Cursor)를 활용하여 얻은 생산성·품질 '
          '효과에 초점을 둔다.')

h(doc, '2. AI(Cursor) 활용 방식', 1)
b(doc, '설계 문서 자동화: 설계서 작성·개정 및 결정사항/미결과제 이력 관리를 대화로 진행')
b(doc, '자료 분석 자동화: 권한 추적 결과(STAUTHTRACE 엑셀)를 직접 분석해 필요한 권한을 자동 도출')
b(doc, '표준 기능 조사 자동화: 개발에 필요한 SAP 표준 기능/사용법을 즉시 조사·확인(수작업 문서 탐색 대체)')
b(doc, '개발–검증 반복 루프: 코드 생성 → 오류 진단 → 즉시 수정을 빠르게 반복하여 완성도 향상')
b(doc, '표준·규칙 자동 준수: “읽기 전용”·명명규칙 등 사내 개발 표준을 규칙으로 상시 자동 적용')

h(doc, '3. AI 규칙·스킬(.md) 기반 표준화', 1)
para(doc, '개발 표준과 작업 절차를 문서 규칙(.md)으로 명문화하여 저장소에 함께 관리한다. '
          '이를 통해 매번 같은 지시를 반복하지 않고도 AI가 사내 표준을 일관되게 준수한다.')
h(doc, '상시 규칙(Rules) — 항상 자동 적용', 2)
b(doc, '.cursor/rules/abap-project-conventions: 모든 작업에 상시 적용되는 불변식')
b(doc, '읽기 전용(데이터 변경·COMMIT·LOCK 금지) 원칙 강제', 1)
b(doc, 'SAP 표준 테이블/함수모듈만 사용, 명명규칙·인터페이스 기반 OO 구조 준수', 1)
h(doc, '온디맨드 스킬(Skills) — 작업 유형별 검증 플레이북', 2)
b(doc, '.cursor/skills: 필요 시 호출하는 재사용 가능한 절차 모음')
b(doc, '구현: 읽기전용 모니터링 / 클린 OO ABAP / 성능 튜닝 / 체계적 디버깅', 1)
b(doc, '검토·문서화: 코드리뷰 / 설계서 작성 / 커밋 메시지 / PR 작성', 1)
h(doc, 'md 파일 활용 효율 효과', 2)
b(doc, '표준을 매번 설명할 필요 없이 일관 적용 → 재작업·휴먼 에러 감소')
b(doc, '리뷰·문서 산출물의 품질 균일화 및 신규 인력 온보딩 가속')
b(doc, '규칙/스킬을 코드처럼 버전관리(.md)하여 팀 전체가 동일 기준으로 재사용·개선')

h(doc, '4. 효율성 · 성과 (정성 위주, 추정)', 1)
h(doc, '개발 생산성', 2)
b(doc, '설계–구현–검토를 하나의 흐름으로 진행(맥락 유지) → 진행 속도 향상')
b(doc, '요구 변경을 즉시 반영하는 반복 개선으로 완성도 조기 확보')
h(doc, '리서치 부담 감소', 2)
b(doc, '표준 기능/사용법 조사를 대화로 즉시 해결 → 탐색 시간 절감')
h(doc, '품질 · 표준 준수', 2)
b(doc, '사내 표준의 일관 적용으로 휴먼 에러 및 재작업 감소')
h(doc, '효과 규모(추정)', 2)
b(doc, '설계 문서화·표준 조사·오류 수정 사이클 시간이 수작업 대비 크게 단축(추정)')
b(doc, '정량 수치는 향후 개발 소요시간 전/후 비교로 실측하여 보완 예정')

h(doc, '5. 기대 효과 및 향후 계획', 1)
b(doc, '기대 효과: 운영 점검 시간 단축·누락 방지, 운영 안전성(읽기 전용) 확보')
b(doc, '기대 효과: AI 페어프로그래밍의 사내 개발 생산성 향상 가능성 확인')
b(doc, '향후 계획: 검증본 정식 오브젝트화 및 기능 고도화')
b(doc, '향후 계획: 정량 효과 실측 및 타 개발 과제로의 확대 적용 검토')

out = 'docs/report/Y_OPS_MONITOR_V2_성과보고서.docx'
doc.save(out)
print('saved', out)
