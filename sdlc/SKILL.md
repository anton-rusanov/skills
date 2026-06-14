---
name: sdlc
description: Orchestrate autonomous software development with separate Worker and Reviewer agent sessions coordinated through filesystem artifacts. Use this skill whenever the user asks to implement a roadmap task, create a plan for a roadmap task, review a roadmap task, address review findings, run the SDLC pipeline, or anything involving plan-then-review development workflows. Trigger on phrases like "work on the next roadmap task", "create a plan for task X", "review the current roadmap task", "address review findings", "run the pipeline", "implement from the roadmap", or "autonomous development". Also use when the user mentions ROADMAP.md, code review rounds, or plan-review cycles.
---

# SDLC Lifecycle

A development lifecycle skill that separates **planning**, **implementation**, and **review** into distinct agent sessions, coordinated through filesystem artifacts. The lifecycle has two review gates: the Reviewer first critiques the **plan** (before any code is written), then critiques the **code** (after implementation). Each session has fresh context — the Reviewer never sees the Worker's reasoning, only the artifacts and diffs. This mirrors real engineering workflows where code must stand on its own without the author's internal monologue.

## How It Works

```
ROADMAP.md          .agents/sdlc/tasks/TASK-001/
┌──────────┐       ┌──────────────────────────────┐
│ [PENDING]│       │ status.md     ← handshake    │
│ TASK-001 │       │ plan.md       ← Worker writes │
│          │──────→│ review-N.md   ← Reviewer writes│
│ [DONE]   │       │ summary.md    ← Reviewer writes│
│ TASK-002 │       └──────────────────────────────┘
└──────────┘
```

Two modes, auto-detected from context:

| Mode | Trigger | What happens |
|------|---------|--------------|
| **WORKER** | "implement task X", "work on next roadmap task", "create a plan for task X", "address review findings" | Plans, implements code, leaves changes unsubmitted |
| **REVIEWER** | "review the current roadmap task", "review the plan for task X" | Reads plan or diffs, produces structured review, makes verdict |

## Mode Detection

Determine mode from the user's prompt and the filesystem state:

1. If the prompt explicitly says "review" in the context of a roadmap task → **REVIEWER** mode
2. If the prompt says "implement", "work on", "create a plan", "address findings" in the context of a roadmap task → **WORKER** mode
3. If ambiguous, check `.agents/sdlc/tasks/` for a task with status `AWAITING_REVIEW` → **REVIEWER**
4. If ambiguous and no task is awaiting review → **WORKER**

Once mode is determined, read the appropriate reference file:
- **WORKER**: Read `references/worker.md` in this skill directory for the full protocol
- **REVIEWER**: Read `references/reviewer.md` in this skill directory for the full protocol

## Artifact Protocol

All coordination happens through files in `.agents/sdlc/tasks/<TASK-ID>/`:

### status.md
First line is the status keyword. The Orchestrator reads this file after each subagent returns.

```
AWAITING_REVIEW
phase: PLAN
round: 1
updated: 2026-04-27T21:43:00
task: TASK-003
```

The `phase` field tells the Reviewer **what** to review:
- `PLAN` — review `plan.md` only (no code written yet)
- `CODE` — review `git diff` against the approved plan

**Status values:**

| Status | Meaning | Who sets it |
|--------|---------|-------------|
| `IN_PROGRESS` | Worker is actively planning/implementing | Worker |
| `AWAITING_REVIEW` | Worker is done, code is ready for review | Worker |
| `IN_REVIEW` | Reviewer is actively reviewing | Reviewer |
| `NEEDS_FIXES` | Reviewer found issues, Worker needs to address | Reviewer |
| `DONE` | Reviewer approved the changes | Reviewer |
| `BLOCKED` | 3 review rounds exhausted or unresolvable issue | Reviewer |

### plan.md
The implementation plan. Written by Worker, read by Reviewer. Updated by Worker when addressing fixes.

### review-round-N.md
Structured review findings. Written by Reviewer (one per round). Read by the next Reviewer session for continuity — this is how the Reviewer "remembers" previous suggestions across sessions.

### summary.md
Written by Reviewer on approval. Contains the git commit message and a summary of what was accomplished. The Orchestrator uses this for the commit.

## ROADMAP.md Format

Read `references/roadmap-spec.md` for the full specification. The skill supports two formats:

**Recommended format** (machine-parseable status markers):
```markdown
### [PENDING] TASK-001: Short title here
**Priority**: HIGH

Description of what needs to be done.
```

**Session-based format** (also supported — used by existing roadmaps):
```markdown
## Session 4: Startup Config Validation
**Status in Session Index table**: `[ ]` = PENDING, `[x]` = DONE
```

The Orchestrator and Worker can parse either format. See `references/roadmap-spec.md` for details on both.

## Orchestration

When the user asks to run the full pipeline ("run the pipeline", "work on all roadmap tasks", "implement TASK-003"), the **current agent session acts as the Orchestrator**.

### Setup: Parse Options from the User's Prompt

Before starting, extract these settings from the user's prompt. If `TaskFilter` is not specified, **ask the user explicitly** — do not assume "all".

| Option | Required | How to specify | Default |
|--------|----------|----------------|---------|
| `TaskFilter` | **Yes — ask if missing** | "run the pipeline for TASK-007, TASK-012" / "implement TASK-003" / "all pending tasks" | — |
| `MaxRounds` | No | "with up to 2 review rounds" | 3 |
| `ContinueOnBlocked` | No | "skip blocked tasks" | false (stop on first blocked task) |

### Orchestration Loop

For each task in `TaskFilter` (in ROADMAP.md order when "all"):

**1 — Find and lock the task**

Read `ROADMAP.md`. Locate the task:
- **Format A (recommended)**: find the heading `### [PENDING] <TASK-ID>: ...`
- **Format B (session-based)**: find the Session Index table row with `` `[ ]` `` matching the session number

If the task is not `[PENDING]` (Format A) or `` `[ ]` `` (Format B), skip it with a note — don't re-process.

Create `.agents/sdlc/tasks/<TASK-ID>/` if it doesn't exist.

Update ROADMAP.md to mark the task in-progress:
- **Format A**: replace `[PENDING] <TASK-ID>` with `[IN_PROGRESS] <TASK-ID>`
- **Format B**: replace the task row's `` `[ ]` `` with `` `[/]` `` in the Session Index table

**2 — Phase 1: Plan**

a. Delegate to a Worker subagent using the **Worker prompt template** below (action: "Create a plan for roadmap task <TASK-ID>").

b. After the subagent returns, read `status.md`. The first line must be `AWAITING_REVIEW`. If it is anything else — go to the **blocked outcome** with reason `WORKER_DID_NOT_SIGNAL`.

c. Run review rounds (up to `MaxRounds`). For each round:
   - Delegate to a Reviewer subagent using the **Reviewer prompt template** below.
   - After it returns, read `status.md`:
     - `DONE` → plan approved; proceed to Phase 2
     - `NEEDS_FIXES` and round < `MaxRounds` → delegate to Worker (action: "Address review findings for roadmap task <TASK-ID>"); verify `AWAITING_REVIEW` as in step 2b; increment round and re-review
     - `NEEDS_FIXES` and round == `MaxRounds` → **blocked outcome**, reason `MAX_ROUNDS_EXCEEDED`
     - `BLOCKED` → **blocked outcome**, reason from `status.md`
     - Anything else, or unchanged → **blocked outcome**, reason `REVIEWER_DID_NOT_SIGNAL`

**3 — Phase 2: Code**

Same structure as Phase 1. Initial Worker action: "Implement the approved plan for roadmap task <TASK-ID>".

Documentation is the Worker's responsibility, not the Orchestrator's. When structure or logic changes, the Worker updates the affected docs (`README.md` and the files it links under `docs/`) as part of this phase, and the Reviewer reviews those doc changes alongside the code. The Orchestrator never reads the diff or edits docs itself — this is what keeps its context flat across many tasks in a row.

**4 — Commit**

Read `summary.md`. Extract the commit message from the `## Commit Message` section. Run:
```
git add -A
git commit -m "<message>"
```

Update ROADMAP.md to mark the task done:
- **Format A**: replace `[IN_PROGRESS] <TASK-ID>` with `[DONE] <TASK-ID>`
- **Format B**: replace the task row's `` `[/]` `` with `` `[x]` `` in the Session Index table

**Blocked outcome (applies to any step above)**

When any step produces a blocked outcome:
1. Set `status.md` first line to `BLOCKED` with the reason (if not already set by the subagent)
2. Update ROADMAP.md:
   - **Format A**: replace `[IN_PROGRESS] <TASK-ID>` with `[BLOCKED] <TASK-ID>`
   - **Format B**: revert the task row's `` `[/]` `` back to `` `[ ]` `` (Format B tracks block details in `status.md`, not the ROADMAP)
3. If `ContinueOnBlocked` is true → continue to next task. Otherwise → stop the pipeline and report which task is blocked and why.

### Subagent Prompt Templates

Use these templates verbatim. Fill in `<TASK-ID>` and `<action>`.

**Worker:**
> "You are the Worker in the SDLC lifecycle for this project. Read `.agents/skills/sdlc/references/worker.md` for your full protocol. Your task: `<action>` — where action is one of: 'Create a plan for roadmap task <TASK-ID>' | 'Implement the approved plan for roadmap task <TASK-ID>' | 'Address review findings for roadmap task <TASK-ID>'. Artifacts are in `.agents/sdlc/tasks/<TASK-ID>/`."

**Reviewer:**
> "You are the Reviewer in the SDLC lifecycle for this project. Read `.agents/skills/sdlc/references/reviewer.md` for your full protocol. Review roadmap task <TASK-ID>. Artifacts are in `.agents/sdlc/tasks/<TASK-ID>/`. The `status.md` file should say `AWAITING_REVIEW` — if it does not, report this and stop without writing a review."

Subagents are synchronous: the Orchestrator waits for them to finish before reading `status.md`. No polling is required.

## Critical Rules

1. **Never skip the plan.** Even for tasks that seem simple, Worker must write `plan.md` before implementing. The plan goes through its own review cycle before any code is written.
2. **Status file is the handshake.** Always update `status.md` as the LAST action in your session. The Orchestrator reads this file immediately after the subagent returns — updating it prematurely or skipping it breaks the pipeline.
3. **Clean git state.** Worker must verify `git status` shows a clean working tree before starting. If it doesn't, something went wrong in a previous cycle — set status to `BLOCKED` with reason and stop.
4. **Reviewer reads ALL previous rounds.** When writing `review-round-3.md`, read both `review-round-1.md` and `review-round-2.md` first. Reference previous findings — "I flagged X in round 1 and it remains unaddressed."
5. **Worker reads ALL review findings.** When addressing fixes, read all `review-round-N.md` files and the original `plan.md`. Respond to each finding — either fix it or explain why the current approach is better.
6. **Domain-specific compliance.** Check the project's GEMINI.md or similar configuration file for domain-specific review criteria (e.g., financial regulations, security requirements). Apply these during review if present.
7. **Follow existing project workflows.** The Worker should follow the project's established development workflow (e.g., `dev-flow.md` or similar) for the implementation phase. The SDLC skill adds review orchestration on top — it doesn't replace the implementation methodology.
