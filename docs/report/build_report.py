# -*- coding: utf-8 -*-
"""통합 운영 모니터링(Y_OPS_MONITOR_V2) 발표/성과 보고 자료 생성.
   - PPTX(발표), DOCX(보고서) 동시 생성.
"""
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

KOR_FONT = 'Malgun Gothic'
NAVY   = RGBColor(0x1F, 0x35, 0x64)
BLUE   = RGBColor(0x2E, 0x5B, 0xFF)
GREY   = RGBColor(0x55, 0x55, 0x55)
LIGHT  = RGBColor(0xF2, 0xF5, 0xFB)
WHITE  = RGBColor(0xFF, 0xFF, 0xFF)


def _set_font(run, size=18, bold=False, color=None):
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.name = KOR_FONT
    if color is not None:
        run.font.color.rgb = color


def add_title_slide(prs, title, subtitle):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    # background band
    band = slide.shapes.add_shape(1, 0, Inches(2.2), prs.slide_width, Inches(2.4))
    band.fill.solid(); band.fill.fore_color.rgb = NAVY
    band.line.fill.background()
    tb = slide.shapes.add_textbox(Inches(0.7), Inches(2.5), Inches(11.9), Inches(1.4))
    tf = tb.text_frame; tf.word_wrap = True
    p = tf.paragraphs[0]; r = p.add_run(); r.text = title
    _set_font(r, 34, True, WHITE)
    p2 = tf.add_paragraph(); r2 = p2.add_run(); r2.text = subtitle
    _set_font(r2, 18, False, RGBColor(0xD5, 0xDE, 0xF5))
    foot = slide.shapes.add_textbox(Inches(0.7), Inches(6.7), Inches(11.9), Inches(0.5))
    fr = foot.text_frame.paragraphs[0].add_run()
    fr.text = 'SAP S/4HANA · ABAP (SAP GUI, OO ALV, IGS Chart) · 개발 도구: Cursor'
    _set_font(fr, 12, False, GREY)
    return slide


def add_section_slide(prs, title, bullets):
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    bar = slide.shapes.add_shape(1, 0, 0, prs.slide_width, Inches(1.0))
    bar.fill.solid(); bar.fill.fore_color.rgb = NAVY; bar.line.fill.background()
    tb = slide.shapes.add_textbox(Inches(0.6), Inches(0.18), Inches(12.1), Inches(0.7))
    r = tb.text_frame.paragraphs[0].add_run(); r.text = title
    _set_font(r, 24, True, WHITE)

    body = slide.shapes.add_textbox(Inches(0.7), Inches(1.3), Inches(11.9), Inches(5.9))
    tf = body.text_frame; tf.word_wrap = True
    first = True
    for item in bullets:
        level, text = item if isinstance(item, tuple) else (0, item)
        p = tf.paragraphs[0] if first else tf.add_paragraph()
        first = False
        p.level = level
        r = p.add_run(); r.text = text
        if level == 0:
            _set_font(r, 17, True, NAVY)
            p.space_before = Pt(8)
        else:
            _set_font(r, 14.5, False, RGBColor(0x22, 0x22, 0x22))
            p.space_before = Pt(2)
    return slide


prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)

# 1. Title
add_title_slide(
    prs,
    '통합 운영 모니터링 프로그램 개발',
    'SM37(배치) · ST22(런타임 덤프) · SXI_MONITOR(인터페이스) 통합 대시보드\nAI 페어프로그래밍(Cursor) 기반 설계·구현 성과 보고')

# 2. Agenda
add_section_slide(prs, '목차', [
    (0, '1. 프로젝트 배경 및 목표'),
    (0, '2. 시스템 아키텍처'),
    (0, '3. 주요 기능 및 화면 구성'),
    (0, '4. 진행 경과'),
    (0, '5. Cursor(AI) 활용 방식'),
    (0, '6. 효율성 · 성과'),
    (0, '7. 기대 효과 및 향후 계획'),
])

# 3. 배경/문제
add_section_slide(prs, '1. 프로젝트 배경 및 목표', [
    (0, '배경 — 운영 점검의 비효율'),
    (1, '운영자가 매일 SM37/ST22/SXI_MONITOR 3개 트랜잭션을 개별 실행·확인'),
    (1, '화면 전환이 잦고, 점검 누락 및 대응 지연 위험'),
    (0, '목표 — 단일 화면 통합 모니터링'),
    (1, '3개 영역 에러 현황을 하나의 대시보드에서 동시 가시화'),
    (1, '요약(신호등) + 집중도 차트 + 상세 목록 + 상세 화면 즉시 이동'),
    (0, '핵심 원칙'),
    (1, '읽기 전용(Read-Only): 데이터 변경/COMMIT/재처리 전면 금지'),
    (1, '표준 테이블/표준 FM만 사용, 드릴다운은 표시(Display) 모드'),
    (1, '확장성: 인터페이스 기반 모듈화(신규 영역 = 프로바이더 추가)'),
])

# 4. 아키텍처
add_section_slide(prs, '2. 시스템 아키텍처', [
    (0, '설계 패턴 — 관심사 분리 + 전략(Strategy) 패턴'),
    (1, '선택화면 → 컨트롤러 → (영역별 데이터 프로바이더) → 집계 → 대시보드 UI'),
    (0, '구성 요소'),
    (1, 'ZIF_MON_DATA_PROVIDER : 데이터 조회 공통 계약(인터페이스)'),
    (1, 'DP_BATCH / DP_DUMP / DP_INTERFACE : SM37 / ST22 / SXI 조회'),
    (1, 'CONTROLLER : 프로바이더 레지스트리·오케스트레이션'),
    (1, 'AGGREGATOR : 영역별 Top-N / 시간대별 추이 집계'),
    (1, 'UI_DASHBOARD : Splitter + 요약 + 차트(IGS) + 3분할 ALV'),
    (1, 'NAVIGATOR : 표준 상세화면 드릴다운(표시 전용) 캡슐화'),
    (0, '데이터 소스(표준)'),
    (1, 'SM37: TBTCO/TBTCP · ST22: RS_ST22_GET_DUMPS · SXI: SXMSPERROR 외'),
])

# 5. 주요 기능
add_section_slide(prs, '3. 주요 기능', [
    (0, '통합 대시보드 (단일 트랜잭션)'),
    (1, '상단: 영역별 신호등(3단계) + 건수 + 조회기간 한눈 요약'),
    (1, '중간: 영역별 개별 그래픽 차트(IGS) — Top-N 집중도 / 시간대별 추이 토글'),
    (1, '하단: SM37/ST22/SXI 3분할 ALV(영역 고정색 강조)'),
    (0, '조회·필터'),
    (1, '조회기간(기본 −24H), 영역 On/Off, 잡명/사용자/인터페이스명 필터'),
    (1, '자정 경계·타임존(UTC↔로컬) 정확 처리, 결과 상한 안내'),
    (0, '상호작용'),
    (1, '라인 더블클릭 → 해당 건 상세 로그로 직접 이동(잡로그/덤프/메시지)'),
    (1, '새로고침(REFRESH) · 자동 새로고침 · 관점 전환(TOGGLE)'),
    (0, '보안'),
    (1, '영역별 권한 체크 후 없으면 해당 영역만 스킵(타 영역 정상)'),
])

# 6. 진행 경과
add_section_slide(prs, '4. 진행 경과', [
    (0, '설계 (문서화)'),
    (1, '상세 설계서 작성 v0.1 → v0.4 (요구사항·데이터소스·화면·로직·권한·테스트)'),
    (1, 'Open Issue(O-1~O-11) 추적·확정 관리'),
    (0, '권한 객체 확정 (O-7)'),
    (1, 'STAUTHTRACE 추적 결과로 실제 체크 객체 확정'),
    (1, 'SM37 S_BTCH_JOB · ST22 S_ABAPDUMP(후보 S_ADMI_FCD 정정) · SXI S_XMB_MONI'),
    (0, '구현 (로컬 우선 방식)'),
    (1, '단일 실행형 리포트 + 로컬 클래스로 우선 검증 → 이후 글로벌 분리 예정'),
    (1, '대시보드/차트/드릴다운/새로고침 등 반복 개선(iteration)으로 완성도 향상'),
])

# 7. Cursor 활용
add_section_slide(prs, '5. Cursor(AI) 활용 방식', [
    (0, '설계 문서 자동 작성·개정'),
    (1, '설계서 구조화, 결정사항/Open Issue 반영, 버전 이력 자동 관리'),
    (0, '자료 분석 자동화'),
    (1, 'STAUTHTRACE 엑셀을 직접 파싱 → 권한 객체/필드/값 자동 도출'),
    (0, '표준 API 조사 자동화'),
    (1, '웹/문서 검색으로 표준 FM·클래스 시그니처 확인'),
    (1, 'RS_SNAP_DUMP_DISPLAY, SXMB_DISPLAY_MESSAGE_MONITOR, CL_GUI_CHART_ENGINE(XML)'),
    (0, '반복 개발 루프(설계→코딩→오류수정)'),
    (1, '구문/형식 오류를 즉시 진단·수정(파라미터명, 형식호환, IGS XML 등)'),
    (1, '전체 소스 일괄 생성·출력, 복사-붙여넣기 지원'),
    (0, '표준·규칙 자동 적용'),
    (1, '읽기전용 원칙·명명규칙을 프로젝트 규칙(Rules/Skills)으로 상시 적용'),
])

# 8. 효율성/성과
add_section_slide(prs, '6. 효율성 · 성과', [
    (0, '정성적 효과'),
    (1, '설계-구현-검토를 한 흐름으로: 문서/코드/오류대응 컨텍스트 유지'),
    (1, '표준 오브젝트(FM/권한객체) 탐색을 대화로 즉시 해결 → 리서치 부담 대폭 감소'),
    (1, '읽기전용·명명규칙 등 사내 표준을 일관 적용(휴먼 에러 감소)'),
    (1, '아키텍처(인터페이스 기반) 유지로 신규 영역 확장 용이'),
    (0, '정량적 효과(추정)'),
    (1, '설계서 작성/개정 시간 대폭 단축(수작업 대비)'),
    (1, '표준 API/파라미터 조사 시간 절감(문서 탐색 → 대화형 확인)'),
    (1, '오류 수정 사이클(원인 파악→수정) 단축, 반복 개선 회수↑'),
    (0, '산출물'),
    (1, '설계서 v0.4, 실행형 리포트 소스, 빌드 가이드(화면/상태/텍스트), 권한 확정표'),
])

# 9. 기대효과 & 향후
add_section_slide(prs, '7. 기대 효과 및 향후 계획', [
    (0, '기대 효과'),
    (1, '일일 운영 점검 시간 단축 및 점검 누락 방지'),
    (1, '에러 집중도(Top-N)·추이로 반복 원인 신속 식별'),
    (1, '읽기전용 보장으로 운영 안전성 확보'),
    (0, '향후 계획'),
    (1, '로컬 클래스 → 글로벌 오브젝트(DDIC/클래스/메시지클래스/트랜잭션) 분리'),
    (1, 'IGS 그래픽 차트 고도화(색상 규약·값 라벨), 다국어(메시지클래스) 적용'),
    (1, '자동 새로고침 관제 모드, 임계치 알림(운영 정책 검토)'),
    (1, '신규 모니터링 영역 확장(SM21/RZ20 등) — 프로바이더 추가만으로'),
])

# 10. 맺음
s = add_section_slide(prs, '맺음말', [
    (0, '요약'),
    (1, '3개 운영 영역을 단일 읽기전용 대시보드로 통합, 상세 즉시 이동 제공'),
    (1, 'Cursor(AI) 활용으로 설계·구현·검증을 가속하고 표준 준수를 강화'),
    (0, '핵심 메시지'),
    (1, '"운영 점검의 통합·자동화 + AI 페어프로그래밍으로 개발 생산성 향상"'),
])

out = 'docs/report/Y_OPS_MONITOR_V2_발표자료.pptx'
prs.save(out)
print('saved', out, len(prs.slides.__iter__.__self__._sldIdLst), 'slides')
