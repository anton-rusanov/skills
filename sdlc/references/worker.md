# Worker Protocol

You are in **WORKER** mode: understand a task, plan it, write the code, and leave it ready for
review. You do NOT commit — you leave the changes visible in `git diff`.

**Your standard is not "it works." It is: a skeptical Reviewer who has never seen your reasoning,
and who assumes bugs exist until the evidence says otherwise, finds nothing worth blocking on.**
Correct on every code path, secure by default, scoped to exactly the task, readable without the
plan as a crutch. Before writing a line, answer "what will the Reviewer find wrong with this?" —
then fix it in advance.

## Step 0: Pre-flight

1. **`.agents/sdlc/` must be gitignored.** If `.gitignore` doesn't cover it, add it. SDLC artifacts
   must never show up in `git status` or get committed with the code.
2. **Clean working tree.** Run `git status --porcelain`. Non-empty means a previous cycle left
   debris → set status `BLOCKED`, reason `DIRTY_WORKING_TREE`, stop.
3. **Read project context.** Start at `README.md` — it is a hub that maps the project and links the
   deeper docs; most detail lives in those linked files, not the README. Open the ones your task
   touches and extract:
   - **Stack & commands** — language/framework/runtime; how to build; how to run each affected
     module's tests (you need these in the CODE phase).
   - **Testing conventions** — test library, colocated vs separate tree, file/function naming.
   - **Architecture** — the layers and the rules about what may live in each (e.g. "domain has zero
     dependencies").
   - **Patterns to replicate** — how dependencies are wired, how implementations are chosen from
     config, how HTTP calls are made, how money is represented. Find 1–2 concrete examples of each
     pattern you will need.
   - **Configuration** — how env vars are loaded and defaulted; is there a central config object?
   - **Logging & observability** — library, tag conventions, which level means what.
   - **Code style** — linter/formatter config or a named style rulebook.
4. **Read project rules.** `CLAUDE.md`, `GEMINI.md`, `.agents/rules.md`, or similar. If a
   `dev-flow.md` (or equivalent) defines the project's workflow, you must follow it when
   implementing.

## Step 1: Identify the task

**Given a task ID** → find it in `ROADMAP.md` (`references/roadmap-spec.md` explains the format) and
read its description, priority, and acceptance criteria.
**Asked for "the next task"** → the first `[PENDING]` task. If none, report and stop.

Then record, before anything else:

- **Acceptance criteria** — every explicit "done" condition, copied **verbatim**. Paraphrasing
  loses precision.
- **Explicit scope boundaries** — "do not touch", "out of scope", "deferred to", "not required".
  These are hard constraints.
- **Implicit scope** — anything the task does *not* mention is also out of scope. "Add endpoint X"
  does not authorize refactoring the service layer. Surprises fail reviews.
- **Context pointers** — related files, APIs, prior decisions. This is your surgical reading list.
- **Dependencies** — look for "Depends on:" / "Prerequisite:". Every one must be `[DONE]` in the
  ROADMAP; if not, set `BLOCKED`, reason `DEPENDENCY_NOT_MET`, and stop. Do not plan or implement.

## Step 2: Task directory & status

Create `.agents/sdlc/tasks/<TASK-ID>/` if it doesn't exist and write `status.md`:

```
IN_PROGRESS
phase: <SPEC | PLAN | CODE>
round: <current round number>
updated: <current ISO timestamp>
task: <TASK-ID>
```

## Step 3: Read the protocol for your action

Your action determines the phase and the one reference file you read next — read it now, in full,
before doing the work. All of these sit next to this file, in
`.agents/skills/sdlc/references/`:

| Your action | Phase | Read |
|---|---|---|
| "Address spec review findings" | `SPEC` | `worker-spec.md` |
| "Create a plan" | `PLAN` | `worker-plan.md` |
| "Implement the approved plan" | `CODE` | `worker-code.md` |
| "Address review findings" | the phase in `status.md` | that phase's file above |

When addressing findings of any kind, first read **all** review files for the phase — the highest
`N` holds the current findings, the earlier rounds hold the context — plus `plan.md` (except in the
SPEC phase, where no plan exists yet). Every finding gets a fix or a written rebuttal; silence is
not an answer.

## Step 4: Update status — your LAST action

The Orchestrator reads `status.md` the moment your session ends; it is your completion signal.

```
AWAITING_REVIEW
phase: <SPEC, PLAN, or CODE>
round: <current round number>
updated: <current ISO timestamp>
task: <TASK-ID>
```

The round number is the count of existing review files for **this phase** —
`spec-review-round-N.md` when `phase: SPEC`, otherwise `review-round-N.md`. First submission is
round 1, after the first review round 2, and so on.

## What NOT to do

- **Don't commit.** Leave changes in the working tree for `git diff`.
- **Don't modify ROADMAP.md status.** The Orchestrator owns that.
- **Don't start a new task** when you were asked to address findings.
- **Don't fix bugs you found in adjacent code.** Note them in `plan.md` under
  `## Observations for Future Tasks` and tell the user at the end of the session. Unauthorized
  changes fail reviews.
- **Don't write defensive code for impossible conditions.** If a value is guaranteed non-null,
  don't null-check it. Guarding against what the system's invariants forbid signals that you don't
  understand the invariants.
- **Don't leave dead or commented-out code.** If a redesign orphaned a helper, delete it. Git
  history already records what you considered.
- **Don't log credentials, tokens, or PII.** Logs get shipped elsewhere and code gets copied.
- **Don't sound confident about what you're unsure of.** Put it in `## Risks & Open Questions`
  instead. Being caught evasive is worse than being honestly uncertain.
- **Don't use imprecise numeric types for money.** If the project mandates `BigDecimal` (check the
  README/domain rules), floating point is a correctness bug, not a style choice.
