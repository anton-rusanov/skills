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
| `progress.md` | Worker | Append-only checkpoint log. Lets a Worker killed mid-flight be replaced without redoing — or blindly trusting — its partial work. |
| `review-round-N.md` | Reviewer | Plan/code findings, one per round. The next Reviewer session reads these — this is how it "remembers". |
| `dispatched.md` | **Orchestrator only** | The in-flight marker and delegation lock. Written before every `Agent` call, deleted the moment that agent's completion notification arrives. Subagents never read or write it. |
| `handoff.md` | Reviewer | The Reviewer's terminal artifact. On CODE approval: commit message, what changed, verification evidence. On `BLOCKED`: the unresolved decisions for the human. |

`status.md` format — the Orchestrator reads it after every subagent returns:

```
AWAITING_REVIEW
phase: PLAN
round: 1
updated: 2026-04-27T21:43:00
task: TASK-003
```

The five keys are the subagent's handshake. **`status.md` carries no in-flight marker** — earlier
versions of this skill appended `dispatched:` / `dispatched_at:` here and inferred a mid-flight
death from their presence. That never worked: `references/worker.md` Step 2 instructs the Worker to
drop those keys *on startup*, before doing any work, so the marker was gone within about a minute
of dispatch and every later death looked identical to a clean finish. The in-flight marker now
lives in `dispatched.md`, a file no subagent ever writes. If you see `dispatched:` keys in an old
`status.md`, ignore them.

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

### Setup: arm the watchdog

Once the options are resolved and before the first task, arm a self-nudge so a stalled run restarts
itself instead of waiting for a human. `CronCreate` and `CronDelete` may be deferred tools — load
them with `ToolSearch("select:CronCreate,CronDelete")` first if they are not already available.

```
CronCreate({
  cron: "*/17 * * * *",
  recurring: true,
  prompt: "SDLC watchdog for <TaskFilter>. If a subagent is currently running, or the run is
           finished or blocked awaiting the user, do nothing and say nothing. Otherwise the run
           stalled: follow 'Resuming an interrupted run' in the sdlc skill and continue."
})
```

Why this works: cron jobs fire **only while the session is idle**. A healthy pipeline sits inside
an `Agent` call almost continuously, so the watchdog stays silent. When a session limit or a crash
ends the turn, the session goes idle and the watchdog fires. If the limit has not reset yet, that
fire fails harmlessly and the recurring job stays armed — the first fire after the reset picks the
run back up. An off-minute (`*/17`, not `*/15`) keeps it off the clustered :00 and :30 marks.

Two limits to state to the user when you arm it: the job lives only in this session's memory, so
quitting Claude Code loses it, and recurring jobs auto-expire after 7 days.

**`CronDelete` it when the run ends** — completed, blocked, or handed back. A watchdog left armed
after the pipeline finishes will keep waking an idle session for a week.

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

**Arming a delegation.** Before *every* `Agent` call — Worker or Reviewer, every phase, including
re-dispatches — write `dispatched.md`:

```
role: WORKER
action: Implement the approved plan for roadmap task TASK-003
phase: CODE
round: 1
dispatched_at: <current ISO timestamp, read from the clock>
```

Delete it the moment that agent's completion notification arrives. Two rules follow from it, and
they are what make an interrupted run recoverable:

- **`dispatched.md` is a lock.** Never start a second Worker or Reviewer for a task while it
  exists. If you believe the running one is dead, you must still resolve the lock deliberately
  (below) rather than dispatching alongside it. Two agents editing one tree is the worst outcome
  this skill can produce — worse than a stalled run — because neither one's work can afterwards be
  trusted or cleanly separated.
- **Never infer liveness from silence.** `progress.md` is milestone-based by design
  (`references/worker.md` Step 4: append when a unit of work is *finished*, never when starting
  one), so a Worker in a single long implementation step legitimately writes nothing for an hour or
  more. Its timestamps are self-reported and in practice are often wrong by minutes, so they cannot
  even measure that silence reliably. Silence is not evidence of death.

**How you actually learn an agent stopped: the harness tells you.** `Agent` calls in this harness
are asynchronous and emit a task-notification carrying `completed` or `killed` when the agent
stops. That notification is authoritative and immediate — wait for it. Do not poll files, do not
time out a quiet agent, and do not reason about `git status` mtimes to decide whether something is
still alive.

**Model inheritance.** When spawning Worker or Reviewer agents via the `Agent` tool, pass the
current session's model via the `model` parameter. This ensures all agents in the SDLC pipeline —
orchestrator, Worker, and Reviewer — run on the same model tier. If the orchestrator is Fable 5,
workers and reviewers will be Fable 5. If Opus 5, they will be Opus 5, and so on.

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
do **not** re-run it. Instead confirm `handoff.md` has a `## Verification` section recording a green
`/verify`. If that evidence is missing, the approval is incomplete: do not commit — report it and
re-delegate the CODE review. (If the Reviewer reports it could not write `handoff.md`, transcribe
the content it returned into `handoff.md` yourself, then continue.)

Take the commit message verbatim from the `## Commit Message` section. **Stage explicit paths —
never `git add -A`.** Concurrent sessions share this checkout, so `-A` can commit another task's
uncommitted work as part of yours, which is both wrong and hard to unpick afterwards. Stage exactly
the paths in the plan's `## Impact Map`, repo by repo, plus the governing spec under `spec/`:

```
git -C <repo> add <path> <path> …
git -C <repo> commit -m "<message>"
```

`ROADMAP.md` needs extra care because it is shared. Before staging it, read `git diff ROADMAP.md`:
if it carries only your task's heading, stage the file; if another session's heading flip is in
there too, stage just your hunk with `git apply --cached` and leave theirs alone.

Then mark the ROADMAP heading `[DONE]` and either amend or add a follow-up commit — either is fine,
with the same explicit staging.

**6 — Integrate.** Commit on the project's **canonical branch** — never invent a per-task
`feature/<task>` or `sdlc/<TASK-ID>` branch. If that canonical branch is `master` (a solo project
where the PR flow is retired), committing there is correct; what is never automatic is the **push**.
Act on the `CreatePR` decision resolved at the start (do not re-ask):
- **false (default)** → stop at the local commit and report. The user reviews and pushes.
- **true** → push the branch and open a PR targeting the integration branch, building the body from
  `handoff.md` (`## What Changed`, `## Review Notes`). If a PR already exists, push to it instead of
  opening a duplicate. Report the URL.

**7 — Disarm.** When the last task in `TaskFilter` is done, `CronDelete` the watchdog before you
report.

**Blocked outcome (any step).** Set `status.md`'s first line to `BLOCKED` with the reason if the
subagent didn't, revert the ROADMAP heading to `[PENDING]` (block details live in `status.md`), then
continue to the next task if `ContinueOnBlocked` is true — otherwise `CronDelete` the watchdog, stop,
and report which task is blocked and why. The same applies at the Phase 0 decision gate: if you are
stopping to wait on the user, disarm first — the watchdog exists to restart stalled *work*, not to
nag someone who owes you an answer.

### Resuming an interrupted run

A run can stop dead at any point. The most common cause is an API session limit, and it does **not**
just kill the subagent — the error comes back as that subagent's tool result and then your own next
request fails too, ending the turn. The session sits idle until something restarts it. Crashes,
upgrades and machine restarts do the same thing.

So whenever you wake up on a task that already has a `.agents/sdlc/tasks/<TASK-ID>/` directory —
whether from the watchdog, a user's "continue", or a fresh session — **do not assume your context
reflects reality, and do not assume you dispatched what you think you dispatched.** Rebuild from
disk, in this order:

1. **`orchestrator-notes.md`** — binding user directives, the authorized round budget, and the
   interruption log. Read it first; it is the only place earlier sessions' decisions survive.
2. **`dispatched.md`** — present or absent; then **`status.md`** for the phase and round.
3. **`git status --porcelain`** in the umbrella and in each repo the plan's `## Impact Map` names —
   the repos your dead subagent could have touched. Changes elsewhere are a concurrent session's,
   not your casualty's; do not attribute them to it and do not act on them.

Then classify:

| What you find | What it means | What to do |
|---|---|---|
| No `dispatched.md` | The last subagent finished cleanly | Continue the round loop from `status.md` |
| `dispatched.md` present, and you are a *fresh* session (the run died with it) | That subagent died mid-flight — its reasoning is gone, its work is partial and unreviewed | Assess the tree, log it, delete `dispatched.md`, re-dispatch the same action |
| `dispatched.md` present and you are the *same* session that armed it | You have not received its completion notification, so **it is still running** | Wait. Do not dispatch alongside it. |

**Assessing the tree after a death.** You cannot tell finished work from abandoned work by looking
at it. `progress.md` is the successor's only trustworthy record of what actually landed. Anything
the tree contains that `progress.md` does not account for has **unknown provenance** — a file may
be a real artifact or a half-written guess. Say so explicitly in `orchestrator-notes.md` and name
what the successor must re-do or re-verify, rather than letting the next Worker inherit a file it
will assume is good.

**Log the interruption** under `## Interruptions` in `orchestrator-notes.md` before re-dispatching:
the phase it died in, when, what it left behind, and what the successor must re-verify. Then delete
`dispatched.md` and delegate again, arming a fresh one for the new dispatch.

**If you are wrong about the death, the log is what saves you.** An agent you wrote off can still
surface alive — it may simply have been inside one long, silent unit of work. The moment that
happens you have two writers on one tree, so stop *one* of them immediately and record in
`## Interruptions` which one you stopped and which files each had touched. Prefer keeping whichever
agent's context matches the tree as it now stands.

That entry is not bookkeeping. It is the replacement Worker's **authorization** to start against a
dirty tree, and it must name the phase, because a Worker with a partial tree and no interruption
entry is required to block with `DIRTY_WORKING_TREE`. Skip it and the pipeline stops dead; write it
loosely — "some work was in progress" — and the Worker inherits a tree it cannot reason about.

Do **not** roll the round counter forward for a subagent that died. It produced no review and no
submission; the round it was dispatched for is still unspent.

### Subagent prompt templates

Use verbatim, filling in `<TASK-ID>` and `<action>`. Subagent calls are **asynchronous**: the
`Agent` tool returns immediately and a task-notification arrives when the agent completes or is
killed. Wait for that notification — never poll the filesystem to guess at its state.

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
3. **Clean git state.** The Worker verifies `git status` before starting, and a dirty tree is debris
   unless its **action** explains it: the ROADMAP lock and uncommitted spec edits always, the
   previous round's code when addressing CODE findings, and a killed predecessor's partial work
   *only* when you recorded the interruption in `orchestrator-notes.md`. Otherwise `BLOCKED`, don't
   guess. Your half of this is writing that entry — without it the replacement Worker will
   correctly refuse to start.
4. **Assume you will be interrupted.** Only files survive a session limit. Arm the dispatch marker
   before delegating, keep `orchestrator-notes.md` current, and never let a decision live solely in
   your context.
5. **Reviewer reads ALL previous rounds** and says so explicitly ("I flagged X in round 1 and it
   remains unaddressed").
6. **Worker answers ALL findings** — fixed or explicitly rebutted, never silently dropped.
7. **Honor project rules.** Check `CLAUDE.md`, `GEMINI.md`, or an equivalent rules file for
   domain-specific criteria (financial precision, security policy, style mandates) and apply them
   in both implementation and review.
8. **Follow the project's own workflow** (e.g. `dev-flow.md`) during implementation. This skill adds
   review orchestration on top; it does not replace the project's methodology.
