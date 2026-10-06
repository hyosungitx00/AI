#!/usr/bin/env python3
"""ABAP 정적 점검기 — Gate 3 자가검증 자동화.

HARNESS.md Gate 3 체크리스트와 practice/error-patterns.md 패턴을 기계 점검으로 옮긴 도구다.
AI는 코드를 사용자에게 제시하기 전에 이 스크립트를 실행하고 오류 0건을 확인한다.

사용법:
    python3 tools/abap_check.py                      # 저장소 전체 *.abap 점검
    python3 tools/abap_check.py sessions/*/code.abap # 특정 파일만
    python3 tools/abap_check.py --release classic    # ECC 호환(보수적) 문법 게이트
    python3 tools/abap_check.py --json               # 기계 판독용 출력
    python3 tools/abap_check.py --fail-on warning    # 경고도 실패로 처리

파일 단위 예외 지정(코드 안에 주석으로 기입):
    "! abap-check: ignore CHK-012 CHK-015
    "! abap-check: release classic
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ERROR = "ERROR"
WARNING = "WARNING"

HANGUL = re.compile(r"[\uac00-\ud7a3]")
PRAGMA_IGNORE = re.compile(r"abap-check:\s*ignore\s+([A-Z0-9\-,\s]+)", re.IGNORECASE)
PRAGMA_RELEASE = re.compile(r"abap-check:\s*release\s+(\w+)", re.IGNORECASE)

# 점검 규칙 사전 — ID, 기본 심각도, 근거 문서, 처방 한 줄.
RULES: dict[str, dict[str, str]] = {
    "CHK-001": {"severity": ERROR, "ref": "SKILL §3.4", "fix": "필요한 필드만 나열하는 SELECT로 바꾸십시오."},
    "CHK-002": {"severity": ERROR, "ref": "SKILL §3.4", "fix": "루프 밖에서 FOR ALL ENTRIES 또는 조인으로 선수집하십시오."},
    "CHK-003": {"severity": ERROR, "ref": "SKILL §3.4", "fix": "FOR ALL ENTRIES 앞에 `IF lt_key IS NOT INITIAL.` 체크를 넣으십시오."},
    "CHK-004": {"severity": ERROR, "ref": "SKILL §3.4", "fix": "직후에 `IF sy-subrc <> 0.` 분기(메시지 + RETURN)를 넣으십시오."},
    "CHK-005": {"severity": ERROR, "ref": "ERR-006", "fix": "코드 상단에 `TABLES <테이블>.` 선언을 추가하십시오."},
    "CHK-006": {"severity": ERROR, "ref": "SKILL §3.5", "fix": "TADIR 등록 가능한 실명(Z+모듈약어+기능)으로 바꾸십시오."},
    "CHK-007": {"severity": ERROR, "ref": "SKILL §3.2", "fix": '헤더에 `"! 기준: SAP_BASIS 750 / S/4HANA, 모던 ABAP 허용`을 적으십시오.'},
    "CHK-008": {"severity": WARNING, "ref": "SKILL §3.3", "fix": "복사 순서·DDIC 정의서·T1~T3 테스트 절차를 주석 부록으로 붙이십시오."},
    "CHK-009": {"severity": ERROR, "ref": "SKILL §3.3", "fix": "생략 표시를 지우고 완전한 소스를 제시하십시오."},
    "CHK-010": {"severity": ERROR, "ref": "SKILL §3.2", "fix": "지정 릴리스에서 허용되는 클래식 문법으로 바꾸십시오."},
    "CHK-011": {"severity": WARNING, "ref": "SKILL §3.4", "fix": "조회 리포트에서는 COMMIT을 쓰지 말고, BAPI 뒤에만 BAPI_TRANSACTION_COMMIT을 쓰십시오."},
    "CHK-012": {"severity": WARNING, "ref": "SKILL §3.4", "fix": "선택화면 파라미터나 커스텀 테이블 값으로 바꾸십시오."},
    "CHK-013": {"severity": WARNING, "ref": "SKILL §3.3", "fix": '핵심 주석을 `"! 한국어 / English` 병기로 작성하십시오.'},
    "CHK-014": {"severity": WARNING, "ref": "MSG-002", "fix": "메시지 클래스 정의서(SE91 등록값)를 주석 부록에 적거나 텍스트 리터럴로 바꾸십시오."},
    "CHK-015": {"severity": WARNING, "ref": "HARNESS §3.2", "fix": "[확인필요] 가정이 3개를 넘으면 Gate 1로 돌아가 DDIC를 확정하십시오."},
    "CHK-016": {"severity": ERROR, "ref": "MSG-001", "fix": "AUTHORITY-CHECK 직후 `IF sy-subrc <> 0.` 분기를 넣으십시오."},
    "CHK-017": {"severity": WARNING, "ref": "ERR-005", "fix": "`AT SELECTION-SCREEN`에 최소 1조건 필수·일자 범위 상한 검증을 넣으십시오."},
}

# 릴리스별 금지 문법 — 기준 750/S4는 모던 허용이므로 비어 있다.
FORBIDDEN_SYNTAX: dict[str, list[tuple[str, str]]] = {
    "750": [],
    "740": [
        (r"\bfilter\s+#\(", "FILTER #( )"),
        (r"\bcorresponding\s+#\(", "CORRESPONDING #( )"),
        (r"\breduce\s+\w+\(", "REDUCE"),
    ],
    "classic": [
        (r"\bdata\(\s*\w+\s*\)", "인라인 선언 DATA( )"),
        (r"\bfield-symbol\(\s*<\w+>\s*\)", "인라인 FIELD-SYMBOL( )"),
        (r"\bvalue\s+#\(", "VALUE #( )"),
        (r"\bcond\s+#\(", "COND #( )"),
        (r"\bswitch\s+#\(", "SWITCH #( )"),
        (r"\bfilter\s+#\(", "FILTER #( )"),
        (r"\bcorresponding\s+#\(", "CORRESPONDING #( )"),
        (r"@\w", "호스트변수 @"),
    ],
}

LOOP_OPEN = re.compile(r"^(loop\s+at|do\b|while\b)")
LOOP_CLOSE = re.compile(r"^(endloop|enddo|endwhile)\b")
# `SELECT-OPTIONS` / `SELECTION-SCREEN`을 SELECT 문으로 오인하지 않도록 구분자를 명시한다.
SELECT_STATEMENT = re.compile(r"^select(\s|$)")
BANNED_NAMES = re.compile(r"\b(ztest\w*|ztemp\w*|zzzz\w*|z_test\w*)\b")


@dataclass
class Finding:
    path: str
    line: int
    rule: str
    severity: str
    message: str

    def to_dict(self) -> dict:
        return {
            "path": self.path,
            "line": self.line,
            "rule": self.rule,
            "severity": self.severity,
            "message": self.message,
            "ref": RULES[self.rule]["ref"],
            "fix": RULES[self.rule]["fix"],
        }


@dataclass
class Statement:
    text: str  # 주석 제거 + 소문자 정규화된 1개 문장
    line: int


@dataclass
class Source:
    path: Path
    lines: list[str]
    code_lines: list[str]  # 주석을 제거한 줄 (줄 번호 유지)
    comment_text: str
    statements: list[Statement]
    ignored: set[str] = field(default_factory=set)
    release: str | None = None


def strip_comment(line: str) -> tuple[str, str]:
    """ABAP 한 줄을 (코드, 주석)으로 나눈다. 문자열 리터럴 안의 따옴표는 주석이 아니다."""
    if line[:1] == "*":
        return "", line
    in_literal = False
    for idx, char in enumerate(line):
        if char == "'":
            in_literal = not in_literal
        elif char == '"' and not in_literal:
            return line[:idx], line[idx:]
    return line, ""


def split_statements(code_lines: list[str]) -> list[Statement]:
    """마침표 기준으로 문장을 자른다. 리터럴 안의 마침표는 무시한다."""
    statements: list[Statement] = []
    buffer: list[str] = []
    start_line = 0
    in_literal = False
    for lineno, line in enumerate(code_lines, start=1):
        for char in line:
            if char == "'":
                in_literal = not in_literal
            if not buffer and char.strip():
                start_line = lineno
            if char == "." and not in_literal:
                text = " ".join("".join(buffer).split()).lower()
                if text:
                    statements.append(Statement(text=text, line=start_line or lineno))
                buffer = []
                continue
            buffer.append(char)
        buffer.append(" ")
    text = " ".join("".join(buffer).split()).lower()
    if text:
        statements.append(Statement(text=text, line=start_line))
    return statements


def load_source(path: Path) -> Source:
    raw = path.read_text(encoding="utf-8").splitlines()
    code_lines: list[str] = []
    comments: list[str] = []
    for line in raw:
        code, comment = strip_comment(line)
        code_lines.append(code)
        if comment:
            comments.append(comment)
    comment_text = "\n".join(comments)
    source = Source(
        path=path,
        lines=raw,
        code_lines=code_lines,
        comment_text=comment_text,
        statements=split_statements(code_lines),
    )
    for match in PRAGMA_IGNORE.finditer(comment_text):
        source.ignored.update(re.split(r"[,\s]+", match.group(1).strip().upper()))
    release = PRAGMA_RELEASE.search(comment_text)
    if release:
        source.release = release.group(1).lower()
    source.ignored.discard("")
    return source


DECLARATION_KEYWORD = re.compile(r"^(data|types|constants|statics|class-data|field-symbols|ranges)\b")


def declared_symbols(source: Source) -> tuple[set[str], set[str]]:
    """TABLES 선언 집합과, 프로그램 내부에서 선언된 구조·변수명 집합을 모은다.

    선언문의 `TYPE vbak-vkorg` 같은 참조형은 선언명이 아니므로 제외한다 — 포함시키면
    `TABLES` 누락(ERR-006)을 놓친다.
    """
    tables: set[str] = set()
    locals_: set[str] = set()
    for statement in source.statements:
        text = statement.text
        keyword = DECLARATION_KEYWORD.match(text)
        if text.startswith("tables"):
            body = text[len("tables") :].lstrip(": ")
            tables.update(name for name in re.split(r"[,\s]+", body) if name)
        elif keyword:
            body = text[keyword.end() :].lstrip(": ")
            for part in body.split(","):
                part = re.sub(r"^(begin|end)\s+of\s+", "", part.strip())
                name = re.match(r"<?([a-z_][\w]*)>?", part)
                if name:
                    locals_.add(name.group(1))
    return tables, locals_


def check_statements(source: Source, release: str) -> list[Finding]:
    findings: list[Finding] = []
    path = str(source.path)
    tables, locals_ = declared_symbols(source)
    loop_depth = 0
    forbidden = FORBIDDEN_SYNTAX.get(release, [])

    def add(rule: str, line: int, message: str) -> None:
        findings.append(Finding(path, line, rule, RULES[rule]["severity"], message))

    def subrc_checked(index: int, window: int = 4, extra: tuple[str, ...] = ()) -> bool:
        for follow in source.statements[index + 1 : index + 1 + window]:
            if "sy-subrc" in follow.text:
                return True
            if any(token in follow.text for token in extra):
                return True
        return False

    for index, statement in enumerate(source.statements):
        text = statement.text

        if LOOP_CLOSE.match(text):
            loop_depth = max(0, loop_depth - 1)

        if SELECT_STATEMENT.match(text):
            if re.match(r"^select\s+(single\s+)?\*", text):
                add("CHK-001", statement.line, "`SELECT *` 사용 — 전 필드 조회는 금지입니다.")
            if loop_depth > 0:
                add("CHK-002", statement.line, "루프 내부 SELECT — 건별 DB 호출은 금지입니다.")
            target = re.search(r"into\s+(?:corresponding\s+fields\s+of\s+)?table\s+@?(\w+)", text)
            extra = (f"{target.group(1)} is initial",) if target else ()
            if not subrc_checked(index, extra=extra):
                add("CHK-004", statement.line, "SELECT 직후 `SY-SUBRC` 체크가 없습니다.")
            for pattern in (r"\bbukrs\s*=\s*'", r"\bwerks\s*=\s*'", r"\bvkorg\s*=\s*'", r"\bspras\s*=\s*'"):
                if re.search(pattern, text):
                    add("CHK-012", statement.line, "WHERE 절에 회사코드·플랜트·언어가 하드코딩되어 있습니다.")
                    break

        if "for all entries in" in text:
            itab = re.search(r"for all entries in @?(\w+)", text)
            name = itab.group(1) if itab else ""
            window = source.statements[max(0, index - 12) : index]
            guarded = any(
                name and name in prev.text and ("is not initial" in prev.text or "lines(" in prev.text)
                for prev in window
            )
            if not guarded:
                add("CHK-003", statement.line, f"FOR ALL ENTRIES 앞에 `{name.upper()} IS NOT INITIAL` 체크가 없습니다.")

        if text.startswith("call function") and not subrc_checked(index, extra=("exceptions", "importing")):
            add("CHK-004", statement.line, "CALL FUNCTION 직후 `SY-SUBRC` 체크나 예외 처리가 없습니다.")

        if text.startswith("authority-check") and not subrc_checked(index, window=2):
            add("CHK-016", statement.line, "AUTHORITY-CHECK 직후 `SY-SUBRC` 체크가 없습니다.")

        dict_ref = re.match(r"^select-options\s+\w+\s+for\s+(\w+)-\w+", text) or re.match(
            r"^parameters\s+\w+\s+like\s+(\w+)-\w+", text
        )
        if dict_ref:
            owner = dict_ref.group(1)
            if owner not in tables and owner not in locals_:
                add(
                    "CHK-005",
                    statement.line,
                    f"사전 필드 `{owner.upper()}-...`를 참조하는데 `TABLES {owner}.` 선언이 없습니다.",
                )

        if re.match(r"^(report|program|function|class|function-pool)\b", text):
            banned = BANNED_NAMES.search(text)
            if banned:
                add("CHK-006", statement.line, f"임시 오브젝트명 `{banned.group(1).upper()}` 사용 — 금지입니다.")

        if text.startswith("commit work"):
            add("CHK-011", statement.line, "`COMMIT WORK` 직접 호출 — 조회 리포트에서는 금지입니다.")

        for pattern, label in forbidden:
            if re.search(pattern, text):
                add("CHK-010", statement.line, f"릴리스 `{release}`에서 금지된 문법: {label}")
                break

        if LOOP_OPEN.match(text):
            loop_depth += 1

    return findings


def check_file_level(source: Source) -> list[Finding]:
    findings: list[Finding] = []
    path = str(source.path)
    comments = source.comment_text
    body = "\n".join(source.lines)

    def add(rule: str, line: int, message: str) -> None:
        findings.append(Finding(path, line, rule, RULES[rule]["severity"], message))

    if not re.search(r"(기준|baseline)\s*:\s*sap_basis", comments, re.IGNORECASE):
        add("CHK-007", 1, "헤더에 릴리스 기준(`기준: SAP_BASIS ...`) 명시가 없습니다.")

    missing = [
        label
        for label, pattern in (
            ("복사 순서", r"복사\s*순서|copy\s*order"),
            ("DDIC 정의서", r"ddic"),
            ("테스트 절차(T1)", r"\bt1\b"),
        )
        if not re.search(pattern, comments, re.IGNORECASE)
    ]
    if missing:
        add("CHK-008", 1, "복붙 계약 부록 누락: " + ", ".join(missing))

    for lineno, line in enumerate(source.lines, start=1):
        if re.search(r"(이하\s*동일|이하\s*생략|…\s*생략|\.\.\.\s*생략|코드\s*생략)", line):
            add("CHK-009", lineno, "생략 플레이스홀더 발견 — 완전 소스만 허용됩니다.")

    comment_lines = [line for line in comments.splitlines() if HANGUL.search(line)]
    bilingual = [line for line in comment_lines if "/" in line and re.search(r"[A-Za-z]{3}", line)]
    if not bilingual:
        add("CHK-013", 1, "한국어+영문 병기 주석이 없습니다.")

    for match in re.finditer(r"message\s+[aeiswx]\d{3}\((\w+)\)", body, re.IGNORECASE):
        klass = match.group(1)
        if not re.search(rf"(se91|{re.escape(klass)})", comments, re.IGNORECASE):
            line = body[: match.start()].count("\n") + 1
            add("CHK-014", line, f"메시지 클래스 `{klass.upper()}` 정의서가 주석 부록에 없습니다.")
            break

    assumptions = len(re.findall(r"확인필요", body))
    if assumptions > 3:
        add("CHK-015", 1, f"[확인필요] DDIC 가정이 {assumptions}건 — 3건 초과입니다.")

    if re.search(r"^\s*select-options\b", body, re.IGNORECASE | re.MULTILINE) and not re.search(
        r"at selection-screen", body, re.IGNORECASE
    ):
        add("CHK-017", 1, "선택화면이 있는데 `AT SELECTION-SCREEN` 입력 검증이 없습니다.")

    return findings


def check_source(path: Path, release: str) -> list[Finding]:
    source = load_source(path)
    effective_release = source.release or release
    findings = check_file_level(source) + check_statements(source, effective_release)
    findings = [item for item in findings if item.rule not in source.ignored]
    return sorted(findings, key=lambda item: (item.path, item.line, item.rule))


def collect_paths(targets: list[str]) -> list[Path]:
    paths: list[Path] = []
    roots = [Path(target) for target in targets] if targets else [Path(".")]
    for root in roots:
        if root.is_dir():
            paths.extend(sorted(p for p in root.rglob("*.abap") if ".git" not in p.parts))
        elif root.is_file():
            paths.append(root)
        else:
            print(f"[경고] 경로를 찾을 수 없습니다: {root}", file=sys.stderr)
    return paths


def render(findings: list[Finding], paths: list[Path], quiet: bool) -> None:
    by_path: dict[str, list[Finding]] = {}
    for finding in findings:
        by_path.setdefault(finding.path, []).append(finding)

    for path in paths:
        items = by_path.get(str(path), [])
        if not items:
            if not quiet:
                print(f"[OK] {path}")
            continue
        print(f"[점검] {path}")
        for item in items:
            rule = RULES[item.rule]
            print(f"  {item.severity:<7} L{item.line:<5} {item.rule}  {item.message}")
            print(f"  {'':<7} {'':<6} 근거 {rule['ref']} · 처방: {rule['fix']}")

    errors = sum(1 for item in findings if item.severity == ERROR)
    warnings = sum(1 for item in findings if item.severity == WARNING)
    print(f"\n요약: 파일 {len(paths)}개 · 오류 {errors}건 · 경고 {warnings}건")
    if errors:
        print("Gate 3 미통과 — 오류 0건이 될 때까지 코드를 사용자에게 제시하지 마십시오.")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="ABAP 정적 점검기 (Gate 3 자가검증 자동화)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("targets", nargs="*", help="점검할 파일·폴더 (기본: 저장소 전체)")
    parser.add_argument(
        "--release",
        choices=sorted(FORBIDDEN_SYNTAX),
        default="750",
        help="문법 게이트 기준 릴리스 (기본 750 = 모던 허용)",
    )
    parser.add_argument("--json", action="store_true", help="JSON으로 출력")
    parser.add_argument("--quiet", action="store_true", help="문제 없는 파일은 출력하지 않음")
    parser.add_argument(
        "--fail-on",
        choices=["error", "warning", "never"],
        default="error",
        help="종료코드 1을 반환할 기준 (기본 error)",
    )
    args = parser.parse_args(argv)

    paths = collect_paths(args.targets)
    if not paths:
        print("점검할 .abap 파일이 없습니다.", file=sys.stderr)
        return 0

    findings: list[Finding] = []
    for path in paths:
        findings.extend(check_source(path, args.release))

    if args.json:
        print(
            json.dumps(
                {
                    "files": [str(path) for path in paths],
                    "release": args.release,
                    "findings": [finding.to_dict() for finding in findings],
                    "summary": {
                        "files": len(paths),
                        "errors": sum(1 for item in findings if item.severity == ERROR),
                        "warnings": sum(1 for item in findings if item.severity == WARNING),
                    },
                },
                ensure_ascii=False,
                indent=2,
            )
        )
    else:
        render(findings, paths, args.quiet)

    if args.fail_on == "never":
        return 0
    if args.fail_on == "warning" and findings:
        return 1
    if any(item.severity == ERROR for item in findings):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
