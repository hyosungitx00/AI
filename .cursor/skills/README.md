# Agent Skills — SAP ECC/S4HANA ABAP

On-demand `SKILL.md` playbooks for this read-only ops-monitoring ABAP project.
Cursor auto-discovers these; the agent should apply the relevant one during
implementation, review, refactoring, and documentation. Always-on conventions live
in `.cursor/rules/` (`abap-project-conventions`, `abap-delivery-preferences`).

Each skill is a `SKILL.md` with YAML frontmatter (`name`, `description`,
`user-invocable`) plus a structured, step-by-step playbook.

**최소 질문으로 고퀄리티 받기:**
[`docs/guides/high-quality-abap-minimal-prompts.md`](../../docs/guides/high-quality-abap-minimal-prompts.md)
· 브리프 템플릿:
[`docs/templates/ops-monitor-request-brief.md`](../../docs/templates/ops-monitor-request-brief.md)

## Skills

| Skill | Use for | Phase |
|-------|---------|-------|
| [`abap-requirement-intake`](abap-requirement-intake/SKILL.md) | Vague requests: ask ≤8 choices once, state Build Contract, then code | Intake |
| [`abap-ops-monitor-ux`](abap-ops-monitor-ux/SKILL.md) | Dashboard/chart/STATS/HELP/ALV polish at demo quality on first delivery | Implementation |
| [`abap-read-only-monitoring`](abap-read-only-monitoring/SKILL.md) | Build/extend read-only monitoring with mutation guardrails, bounded standard-table queries, display-only drill-downs | Implementation |
| [`abap-clean-oo`](abap-clean-oo/SKILL.md) | Interface-first OO, small methods, strategy/registry, constants, exceptions | Implementation / Refactoring |
| [`abap-code-review`](abap-code-review/SKILL.md) | Review for read-only safety, correctness, performance, authorization, Clean ABAP | Review |
| [`abap-performance-tuning`](abap-performance-tuning/SKILL.md) | Bounded/index-friendly SELECTs, no SELECT*/SELECT-in-LOOP, efficient internal tables | Refactoring / Review |
| [`abap-systematic-debugging`](abap-systematic-debugging/SKILL.md) | Reproduce→isolate→hypothesize→verify with ST22/ST05/debugger | Debugging |
| [`writing-design-docs`](writing-design-docs/SKILL.md) | Maintain `docs/design/` docs — sections, tables, mermaid, Open Issues, change history | Documentation |
| [`writing-commit-messages`](writing-commit-messages/SKILL.md) | Conventional-commit messages matching repo style/language | Documentation / Workflow |
| [`creating-pr`](creating-pr/SKILL.md) | Review-ready PRs with object list, test plan, read-only self-review | Workflow |

## Applying skills

- **Vague / demo UX request:** `abap-requirement-intake` (or filled brief) →
  `abap-ops-monitor-ux` → `abap-read-only-monitoring` + `abap-clean-oo`.
- **Implementation:** start from `abap-read-only-monitoring` + `abap-clean-oo`.
- **Review:** run `abap-code-review` (pull in `abap-performance-tuning`).
- **Refactoring:** `abap-clean-oo` + `abap-performance-tuning`, then re-review.
- **Debugging:** `abap-systematic-debugging`.
- **Documentation:** `writing-design-docs`; commit/PR via `writing-commit-messages`
  and `creating-pr`.

## Adding a skill

Create `.cursor/skills/<name>/SKILL.md` with the frontmatter above and a concrete,
ordered playbook (steps, tables, done-criteria). Keep it project-specific and
actionable, then add a row to the table above.
