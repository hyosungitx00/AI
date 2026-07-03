---
name: writing-commit-messages
description: Write clear Conventional-Commit-style messages matching this repo's history (type prefix + concise subject), one logical change per commit, in the surrounding language (Korean docs use Korean subjects).
user-invocable: true
---

# Writing Commit Messages

Match this repository's existing convention: a Conventional-Commit type prefix
followed by a concise, informative subject (Korean is used for doc commits here).

## Format

```
<type>: <subject>

<optional body — why, not what>

<optional footer>
```

### Types

| Type | When |
|------|------|
| `feat` | New object/feature (report, class, provider, screen) |
| `fix` | Bug fix (wrong criteria, timezone/boundary, dump) |
| `refactor` | Restructure without behavior change (extract class, dedupe) |
| `docs` | Design doc / README / comments only |
| `perf` | Query/loop performance improvement |
| `test` | Test scenarios / unit tests |
| `chore` | Tooling, structure, non-code housekeeping |

### Subject rules

- One logical change per commit — don't mix a refactor with a feature.
- Concise and specific; state the scope and what changed.
- Match the surrounding language: doc changes in this repo are written in Korean
  (e.g. `docs: O-6 신호등 임계치 확정 반영`). Code commits may use Korean or English
  consistently with the object.
- Reference decision IDs where relevant (`O-#`, `FR-##`).

## Body (when needed)

Explain **why** and cross-reference decisions/Open Issues:

```
refactor: 기간 필터 로직 공통 유틸(build_datetime_range)로 단일화

SM37/ST22가 각각 자정 경계 처리를 중복 구현하고 있어 버그 위험이 있었다.
공통 유틸로 통합하여 O-1/O-11 확정 로직을 한 곳에서 유지한다.
```

## Examples (repo style)

Good:
```
docs: ST22 조회 방식을 RS_ST22_GET_DUMPS로 변경(O-3 갱신/O-11)
feat: ZCL_MON_DP_INTERFACE 추가 — SXMSPERROR 기준 SXI 에러 조회
fix: SXI 기간 필터 로컬→UTC 변환 누락 수정
refactor: 드릴다운 호출을 ZCL_MON_NAVIGATOR로 캡슐화
```

Bad:
```
update
wip
fixed stuff
변경
```

## Rules

- Each commit = one logical change; commit before switching from build to test.
- No half-working commits; don't bundle unrelated edits.
- Do not amend/force-push shared history unless explicitly asked.
