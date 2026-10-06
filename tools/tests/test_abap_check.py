#!/usr/bin/env python3
"""abap_check 자체 테스트 — 외부 의존성 없이 `python3 tools/tests/test_abap_check.py`로 실행한다."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools"))

import abap_check  # noqa: E402

FIXTURES = Path(__file__).resolve().parent / "fixtures"
failures: list[str] = []


def rules_of(path: Path, release: str = "750") -> set[str]:
    return {finding.rule for finding in abap_check.check_source(path, release)}


def expect(condition: bool, label: str) -> None:
    if condition:
        print(f"  PASS  {label}")
    else:
        print(f"  FAIL  {label}")
        failures.append(label)


def test_bad_report_detects_every_rule() -> None:
    print("불량 샘플(bad_report.abap) 탐지")
    found = rules_of(FIXTURES / "bad_report.abap")
    expected = {
        "CHK-001",  # SELECT *
        "CHK-002",  # 루프 내 SELECT
        "CHK-003",  # FOR ALL ENTRIES 빈 체크 누락
        "CHK-004",  # SY-SUBRC 누락
        "CHK-005",  # TABLES 선언 누락 (ERR-006)
        "CHK-006",  # ZTEST 금지명
        "CHK-007",  # 릴리스 기준 헤더 누락
        "CHK-008",  # 복붙 계약 부록 누락
        "CHK-009",  # 생략 플레이스홀더
        "CHK-011",  # COMMIT WORK
        "CHK-012",  # WHERE 하드코딩
        "CHK-013",  # 한+영 병기 주석 없음
        "CHK-014",  # 메시지 클래스 정의서 없음
        "CHK-016",  # AUTHORITY-CHECK 후 SY-SUBRC 누락
        "CHK-017",  # AT SELECTION-SCREEN 검증 없음
    }
    for rule in sorted(expected):
        expect(rule in found, f"{rule} 탐지")


def test_good_report_is_clean() -> None:
    print("정상 샘플(good_report.abap) 무결성")
    found = rules_of(FIXTURES / "good_report.abap")
    expect(not found, f"지적 0건 (실제: {sorted(found) or '없음'})")


def test_release_gate() -> None:
    print("릴리스 게이트")
    modern = rules_of(FIXTURES / "good_report.abap", release="750")
    classic = rules_of(FIXTURES / "good_report.abap", release="classic")
    expect("CHK-010" not in modern, "750에서는 모던 문법 허용")
    expect("CHK-010" in classic, "classic에서는 모던 문법 차단")


def test_repo_abap_has_no_errors() -> None:
    print("저장소 ABAP 산출물 오류 0건")
    paths = abap_check.collect_paths([str(ROOT / "examples"), str(ROOT / "templates"), str(ROOT / "sessions")])
    expect(bool(paths), "점검 대상 파일 존재")
    for path in paths:
        errors = [f for f in abap_check.check_source(path, "750") if f.severity == abap_check.ERROR]
        detail = ", ".join(f"L{f.line} {f.rule}" for f in errors) or "없음"
        expect(not errors, f"{path.relative_to(ROOT)} 오류 없음 ({detail})")


def test_line_numbers_point_at_statement_start() -> None:
    print("오류 위치는 문장 시작 줄")
    findings = abap_check.check_source(FIXTURES / "bad_report.abap", "750")
    located = {(f.rule, f.line) for f in findings}
    expect(("CHK-005", 3) in located, "CHK-005 → L3 (SELECT-OPTIONS 줄)")
    expect(("CHK-001", 6) in located, "CHK-001 → L6 (SELECT * 줄)")
    expect(("CHK-002", 10) in located, "CHK-002 → L10 (루프 내 SELECT 줄)")


def test_fixtures_excluded_from_directory_scan() -> None:
    print("폴더 스캔은 불량 픽스처를 건너뜀")
    scanned = abap_check.collect_paths([])
    expect(
        all("fixtures" not in path.parts for path in scanned),
        "기본 스캔에 fixtures 미포함",
    )
    direct = abap_check.collect_paths([str(FIXTURES / "bad_report.abap")])
    expect(len(direct) == 1, "파일 직접 지정 시에는 픽스처도 점검")


def test_pragma_ignore() -> None:
    print("파일 단위 예외(pragma)")
    source = abap_check.load_source(FIXTURES / "bad_report.abap")
    expect(not source.ignored, "불량 샘플에는 예외 지정 없음")
    pragma = abap_check.load_source(FIXTURES / "good_report.abap")
    expect(pragma.release is None, "정상 샘플에는 릴리스 pragma 없음")


def main() -> int:
    for test in (
        test_bad_report_detects_every_rule,
        test_good_report_is_clean,
        test_line_numbers_point_at_statement_start,
        test_release_gate,
        test_fixtures_excluded_from_directory_scan,
        test_pragma_ignore,
        test_repo_abap_has_no_errors,
    ):
        test()
    print()
    if failures:
        print(f"실패 {len(failures)}건: {failures}")
        return 1
    print("전체 통과")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
