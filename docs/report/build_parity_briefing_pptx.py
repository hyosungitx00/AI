# -*- coding: utf-8 -*-
"""Parity / Skills 실험 결과 발표자료 생성 (로컬 다운로드용)."""
from __future__ import annotations

from pathlib import Path

from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.util import Inches, Pt, Emu

HERE = Path(__file__).resolve().parent
OUT = HERE / "Cursor_ABAP_Skills_Parity_발표자료.pptx"
ART = Path("/opt/cursor/artifacts")
ART.mkdir(parents=True, exist_ok=True)

NAVY = RGBColor(0x0B, 0x1F, 0x3A)
ACCENT = RGBColor(0xC4, 0x5C, 0x26)  # terracotta avoided? user said avoid terracotta+cream - use steel blue accent
ACCENT = RGBColor(0x1F, 0x6F, 0x8B)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
DARK = RGBColor(0x1A, 0x1A, 0x1A)
MUTED = RGBColor(0x5A, 0x5A, 0x5A)
LIGHT = RGBColor(0xF2, 0xF5, 0xF8)
GREEN = RGBColor(0x1B, 0x7F, 0x4E)
RED = RGBColor(0xB0, 0x3A, 0x2E)


def set_run(p, text, size=18, bold=False, color=DARK, font="Malgun Gothic"):
    p.clear()
    r = p.add_run()
    r.text = text
    r.font.size = Pt(size)
    r.font.bold = bold
    r.font.color.rgb = color
    r.font.name = font
    return r


def add_bg(slide, prs, color=LIGHT):
    shape = slide.shapes.add_shape(
        1, Emu(0), Emu(0), prs.slide_width, prs.slide_height  # rectangle
    )
    shape.fill.solid()
    shape.fill.fore_color.rgb = color
    shape.line.fill.background()
    # send to back
    spTree = slide.shapes._spTree
    sp = shape._element
    spTree.remove(sp)
    spTree.insert(2, sp)


def add_header_bar(slide, prs):
    bar = slide.shapes.add_shape(1, Emu(0), Emu(0), prs.slide_width, Inches(0.7))
    bar.fill.solid()
    bar.fill.fore_color.rgb = NAVY
    bar.line.fill.background()


def add_title(slide, text, top=0.85, size=28):
    box = slide.shapes.add_textbox(Inches(0.6), Inches(top), Inches(12.2), Inches(0.7))
    tf = box.text_frame
    tf.word_wrap = True
    set_run(tf.paragraphs[0], text, size=size, bold=True, color=NAVY)


def add_bullets(slide, lines, left=0.7, top=1.7, width=12, height=5, size=16):
    box = slide.shapes.add_textbox(Inches(left), Inches(top), Inches(width), Inches(height))
    tf = box.text_frame
    tf.word_wrap = True
    first = True
    for line in lines:
        p = tf.paragraphs[0] if first else tf.add_paragraph()
        first = False
        p.level = 0
        p.space_after = Pt(8)
        set_run(p, line, size=size, color=DARK)


def add_footer(slide, page, total):
    box = slide.shapes.add_textbox(Inches(0.6), Inches(6.9), Inches(12), Inches(0.3))
    set_run(box.text_frame.paragraphs[0], f"Cursor × ABAP Skills 실험  |  {page}/{total}", size=10, color=MUTED)


def add_table(slide, rows, left, top, width, height, col_w=None):
    cols = len(rows[0])
    rcount = len(rows)
    table = slide.shapes.add_table(rcount, cols, Inches(left), Inches(top), Inches(width), Inches(height)).table
    if col_w:
        for i, w in enumerate(col_w):
            table.columns[i].width = Inches(w)
    for ri, row in enumerate(rows):
        for ci, val in enumerate(row):
            cell = table.cell(ri, ci)
            cell.text = str(val)
            for p in cell.text_frame.paragraphs:
                for run in p.runs:
                    run.font.size = Pt(11 if ri else 12)
                    run.font.bold = ri == 0
                    run.font.name = "Malgun Gothic"
                    run.font.color.rgb = WHITE if ri == 0 else DARK
            cell.fill.solid()
            cell.fill.fore_color.rgb = NAVY if ri == 0 else (RGBColor(0xE8, 0xEE, 0xF3) if ri % 2 == 0 else WHITE)
    return table


def build():
    prs = Presentation()
    prs.slide_width = Inches(13.333)
    prs.slide_height = Inches(7.5)
    blank = prs.slide_layouts[6]
    slides_meta = []

    # 1 Title
    s = prs.slides.add_slide(blank)
    add_bg(s, prs, NAVY)
    box = s.shapes.add_textbox(Inches(0.8), Inches(2.0), Inches(11.5), Inches(1))
    set_run(box.text_frame.paragraphs[0], "ABAP 개발에 Cursor Skills를 적용하면", size=20, color=RGBColor(0xA8, 0xC5, 0xD8))
    box2 = s.shapes.add_textbox(Inches(0.8), Inches(2.6), Inches(11.5), Inches(1.4))
    set_run(box2.text_frame.paragraphs[0], "질문·오류는 줄고, 품질은 유지되는가?", size=32, bold=True, color=WHITE)
    box3 = s.shapes.add_textbox(Inches(0.8), Inches(4.4), Inches(11.5), Inches(1))
    set_run(
        box3.text_frame.paragraphs[0],
        "Ops Monitor (SM37/ST22/SXI) 동일 설계서 재현 실험\nSession A(장기 구현+Skills 정착) vs Session B(Greenfield 재현)",
        size=16,
        color=RGBColor(0xD0, 0xDC, 0xE8),
    )
    slides_meta.append(s)

    # 2 Agenda
    s = prs.slides.add_slide(blank)
    add_bg(s, prs)
    add_header_bar(s, prs)
    add_title(s, "목차")
    add_bullets(
        s,
        [
            "1. 실험 구조 — 두 세션의 관계",
            "2. Skills로 무엇을 고착했는가",
            "3. ‘만족할 때까지 질문 수’의 한계",
            "4. 품질 동등성(Parity) 채점표 · Hard Gate",
            "5. 최종 점수 & 질문 수에 따른 향상 곡선",
            "6. 일반화 한계와 다음 단계",
            "7. 보고용 결론",
        ],
    )
    slides_meta.append(s)

    # 3 Experiment structure
    s = prs.slides.add_slide(blank)
    add_bg(s, prs)
    add_header_bar(s, prs)
    add_title(s, "1. 실험 구조 — 두 세션의 관계")
    add_table(
        s,
        [
            ["구분", "Session A", "Session B"],
            ["이름", "Awesome skills automation", "통합 운영 모니터링 대시보드"],
            ["성격", "장기 구현 → 오류/UX 루프 → Skills 작성", "설계서+Skills만으로 Greenfield 재구현"],
            ["산출", "Y_OPS_MONITOR_V2 + skills/rules", "동일 프로그램 재생성 + scorecard"],
            ["공정 Q", "≈63 (프로그램 관련)", "≈16"],
        ],
        0.6,
        1.7,
        12.1,
        3.2,
        [2.2, 5.0, 4.9],
    )
    add_bullets(
        s,
        ["인과: A의 실패 패턴을 Skill/Rule로 고착 → B에서 동일 설계서를 더 짧은 과정으로 재현"],
        top=5.2,
        size=15,
    )
    slides_meta.append(s)

    # 4 What was added
    s = prs.slides.add_slide(blank)
    add_bg(s, prs)
    add_header_bar(s, prs)
    add_title(s, "2. Skills로 무엇을 고착했는가")
    add_bullets(
        s,
        [
            "Always-on Rules: 읽기전용 불변 · SE38 붙여넣기 · 선언+구현 동시",
            "abap-activation-preflight: 세션 실패 → P1~P10 정적 점검 (선언누락, ECC fcode, CSS {}, 타입…)",
            "abap-ops-monitor-ux: HTML 차트/STATS·HELP · 영역색 · ALV 최소 툴바",
            "abap-requirement-intake: 모호한 UX 요청을 ≤8 선택지로 한 번 계약",
            "가이드/템플릿: 최소 프롬프트 · Replay 테스트 · Parity 채점표",
        ],
        size=15,
    )
    slides_meta.append(s)

    # 5 Problem with Q count
    s = prs.slides.add_slide(blank)
    add_bg(s, prs)
    add_header_bar(s, prs)
    add_title(s, "3. ‘만족할 때까지 질문 수’만으로는 객관적이지 않음")
    add_bullets(
        s,
        [
            "문제: 사용자가 그만둔 시점이 곧 ‘품질 달성’이 됨 → 채점 기준이 주관적",
            "해결: 품질(Parity)과 과정(질문·오류 수)을 분리 측정",
            "품질 = 동일 설계서 대비 채점표 점수 (만점 56)",
            "과정 = cum_Q_program / E_compile / E_runtime (효율 지표)",
            "DoD(완료정의)도 내부 체크리스트일 뿐, 외부 공인 지표가 아님 → Parity로 대체·보완",
        ],
        size=15,
    )
    slides_meta.append(s)

    # 6 Rubric
    s = prs.slides.add_slide(blank)
    add_bg(s, prs)
    add_header_bar(s, prs)
    add_title(s, "4. Parity 채점표 (56점) + Hard Gate")
    add_table(
        s,
        [
            ["섹션", "만점", "내용"],
            ["S1 기능", "20", "FR: 3영역 조회·대시보드·기간·On/Off·드릴다운·권한…"],
            ["S2 안전", "12", "읽기전용·표준오브젝트·모듈화·활성화"],
            ["S3 UX 바", "16", "HTML차트·영역색·스케일·STATS/HELP·ALV툴바"],
            ["S4 전달", "8", "붙여넣기 소스·Dynpro가이드·선언완비·Selection texts"],
        ],
        0.6,
        1.6,
        12.1,
        2.6,
        [2.5, 1.2, 8.4],
    )
    add_bullets(
        s,
        [
            "PASS = Total≥50 AND 차단 결함 0건 AND 활성화 성공(S2-06=2)",
            "차단 예: 문법 오류, 빈 화면, 팝업 X 불능, 필수 영역 조회 버그, 드릴다운 불능",
            "코드만 있고 미실기 → Total 상한 40 (코드 ≠ 동작)",
        ],
        top=4.5,
        size=14,
    )
    slides_meta.append(s)

    # 7 Final scores
    s = prs.slides.add_slide(blank)
    add_bg(s, prs)
    add_header_bar(s, prs)
    add_title(s, "5-1. 최종 품질 — 동등 (A 54 / B 55)")
    add_table(
        s,
        [
            ["지표", "Session A", "Session B"],
            ["Parity 총점 (/56)", "54", "55"],
            ["등급", "PASS", "PASS"],
            ["|A−B|", "1 → 품질 동등", ""],
            ["공정 Q (프로그램)", "≈63", "≈16"],
            ["E_compile (첨부)", "~18+", "2"],
            ["첫 PASS 도달 Q (Hard Gate)", "≈57", "≈12"],
        ],
        0.6,
        1.7,
        12.1,
        4.0,
        [4.0, 4.0, 4.1],
    )
    slides_meta.append(s)

    # 8 Curve correction
    s = prs.slides.add_slide(blank)
    add_bg(s, prs)
    add_header_bar(s, prs)
    add_title(s, "5-2. 질문 수에 따른 Parity 향상 (Hard Gate 보정)")
    add_bullets(
        s,
        [
            "잘못된 채점: B Q=1을 ‘소스에 HTML 있음’만으로 ~44점·조기 PASS처럼 처리",
            "올바른 채점: 활성화 전·팝업X 불능·ST22 0건(버그) 구간은 FAIL/PARTIAL",
            "B 실제 곡선: Q1=30(FAIL) → Q7 팝업/ST22 차단 → Q12=53(첫 PASS) → Q16=55",
            "A 실제 곡선: 천천히 상승, IGS/타입 오류로 정체 → Q≈57에서 첫 PASS → 최종 54",
            "효율: 첫 PASS까지 pt/Q  ≈ 0.89(A) vs ≈4.4(B)  — 같은 바, 더 짧은 과정",
        ],
        size=15,
    )
    slides_meta.append(s)

    # 9 Side by side Q
    s = prs.slides.add_slide(blank)
    add_bg(s, prs)
    add_header_bar(s, prs)
    add_title(s, "5-3. 동일 질문 수에서 본 점수")
    add_table(
        s,
        [
            ["cum_Q", "A Total", "A 등급", "B Total", "B 등급"],
            ["1", "0", "FAIL", "30", "FAIL"],
            ["5", "~2", "FAIL", "40", "FAIL"],
            ["10", "~30", "FAIL", "47", "PARTIAL"],
            ["12", "~31", "FAIL", "53", "PASS"],
            ["16", "~33", "FAIL", "55", "PASS"],
            ["57", "51", "PASS", "—", "—"],
            ["63", "54", "PASS", "—", "—"],
        ],
        0.6,
        1.6,
        12.1,
        4.4,
        [2.0, 2.4, 2.4, 2.4, 2.9],
    )
    slides_meta.append(s)

    # 10 Generalization
    s = prs.slides.add_slide(blank)
    add_bg(s, prs)
    add_header_bar(s, prs)
    add_title(s, "6. 일반화 — 추정은 맞지만, 범위가 있다")
    add_bullets(
        s,
        [
            "큰 효과의 상당 부분 = 동일 설계서·동일 프로그램 유형의 오류를 목록화한 결과",
            "Preflight의 ~70%는 다른 ALV/HTML/OO 리포트에도 전이 가능 (선언, ECC fcode, CSS {})",
            "UX/도메인 스킬의 ~80%+는 Ops Monitor(SM37/ST22/SXI) 특화",
            "다른 형식 프로그램이면 특화 규칙이 약해져 오류·질문이 다시 늘 가능성 (유형 n=1)",
            "다양한 프로그램 대화를 쌓아 실패→규칙으로 승격할수록 일반 효과가 커짐",
        ],
        size=15,
    )
    slides_meta.append(s)

    # 11 Conclusion
    s = prs.slides.add_slide(blank)
    add_bg(s, prs)
    add_header_bar(s, prs)
    add_title(s, "7. 보고용 결론")
    add_bullets(
        s,
        [
            "① 품질: 동일 Parity 채점표로 A=54, B=55 (Δ=1) → 유사 수준으로 생성됨",
            "② 과정: Hard Gate 기준 첫 PASS Q ≈57(A) → ≈12(B), 공정 질문 ≈63→16",
            "③ 방법: 실패를 Skill/Rule로 고착하면 같은/유사 유형의 왕복이 크게 감소",
            "④ 한계: ‘처음부터 완벽’이 아님. 활성화·런타임 결함 구간은 PASS 불가",
            "⑤ 확장: 다른 ABAP 유형 실험으로 일반화 가설을 숫자로 검증할 차례",
        ],
        size=16,
    )
    slides_meta.append(s)

    # 12 Closing
    s = prs.slides.add_slide(blank)
    add_bg(s, prs, NAVY)
    box = s.shapes.add_textbox(Inches(0.8), Inches(2.6), Inches(11.5), Inches(1.2))
    set_run(box.text_frame.paragraphs[0], "실패를 규칙으로 축적하면,\n같은 목표를 더 짧은 대화로 달성할 수 있다.", size=26, bold=True, color=WHITE)
    box2 = s.shapes.add_textbox(Inches(0.8), Inches(4.5), Inches(11.5), Inches(0.8))
    set_run(box2.text_frame.paragraphs[0], "단, 동작 검증(Hard Gate) 없는 점수는 신뢰하지 않는다.", size=16, color=RGBColor(0xA8, 0xC5, 0xD8))
    slides_meta.append(s)

    total = len(slides_meta)
    for i, sl in enumerate(slides_meta, 1):
        if i == 1 or i == total:
            continue
        add_footer(sl, i, total)

    prs.save(OUT)
    dest = ART / OUT.name
    dest.write_bytes(OUT.read_bytes())
    print(f"Wrote {OUT}")
    print(f"Wrote {dest}")
    return OUT, dest


if __name__ == "__main__":
    build()
