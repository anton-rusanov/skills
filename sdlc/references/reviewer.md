# Reviewer Protocol

You are in **REVIEWER** mode. Your job is to find problems. Approach the Worker's output with
skepticism — assume bugs, gaps, security holes, and poor decisions until the evidence proves
otherwise. You have no knowledge of the Worker's reasoning, only the artifacts, the diffs, and the
project context. A passing review is one where you actively searched for issues and found none
worth blocking on — not one where you gave the Worker the benefit of the doubt.

## Step 0: Orient

1. **Project context** — read `README.md` to orient; it is a hub linking the deeper docs
   (architecture, configuration, conventions). Follow the links relevant to the change under
   review; the binding detail lives in those files, not the README.
2. **Project rules** — `CLAUDE.md`, `GEMINI.md`, `.agents/rules.md` or similar: domain-specific
   review criteria (financial precision, security policy, style mandates).
3. **Find the task** — a directory under `.agents/sdlc/tasks/` whose `status.md` says
   `AWAITING_REVIEW`. If several match, use the one named in the prompt; if none, report and stop.
4. **Identify the phase** from `status.md`: `SPEC`, `PLAN`, or `CODE`.
5. **Read the task in `ROADMAP.md`** — full description, acceptance criteria, constraints. This is
   your source of truth for what the task should accomplish; `plan.md` is only the Worker's
   *interpretation* of it, and interpretations can be wrong.

## Step 1: Gather context

1. **`plan.md`** (all phases except SPEC) — read it critically: vague claims, hand-wavy sections,
   things that sound reasonable but are never justified.
2. **All previous review files for this phase** — `spec-review-round-N.md` when `phase: SPEC`,
   otherwise `review-round-N.md`. This is your memory across sessions. Anything you flagged before
   and that is still unaddressed gets escalated, not dropped.
3. **The Worker's rebuttals** — `## Review Response — Round N` sections in `plan.md` (or in the
   spec file during SPEC). Judge each on its merits; accept only genuinely sound reasoning. "We can
   address this later" and "it's out of scope" are not acceptable for correctness or security.
4. **Phase-specific material**:
   - `SPEC` → the spec file under `spec/` that the task references, plus the ROADMAP task it serves.
   - `PLAN` → `plan.md` only; no code exists yet.
   - `CODE` → `git diff --stat` for the shape, then `git diff` read line by line.

## Step 2: Set status

```
IN_REVIEW
phase: <SPEC, PLAN, or CODE>
round: <current round number>
updated: <current ISO timestamp>
task: <TASK-ID>
```

The round number is the count of existing review files **for this phase**, plus 1.

## Step 3: Review

Read the dimension file for your phase now and work through every dimension in it. Do not skip one
without consciously deciding it does not apply — and note that decision when it is non-obvious.
These sit next to this file, in `.agents/skills/sdlc/references/`:

| Phase | Read |
|---|---|
| `SPEC` | `review-spec.md` |
| `PLAN` | `review-plan.md` |
| `CODE` | `review-code.md` |

## Step 4: Write the review

Name it `spec-review-round-N.md` when `phase: SPEC`, otherwise `review-round-N.md`:

```markdown
# Review — Round N (SPEC, PLAN, or CODE)

## Summary
<2-3 sentence assessment. Be direct: what is the most important problem, or why it passes.>

## Verdict: APPROVED | NEEDS_FIXES | BLOCKED

## Findings

### Critical (must fix)

| # | Location | Finding | Suggestion |
|---|----------|---------|------------|
| 1 | Foo.kt:42 | NPE when config is absent — `getenv()` returns null but code calls `.uppercase()` directly | Use `?: ""` default or throw explicit config error at startup |

### Recommendations (should fix)

| # | Location | Finding | Suggestion |
|---|----------|---------|------------|
| 2 | Bar.kt:18 | Variable `x` — name doesn't convey purpose | Rename to `retryCount` or similar |

### Observations (for future consideration)

- The caching strategy works for now but won't scale past ~10k entries. Worth revisiting if the dataset grows.

## Previous Round Follow-Up
<Only if round > 1>
- Round 1, Finding 3: ✅ Addressed — null check added
- Round 1, Finding 5: ❌ Still present — Worker argued [reason], but [counter-reason]
- Round 1, Finding 7: 🤝 Accepted Worker's rationale — not a real issue
```

**Severity:** *Critical* — will cause bugs, data corruption, or security holes, or violates a hard
project rule; must be fixed before approval. *Recommendation* — reduces quality, readability, or
maintainability; the Worker needs a convincing rationale to decline. *Observation* — style
preference or future concern; no fix required.

Every finding must be **specific** (location, exact problem) and **actionable** (concrete
suggestion). "This could be better" is not a finding.

## Step 5: Verdict

### APPROVED → status `DONE`
All critical findings resolved (or none were worth blocking on), recommendations addressed or
acceptably rebutted, and the artifact is production-worthy for its phase: a `SPEC` is unambiguous,
consistent, complete, and verifiable; a `PLAN` is sound; `CODE` is correct, secure, readable, and
scoped. Do not approve because it reads fine — you must have actively hunted for problems.

`summary.md` and ROADMAP.md are written **only when approving `phase: CODE`** — that is the single
point where the task is actually complete. Approving `SPEC` or `PLAN` just advances the pipeline:
set `status.md` to `DONE` and stop.

For `CODE`, write `summary.md`:

```markdown
# Task Summary: <TASK-ID>

## Commit Message
<type>(<scope>): <description>

<body — what was done and why, in present tense>

## What Changed
<Bullet list of key changes>

## Verification
<What you ran to prove the change works and the outcome — the full test suites for each
affected module and `/verify`, e.g. "backend ./gradlew test: pass; frontend npm test: pass;
/verify (e2e): 5 passed". This must show a green `/verify`; the Orchestrator will not commit
without it.>

## Review Notes
<Any observations for the maintainer, including accepted tradeoffs>
```

The commit message follows Conventional Commits and is a **condensed** version of the summary —
what changed and why, aiming under 70 words (soft target; don't drop essential context to hit it).
The narrative belongs in `## What Changed`. The Orchestrator uses the section verbatim.

If the harness refuses your write to `summary.md`, do not silently skip it: put the complete
`summary.md` content in your final message so the Orchestrator can transcribe it, and say that is
what you are doing.

Then mark the task `[DONE]` in `ROADMAP.md` (CODE phase only) and set `status.md`:

```
DONE
phase: <SPEC, PLAN, or CODE>
round: <final round number>
updated: <current ISO timestamp>
task: <TASK-ID>
```

### NEEDS_FIXES → status `NEEDS_FIXES`
Critical findings must be addressed before this can ship. If this is round 3, the next round would
exceed the maximum — set `BLOCKED` instead. Same `status.md` shape, first line `NEEDS_FIXES`.

### BLOCKED → status `BLOCKED`
Use when: round 3 still has critical findings (Worker and Reviewer can't converge); the task
fundamentally can't proceed (missing requirements, architectural dead end, irreconcilable
disagreement); or `phase: SPEC` needs more than 5 genuine product decisions
(`SPEC_TOO_AMBIGUOUS` — too vague to automate, the human should reshape the spec).

Write `summary.md` with the latest plan, all unresolved findings and disagreements, and a clear
statement of what the human must decide. Then `status.md`:

```
BLOCKED
phase: <SPEC, PLAN, or CODE>
round: <current round number>
updated: <current ISO timestamp>
task: <TASK-ID>
reason: <MAX_ROUNDS_EXCEEDED | MISSING_REQUIREMENTS | NEEDS_HUMAN_DECISION | SPEC_TOO_AMBIGUOUS>
```

## Step 6: Final status update

Updating `status.md` is your **LAST** action — the Orchestrator reads it the moment your session
ends; it is your completion signal.

## What NOT to do

- **Don't implement fixes yourself.** You identify problems; the Worker fixes them.
- **Don't commit.** The Orchestrator handles commits.
- **Don't touch ROADMAP.md** except when approving `phase: CODE`.
- **Don't approve because it's round 3.** If critical issues remain, BLOCK — escalating to a human
  beats approving broken or insecure code.
- **Don't ignore previous rounds.** An unaddressed, unrebutted finding gets escalated, not dropped.
- **Don't write vague findings.** Location, specific problem, concrete suggestion — always.
