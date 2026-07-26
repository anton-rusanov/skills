# ROADMAP.md Specification

`ROADMAP.md` lives at the project root and is the single source of truth for what work needs to be
done.

## Format

```markdown
# Roadmap

Brief description of the project's current priorities and direction.

---

### [PENDING] TASK-001: Short descriptive title
**Priority**: HIGH

What needs to happen. Be specific — the Worker uses this as the starting point:
- Acceptance criteria (what "done" looks like)
- Constraints and boundaries (what NOT to touch)
- Relevant context (related files, APIs, prior decisions)

---

### [DONE] TASK-002: A completed task
**Priority**: MEDIUM

Description...
```

**Task IDs** are `TASK-NNN` (zero-padded, three digits), sequential, never reused.

**Status markers:**

| Marker | Meaning |
|--------|---------|
| `[PENDING]` | Ready to be worked on. The Orchestrator picks these up. |
| `[IN_PROGRESS]` | A Worker is currently implementing this task. |
| `[DONE]` | Completed, reviewed, and committed. |
| `[BLOCKED]` | Could not be completed — needs human intervention. |

Any other marker (e.g. `[SUPERSEDED]`) is outside the vocabulary on purpose: the Orchestrator
**skips** it rather than picking it up.

**Priority** is `HIGH`, `MEDIUM`, or `LOW`. Tasks are processed in file order unless the roadmap
itself states a selection rule, so place higher-priority tasks first.

**Who updates what:** the Orchestrator sets `[PENDING]` → `[IN_PROGRESS]` and
`[IN_PROGRESS]` → `[BLOCKED]`; the Reviewer sets `[IN_PROGRESS]` → `[DONE]`, but only when
approving the CODE phase.

A long-lived roadmap may keep completed tasks as a compact index and move their full descriptions
to an archive file. Only the live entries matter to the pipeline — but a dependency check still has
to be able to see that `TASK-003` is `[DONE]`, so keep the index in `ROADMAP.md` itself.

## Dependencies

Declare them in the description: `Depends on: TASK-003` / `Prerequisite: TASK-003`. When the Worker
picks up a task, it checks each declaration; if any dependency is not `[DONE]`, it immediately sets
`BLOCKED` with reason `DEPENDENCY_NOT_MET`. This works regardless of task order in the file. Once a
dependency is satisfied and archived, drop the line — a stale `Depends on:` pointing at completed
work is noise the next agent has to re-verify.

## Task descriptions

Good ones contain **what** (the change), **why** (business or technical motivation), **acceptance
criteria** (measurable "done"), **scope boundaries** (what not to change — this is what prevents
scope creep), and **context** (files, interfaces, prior decisions to read).

They don't need to specify *how* — that is the Worker's job during planning — but may suggest an
approach where it helps.

## Creating a new ROADMAP.md

If the project has none, the Worker can create a minimal one or prompt the user:

```markdown
# Roadmap

---

### [PENDING] TASK-001: <title from user's request>
**Priority**: MEDIUM

<description based on what the user asked for>
```
