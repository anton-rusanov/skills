---
name: sdlc
description: Orchestrate autonomous development with separate Worker and Reviewer agent sessions coordinated through filesystem artifacts. Use whenever the user asks to implement, plan, or review a roadmap task, address review findings, run the SDLC pipeline, or do plan-then-review development. Trigger phrases: "work on the next roadmap task", "create a plan for task X", "review the current roadmap task", "address review findings", "run the pipeline", "implement from the roadmap", "autonomous development". Also use when the user mentions ROADMAP.md, code review rounds, or plan-review cycles.
---

# SDLC Lifecycle

Separates **spec hardening**, **planning**, **implementation**, and **review** into distinct agent
sessions coordinated through files in `.agents/sdlc/tasks/<TASK-ID>/`. Up to three review gates:
when a **product spec** governs the task, the Reviewer first pokes holes in that spec (before any
planning) and the Worker closes them; then the Reviewer critiques the **plan** (before any code);
then the **code**. Each session starts fresh — the Reviewer never sees the Worker's reasoning, only
the artifacts and diffs, so the work must stand on its own.

Two roles, auto-detected from the prompt:

| Mode | Trigger | Protocol file to read |
|------|---------|-----------------------|
| **WORKER** | "implement task X", "work on next roadmap task", "create a plan for task X", "address (spec) review findings" | `references/worker.md` |
| **REVIEWER** | "review the current roadmap task", "review the plan for task X" | `references/reviewer.md` |

If the prompt is ambiguous: a task whose `status.md` says `AWAITING_REVIEW` → REVIEWER, otherwise
WORKER. Read your protocol file before doing anything else.

When the user asks to run the full pipeline ("run the pipeline", "implement TASK-003", "work on all
roadmap tasks"), **this session is the Orchestrator** — follow the rest of this file and delegate
the Worker/Reviewer sessions as subagents.

## Artifact Protocol

Everything lives in `.agents/sdlc/tasks/<TASK-ID>/` (gitignored):

| File | Written by | Purpose |
|---|---|---|
| `status.md` | both | The handshake. First line is the status keyword. |
| `spec-review-round-N.md` | Reviewer | Findings against the product spec (SPEC phase). Kept separate so spec rounds don't inflate the plan/code counters. |
| `plan.md` | Worker | The implementation plan; also holds the Worker's rebuttals. |
| `review-round-N.md` | Reviewer | Plan/code findings, one per round. The next Reviewer session reads these — this is how it "remembers". |
| `summary.md` | Reviewer | Written on CODE approval: commit message, what changed, verification evidence. |

`status.md` format — the Orchestrator reads it after every subagent returns:

```
AWAITING_REVIEW
phase: PLAN
round: 1
updated: 2026-04-27T21:43:00
task: TASK-003
```

`phase` tells the Reviewer **what** to review: `SPEC` (the governing spec under `spec/`, no plan or
code yet), `PLAN` (`plan.md`, no code yet), `CODE` (`git diff` against the approved plan).

| Status | Meaning | Who sets it |
|--------|---------|-------------|
| `IN_PROGRESS` | Worker is planning/implementing | Worker |
| `AWAITING_REVIEW` | Worker done, artifact ready for review | Worker |
| `IN_REVIEW` | Reviewer is reviewing | Reviewer |
| `NEEDS_FIXES` | Reviewer found issues to address | Reviewer |
| `DONE` | Reviewer approved this phase | Reviewer |
| `BLOCKED` | Rounds exhausted or unresolvable issue | Reviewer |

## ROADMAP.md Format

```markdown
### [PENDING] TASK-001: Short title here
**Priority**: HIGH

Description of what needs to be done.
```

Markers: `[PENDING]` → `[IN_PROGRESS]` → `[DONE]`, or `[BLOCKED]`. Anything else (e.g.
`[SUPERSEDED]`) is outside the vocabulary and is **skipped, never implemented**. Full spec:
`references/roadmap-spec.md`.

## Orchestration

### Setup: options from the user's prompt

| Option | Required | How to specify | Default |
|--------|----------|----------------|---------|
| `TaskFilter` | **Yes — ask if missing** | "run the pipeline for TASK-007, TASK-012" / "implement TASK-003" / "all pending tasks" | — |
| `MaxRounds` | No | "with up to 2 review rounds" | 3 |
| `ContinueOnBlocked` | No | "skip blocked tasks" | false (stop on first blocked task) |
| `CreatePR` | **Ask once at the start** | "open a PR for this" / "no PR, I'll push" | false (stop at the local commit; the user pushes) |

Resolve `CreatePR` **once, up front** and apply it to every task in the run — never re-ask
mid-pipeline.

### Loop

For each task in `TaskFilter` (ROADMAP.md order when "all"):

**1 — Find and lock the task.** Read `ROADMAP.md` and find `### [PENDING] <TASK-ID>: ...`. If it is
not `[PENDING]`, skip it with a note. Create `.agents/sdlc/tasks/<TASK-ID>/` if missing and mark
the heading `[IN_PROGRESS]`.

**2 — Phase 0: Spec review** *(only when a product spec governs the task — the prompt references a
`spec/spec-*.md` or the ROADMAP task links one; otherwise skip straight to Phase 1)*.

Harden the spec before anyone plans against it:

a. Delegate to a **Reviewer** with `phase: SPEC` (action: "Poke holes in the product spec for
   roadmap task <TASK-ID>"). It hunts ambiguity, contradictions, missing requirements, and
   unverifiable acceptance criteria, then writes `spec-review-round-N.md` and a verdict.

b. Read `status.md` and branch as in the **round loop** below, except the Worker action is
   "Address spec review findings for roadmap task <TASK-ID>" (it edits the spec under `spec/`,
   leaving it unsubmitted) and step **c** runs first.

c. **Decision gate — the one place the human is consulted.** Read the latest
   `spec-review-round-N.md` for an `## Open Decisions` section: product/intent calls only the user
   can make (the Reviewer triages these away from gaps the Worker can close itself, capped at ~5 —
   more than that means **blocked**, reason `SPEC_TOO_AMBIGUOUS`).
   - No `## Open Decisions` section, or empty → skip to the Worker delegation; don't interrupt.
   - Otherwise → present them **in a single batch** with `AskUserQuestion`, one question per
     decision, each with the Reviewer's options and its **recommended default first, marked
     "(Recommended)"**, so defaults can be confirmed in seconds. Write each answer into the
     `Resolution` column of that row; the Worker reads them back.

   This is the **only** human checkpoint — the rest of the pipeline runs autonomously.

   Spec rounds are counted independently (`spec-review-round-N.md`) and do not consume the Phase 1
   or Phase 2 round budget.

**3 — Phase 1: Plan.** Delegate to a **Worker** (action: "Create a plan for roadmap task
<TASK-ID>"), then run the round loop.

**4 — Phase 2: Code.** Same shape. Initial Worker action: "Implement the approved plan for roadmap
task <TASK-ID>". Documentation is the Worker's job, not yours: it updates the affected docs as part
of this phase and the Reviewer reviews them with the code. **Never read the diff or edit docs
yourself** — that is what keeps your context flat across many tasks in a row.

**Round loop (each phase).** After every subagent returns, read `status.md`:
- Worker returned anything but `AWAITING_REVIEW` → **blocked**, reason `WORKER_DID_NOT_SIGNAL`.
- Delegate to a **Reviewer**, then read `status.md` again:
  - `DONE` → phase approved; advance.
  - `NEEDS_FIXES`, round < `MaxRounds` → delegate to Worker ("Address review findings for roadmap
    task <TASK-ID>"), verify `AWAITING_REVIEW`, increment the round, re-review.
  - `NEEDS_FIXES`, round == `MaxRounds` → **blocked**, reason `MAX_ROUNDS_EXCEEDED`.
  - `BLOCKED` → **blocked**, reason from `status.md`.
  - Anything else, or unchanged → **blocked**, reason `REVIEWER_DID_NOT_SIGNAL`.

**5 — Commit.** The Reviewer runs `/verify` before approving, so `DONE` already means the change was
exercised against its real runtime surface — and the code is frozen between approval and here, so
do **not** re-run it. Instead confirm `summary.md` has a `## Verification` section recording a green
`/verify`. If that evidence is missing, the approval is incomplete: do not commit — report it and
re-delegate the CODE review. (If the Reviewer reports it could not write `summary.md` — e.g. the
harness blocks subagent writes to that path — transcribe the summary it returned into
`summary.md` yourself, then continue.)

Take the commit message verbatim from the `## Commit Message` section and run:

```
git add -A
git commit -m "<message>"
```

Then mark the ROADMAP heading `[DONE]` and either amend (`git add -A && git commit --amend
--no-edit`) or add a follow-up commit — either is fine.

**6 — Integrate.** Commit on the project's **canonical branch** — never invent a per-task
`feature/<task>` or `sdlc/<TASK-ID>` branch. If that canonical branch is `master` (a solo project
where the PR flow is retired), committing there is correct; what is never automatic is the **push**.
Act on the `CreatePR` decision resolved at the start (do not re-ask):
- **false (default)** → stop at the local commit and report. The user reviews and pushes.
- **true** → push the branch and open a PR targeting the integration branch, building the body from
  `summary.md` (`## What Changed`, `## Review Notes`). If a PR already exists, push to it instead of
  opening a duplicate. Report the URL.

**Blocked outcome (any step).** Set `status.md`'s first line to `BLOCKED` with the reason if the
subagent didn't, revert the ROADMAP heading to `[PENDING]` (block details live in `status.md`), then
continue to the next task if `ContinueOnBlocked` is true — otherwise stop and report which task is
blocked and why.

### Subagent prompt templates

Use verbatim, filling in `<TASK-ID>` and `<action>`. Subagents are synchronous — no polling.

**Worker:**
> "You are the Worker in the SDLC lifecycle for this project. Read
> `.agents/skills/sdlc/references/worker.md` for your full protocol. Your task: `<action>` — one of:
> 'Address spec review findings for roadmap task <TASK-ID>' | 'Create a plan for roadmap task
> <TASK-ID>' | 'Implement the approved plan for roadmap task <TASK-ID>' | 'Address review findings
> for roadmap task <TASK-ID>'. Artifacts are in `.agents/sdlc/tasks/<TASK-ID>/`."

**Reviewer:**
> "You are the Reviewer in the SDLC lifecycle for this project. Read
> `.agents/skills/sdlc/references/reviewer.md` for your full protocol. Review roadmap task
> <TASK-ID> at the phase named in `status.md` (`SPEC`, `PLAN`, or `CODE`). Artifacts are in
> `.agents/sdlc/tasks/<TASK-ID>/`. `status.md` should say `AWAITING_REVIEW` — if it does not, report
> this and stop without writing a review."

## Critical Rules

1. **Never skip the plan.** However simple the task looks, `plan.md` is written and reviewed before
   any code.
2. **`status.md` is the handshake.** Always update it as the LAST action of a session. Updating it
   early or skipping it breaks the pipeline.
3. **Clean git state.** The Worker verifies `git status` is clean before starting; if not, a
   previous cycle left debris — `BLOCKED`, don't guess.
4. **Reviewer reads ALL previous rounds** and says so explicitly ("I flagged X in round 1 and it
   remains unaddressed").
5. **Worker answers ALL findings** — fixed or explicitly rebutted, never silently dropped.
6. **Honor project rules.** Check `CLAUDE.md`, `GEMINI.md`, or an equivalent rules file for
   domain-specific criteria (financial precision, security policy, style mandates) and apply them
   in both implementation and review.
7. **Follow the project's own workflow** (e.g. `dev-flow.md`) during implementation. This skill adds
   review orchestration on top; it does not replace the project's methodology.
