---
name: creating-pr
description: Package ABAP work into a clean, review-ready pull request — conventional title, structured summary/changes/test-plan body, transported-object list, read-only self-review, and linked design-doc decisions.
user-invocable: true
---

# Creating a PR (ABAP)

Package work so a reviewer can verify read-only safety and design conformance fast.

## 1. Prepare the branch

```bash
git fetch origin
git log origin/<base>..HEAD --oneline
git diff origin/<base> --stat
```

Keep logical commits separate (one change each). Branch names use the project
prefix/suffix convention.

## 2. Title

`<type>: <short description>` (see `writing-commit-messages` for types), matching
the surrounding language. Examples:
- `feat: SXI 인터페이스 에러 프로바이더(ZCL_MON_DP_INTERFACE) 추가`
- `docs: 통합 운영 모니터링 설계서 O-6~O-11 확정 반영`

## 3. Description

```markdown
## 요약 (Summary)
1–3문장: 무엇을, 왜.

관련 결정: O-#, FR-##

## 변경 사항 (Changes)
- 추가/변경된 오브젝트와 핵심 로직

## 오브젝트 목록 (Transport)
- Report/Class/Interface/DDIC/Screen/Transaction/Message class 목록

## 테스트 계획 (Test Plan)
- [ ] TC-## … (기본 24H 조회, 자정 경계, 권한 스킵, 읽기전용 검수 등)
```

## 4. Self-review before requesting review

- Read every line of the diff.
- **Read-only scan:** confirm no `INSERT/UPDATE/MODIFY/DELETE`, `COMMIT WORK`,
  `ENQUEUE_*`, `IN UPDATE TASK`, state-changing FMs, or edit-mode
  `CALL TRANSACTION` (see `abap-read-only-monitoring`).
- Run the `abap-code-review` checklist (correctness, perf, auth, Clean ABAP).
- Confirm the **design doc** (`docs/design/`) reflects any decisions changed here;
  update Open Issues / change history if needed.
- Remove leftover debug (`BREAK-POINT`, `WRITE` debug, commented-out code).

## 5. Create / update

Push the branch and open (or update) the PR against the base branch. Prefer small
PRs (<~300 changed lines); for larger ones, note the best file review order.
Use draft until ready for review.

## Tips

- Screenshots/mockups for screen (dynpro/ALV/chart) changes speed up review.
- Link the specific `O-#`/`FR-##`/`TC-##` this PR resolves.
- Note any `TODO: SU24/STAUTHTRACE 검증` items still pending verification.
