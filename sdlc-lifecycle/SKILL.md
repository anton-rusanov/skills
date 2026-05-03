---
name: sdlc-lifecycle
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
First line is the status keyword. The orchestrator script polls this file.

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
Written by Reviewer on approval. Contains the git commit message and a summary of what was accomplished. The orchestrator script uses this for the commit.

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

The orchestrator script and Worker can parse either format. See `references/roadmap-spec.md` for details on both.

## Orchestration

The `scripts/sdlc-orchestrate.ps1` script automates the full cycle across multiple tasks. It:
1. Reads ROADMAP.md for the next `[PENDING]` task
2. Launches Worker and Reviewer sessions via `antigravity chat`
3. Polls status files to detect completion
4. Handles round transitions and timeouts
5. Commits on approval, marks BLOCKED on exhaustion
6. Moves to the next task

Run it with: `powershell -File .agents/skills/sdlc-lifecycle/scripts/sdlc-orchestrate.ps1`

## Critical Rules

1. **Never skip the plan.** Even for tasks that seem simple, Worker must write `plan.md` before implementing. The plan goes through its own review cycle before any code is written.
2. **Status file is the handshake.** Always update `status.md` as the LAST action in your session. The orchestrator polls this file — updating it prematurely breaks the pipeline.
3. **Clean git state.** Worker must verify `git status` shows a clean working tree before starting. If it doesn't, something went wrong in a previous cycle — set status to `BLOCKED` with reason and stop.
4. **Reviewer reads ALL previous rounds.** When writing `review-round-3.md`, read both `review-round-1.md` and `review-round-2.md` first. Reference previous findings — "I flagged X in round 1 and it remains unaddressed."
5. **Worker reads ALL review findings.** When addressing fixes, read all `review-round-N.md` files and the original `plan.md`. Respond to each finding — either fix it or explain why the current approach is better.
6. **Domain-specific compliance.** Check the project's GEMINI.md or similar configuration file for domain-specific review criteria (e.g., financial regulations, security requirements). Apply these during review if present.
7. **Follow existing project workflows.** The Worker should follow the project's established development workflow (e.g., `dev-flow.md` or similar) for the implementation phase. The SDLC skill adds review orchestration on top — it doesn't replace the implementation methodology.
