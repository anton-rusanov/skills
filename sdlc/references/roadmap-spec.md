# ROADMAP.md Specification

The `ROADMAP.md` file defines the project's task queue. It lives at the project root and is the single source of truth for what work needs to be done.

The skill supports two ROADMAP formats. Either format works — the Orchestrator, Worker, and Reviewer can parse both.

---

## Format A: Task-Based (Recommended)

Each task is a heading with a status marker and unique ID:

```markdown
# Roadmap

Brief description of the project's current priorities and direction.

---

### [PENDING] TASK-001: Short descriptive title
**Priority**: HIGH

What needs to happen. Be specific — the Worker agent will use this as the
starting point for implementation. Include:
- Acceptance criteria (what "done" looks like)
- Constraints and boundaries (what NOT to touch)
- Relevant context (related files, APIs, prior decisions)

---

### [DONE] TASK-002: A completed task
**Priority**: MEDIUM

Description...
```

### Task IDs
- Format: `TASK-NNN` (zero-padded three-digit number)
- IDs are sequential and never reused

### Status Markers

| Marker | Meaning |
|--------|---------|
| `[PENDING]` | Ready to be worked on. The Orchestrator picks these up. |
| `[IN_PROGRESS]` | A Worker is currently implementing this task. |
| `[DONE]` | Task completed, reviewed, and committed. |
| `[BLOCKED]` | Task could not be completed — needs human intervention. |

### Priority
One of: `HIGH`, `MEDIUM`, `LOW`. The Orchestrator processes tasks in order of appearance, not by priority — so place higher priority tasks first.

---

## Format B: Session-Based

Tasks are described as "sessions" with a summary table at the top and detailed sections below. Status is tracked via checkboxes in the table.

```markdown
# Project Roadmap

## Session Index

| # | Session | Tier | Status |
|---|---------|------|--------|
| 1 | [Circuit Breakers & Kill Switch](#session-1) | 🔴 Critical | `[x]` |
| 2 | [Market Hours Awareness](#session-2) | 🔴 Critical | `[ ]` |
| 3 | [Startup Config Validation](#session-3) | 🔴 Critical | `[ ]` |

---

## Session 1: Circuit Breakers & Kill Switch

**Risk addressed:** Runaway losses from bad data, API glitches, or indicator edge cases.

### Scope
- **`TradingPipeline.kt`** — Inject a `CircuitBreaker` instance; check before each signal
- **`CircuitBreaker.kt`** (new) — Stateful guard tracking daily loss limits, open positions, trade size caps

### Notes
- Circuit state should be reset daily at market open.
- Kill switch should require a secret header to prevent accidental invocation.

---

## Session 2: Market Hours Awareness

**Risk addressed:** Orders submitted outside trading hours fill at unpredictable prices.

### Scope
- **`MarketCalendar.kt`** (new) — Determines if current time is within NYSE regular hours
- **`TradingScheduler.kt`** — Skip cycle if market is closed (log, don't cancel)
```

### Checkbox States

| Checkbox | Meaning |
|----------|---------|
| `` `[ ]` `` | Pending — not started yet |
| `` `[/]` `` | In progress — Worker is currently implementing |
| `` `[x]` `` | Done — completed, reviewed, and committed |

For blocked tasks, the session stays as `[ ]` — the block is tracked in `.agents/sdlc/tasks/<ID>/status.md`, not in the ROADMAP checkbox.

### How Agents Find the Task Description
1. The Orchestrator identifies the pending session by finding the first `[ ]` row in the Session Index table
2. The task ID is derived as `SESSION-NNN` (e.g., session 2 → `SESSION-002`)
3. The full task description is in the matching `## Session N: Title` section below the table
4. Workers and Reviewers should read the **entire session section** (Scope, Notes, any subsections) — not just the title

---

## Shared Rules (Both Formats)

### Dependencies
If a task depends on another, call it out explicitly in the description:
- "Depends on: TASK-003" or "Prerequisite: Session 1"

**Enforcement**: The Worker checks for dependency declarations when it picks up a task. If any dependency isn't `[DONE]` (or `[x]`), the Worker immediately sets the task to `BLOCKED` with reason `DEPENDENCY_NOT_MET` and moves on. This works regardless of task ordering in the file.

### Task Descriptions
Good task descriptions contain:
- **What**: Clear statement of the change
- **Why**: Business or technical motivation
- **Acceptance criteria**: Measurable conditions for "done"
- **Scope boundaries**: What NOT to change (prevents scope creep)
- **Context**: Related files, interfaces, or prior decisions the Worker should read

The description doesn't need to specify HOW — that's the Worker's job during planning. But it can suggest an approach when helpful.

### Who Updates the ROADMAP

| Actor | What they update |
|-------|-----------------|
| Orchestrator | `[PENDING]` → `[IN_PROGRESS]` (Format A) or `[ ]` → `[/]` (Format B) |
| Reviewer (on approval) | `[IN_PROGRESS]` → `[DONE]` (Format A) or `[/]` → `[x]` (Format B) |
| Orchestrator | `[IN_PROGRESS]` → `[BLOCKED]` (Format A only — Format B tracks blocks in status.md) |

---

## Creating a New ROADMAP.md

If the project doesn't have a `ROADMAP.md` yet, the Worker can prompt the user to create one, or create a minimal one:

```markdown
# Roadmap

---

### [PENDING] TASK-001: <title from user's request>
**Priority**: MEDIUM

<description based on what the user asked for>
```
