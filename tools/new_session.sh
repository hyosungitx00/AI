#!/usr/bin/env bash
# 세션 폴더 스캐폴딩 — sessions/README.md 규칙(1건 1폴더, 빈 파일 금지)대로 준비한다.
# 사용법: tools/new_session.sh <프로그램명> [YYYYMMDD]
set -euo pipefail

if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
  cat <<'USAGE'
사용법: tools/new_session.sh <프로그램명> [YYYYMMDD]

예시:
  tools/new_session.sh ZSD_SALES_ALV01
  tools/new_session.sh ZSD_SALES_ALV01 20261006

하는 일:
  1. sessions/<날짜>-<프로그램명>/ 폴더 생성
  2. 00-intake.filled.md (인터뷰 답변 기록용) 생성 — 나머지 파일은 각 게이트 통과 시 만든다
  3. 다음 단계 안내 출력
USAGE
  exit 0
fi

PROGRAM="$(printf '%s' "$1" | tr '[:lower:]' '[:upper:]')"
DATE="${2:-$(date +%Y%m%d)}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$ROOT/sessions/$DATE-$PROGRAM"

if [[ ! "$PROGRAM" =~ ^[YZ][A-Z0-9_]+$ ]]; then
  echo "오류: 프로그램명은 Y/Z로 시작하는 실명이어야 합니다 (입력: $PROGRAM)" >&2
  exit 1
fi
if [[ "$PROGRAM" =~ ^Z(TEST|TEMP|ZZZ) ]]; then
  echo "오류: ZTEST/ZTEMP/ZZZZ 같은 임시명은 금지입니다 (SKILL §3.5)" >&2
  exit 1
fi
if [[ ! "$DATE" =~ ^[0-9]{8}$ ]]; then
  echo "오류: 날짜는 YYYYMMDD 형식이어야 합니다 (입력: $DATE)" >&2
  exit 1
fi
if [[ -d "$DIR" ]]; then
  echo "오류: 이미 존재하는 세션 폴더입니다 — $DIR" >&2
  exit 1
fi

mkdir -p "$DIR"
cat > "$DIR/00-intake.filled.md" <<EOF
# 접수 기록 — $PROGRAM ($DATE)

> 인터뷰(I-0~I-8) 답변 정리본. 자유 텍스트·파일 접수는 받지 않는다 (인터뷰 전용).
> 사용자가 \`[모름]\`·\`건너뛰기\`로 답한 칸은 \`[추정]\` 표시와 함께 AI 제안을 적는다.

## I-0 접수

- 신규/변경:
- 화면 데모: [ ] 있음(경로A) [ ] 없음-AI 생성(경로B)
- 희망 유형:

## I-1 한 줄 요약

- 목적:
- 사용자·빈도:
- 기존 대체:

## I-2 핵심 기능

1.
2.

## I-3 입력 조건

- 입력 항목:
- 기본값:
- 입력 검증:

## I-4 출력 형태

- 출력 형태:
- 출력 항목:
- 출력 동작:

## I-6 데이터·기존 정보

- 후보 테이블:
- 조인·조건:
- 기존 함수:

## I-7 권한·예외·제약

- 권한 오브젝트:
- 0건·실패 시:
- 개인정보·제약:

## I-8 테스트값

- T1 정상:
- T2 0건:
- T3 권한·검증:

## 게이트 진행 기록

| 게이트 | 산출물 | 상태 |
|---|---|---|
| Gate U 이해도 | (답변 안에 기재) | 대기 |
| Gate D 화면 | \`08-demo.filled.md\` + \`demo-s1/s2.png\` | 대기 |
| Gate F 필드·구현 | \`09-fieldmap.filled.md\` | 대기 |
| Gate 2 스펙 | \`spec.md\` | 대기 |
| Gate 3 코드 | \`code.abap\` (+ \`abap_check\` 오류 0건) | 대기 |
| Gate 4 Verify | \`verify.md\` (+ 오류 시 \`errors.md\`) | 대기 |
| Handover | \`handover.md\` | 대기 |
EOF

cat <<EOF
세션 폴더를 만들었습니다: sessions/$DATE-$PROGRAM/
  - 00-intake.filled.md (인터뷰 답변 기록용)

다음 단계:
  1. 인터뷰(I-0~I-8) 답변을 00-intake.filled.md에 채운다 — harness/prompts/interview-script.md
  2. Gate U 이해도 확인 → Gate D(08-demo) → Gate F(09-fieldmap) → Gate 2(spec.md) 순으로
     게이트를 통과할 때마다 해당 파일을 추가한다 (빈 파일은 만들지 않는다).
  3. Gate 3 코드는 templates/abap/ 골격을 복제해 작성하고, 제시 전에 점검한다:
       python3 tools/abap_check.py sessions/$DATE-$PROGRAM/code.abap
EOF
