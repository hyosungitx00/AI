# -*- coding: utf-8 -*-
"""통합 운영 모니터링(Y_OPS_MONITOR_V2) 성과 보고서(DOCX) 생성."""
from docx import Document
from docx.shared import Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

KOR = 'Malgun Gothic'
NAVY = RGBColor(0x1F, 0x35, 0x64)


def style_base(doc):
    st = doc.styles['Normal']
    st.font.name = KOR
    st.font.size = Pt(10.5)
    st.element.rPr.rFonts.set(__import__('docx').oxml.ns.qn('w:eastAsia'), KOR)


def h(doc, text, level=1):
    p = doc.add_heading(level=level)
    r = p.add_run(text)
    r.font.name = KOR
    r.font.color.rgb = NAVY
    r.element.rPr.rFonts.set(__import__('docx').oxml.ns.qn('w:eastAsia'), KOR)
    return p


def b(doc, text, level=0):
    style = 'List Bullet' if level == 0 else 'List Bullet 2'
    p = doc.add_paragraph(style=style)
    r = p.add_run(text)
    r.font.name = KOR
    r.element.rPr.rFonts.set(__import__('docx').oxml.ns.qn('w:eastAsia'), KOR)
    return p


def para(doc, text):
    p = doc.add_paragraph()
    r = p.add_run(text)
    r.font.name = KOR
    r.element.rPr.rFonts.set(__import__('docx').oxml.ns.qn('w:eastAsia'), KOR)
    return p


doc = Document()
style_base(doc)

# 표지
t = doc.add_paragraph(); t.alignment = WD_ALIGN_PARAGRAPH.CENTER
tr = t.add_run('통합 운영 모니터링 프로그램 개발 성과 보고서')
tr.bold = True; tr.font.size = Pt(20); tr.font.name = KOR; tr.font.color.rgb = NAVY
tr.element.rPr.rFonts.set(__import__('docx').oxml.ns.qn('w:eastAsia'), KOR)
s = doc.add_paragraph(); s.alignment = WD_ALIGN_PARAGRAPH.CENTER
sr = s.add_run('SM37(배치) · ST22(런타임 덤프) · SXI_MONITOR(인터페이스) 통합 대시보드\n'
               'AI 페어프로그래밍(Cursor) 기반 설계·구현')
sr.font.size = Pt(11); sr.font.name = KOR
sr.element.rPr.rFonts.set(__import__('docx').oxml.ns.qn('w:eastAsia'), KOR)
doc.add_paragraph()

h(doc, '1. 프로젝트 개요', 1)
para(doc, '운영 담당자가 매일 개별 실행하던 3개 표준 트랜잭션(SM37/ST22/SXI_MONITOR)의 '
          '에러 현황을 단일 트랜잭션의 통합 대시보드에서 동시에 확인할 수 있도록 하는 '
          '읽기 전용 모니터링 프로그램을 개발한다.')
b(doc, '대상: SAP S/4HANA (ABAP Integration Engine)')
b(doc, '환경: SAP GUI (Classic Dynpro + OO ALV + IGS Chart)')
b(doc, '핵심 원칙: 읽기 전용(데이터 변경/COMMIT/재처리 금지), 표준 오브젝트만 사용, 드릴다운은 표시 모드')

h(doc, '2. 목표 및 기대 효과', 1)
b(doc, '3개 영역 에러를 한 화면에서 동시 가시화 → 점검 시간 단축·누락 방지')
b(doc, '요약(신호등) + 영역별 집중도 차트 + 상세 목록 + 상세화면 즉시 이동')
b(doc, '인터페이스 기반 모듈화로 신규 모니터링 영역 확장 용이')

h(doc, '3. 시스템 아키텍처', 1)
para(doc, '관심사 분리와 전략(Strategy) 패턴을 적용하였다. 컨트롤러가 영역별 데이터 '
          '프로바이더(공통 인터페이스 구현)를 순회 호출하고, 집계기가 차트 데이터를 파생하며, '
          '대시보드 UI가 요약/차트/ALV를 렌더링한다. 드릴다운은 네비게이터가 표시 전용으로 캡슐화한다.')
b(doc, 'ZIF_MON_DATA_PROVIDER (공통 계약) → DP_BATCH / DP_DUMP / DP_INTERFACE')
b(doc, 'CONTROLLER(오케스트레이션) · AGGREGATOR(Top-N/추이) · UI_DASHBOARD · NAVIGATOR')
b(doc, '데이터 소스(표준): TBTCO/TBTCP, RS_ST22_GET_DUMPS, SXMSPERROR/SXMSPMAST/SXMSPEMAS')

h(doc, '4. 주요 기능', 1)
b(doc, '상단 요약: 영역별 신호등(3단계) + 건수 + 조회기간')
b(doc, '중간 차트(IGS): 영역별 개별 그래픽 차트, Top-N 집중도 / 시간대별 추이 토글')
b(doc, '하단 ALV: SM37/ST22/SXI 3분할, 영역 고정색 강조')
b(doc, '조회/필터: 조회기간(기본 −24H), 영역 On/Off, 잡명·사용자·인터페이스명 필터')
b(doc, '정확성: 자정 경계 처리, 타임존(UTC↔로컬) 변환, 결과 상한 안내')
b(doc, '상호작용: 라인 더블클릭 → 해당 건 상세(잡로그/덤프/메시지)로 직접 이동')
b(doc, '운영 편의: 새로고침 / 자동 새로고침 / 관점 전환')
b(doc, '보안: 영역별 권한 체크 후 없으면 해당 영역만 스킵')

h(doc, '5. 진행 경과', 1)
b(doc, '설계서 작성·개정: v0.1 → v0.4 (요구사항·데이터소스·화면·로직·권한·테스트)')
b(doc, '권한 객체 확정(O-7): STAUTHTRACE 추적으로 실제 체크 객체 확정')
b(doc, '  · SM37 S_BTCH_JOB / ST22 S_ABAPDUMP(후보 S_ADMI_FCD 정정) / SXI S_XMB_MONI', 1)
b(doc, '구현: 로컬 우선(단일 리포트+로컬 클래스)로 검증 → 이후 글로벌 오브젝트 분리 예정')
b(doc, '반복 개선: 대시보드/차트/드릴다운/새로고침/입력검증 등 iteration으로 완성도 향상')

h(doc, '6. Cursor(AI) 활용 방식', 1)
b(doc, '설계 문서 자동 작성·개정 및 버전/Open Issue 이력 관리')
b(doc, 'STAUTHTRACE 엑셀 직접 분석 → 권한 객체/필드/값 자동 도출')
b(doc, '표준 FM·클래스 시그니처 자동 조사(RS_SNAP_DUMP_DISPLAY, SXMB_DISPLAY_MESSAGE_MONITOR, CL_GUI_CHART_ENGINE)')
b(doc, '설계→코딩→오류수정 반복 루프: 파라미터/형식호환/IGS XML 오류 즉시 진단·수정')
b(doc, '전체 소스 일괄 생성·출력(복사-붙여넣기), 변경 이력(git) 관리')
b(doc, '읽기전용 원칙·명명규칙을 프로젝트 규칙(Rules/Skills)으로 상시 적용')

h(doc, '7. 효율성 · 성과', 1)
h(doc, '정성적 효과', 2)
b(doc, '설계-구현-검토를 하나의 흐름으로 진행(컨텍스트 유지)')
b(doc, '표준 오브젝트 탐색을 대화로 즉시 해결 → 리서치 부담 감소')
b(doc, '사내 표준 일관 적용으로 휴먼 에러 감소')
h(doc, '정량적 효과(추정)', 2)
b(doc, '설계서 작성/개정 시간 대폭 단축')
b(doc, '표준 API/파라미터 조사 시간 절감')
b(doc, '오류 수정 사이클 단축 → 반복 개선 회수 증가')

h(doc, '8. 향후 계획', 1)
b(doc, '로컬 클래스 → 글로벌 오브젝트(DDIC/클래스/메시지클래스/트랜잭션) 분리')
b(doc, 'IGS 그래픽 차트 고도화(색상 규약·값 라벨), 다국어(메시지클래스) 적용')
b(doc, '자동 새로고침 관제 모드, 임계치 기반 알림(정책 검토)')
b(doc, '신규 모니터링 영역 확장(SM21/RZ20 등) — 프로바이더 추가만으로')

out = 'docs/report/Y_OPS_MONITOR_V2_성과보고서.docx'
doc.save(out)
print('saved', out)
