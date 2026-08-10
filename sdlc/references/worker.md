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
2. **Working tree.** Run `git status --porcelain` in the umbrella and every submodule. A dirty tree
   is sometimes correct and sometimes debris, and you cannot tell which by reading the diff — so
   decide from your **action**, never from whether the changes look related to the task.

   Legitimate in every phase, and nothing else is:
   - the Orchestrator's `[IN_PROGRESS]` flip on the task's `ROADMAP.md` heading;
   - from PLAN onward, the approved-but-uncommitted edits to the governing spec under `spec/` —
     the SPEC phase leaves them unsubmitted by design and the Orchestrator commits them with the
     code.

   Source changes on top of those depend on your action:

   | Your action | Source changes allowed |
   |---|---|
   | "Address spec review findings" | None. |
   | "Create a plan" | None. |
   | "Implement the approved plan" | None — unless you are reviving a killed predecessor (below). |
   | "Address review findings" | In CODE, the previous round's changes: that is the reviewed baseline you are editing. In SPEC and PLAN, none. |

   **Reviving a killed predecessor** is the only thing that licenses partial, unreviewed source
   changes on a first dispatch, and it takes positive evidence — an `## Interruptions` entry in
   `orchestrator-notes.md` naming your phase. No entry, no revival: assume debris and block. Your
   own judgement that "a previous session probably died here" is not evidence; the Orchestrator
   writes that entry precisely so you never have to guess.

   With an entry, reconcile the tree against `progress.md` before you touch anything. What the
   entry and `progress.md` account for is yours to continue. Anything else has unknown provenance
   — re-verify it or throw it away, never build on it.

   Anything the rules above do not explain is debris from an earlier cycle → set status `BLOCKED`,
   reason `DIRTY_WORKING_TREE`, stop. Do not widen the list to fit what you found.
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

Create `.agents/sdlc/tasks/<TASK-ID>/` if it doesn't exist and write `status.md`. If the existing
file carries `dispatched:` / `dispatched_at:` keys, they are the Orchestrator's in-flight marker
for your session — write the plain template below and let them go:

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

## Step 4: Checkpoint as you go

Your session can end without warning. An API session limit kills you mid-tool-call — no final
message, no summary, nothing written back. Everything held only in your context is gone. Only files
survive, so keep `progress.md` in the task directory current as you work.

**Read it first.** `progress.md` accumulates across the whole task, so every entry carries its
phase. Entries under a phase **earlier** than yours are history — useful background, nothing more.
Entries under **your own** phase mean a previous Worker in this phase was killed: those are the
only trustworthy account of what actually landed, so start from there instead of redoing finished
work, and re-verify anything in the tree they do not mention.

**Append an entry the moment a unit of work is genuinely finished** — a plan step complete, a
migration validated, a suite green. Not when you are about to start one. Lead every entry with its
phase:

```
- 2026-04-27T21:52 — CODE step 3/9 done: added listing_comps migration; flywayValidate green.
- 2026-04-27T22:04 — CODE step 4/9 done: rebuild() captures the instant before the index read.
- 2026-04-27T22:09 — CODE: wrote wire/client-detail-with-comps.json. WRITTEN, UNVERIFIED — successor must re-capture it from a real run before touching production code.
```

Append only, never rewrite. One line per entry: what completed, and the evidence it completed. A
file you created but have not verified is **not** a finished unit — if you record it at all, mark
it unverified in those words, because your successor will otherwise trust it and build on a guess.

This file exists for recovery. It is not for the Reviewer and does not replace `plan.md` or your
written responses to findings.

## Step 5: Update status — your LAST action

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
