# sdlc — agreed changes, not yet implemented

Working record of a design session held 2026-08-19/20 between the skill's author and a
design-partner agent. The agent walked `SKILL.md` and the author reviewed it section by
section; the session ended mid-walkthrough when the dev container died. **Nothing below has
been implemented.** Each item is either *agreed* (author decided), *recommended* (agent's
proposal, no decision yet), or *open*.

Two source documents back this up:
- the design partner's transcript: `~/.claude/projects/-IdeaProjects-Ricci/ef584fc6-25f5-4dd9-9f1d-07e4b79b8b66/subagents/agent-ad847d6fbf3ef9a61.jsonl`
- `docs/AUTONOMOUS_RUNS.md` in the Ricci repo, which records the evidence behind the
  three commits already landed (`e819746`, `015f548`, `9c2d6d4`).

The walkthrough covered `SKILL.md` only. **`worker.md` and `reviewer.md` were never
walked** — that is where the next session picks up.

---

## Index

One line per item, so a bare number is resolvable without scrolling.

| # | Item |
|---|---|
| 1 | One authority for the round cap |
| 2 | The ROADMAP `[DONE]` flip belongs to the Orchestrator |
| 3 | Handle the in-session `killed` notification |
| 4 | A real gate on Reviewer errors — **SETTLED 2026-08-22, see item 65: evidence floor only, no adjudicator** |
| 5 | Reviewer trigger table is missing the CODE-only trigger |
| 6 | Per-phase review filenames |
| 7 | Delete the archaeology |
| 8 | `CreatePR` defaults to false and is never asked at the start |
| 9 | Drop the TASK-030 anecdote from the commit-the-flip instruction |
| 10 | `SPEC_TOO_AMBIGUOUS` — keep the name, change the behavior |
| 11 | Delete the self-reported-timestamp caveat |
| 12 | Staging: the Impact Map is the wrong staging list |
| 13 | Branch policy becomes an input; legibility is served by a digest, not a PR |
| 14 | `orchestrator-notes.md` — keep it, fix four defects |
| 15 | Record process identity, not session identity, in `dispatched.md` |
| 16 | Delete the duplicated async note |
| 17 | Watchdog escalation must re-derive elapsed time from the clock |
| 18 | Stop trying to detect death; act with the `agent_id` — `SendMessage` first |
| 19 | The current watchdog prompt actively prevents its own fix |
| 20 | Say plainly that the skill cannot fix process death |
| 21 | Phase 0's first dispatch contradicts the Reviewer's own start-up guard |
| 22 | There is no channel for naming the governing spec |
| 23 | Item 6 lands harder than recorded — two rival conventions, not one improvisation |
| 24 | `worker.md` Step 5's round rule is arithmetically wrong |
| 25 | Files outside the Impact Map are reported but never reviewed — and then staged |
| 26 | `## Observations for Future Tasks` is a dead-letter box |
| 27 | `## Observations for Future Tasks` is not in the `plan.md` template |
| 28 | Item 11's premise is only half true — the Reviewer has no clock |
| 29 | The Reviewer has no crash story |
| 30 | `reviewer.md` never mentions `orchestrator-notes.md` or `progress.md` |
| 31 | Item 1 and item 10 each have a second site in the phase files |
| 32 | Item 10 collides with an existing `## Assumptions` section |
| 33 | Item 13's digest premise is stronger than recorded |
| 34 | `/verify` carry-forward is an undocumented carve-out agents invented |
| 35 | Do not weaken the Reviewer's independent test run |
| 36 | The invented clock is inherited through `status.md` |
| 37 | `worker.md` L17 offers a passive channel for something that requires a stop |
| 38 | Mandate the command, not the prohibition — and require the `Z` |
| 39 | Step 0.1 tells the Worker to make an edit Step 0.2 would later call debris |
| 40 | The per-repo scoping is a no-op in this project |
| 41 | Step 0.2 has never fired — not once |
| 42 | The legitimacy list is missing "the task's own ROADMAP row is new" |
| 43 | Step 0's revival path depends on a file nothing creates |
| 44 | Item 7's archaeology has three sites, not one |
| 45 | Item 6's `round:` warning has three sites too |
| 46 | Three different agents create `status.md` and nothing arbitrates |
| 47 | A self-selecting Worker takes a task without locking it |
| 48 | The Worker is told to read `orchestrator-notes.md` for only one of its four purposes |
| 49 | `Depends on:` is checked but never re-checked |
| 50 | Item 2 has a fourth site — and it is a *spec* file |
| 51 | `progress.md` adoption tracks `orchestrator-notes.md` exactly |
| 52 | The Worker is told to emit a block reason with no field and no template |
| 53 | The Orchestrator relabels a correct Worker block as a protocol failure |
| 54 | The `date` command needs the `Z` and seconds baked in |
| 55 | "What NOT to do" restates phase-file rules and is read where they cannot apply |
| 56 | A `progress.md` heartbeat line — parked, author unconvinced |
| 57 | `progress.md` needs entry *types*, not more detail |
| 58 | The Reviewer self-selects its task, the same way the Worker did |
| 59 | PLAN and CODE Reviewers are never told to read the governing spec |
| 60 | In a single-repo project the unaccounted-changes sweep reports the siblings |
| 61 | The `BLOCKED` reason vocabulary is split across three files with no canonical list |
| 62 | The review template has no `## Verification` section, so 51 reviews invented ten |
| 63 | Step 6 is an empty section |
| 64 | `handoff.md` on `BLOCKED` — two files disagree about where block details live |
| 65 | Item 4 (the Reviewer-error gate) — SETTLED: evidence floor only |
| 66 | The three-architects PLAN fan-out has never fired |
| 67 | Specs are pinning implementation, and it is measurable |
| 68 | Spot-check 1 — reconciling `## Assumptions` with `## Assumed Decisions` |
| 69 | Spot-check 2 — the unreviewed-file hole, and a reconsideration of item 12 |
| 70 | Spot-check 3 — `worker-plan.md`'s Impact Map paragraph states a purpose that becomes false |
| 71 | Deduplication and read amplification — measured |
| 72 | The plan-length budget — WITHDRAWN, the author's worry is correct |
| 73 | Fix the 50-150 guidance text instead |
| 74 | Item 59 restated and re-priced |
| 75 | There is no spec template, and that is the root cause of two other problems |
---

## Agreed

### 1. One authority for the round cap
`reviewer.md` hardcodes `round 3` in three places (lines 185, 189, 216), stale against the
new `MaxRounds: 4`. Worse, the Reviewer is *never told* `MaxRounds` — it is absent from the
Reviewer prompt template and from `status.md`. Two independent enforcers hold different
numbers: at MaxRounds 4 the Reviewer self-blocks a round early; at MaxRounds 2 it happily
writes round 3. Drop the hardcoded number and pass `MaxRounds` through.

Same class of bug as the `round:` ambiguity already fixed — a counter compared against the
wrong authority.

### 2. The ROADMAP `[DONE]` flip belongs to the Orchestrator
Three documents disagree today: `reviewer.md` Step 5 tells the Reviewer to mark `[DONE]` on
CODE approval, `SKILL.md` step 5 tells the Orchestrator to do it after committing, and
`worker.md` says "Don't modify ROADMAP.md status. The Orchestrator owns that."

Beyond the contradiction, the Reviewer's flip lands *before the commit exists* — and
`SKILL.md` explicitly contemplates the Orchestrator refusing to commit over a missing
`## Verification` section. The ROADMAP would then claim DONE for work never committed.
That is the TASK-030 invisible-state failure with the sign flipped.

Strip the flip from `reviewer.md` Step 5.

### 3. Handle the in-session `killed` notification
The recovery table covers a *fresh* session finding a stale `dispatched.md`. It does not
cover a subagent killed while the Orchestrator is alive: the Orchestrator gets a `killed`
notification and falls into the round loop, where a Worker that left `IN_PROGRESS` reads as
`WORKER_DID_NOT_SIGNAL` → blocked.

Correct response is the death path: log an `## Interruptions` entry, delete the lock,
re-dispatch the same action, **do not spend a round**.

> Settled after the session ended: `killed` is real, and it is specifically the `TaskStop`
> signature — 18 occurrences in this session's transcript. It is absent from the historical
> corpus (450 transcripts) only because `TaskStop` had essentially never been used before
> 2026-08-19. Quota kills use `completed`/`failed`, never `killed`. Safe to write into
> `SKILL.md`; see the measurement block below for the full signature table.

### 5. Reviewer trigger table is missing the CODE-only trigger
`SKILL.md`'s trigger table for the Reviewer omits "review the code for task X".

### 6. Per-phase review filenames
`plan-review-round-N.md` / `code-review-round-N.md` alongside the existing
`spec-review-round-N.md`.

This does more than tidy names — **it removes the source of the `round:` bug.** Today the
filename counter runs across phases while `round:` resets, so `SKILL.md` has to carry a
warning that a Worker will misread it. That warning is maintenance of a trap. Per-phase
filenames make filename `N` == `round:` `N` in every phase and the warning can be deleted.

Supported by observed behavior: TASK-032 and TASK-044 spontaneously wrote
`plan-review-round-N.md` / `code-review-round-N.md` on their own. We would be ratifying what
agents already do when the shared counter confuses them. Task dirs are gitignored and
disposable — no migration story.

### 7. Delete the archaeology
"earlier versions of this skill appended `dispatched:` / `dispatched_at:` here and inferred a
mid-flight death from their presence…" — nobody cares what it was. Drop it.

### 8. `CreatePR` defaults to false and is never asked at the start

### 9. Drop the TASK-030 anecdote from the commit-the-flip instruction

### 10. `SPEC_TOO_AMBIGUOUS` — keep the name, change the behavior
The author's call: the name is fine, the behavior is wrong. Instead of bailing out, the
pipeline should ask the questions that matter and decide the rest.

- **Ask** target 0-5, hard ceiling 10 for genuinely complex tasks. Decide the remainder.
- **The split needs a mechanical test, not "importance"** (agreed): *would a different answer
  change what gets built?* → ask. *Only how it is described, named, or ordered?* → assume.
  "Most important" with no test behind it becomes whatever the Reviewer already wanted —
  same reasoning as `AUTONOMOUS_RUNS.md`'s "resist soft criteria".
- **Visibility without a second stop** (agreed after pushback): the author's "show me the
  list of decisions before the next stage" read as a *second* gate, which in an unattended
  run is a stall discovered hours later. Instead the **Reviewer** produces both tables in
  `spec-review-round-N.md` — `## Open Decisions` (asked) and `## Assumed Decisions`
  (decision, recommended answer, one-clause rationale). Both surface at the *existing*
  Phase 0 gate: questions via `AskUserQuestion`, the assumption table rendered alongside with
  a closing "any of these wrong?". One checkpoint preserved.
- **`SPEC_TOO_AMBIGUOUS` survives with a new trigger**: irreducible ambiguity only — the spec
  contradicts itself, or a decision needs information nobody in the pipeline has. *Never a
  count.* Without that exit, a self-contradictory spec has no escape and the Worker assumes
  its way through a contradiction.
- **Implementation note:** `AskUserQuestion` caps at 4 questions per call. Ten asked
  decisions therefore means consecutive prompts — one gate, several prompts.

### 11. Delete the self-reported-timestamp caveat
`SKILL.md` says progress timestamps "are self-reported and in practice are often wrong by
minutes, so they cannot even measure that silence reliably." `worker.md` now mandates running
`date -u +%Y-%m-%dT%H:%M` as a tool call and pasting stdout unedited, so the caveat describes
a bug that no longer exists. Delete it; **keep** "silence is not evidence of death."

### 12. Staging: the Impact Map is the wrong staging list
The author observed Orchestrators improvising past the rule during review rounds — correctly.
The skill uses the **Impact Map** as the staging list, but the Impact Map is a *plan* artifact,
written before code exists and reviewed as intent. Review rounds legitimately push the Worker
outside it; that is what round 2 is *for*. So the staging list is guaranteed to drift and the
Orchestrator must either commit an incomplete change or break the rule.

Two distinct problems, two fixes:

- **Stale list** → ask the agent that actually knows. The Worker wrote the files, so have it
  maintain `changed-files.md` — path plus a one-clause "what I changed here" — refreshed at
  the end of each round. The Orchestrator stages from that, not from the Impact Map. The
  Impact Map keeps its real job (approved intent), and manifest-vs-map divergence becomes a
  **Reviewer** check — it already compares `git status` against the Impact Map. Divergence is
  a *reported deviation*, not an automatic block; "flag deviations even when they are
  improvements" is already the rule and a round-2 fix touching a new file is normal.
- **Shared file** → the skill already prescribes hunk-splitting, but only for `ROADMAP.md`.
  Generalize that paragraph to any shared file with `ROADMAP.md` as the worked example. The
  Worker's one-clause note per file turns the Orchestrator's job from *judging* provenance
  into *looking it up* — it still never reads a diff.

Say plainly what the text leaves implicit: hunk-splitting is a fallback for running the
pipeline in a **shared checkout**; a dedicated worktree removes the entire class, which is why
autonomous runs never hit it. **Keep "never `git add -A`"** — the answer to a stale path list
is a better path list, not a blunter instrument.

### 13. Branch policy becomes an input; legibility is served by a digest, not a PR
Real contradiction found by the author: `CreatePR: true` needs a branch that is not the
integration target, but "never invent a per-task branch" plus "canonical == `master`" makes
the PR a self-PR. The text silently assumes canonical is a working branch.

- **Fix:** make branch policy an **input**. `Branch: canonical` is the default — exactly
  today's behavior, so Masha's flow is untouched and she never has to know the option exists —
  or a named run-scoped branch when the caller wants one. **Reject per-task branches**; they
  would earn back the rebase-cascade pain already suffered.
- **The author's actual reason was legibility** ("I have a hard time understanding what the
  robot does at this point"), not isolation. A worktree isolates the *tree* and does nothing
  for the *history*, which is what you read. Meanwhile the pipeline already produces exactly
  the wanted artifact and throws it away: every task's `handoff.md` has `## What Changed`,
  `## Verification`, `## Review Notes`, written by a Reviewer that just read the whole diff —
  and it sits in a gitignored directory nobody opens again.
- **Decided: a run digest.** Assembled from each task's `handoff.md` plus the commit SHA,
  written locally, no push. The `AUTONOMOUS_RUNS.md` "may never push, open, or comment on a
  PR" rail stays untouched. The handoffs stay on disk for when detail is wanted.

### 14. `orchestrator-notes.md` — keep it, fix four defects
The agent initially suspected the file was dead weight and **its premise was wrong**; an audit
of all 49 task directories settled it:

- The artifact only entered the skill on 2026-08-09 (`d720904`). Of the 8 runs since, 6 wrote
  one; of the runs since 2026-08-13, **6 of 6**. The 41 older dirs predate it, so their
  absence proves nothing.
- It has been **consumed for real recovery twice** — on both TASK-044 and TASK-030 the
  successor Worker cites it by name in `progress.md` to justify starting against a dirty tree,
  and on TASK-030 it is what caught the corrupted round counter.
- Four classes of information live nowhere else on disk: in-session user decisions (skip
  Phase 0, raise the round budget, model sizing, "take fix (a) not (b)"); round-budget and
  round-counter corrections; cross-phase carry-forward and pre-authorized scope; and
  interruption provenance.

Defects to fix:

1. **Nothing tells the Orchestrator to create it.** The only write instructions are a
   half-sentence at L316 and "keep it current" in rule 4. The six existing files converged by
   *imitation*, not specification — which is why the seventh will drift.
2. **`cat >>` appends re-emit `## Interruptions`.** TASK-044 and TASK-030 each carry the
   heading twice, and in both the **empty placeholder comes first**. A successor scanning for
   the section finds `_(none)_`, concludes there was no interruption, and deadlocks on "no
   authorization to start on a dirty tree." *The sharpest bug the audit turned up.*
3. **No template.** Six files, six vocabularies — `## Log` vs `## Phase log`, one directives
   section vs two, plus one-off sections nobody else used.
4. **No size discipline.** 920 B to 21 KB. TASK-038's log paraphrases the review files at
   length and buries the recovery-critical round-budget caveat inside 21 KB of narrative.
   Rule: **this file holds only what no other artifact holds.**

### 15. Record process identity, not session identity, in `dispatched.md`
`claude --continue` restores the transcript, so a resumed Orchestrator "remembers" arming the
lock and classifies itself as the same session — then waits forever for a notification from a
subagent that died with the old process. Write `owner_pid` plus `owner_start` (field 22 of
`/proc/<pid>/stat`, which defeats PID reuse) at arm time. On wake, if the PID is gone or the
start time does not match, take the fresh-session path regardless of what the transcript
remembers. Process death is a fact on disk; session identity is a story in the context.

**Scope correction:** this addresses the Docker-death case, which is *rare*. It does **not**
help the quota case — see item 19.

### 16. Delete the duplicated async note
"Subagent calls are asynchronous: the Agent tool returns immediately and a task-notification
arrives…" appears twice in `SKILL.md`, once in the prompt-template section repeating a note
above it in the same file.

### 17. Watchdog escalation must re-derive elapsed time from the clock
The proposed ladder counted watchdog ticks. Forensics killed that: **cron fires are dropped,
not queued**, while a turn is pending (measured blackouts of 88 and 66 minutes, swallowing
roughly five and three fires). A `*/17` schedule does not give you 17-minute ticks. Every fire
must compute elapsed time from timestamps, never from a tick count.

### 18. Stop trying to detect death; act with the `agent_id` — `SendMessage` first
The Orchestrator holds the `agent_id` the `Agent` tool returns. **Record it in
`dispatched.md`.** Recovery then becomes a ladder keyed off that id, cheapest and least
destructive first:

| Elapsed, no notification | Action |
|---|---|
| < ~35 min | no-op — normal silence during a long unit of work |
| ~35 min+ | **`SendMessage(agent_id)`** — non-destructive; costs a message if healthy, unsticks it if not |
| ~1 h+, still nothing | `TaskStop(agent_id)`, log `## Interruptions`, re-dispatch |

The agent's first draft had `TaskStop` **first** on the theory that destructiveness buys
certainty. The author corrected it — the subagent is not gone, it is recoverable, and normally
the author just tells the Orchestrator to continue. Forensics confirmed: `SendMessage` on a
quota-killed agent returns *"had no active task; resumed from transcript in the background
with your message"* and the agent continues **with full context**. Proven twice.

One nuance the skill must get right: it is **not** suspension. The process is gone and the
transcript is replayed into a fresh one. Practically identical for our purposes, but the skill
must describe the *recovery* as available — never describe the agent as "still running."

The counter-example matters: a third quota-killed agent was simply abandoned because nobody
messaged it. **The harness will not resume it for you.**

Property worth naming: being wrong is now cheap at every rung. The old design had one action
(re-dispatch) whose failure mode was two writers on one tree, so it had to be certain first —
and certainty was never available.

### 19. The current watchdog prompt actively prevents its own fix
It says "if a subagent is currently running… do nothing and say nothing" — and a quota-killed
subagent still reads as running. **That clause has to go.** Forensics: **28 fires out of 28**
landed while an async Agent was outstanding; zero landed with nothing running. The watchdog has
been a permanent no-op for its entire existence.

### 20. Say plainly that the skill cannot fix process death
When the process dies, everything in-session dies with it — including the cron watchdog, which
is in-memory. No instruction in `SKILL.md` can revive a process that no longer exists. What the
skill *can* own is the property it already has: leave enough on disk that any fresh session
rebuilds the state (`dispatched.md` + `orchestrator-notes.md` + `progress.md`). The
fresh-session path is the one branch of the recovery table that is actually proven.

The other half — *who starts the fresh session* — belongs in `AUTONOMOUS_RUNS.md`, not here:
an external supervisor living outside the container (host-side tmux plus a systemd timer or
cron) that notices a dead or idle session and issues `claude --continue`. Note `--print` is
unusable for this: it cannot answer `AskUserQuestion`. Whether that supervisor lives on the WSL
host or on loshadka is undecided, and it is separate work from the skill edits.

---

## Recommended, awaiting a decision

### 4. A real gate on Reviewer errors — **SETTLED 2026-08-22, see item 65: evidence floor only, no adjudicator**
Today the Reviewer is judge in its own cause: the Worker rebuts, and the Reviewer's own
"Previous Round Follow-Up" decides whether the rebuttal stands. Three candidates, ranked by the
agent:

1. **Adjudicated contested findings (its recommendation).** A gate fires only on *contest* —
   Worker rebuts with a citation, Reviewer re-asserts — and dispatches a third agent scoped to
   just the finding, the rebuttal, and the cited source. No diff, no plan, tiny context, fires
   rarely. Hits the observed failure exactly: TASK-030's "no shift shape is loadable" survived
   only because that Worker happened to be rigorous. Cost: one small dispatch per contested
   finding, plus one new artifact.
2. **Evidence floor (cheap — do it regardless).** Every Critical must cite a resolvable
   `file:line` or pasted command output, and `worker.md` states plainly that an uncited
   Critical is a legitimate rebuttal. Kills fabricated citations; does nothing about wrong
   inference from a real line. Good as the floor *under* the adjudicator, not as the gate.
3. **Second full reviewer — rejected.** Doubles cost, same failure mode, invites infinite
   regress.

Explicitly rejected: having the Orchestrator spot-check reviews. Its value is that it never
reads a diff, and context flatness across many tasks is what makes long unattended runs
possible.

---

## Measurement block

From a forensic sweep of the full transcript corpus — 450 `.jsonl` files, 165 MB, 31 parent
sessions. Only two quota windows exist in the entire history, both July 2026.

**Death signatures, and how to tell them apart:**

| Signature | Cause | Response |
|---|---|---|
| `killed` notification | deliberate `TaskStop` | you did it — act accordingly |
| `completed` *or* `failed`, result text contains `Agent terminated early due to an API error` | quota / session limit | `SendMessage(agent_id)` to resume |
| **nothing ever arrives** — no result, no notification, no error; transcript ends mid-tool-call | process death | `TaskStop`, then re-dispatch |

1. **Detection keyed on the status field is blind.** A quota kill reports
   `toolUseResult.status = "completed"` on the blocking path and `failed` on the async path
   for the *identical* failure. The reliable signal is the result **text**, never the status.
   The real limit string is `You've hit your session limit · resets <time> (UTC)` — note
   `resets`, not `resets at`. The reliable index across transcripts is
   `"isApiErrorMessage":true`.
2. **Process death has a clean, observable signature: nothing ever arrives.** Unlike "am I a
   fresh session," that is a fact rather than a belief. One of the two process deaths found is
   a direct precedent for the dual-writer hazard — a dispatched agent worked 3 hours, stopped
   silently, the parent got nothing, and later dispatched a **duplicate worker onto the same
   tree**.
3. **The watchdog is empirically a permanent no-op: 28 fires out of 28** landed while an async
   Agent was outstanding; zero landed with nothing running.
4. **Cron fires are dropped, not queued** while a turn is pending — blackouts of 88 and 66
   minutes measured.
5. **Recovery was never automatic: 3 of 3 stalls were resumed by the author typing
   "continue"** — after 18h45m, 9h15m, and 9h15m, all well past the quota reset. The delay was
   human availability, not the limit. That is the cost of the missing automation, measured.
6. The limit is **account-wide, not session-scoped**: in window B two independent parent
   sessions were killed within 300 ms of each other.
7. A single-holder `.claude/scheduled_tasks.lock` does **not** block a sibling session's cron —
   measured 2026-08-20T01:52:06 against a `01:52` target (6 s late) while PID 96976 held it.

---

## Still to do

- **`worker.md` and `reviewer.md` were never walked.** The author stopped after `SKILL.md`'s
  Integrate section. Resume there.
- Decide item 4 (the Reviewer-error gate).
- Then SDLC the whole list — the author's instruction was "make a list of things for you to
  later SDLC them," so this file is the input to a Spec, not a change order.

---

# Session 2 — `worker.md` / `reviewer.md`

Second design session, 2026-08-20. Everything below is the **design partner's own read before the
author walked the files** — marked *recommended* or *open*, none of it decided. It is written down
up front only so a container death cannot lose it again. Numbering continues from 20.

## Recommended / open — not yet walked with the author

### 21. Phase 0's first dispatch contradicts the Reviewer's own start-up guard *(agreed — option A, ratify the observed behaviour)*
`SKILL.md` step 2a makes a **Reviewer** the first agent on a spec-governed task, before any Worker
has run. But:
- `reviewer.md` Step 0.3: find a task dir "whose `status.md` says `AWAITING_REVIEW`".
- `reviewer.md` Step 0.4: "Identify the phase from `status.md`."
- the Reviewer prompt template: "`status.md` should say `AWAITING_REVIEW` — if it does not, report
  this and stop without writing a review."

On a fresh spec-governed task there is no `status.md` at all — only the Worker's Step 2 creates it —
so by the letter of the protocol the first Phase-0 Reviewer must stop. Nothing tells the Reviewer to
create `status.md`, and the template has no `phase:` slot, so `phase: SPEC` has no channel to travel
on. 23 tasks ran SPEC rounds anyway, which means Orchestrators improvised past this every time.

### 22. There is no channel for naming the governing spec *(RESOLVED by agreed items 74 + the `**Spec**:` requirement)*
`SKILL.md` triggers Phase 0 when "the prompt references a `spec/spec-*.md` **or** the ROADMAP task
links one" — but if it came from the prompt, neither Worker nor Reviewer ever learns which file.
Both protocols only say "the spec file the task references". Agents plugged the hole themselves: **8
of 47** `status.md` files carry an invented `spec:` key (A5, A7, B9, B11, B15-live, B20, S22,
SESSION-10), and one carries `plan:`/`review:`/`summary:` as well. The handshake schema is five keys;
agents needed six.

### 23. Item 6 lands harder than recorded — two rival conventions, not one improvisation *(agreed — folded into item 6; fixes Step 1.2's read-list too)*
The corpus shows **six** tasks inventing per-phase filenames across six weeks, in **two mutually
incompatible mappings**:
- B10 (2026-07-05), B15-live (2026-07-15), TASK-044 (2026-08-16): `plan-review-round-N.md` for PLAN,
  `review-round-N.md` for CODE.
- TASK-028 (2026-08-10), TASK-031 (2026-08-11), TASK-032 (2026-08-13): `review-round-N.md` for PLAN,
  `code-review-round-N.md` for CODE.

Three of them wrote an in-file apology for it, citing each other as precedent ("named
`code-review-round-1.md` per the TASK-028 convention (the most recent precedent)"; "the B10/B15-live
naming precedent"). TASK-044 went further and **renamed its predecessor's review files**, a mutation
of prior artifacts nothing authorizes.

The consequence is worse than untidiness: `reviewer.md` Step 1.2 tells a CODE Reviewer to read "all
previous review files for this phase — `review-round-N.md`". Under the TASK-028 convention those
files are the **PLAN** reviews. A CODE Reviewer following the protocol literally reads the wrong
phase's findings and escalates them. Item 6 must therefore also fix Step 1.2's read-list, not just
the write-name.

### 24. `worker.md` Step 5's round rule is arithmetically wrong *(agreed — folded into item 6)*
Step 5: "The round number is the count of existing review files for **this phase** — …otherwise
`review-round-N.md`. First submission is round 1." With the shared counter, a CODE Worker's first
submission after 3 PLAN rounds counts 3 files and writes `round: 3`. The rule contradicts its own
next sentence. `reviewer.md` Step 2 has the identical defect ("count of existing review files for
this phase, plus 1"). Both are *unexecutable* today — you cannot tell a file's phase from its name.
This is the same defect `SKILL.md` currently papers over with a warning paragraph; item 6 deletes the
cause in all three files at once.

### 25. Files outside the Impact Map are reported but never reviewed — and then staged *(RESOLVED by agreed item 69 option B — Reviewer reviews the union)*
`reviewer.md` Step 1.4 (CODE): review "the paths in the plan's `## Impact Map`, **and only those**",
then list anything else as an unaccounted change and "**do not review it**". Item 12 changes staging
to a Worker-maintained `changed-files.md`. Composed, those two give a path that is *staged and
committed without ever being reviewed*: a legitimate round-2 fix in a file the map does not name.
Item 12 must therefore also move the Reviewer's review scope, not only the Orchestrator's staging
scope — otherwise it converts a stale-list problem into an unreviewed-code problem. The corpus shows
unaccounted changes are real and recurring (17 review files across 6 tasks report them).

### 26. `## Observations for Future Tasks` is a dead-letter box *(agreed — alternative A)*
`worker.md` and `worker-code.md` both say: don't fix adjacent bugs, note them in `plan.md` under
`## Observations for Future Tasks` "and tell the user at the end of the session". **34 of 47**
`plan.md` files carry that section — and `plan.md` is gitignored, disposable, and something
`SKILL.md` deliberately keeps the Orchestrator out of. In an unattended run there is no user to tell.
TASK-037's Worker wrote the observation "with the one-line remediation **for the Orchestrator to
raise**" — a handoff to a reader the protocol never appoints.

Sampling shows real content dying there (B15-live: a permanent broker 404 misclassified as
transient). Exactly one survived: TASK-044's `syncFills` observation is now `[PENDING] TASK-045` —
raised by hand in an interactive session, not by the pipeline.

**Author's correction (accepted):** this is a *carry-forward* problem, and it must not be conflated
with escalation. See item 37. Observations are things the Worker noticed and is forbidden to act on;
they never block. Open decisions are things the Worker cannot proceed without; they always block.
Different problems, different channels.

**Author's question: what does co-authoring `handoff.md` cost, and what are the alternatives?**

The cost is real and it is the failure mode this skill has already been bitten by. `handoff.md` today
has exactly one writer, at exactly one moment (Reviewer, at terminal verdict). Adding a second writer
buys three hazards:

- **Silent clobber.** The Reviewer writes `handoff.md` wholesale from a template. A Worker section
  written earlier in the round is simply gone — no conflict, no error. This is item 14 defect 2 with
  the sign flipped: there, `cat >>` appends produced duplicate headings and a successor read the
  wrong one; here, a template rewrite produces a missing section and nobody reads anything.
- **Invisible mid-flight state.** `handoff.md` is terminal by construction. A file titled
  `# Task Handoff` existing during round 1 is exactly the TASK-030 class of bug: a fresh Orchestrator
  rebuilding from disk sees a completion artifact for work that is not complete.
- **Ordering.** The Reviewer's write is always last. Anything the Worker puts there has to survive an
  agent that has no instruction to preserve it.

Four alternatives, ranked:

**A — Reviewer transcribes; `handoff.md` keeps one writer.** The Reviewer already reads `plan.md` in
full (Step 1.1), observations included. Add an `## Observations` section to the Step 5 handoff
template, carried across. *Cost:* one template section. No new writer, no new file, no new read in
`SKILL.md`. The digest (item 13) then picks it up for free. *Downside:* the Reviewer is a filter and
may drop or reword — arguably correct, since it is the skeptical reader, but it is a real loss of
fidelity.

**B — A separate `observations.md`, single writer.** Worker owns it; the Orchestrator collects it
into the digest. *Cost:* one more artifact in a directory that already carries eight file types, and
item 14's lesson is that an artifact without a template and a create instruction drifts into six
vocabularies. *Upside:* preserves the Worker's exact words.

**C — Worker appends a `[PENDING]` row to `ROADMAP.md`. Rejected.** It drives straight through two
existing rails: `worker.md`'s "don't modify ROADMAP.md status — the Orchestrator owns that", and
`AUTONOMOUS_RUNS.md`'s "the loop may never promote a finding into a new task."

**D — Delete the instruction and accept the loss.** Belongs on the table honestly. 34 of 47 tasks
wrote observations; one became a task. If the content is not worth a channel, the cheap fix is to
stop asking for it rather than to build plumbing. Against this: the sample is not noise — the one
that escaped became TASK-045, and B15-live's 404 finding is a live-path defect that is still unfiled.

**Decided: A.** The Reviewer transcribes observations from `plan.md` into an `## Observations`
section of the `handoff.md` template in `reviewer.md` Step 5. `handoff.md` keeps exactly one writer.
B, C and D are rejected.

### 27. `## Observations for Future Tasks` is not in the `plan.md` template *(agreed — follows item 26)*
Two files instruct the Worker to write into a section `worker-plan.md`'s template never defines.

### 28. Item 11's premise is only half true — the Reviewer has no clock *(agreed — see item 38 for the final form)*
Item 11 deletes `SKILL.md`'s self-reported-timestamp caveat because `worker.md` now mandates running
`date -u +%Y-%m-%dT%H:%M` and pasting stdout. That mandate exists **only in `worker.md`**.
`reviewer.md` Steps 2/5 and `SKILL.md`'s `dispatched_at` both just say "current ISO timestamp" — so
Reviewer and Orchestrator timestamps are still composed. Every terminal `status.md` in the corpus
ends in `:00` seconds, and TASK-032's `DONE` claims `12:05` against review files written at `05:57`.
Propagate the mandate to `reviewer.md` and to the Orchestrator's `dispatched.md` before deleting the
caveat — otherwise item 11 deletes a warning that is still accurate for two of the three roles.

### 29. The Reviewer has no crash story *(agreed — option A, idempotent review-file write)*
`worker.md` Step 4 gives the Worker `progress.md` and an explicit "your session can end without
warning". `reviewer.md` has no equivalent. Concretely: a Reviewer killed *after* writing
`review-round-N.md` but *before* rewriting `status.md` leaves `AWAITING_REVIEW` on disk. The
re-dispatched Reviewer counts existing files **plus 1** and writes round N+1 — spending a round on a
review that was already done, and burning the round budget on a death. Needs a rule: if a review file
for the current round already exists and no Worker has submitted since, replace it rather than
increment.

### 30. `reviewer.md` never mentions `orchestrator-notes.md` or `progress.md` *(agreed — same fix as item 48, applied to the Reviewer)*
Item 14 establishes `orchestrator-notes.md` as the only surviving record of in-session user decisions,
round-budget corrections, and pre-authorized scope. The Worker is told to honor an `## Interruptions`
entry. The Reviewer is told nothing — so a Reviewer can block on a deviation the user explicitly
pre-authorized, or flag a partial tree the Orchestrator already logged. At minimum the Reviewer
should read it in Step 0.

### 31. Item 1 and item 10 each have a second site in the phase files *(agreed — folded into items 1 and 10)*
- Item 1 (round cap): the hardcoded `3` is in `reviewer.md` at Step 5 NEEDS_FIXES, Step 5 BLOCKED,
  and the "Don't approve because it's round 3" rule — three sites, all needing `MaxRounds` passed in.
- Item 10 (`SPEC_TOO_AMBIGUOUS`): the cap-of-5 is duplicated in **`review-spec.md`** ("Cap
  escalations at 5") as well as `reviewer.md`. Item 10's mechanical ask/assume test and its
  `## Assumed Decisions` table belong in `review-spec.md`'s Triage section, which is where the
  Reviewer actually makes the call.

### 32. Item 10 collides with an existing `## Assumptions` section *(RESOLVED by agreed item 68 option A)*
`worker-spec.md` already tells the SPEC Worker to record what it guessed in an `## Assumptions`
section **inside the spec file**, calling it "the user's cheap second catch". Item 10 puts an
`## Assumed Decisions` table in `spec-review-round-N.md`, written by the **Reviewer**, surfaced at the
Phase-0 gate. Both can stand, but they must be reconciled explicitly: the Reviewer's table is the
gate-time render of decisions *not yet made*, the Worker's section is the durable record of decisions
*it made*, and each needs to say so or they will drift into two half-kept lists.

### 33. Item 13's digest premise is stronger than recorded *(informational)*
The terminal artifact exists in **45 of 47** task dirs (`summary.md` × 41 before the rename,
`handoff.md` × 4 after). A run digest assembled from them has near-complete source coverage.

### 34. `/verify` carry-forward is an undocumented carve-out agents invented *(agreed — option A, compressed wording)*
`review-code.md`: "A green `/verify` is a **precondition for approval** — any failure here is finding
#1, Critical." `SKILL.md` step 5: the Orchestrator confirms `handoff.md` records a green `/verify`
and refuses to commit without it. Measured: **21 of 25** CODE Reviewers exercised the runtime surface
in-session; **3 approved on a carried-forward green from an earlier round**, each stating the reason
(narrow delta touching one catch clause plus Markdown; fixes touching sync logic and tests only). The
reasoning is sound and the behavior is probably right — but the protocol forbids it, so three
approvals were out of compliance, and the Orchestrator's commit gate cannot tell a carried-forward
green from a fresh one because both render as prose in `## Verification`.

Fix: codify the carve-out (a round whose delta cannot reach any surface the earlier run exercised may
carry it forward) and require `## Verification` to say *which round* the green came from, so the
Orchestrator's check has something mechanical to read.

### 35. Do not weaken the Reviewer's independent test run *(informational)*
Measured: **25 of 25** CODE Reviewers ran the suite themselves via a Bash call; **zero** approved on
the Worker's claimed results. 17 of 25 defeated Gradle's cache with `cleanTest`/`--rerun-tasks`. One
went further and ran a mutation test against the Worker's fix, then cleaned up its own DB rows. The
mandate in `review-code.md` line 1-11 is being honored in full, and it is cheap — see the session-2
measurement block. This is the strongest-performing instruction in either file; leave it alone.

---

## Session-2 measurement block

Second forensic sweep, 2026-08-20. 452 `.jsonl` files, 419 subagent sidechains, of which **75 are
`sdlc` Reviewer sessions** (20 SPEC / 30 PLAN / 25 CODE) and **73 Worker** (13 / 32 / 26 / 2
unclassifiable). Phase determined from the review-file header each session actually wrote.

**1. The Phase-0 contradiction (item 21) is real but has never fired, because Orchestrators
fabricate the handshake.** In **7 of 7** spec-governed entries the Orchestrator hand-wrote
`status.md` with `AWAITING_REVIEW` / `phase: SPEC` / `round: 1` *seconds before* dispatching the
Reviewer, with no Worker having run. **0 of 75** Reviewer sessions ever refused to start — 75/75 read
`AWAITING_REVIEW` and 75/75 wrote a review. The stop-condition never fired because the Orchestrator
always satisfied it in advance, by an act nothing in `SKILL.md` prescribes.

Three consequences the fix must absorb:
- **3 of 7** dispatches used the verbatim template (which never mentions SPEC at all); **4 of 7**
  improvised the SPEC instructions into the prompt. The template is doing none of the work.
- **4 of 7** pre-writes carried an obviously invented midnight timestamp (`2026-08-09T00:00:00`,
  `2026-07-14T00:00:00`, …).
- **3 Orchestrators stuffed the action into the legacy `dispatched:` key inside `status.md`** — the
  one field `reviewer.md` Step 0.4 explicitly tells the Reviewer to ignore and strip. The action
  travelled on a channel the protocol tells the receiver to delete.

**2. The Reviewer's independent verification is honored and cheap.** 25/25 ran the suite; 21/25
exercised the runtime surface (7 via the `Skill` tool, 14 by executing `verify.md`'s recipe by hand).

| Role / phase | n | median wall | median tool calls |
|---|---|---|---|
| Reviewer SPEC | 20 | 5.8 min | 20 |
| Reviewer PLAN | 30 | 6.7 min | 22 |
| **Reviewer CODE** | 25 | **12.6 min** | **52** |
| Worker SPEC | 13 | 5.4 min | 30 |
| Worker PLAN | 32 | 6.7 min | 32 |
| **Worker CODE** | 26 | **18.3 min** | **67** |

The full suite self-reports `BUILD SUCCESSFUL in 1m45s–2m08s` — roughly **15–25% of a CODE review**,
and a CODE review is ~70% of a Worker CODE session. The expensive part of review is diff-reading and
the runtime `/verify` exercise, not the suite.

**3. Base rate of contest — the number item 4 needs.** Across 191 review files, 138 carry a
`## Previous Round Follow-Up`:

| Marker | Meaning | Line items |
|---|---|---|
| ✅ | Addressed | 640 |
| 🤝 | Accepted Worker's rationale | **43** (30 files, 20 tasks) |
| ⚠ | Partial | 5 |
| ❌ | Re-asserted / still present | **3** (3 files, **2 tasks**) |

Workers wrote **82** `## Review Response — Round N` sections across 46 files. So a rebuttal the
Reviewer must rule on occurs in ~6.7% of dispositions, and the Reviewer **sides with the Worker 93%
of the time** (43 of 46).

The severity split is what decides the gate's design: **33 of the 43 accepts were Observations** —
the Reviewer conceding a no-fix-required item, not a standoff. Genuine standoffs are the 3 ❌s, and
one of those is not a contest at all but a *regression catch* (TASK-037 round 4: a claim correctly
removed from `plan.md` in round 1 reappeared in `docs/CONFIGURATION.md` during CODE).

**An adjudicator keyed on ❌ would have fired 3 times in the entire corpus — 2 of 49 tasks, ~once per
15 rebuttal-bearing rounds.** Keyed on any 🤝-or-❌ it fires in 30 of 138 reviews (~22%), but four
fifths of those firings would be over Observations. This cuts both ways and the author should see it
before deciding item 4: the gate is very cheap *and* very rarely useful.

**4. Item 28 is worse than stated, and `worker.md`'s mandate does not cover `status.md`.** The
`date -u` mandate in `worker.md` Step 4 is scoped to **`progress.md` entries only**; Step 5's
`status.md` block says just "`current ISO timestamp`". `reviewer.md` has no mandate anywhere.

| | n | median abs. drift | within 5 min | worst |
|---|---|---|---|---|
| Composed (no `date` call) | 62 | **48 min** | 5 (8%) | 565 min |
| Ran a `date` call | 11 | **3 min** | 6 | 326 min |

**62 of 75 Reviewers composed the timestamp**; 65 of 73 wrote at least one round `:00`/`:30`/
`T00:00:00` value. Workers are barely better — **18 of 73** ran `date` at all.

### The timezone hypothesis, tested and refuted

The author asked whether the 400–560 min cluster was a UTC→Pacific conversion error (Pacific in
August is UTC−7 = **420 min**). It is not. Six independent tests:

1. **The devcontainer has no Pacific clock.** `/etc/timezone` is `Etc/UTC`, `TZ` unset, `date` ==
   `date -u`. No shell call could have picked up a local Pacific time.
2. **The signed distribution is a smooth right-tailed continuum, not a 0/420 bimodal mixture.** Of 62
   composed sessions: **59 positive, 3 negative, 0 zero**; 33 of them sit in `+0..+60`. Full sorted
   list: `-431, -352, -38, +0, +1, +3, +3, +6, +9, +9, +10, +13, +13, +13, +15, +16, +18, +18, +19,
   +23, +24, +25, +27, +28, +32, +33, +33, +36, +37, +41, +43, +45, +48, +50, +55, +55, +61, +82,
   +85, +86, +88, +103, +122, +126, +135, +136, +140, +153, +187, +190, +199, +247, +285, +327, +328,
   +366, +369, +411, +425, +467, +520, +565`.
3. **The 420 test fails.** At ±20 min: 2 sessions in [400,440], 1 in [−440,−400]. Across all 122
   composed writes, every value in [360,480] is `366, 369, 376, 384, 411, 421, 425, 462, 467` —
   **exactly one write in the whole corpus lands within a minute of 420.** Scattered, not constant.
4. **The five-session cluster is a ramp, not an offset** — and this is the real mechanism. Same run,
   same day (`835aa869-…`):

   | sess | phase | written | harness (UTC) | drift |
   |---|---|---|---|---|
   | 25 | SPEC | 2026-08-09T12:00:00 | 05:35:49Z | +384 |
   | 25 | SPEC | 2026-08-09T12:30:00 | 05:38:39Z | +411 |
   | 26 | SPEC | 2026-08-09T13:35:00 | 06:34:05Z | +421 |
   | 26 | SPEC | 2026-08-09T13:40:00 | 06:34:54Z | +425 |
   | 27 | SPEC | 2026-08-09T14:20:00 | 06:37:39Z | +462 |
   | 27 | SPEC | 2026-08-09T14:25:00 | 06:38:06Z | +467 |
   | 28 | PLAN | 2026-08-09T15:20:00 | 06:48:35Z | +511 |
   | 28 | PLAN | 2026-08-09T15:35:00 | 06:54:36Z | +520 |
   | 29 | PLAN | 2026-08-09T16:20:00 | 06:59:39Z | +560 |
   | 29 | PLAN | 2026-08-09T16:25:00 | 07:00:27Z | +565 |

   Monotonic +384 → +565. Real elapsed 85 min; the written clock advances **265 min, ~3x too fast**.
   It starts at +384, not 420. Sessions 30 and 31 of the *same run* drifted +30/+45 and +10/+190.
5. **No conversion was reasoned anywhere.** Searching all five cluster sessions for
   `Pacific|PDT|PST|PT|America/Los_Angeles|UTC-7|-07:00|local time|timezone`: **0 hits**. Across all
   75 Reviewer sessions, 3 hits total, all three about TASK-037's *subject matter* (Ricci's own
   ambient-zone bug), never the agent's own value.
6. **One agent had the true clock in its context and composed anyway — decisive.** Session 53 ran
   `date` incidentally inside verify probes, printing `host date -u: 2026-08-14 03:22:09` … `03:23:47`
   four times into its own transcript. At harness time `03:28:56Z` it wrote
   `updated: 2026-08-14T08:55`. **+326 — neither +420 nor −420.** It had already written `08:35`
   before the first `date` call and then advanced its own fiction by 20 minutes. Sessions 51 (+242)
   and 18 (+250) are the same shape. The 8 sessions that ran `date` *for the timestamp* land at
   +37, +3, +2, +2, −1, −1, −1, −1.

**Control test.** If naked values were secretly Pacific, subtracting 420 would snap them onto the
real clock. It does the opposite:

| group | n | median | in [400,440] | within ±15 min |
|---|---|---|---|---|
| naked, read as UTC | 42 | +73 | 2 | 7 |
| explicit `Z`/`+00:00`/`-04:00` | 31 | +19 | 0 | 11 |
| naked, **re-read as UTC−7** | 42 | **−347** | — | **2** |

5x worse and sign-flipped. The naked and offset-bearing groups also share the same one-sided positive
shape, which they would not if only the naked ones were mis-zoned.

**Offset markers** (144 writes across 73 sessions): naked **83**, `Z` **31**, `+00:00` **29**,
`-04:00` **1**. Per session: naked-only 42, explicit-only 31, mixed 0. **Zero `-07:00` values in the
entire corpus.** The single `-04:00` is Eastern DST — `updated: 2026-08-07T01:10:00-04:00` written at
a real `01:00:15Z` — most likely bleed from Ricci's own `NY_ZONE` constants, which is a
subject-matter contamination worth noting but not a timezone policy problem.

### 36. The invented clock is inherited through `status.md` *(agreed — supersedes half of item 28)*
The ramp in test 4 is not 10 independent guesses. Each Reviewer read its predecessor's invented
`updated:` value out of `status.md`, treated it as the current time, and advanced it by a
plausible-feeling interval — a **compounding narrative clock** that ran 3x real time across five
sessions and ended most of a day ahead.

That changes the fix. Porting `worker.md` Step 4's "never write a timestamp you composed yourself"
into `reviewer.md` is necessary but not sufficient: the mandate must also **forbid seeding from the
value already in `status.md`**, which is the vector that turns one agent's guess into a run-wide
drift. Concretely, the rule wants to be: run `date -u +%Y-%m-%dT%H:%M`, paste stdout unedited, and
never derive `updated:` from any timestamp you read on disk.

Scope for the item-11 edit, now confirmed: `reviewer.md` Steps 2 and 5, `worker.md` Step 5 (the
`status.md` block, which the existing Step 4 mandate does **not** reach), and `SKILL.md`'s
`dispatched_at`. Only after all four does deleting the `SKILL.md` caveat become honest.

### 37. `worker.md` L17 offers a passive channel for something that requires a stop *(agreed)*
> "It is not the user — it cannot answer questions mid-session, so anything you need decided goes in
> writing, into the artifacts."

The author's correction is right and it sharpens the defect. That sentence collapses two different
situations into one instruction, and gets the blocking one wrong:

- **Cannot proceed without an answer** → the Worker must **stop**. `BLOCKED` with reason
  `NEEDS_HUMAN_DECISION` already exists in the vocabulary and already reaches a human through the
  Orchestrator. Telling that Worker to "write it into the artifacts" invites it to guess and continue,
  which is the one outcome the status vocabulary was built to prevent.
- **Noticed but forbidden to act on** → never blocks; needs the carry-forward channel of item 26.

**Decided:** split the sentence along exactly that line and name the destination for each —
can't-proceed goes to `status.md` as `BLOCKED` / `NEEDS_HUMAN_DECISION` and the Worker **stops**;
noticed-but-out-of-scope goes to the item-26 carry-forward channel. Neither destination is
`handoff.md`.

### 38. Mandate the command, not the prohibition — and require the `Z` *(agreed; supersedes the wording in items 28/36)*
The author's objection is correct: "never write a timestamp you composed yourself" is a prohibition
with no action attached, and an agent that has nothing else to do will compose anyway — session 53
proves it did so with the true clock printed four times in its own context.

Note that `worker.md` Step 4 **already has the right form** and it works: the literal command, plus
"paste its stdout into the entry **unedited** — do not round it, adjust it, or reuse one from an
earlier entry." The 8 sessions that ran `date` for the timestamp landed at +37, +3, +2, +2, −1, −1,
−1, −1. The defect is **scope, not wording**. So the edit is to port that paragraph *verbatim,
command included* to the three sites it does not reach — `worker.md` Step 5, `reviewer.md` Steps 2
and 5, `SKILL.md`'s `dispatched_at` — and to add item 36's anti-seeding clause.

**New, and it raises the stakes: the devcontainer is being switched to `TZ=America/Los_Angeles`.**
Every measurement in the session-2 block was taken on a container where `date` == `date -u`, so a
bare `date` was harmless. After the rebuild it will not be. An agent that runs bare `date` gets
Pacific and writes it into a field every consumer reads as UTC — a silent 7-hour error, and
**precisely the ambient-zone bug Ricci itself is carrying as audit #43**. The skill would be
reproducing in its own bookkeeping the defect its own pipeline exists to fix.

Two consequences:

1. The guidance must be the exact string **`date -u +%Y-%m-%dT%H:%M`**. Never "read the clock", never
   "the current timestamp", never bare `date`.
2. **Require the `Z` suffix on every written value.** Today **83 of 144** writes are naked, and on a
   UTC container naked was merely sloppy. On a Pacific container naked is ambiguous, and a mis-zoned
   value becomes undetectable after the fact. Mandating `Z` costs one character and converts a silent
   class of error into a visible one. (Corpus support: the corpus already contains one non-UTC value,
   `2026-08-07T01:10:00-04:00`, written at a real `01:00:15Z` — Eastern, almost certainly bleed from
   Ricci's own `NY_ZONE` constants into the agent's own bookkeeping. It was detectable *only* because
   it carried an offset.)

## `worker.md` Step 0 — Pre-flight

### 39. Step 0.1 tells the Worker to make an edit Step 0.2 would later call debris *(agreed — Orchestrator does it once at setup)*
> "**`.agents/sdlc/` must be gitignored.** If `.gitignore` doesn't cover it, add it."

That edit is an uncommitted source change, and `.gitignore` appears nowhere in Step 0.2's list of
legitimate dirty paths. So the next Worker dispatched on the task sees a modified `.gitignore`,
applies its own rules, and blocks with `DIRTY_WORKING_TREE`. Worse, it never clears: the Orchestrator
stages "exactly the paths in the plan's `## Impact Map`, plus the governing spec", and `.gitignore`
is in neither, so the edit is never committed and stays dirty for the life of the checkout.

Moot in Ricci — `.gitignore:45` already covers `/.agents/sdlc/` — but it is a live trap in exactly
the situation Step 0.1 exists for: a project running the pipeline for the first time.

Options: have the **Orchestrator** do it once at run setup (it already commits the ROADMAP lock on
its own, so it has a committing path); or keep it in the Worker and add `.gitignore` to both the
legitimacy list and the staging list.

### 40. The per-repo scoping is a no-op in this project *(agreed — keep multi-repo machinery, strip project-specific names)*
Step 0.2 scopes the tree check to "each repo named in the plan's `## Impact Map`" and grants
exclusivity "only over the repos in its Impact Map". Measured: **69 Impact Map rows across the task
corpus carry exactly one repo value** (`ricci` × 57, `Ricci` × 12). Ricci is a single repository —
the only nested git is the `.agents/skills` submodule. So "check `git status` in each repo in the
Impact Map" resolves to "check the whole tree", and the exclusivity claim covers everything.

The paragraph reads as if it bounds blast radius; here it bounds nothing. The generic multi-repo
machinery (`backend`, `frontend`, `mls-integration`, `(umbrella)`) is inherited from a different
project shape. If scoping is meant to do real work in a single-repo project it has to be **path**-
scoped, not repo-scoped — which is also the granularity item 12's `changed-files.md` produces.

### 41. Step 0.2 has never fired — not once *(agreed — reduce verbosity, keep every rule)*
**0 of 73 Worker sessions** ever wrote `DIRTY_WORKING_TREE` into `status.md`. The string appears in
84 transcripts only because `worker.md` itself contains it and every Worker reads `worker.md`; no
session ever latched the block. Step 0.2 is ~55 lines — roughly a third of `worker.md` — of machinery
with zero recorded activations.

Three readings, and the corpus does not fully separate them: it is purely preventive (Workers read it
and stay clean); it is dead weight; or Workers are routed around it. Item 42 is evidence for the
third.

### 42. The legitimacy list is missing "the task's own ROADMAP row is new" *(agreed)*
Step 0.2 legitimises the Orchestrator's `[PENDING]` → `[IN_PROGRESS]` **flip** of an existing row and
uncommitted edits to the **governing spec**. It does not cover the case where the ROADMAP row itself
is new and uncommitted — which is what happens whenever a spec and its task are authored together,
immediately before the run.

Measured: the TASK-028 Orchestrator had to override the rule in the dispatch prompt, verbatim —

> "Context: the governing spec is `spec/spec-20260809-…md` (untracked, and the ROADMAP.md edit adding
> TASK-028 is uncommitted — **these are the task's own inputs, NOT a dirty-tree failure**)."

An Orchestrator talking a Worker out of its own pre-flight rule, in-band, is the same anti-pattern as
item 21's fabricated handshake: the protocol is wrong, and the Orchestrator improvises past it every
time rather than the rule being fixed. Add the case to the list.

Note this also interacts with `SKILL.md` step 1, which says to commit the `[IN_PROGRESS]` flip
immediately and on its own. A *new* row cannot be committed that way without also committing the task
description the user may still be editing.

### 43. Step 0's revival path depends on a file nothing creates *(informational — cost of items 14.1/14.2)*
The only thing that licenses a Worker to start against a partial tree is an `## Interruptions` entry
in `orchestrator-notes.md` "naming your phase". Item 14 already records that nothing instructs the
Orchestrator to create that file (defect 1) and that the empty `_(none)_` placeholder sorts *before*
the real entry in the two files that have one (defect 2). Step 0 is where that cost is actually paid:
a Worker scanning for authorization finds `_(none)_`, concludes there was no interruption, and
deadlocks. Recording here so the item-14 fix is understood as unblocking Step 0, not as tidying.

**Keep unchanged:** "never delete or revert it" (L69-72). It is the right rule, the reasoning given is
correct, and destroying a parallel session's uncommitted work is the one error in this section that
cannot be undone.

### Author decisions on Step 0 (2026-08-21)

- **39 — agreed.** The Orchestrator does the `.gitignore` check once at run setup. Step 0.1's
  instruction is removed from `worker.md` entirely, so the Worker never makes an uncommitted edit it
  would later have to classify.
- **40 — corrected by the author; my proposal was wrong.** "Collapse to paths" is **rejected**: the
  skill is used on other projects that genuinely have multiple submodules, and the multi-repo
  machinery must stay. What goes is the *project-specific naming* leaking into a generic skill.

  Scope of that strip — 6 lines, all traceable to a different project:

  | File | Line | Leak |
  |---|---|---|
  | `references/worker-plan.md` | 117 | "`backend`, `frontend`, `mls-integration`, or `(umbrella)`" |
  | `references/worker-plan.md` | 109-110 | `backend` rows in the Impact Map example |
  | `references/reviewer.md` | 158 | "backend ./gradlew test: pass; frontend npm test: pass" |
  | `references/worker.md` | 162 | `listing_comps` migration, `flywayValidate` |
  | `references/worker.md` | 164 | `wire/client-detail-with-comps.json` |

  The honest reconciliation of my finding with the author's call: repo-scoping stays and is correct
  where repos exist; what the measurement actually shows is that **in a single-repo project the repo
  check degenerates to a whole-tree check**, so the *legitimacy list* — not the scoping — is carrying
  all of the weight. That raises the priority of item 42 rather than lowering the value of the
  machinery. Say the degenerate case out loud in the text instead of pretending the scoping bounds
  something it does not.
- **41 — agreed, reduce.** Step 0.2 is too verbose. Verbosity comes out of the prose, not the
  mechanism: keep the legitimacy list, the action-to-allowed-changes table, the revival rules and
  "never delete or revert it"; cut the explanatory padding around them.
- **42 — agreed.** Extend the legitimacy list to cover the task's own inputs: a newly-added (not just
  newly-flipped) `ROADMAP.md` row, together with its untracked governing spec.
- **43 — agreed.** Item 14 is load-bearing for Step 0 revival, not tidying.

## `worker.md` Steps 1-3

### 44. Item 7's archaeology has three sites, not one *(agreed)*
Item 7 agreed to delete the "earlier versions of this skill appended `dispatched:` / `dispatched_at:`"
passage from `SKILL.md`. The same archaeology is restated in **`worker.md` Step 2** ("If the existing
file carries legacy `dispatched:` / `dispatched_at:` keys, let them go…") and **`reviewer.md` Step
0.4** ("Legacy `dispatched:` / `dispatched_at:` keys inside `status.md` are obsolete; ignore them and
drop them…"). Delete all three together.

One caveat the deletion must not lose: **3 of 7 Phase-0 Orchestrators used the legacy `dispatched:`
key as their only channel for the action string** (session-2 measurement block, point 1). Remove the
"strip it" instruction and those keys survive into the review; remove the archaeology *and* fix
item 21's dispatch channel and the situation cannot arise. Sequence the two edits together.

### 45. Item 6's `round:` warning has three sites too *(agreed)*
The inline warning `round: <current PHASE round — resets to 1 each phase, NOT the review-round-N
filename counter>` sits in `worker.md` Step 2's template as well as in `SKILL.md`. Item 6 deletes the
cause; all three copies of the warning go with it (see also item 24 for the two round-counting rules
that are unexecutable today).

### 46. Three different agents create `status.md` and nothing arbitrates *(agreed — fix; single owner to be named with item 21)*
- `worker.md` Step 2: "Create `.agents/sdlc/tasks/<TASK-ID>/` if it doesn't exist and write
  `status.md`."
- `SKILL.md` step 1: the Orchestrator creates the task directory.
- Measured: in **7 of 7** spec-governed runs the Orchestrator also wrote `status.md` itself, because
  Phase 0 dispatches a Reviewer first (item 21).

Whatever item 21 settles, it has to name a single owner for the *creation* of `status.md` and say what
the other two do when they find it already present. Today all three write it and the last writer wins.

### 47. A self-selecting Worker takes a task without locking it *(agreed — delete the branch)*
`worker.md` Step 1: "Asked for 'the next task' → the first `[PENDING]` task." `worker.md`'s own
"What NOT to do": "**Don't modify ROADMAP.md status.** The Orchestrator owns that."

Those two combine badly. A Worker invoked directly — not through the Orchestrator — picks a task and
is forbidden from marking it `[IN_PROGRESS]`. Nothing else marks it either, because no Orchestrator
is running. So the task is worked on while every other session still reads it as free to take.

That is the identical failure `SKILL.md` step 1 spends a paragraph on: TASK-030 ran to completion with
the lock uncommitted and "for two and a half hours every other session saw it as free to take." The
Orchestrator path was hardened against it; the direct-Worker path still has it wide open, and there
the lock is not merely uncommitted but never written at all.

Two ways out: forbid self-selection (a directly-invoked Worker must be given a task ID, and "the next
task" is an Orchestrator-only capability), or carve an exception into the no-ROADMAP-writes rule so a
self-selecting Worker sets and commits the lock exactly as the Orchestrator would.

*(An earlier draft of this item argued the conflict was with the eligibility rules in
`docs/AUTONOMOUS_RUNS.md`. Withdrawn: that document is a work in progress started in this same
session and is not authoritative. The lock conflict above is internal to the skill and stands on its
own.)*

### 48. The Worker is told to read `orchestrator-notes.md` for only one of its four purposes *(agreed)*
Step 0.2 sends the Worker to `orchestrator-notes.md` for exactly one thing: an `## Interruptions`
entry authorizing a dirty-tree start. Item 14 establishes that the file also holds **in-session user
decisions** (skip Phase 0, take fix (a) not (b), model sizing), **round-budget and round-counter
corrections**, and **cross-phase carry-forward and pre-authorized scope**.

A Worker that never reads those can re-litigate a decision the user already made, or implement (b)
after the user said (a). Same gap as item 30 on the Reviewer side, and the fix is the same shape: read
it in Step 0, not only when reviving. `SKILL.md`'s recovery section already treats it as "the only
place earlier sessions' decisions survive" — the subagents are simply never told.

### 49. `Depends on:` is checked but never re-checked *(informational)*
Step 1 requires every declared dependency to be `[DONE]` or the Worker blocks with
`DEPENDENCY_NOT_MET`, and `references/roadmap-spec.md:58` defines the syntax. This is sound and the
only note is that the check happens once, in the first Worker of the task; a dependency that regresses
to `[BLOCKED]` mid-pipeline is not noticed. Low value to fix; recording so it is not rediscovered.

### 50. Item 2 has a fourth site — and it is a *spec* file *(agreed; extends agreed item 2)*
Item 2 named three documents disagreeing about who flips `ROADMAP.md` to `[DONE]`. There is a fourth,
and it is the one that reads as normative: `references/roadmap-spec.md:48-50`, under the heading
**"Who updates what"** —

> "the Orchestrator sets `[PENDING]` → `[IN_PROGRESS]` and `[IN_PROGRESS]` → `[BLOCKED]`; the
> **Reviewer** sets `[IN_PROGRESS]` → `[DONE]`, but only when approving the CODE phase."

It sides with `reviewer.md` against `SKILL.md` and `worker.md`, and because it lives in the file
called "ROADMAP.md Specification" it is where an agent resolving the conflict would reasonably go to
settle it. Stripping the flip from `reviewer.md` Step 5 without fixing this line leaves the
contradiction intact and moves it somewhere more authoritative.

While in that paragraph: it also assigns `[IN_PROGRESS]` → `[BLOCKED]` to the Orchestrator, which
matches `SKILL.md`'s blocked path — except `SKILL.md` says to revert the heading to **`[PENDING]`**,
not to `[BLOCKED]`. A second, quieter disagreement in the same sentence.

### 47 (continued) — measured: the direct-Worker path has never been used

The author asked whether a Worker is ever legitimately invoked outside the Orchestrator. Measured
across the whole corpus:

- **31 top-level (non-sidechain) sessions. Exactly one ever opened `references/worker.md`** — and it
  was an **Orchestrator**, launched as `/sdlc ROADMAP_ALGO.md tasks B21 …, B23 …, and B22 in order`,
  which then made 19 `Agent` calls and spawned 38 subagents. It read `worker.md` for reference, never
  acted as a Worker.
- **Zero top-level sessions wrote `plan.md` or `status.md` without dispatching an agent.** Every one
  of the 73 Worker sessions in the corpus is an Orchestrator-dispatched sidechain.
- **Self-selection was never used either.** Every real launch named explicit targets — `TASK-037`,
  `TASK-038`, `task 038`, `B21/B23/B22`, `#6 and #14 of LIVE_PATH_AUDIT.md`, `#19 and #35`. Not one
  launch said "the next roadmap task" or "all pending tasks". (Those phrases hit ~135 times in the
  corpus only because `SKILL.md`'s own trigger table contains them and every session reads it — a
  reminder that grepping transcripts for a phrase the skill itself defines measures reading, not
  behavior.)

So both halves of the path are dead in this project: nothing has ever invoked a Worker directly, and
nothing has ever asked one to choose its own task.

**Recommendation: delete the path rather than patch it, and fail loudly if it is ever taken.**
`worker.md` Step 1 loses the "asked for 'the next task'" branch; the Worker is always dispatched by an
Orchestrator with a task ID, and a Worker that finds itself without one stops and says so instead of
silently working an unlocked task. That is the same fail-loud disposition the project applies
elsewhere, and it costs nothing that has ever been used.

**Consequence to reconcile:** `SKILL.md`'s mode table advertises the deleted capability — "Two roles,
auto-detected from the prompt", with WORKER triggers "implement task X", "work on next roadmap task",
and a tie-break rule ("if the prompt is ambiguous: … otherwise WORKER"). Deleting self-selection in
`worker.md` without touching that table leaves the skill advertising an entry point its protocol file
refuses. Both move together, or neither.

**Caveat the author must rule on:** this corpus is one project. The skill runs on others, and the
measurement cannot see them. If a Worker is invoked directly anywhere else, deleting the branch breaks
it — though the lock hole is real there too, so the alternative is not "leave it alone" but "let it
set and commit the lock itself".

**Decided (author, 2026-08-21):** the other projects do not invoke Workers directly either. **Delete
the branch.** `worker.md` Step 1 loses the "asked for 'the next task'" path; a Worker is always
dispatched with a task ID and stops loudly without one. `SKILL.md`'s mode table — the WORKER trigger
rows and the "otherwise WORKER" tie-break — is edited in the same change.

## `worker.md` Steps 4-5 and "What NOT to do"

### 51. `progress.md` adoption tracks `orchestrator-notes.md` exactly *(informational — supports keeping both)*
Both artifacts entered the skill on 2026-08-09 (`d720904`). Of the 9 task directories created on or
after that date:

| Task | Created | `progress.md` | `orchestrator-notes.md` |
|---|---|---|---|
| TASK-027 | 08-09 | no | no |
| TASK-028 | 08-10 | no | no |
| TASK-031 | 08-10 | no | no |
| TASK-032 | 08-12 | **yes** | **yes** |
| TASK-037 | 08-13 | **yes** | **yes** |
| TASK-038 | 08-14 | **yes** | **yes** |
| TASK-044 | 08-15 | **yes** | **yes** |
| TASK-030 | 08-16 | **yes** | **yes** |
| TASK-036 | 08-16 | **yes** | **yes** |

**6 of 6 since 2026-08-12**, and the two files co-occur perfectly — never one without the other. The
three misses are the first two days after the commit landed. Same shape as item 14's finding for
`orchestrator-notes.md`, and it settles the equivalent question for `progress.md`: it is adopted, not
ignored. The 41 older directories predate both and prove nothing.

### 52. The Worker is told to emit a block reason with no field and no template *(agreed)*
`worker.md` tells the Worker to block in four places — `DIRTY_WORKING_TREE` (Step 0.2, three times)
and `DEPENDENCY_NOT_MET` (Step 1). Step 5 then gives it exactly one `status.md` template, the
`AWAITING_REVIEW` success shape, with five keys and **no `reason:` line**. Grepping the whole skill,
`reason:` appears in exactly one place: `reviewer.md:203`.

So a blocking Worker has to invent both the field and the file shape. Give `worker.md` Step 5 a
`BLOCKED` template with `reason: <DIRTY_WORKING_TREE | DEPENDENCY_NOT_MET>`, matching the Reviewer's.

### 53. The Orchestrator relabels a correct Worker block as a protocol failure *(agreed)*
`SKILL.md` round loop: "Worker returned anything but `AWAITING_REVIEW` → **blocked**, reason
`WORKER_DID_NOT_SIGNAL`."

A Worker that blocks *correctly* — dependency not met, tree genuinely dirty — has done exactly what
Step 0 and Step 1 instruct, and the Orchestrator overwrites its diagnosis with
`WORKER_DID_NOT_SIGNAL`, which means the opposite: the Worker failed to report. The true reason is
sitting in `status.md` and gets discarded, and the human sees a handshake failure instead of "TASK-019
isn't `[DONE]` yet".

Fix: split the branch. `BLOCKED` from a Worker propagates the Worker's own `reason:`;
`WORKER_DID_NOT_SIGNAL` is reserved for what it says — `IN_PROGRESS` left behind, or no `status.md`
change at all. This pairs with item 52: the Orchestrator can only propagate a reason the Worker had a
field to write.

### 54. The `date` command needs the `Z` and seconds baked in *(agreed; refines item 38)*
Item 38 agreed to port `worker.md` Step 4's literal command to the other three sites and to require an
explicit `Z`. Concretely the command string changes:

```
date -u +%Y-%m-%dT%H:%M     ->     date -u +%Y-%m-%dT%H:%M:%SZ
```

**Author's call: include seconds.** Minute resolution cannot order two entries inside the same
minute, and the corpus has several — TASK-030 wrote three CODE entries between 08:51 and 08:53. The
ordering the file exists to convey is lost exactly when work moves fastest.

`Z` is not a `strftime` specifier, so it emits literally. One edit, and it makes every generated
timestamp self-describing at the moment of creation rather than relying on an agent to append the
suffix by hand. Update the existing Step 4 occurrence too, not just the three new sites.

### 55. "What NOT to do" restates phase-file rules and is read where they cannot apply *(agreed)*
Five of the eight bullets are code-quality rules stated again, usually more precisely, in the phase
files:

| Rule | Also in |
|---|---|
| no defensive code for impossible conditions | `worker-code.md`, `review-code.md` |
| no dead or commented-out code | `worker-code.md`, `review-code.md` |
| don't log credentials/tokens/PII | `worker-code.md`, `worker-plan.md`, `review-code.md`, `review-plan.md` |
| imprecise numeric types for money | `review-code.md` |
| don't fix adjacent bugs | `worker-code.md` |

`worker.md` is read by every Worker in every phase, so a SPEC Worker editing a Markdown file under
`spec/` reads five rules about dead code, null checks and `BigDecimal` that cannot apply to it. The
author's verbosity call on Step 0 (item 41) applies here for the same reason: move the code rules to
`worker-code.md`, where they already are, and keep in `worker.md` only what is true in all three
phases — don't commit, don't touch ROADMAP status, don't start a different task, don't sound
confident about what you are unsure of.

Two smaller notes in the same list:
- "Put it in `## Risks & Open Questions`" points at a `plan.md` section that does not exist in the
  SPEC phase.
- The money bullet is the last project-shaped assumption left in the generic text after the item-40
  strip. It is guarded ("if the project mandates `BigDecimal`"), so it is defensible — but it belongs
  next to the other domain rules in `worker-code.md`, not in the cross-phase list.

### 56. A `progress.md` heartbeat line — parked, author unconvinced *(agreed — superseded by item 57's labelled types)*
Recording so it is not re-proposed. Step 4 deliberately forbids writing an entry when a unit of work
*starts*, which is what produced the TASK-044 false death: the Orchestrator read ~1h of silence as a
dead Worker and dispatched a second one onto the same tree.

A "still working" heartbeat would fix the silence but break the file's contract — `progress.md` is
defined as the successor's record of *what actually landed*, and a successor that cannot distinguish
a heartbeat from a completion will build on unfinished work. That is a worse failure than a false
death, and it is the failure the "WRITTEN, UNVERIFIED" convention exists to prevent.

The liveness problem is already solved on the other side, by item 18's `SendMessage(agent_id)` ladder:
the Orchestrator asks the agent instead of guessing from the file. Keep Step 4's milestone-only rule
exactly as it is.

**Author's position (2026-08-21): unconvinced.** "I don't know why not write when the work starts.
Happy to leave it alone for now." Parked, not settled — and the corpus supports the author's
skepticism more than my rejection did. See item 57: Workers already write start-shaped entries, the
protocol notwithstanding, and one of them was written by the predecessor in a real death case.

### 57. `progress.md` needs entry *types*, not more detail *(agreed — labelled DONE / START / NOTE)*
The author asked whether `progress.md` should be more detailed. The corpus says detail is the wrong
axis.

**Length does not predict usefulness.** TASK-032 (133 lines) and TASK-037 (131) are the longest; the
two files that actually drove a recovery are TASK-030 (**17 lines**) and TASK-044 (**20**). The
shortest files did the real work.

**What successors actually consumed, verbatim from their own entries:**

- TASK-030, PLAN recovery — *"predecessor entries FOUND under my own phase (PLAN, two entries) and
  REUSED — I inherit their pre-flight verdict and their file-level analysis (incl. the multi-ticker
  `tickers` finding) as the starting point rather than re-deriving it."* What was consumed was
  **orientation** — which files were read and what was concluded — not a list of completions.
- TASK-030, CODE recovery — *"`util/BacktestCsv.kt` = KDoc + two `TODO(\"TASK-030\")` bodies (a pure
  TDD red stub, no logic to trust) … Verdict: KEEP the test file …, IMPLEMENT the two stub bodies."*
  Consumed: **per-file trust status**.
- TASK-044, CODE recovery — *"git status shows the 11 files the Interruptions entry lists PLUS
  SignalExecutor.kt (entry said NOT touched — **stale**)."* The successor caught the Orchestrator's
  `## Interruptions` entry being wrong, by checking `git status` against it. `progress.md` was the
  cross-check, not the source.

**Three de facto entry types already exist, and only one is sanctioned:**

1. **Completion** — "step 3/4 done: X; evidence Y". The only type Step 4 describes.
2. **Orientation / intent** — "pre-flight done (tree clean except the ROADMAP flip)", and TASK-044's
   predecessor: *"Starting implementation: schema/domain first, then broker seams, then
   BracketOrderManager resolution + submitEngineExit, then SignalExecutor, then tests, then docs."*
   That is a **start entry, written in defiance of the rule, by the Worker that then died** — exactly
   the case Step 4's prohibition is aimed at, and it told the successor the intended order.
3. **Anomaly** — TASK-044: *"FOREIGN EDIT observed at 03:21 … Per the concurrent-sessions memory:
   adopting, will re-verify by running the suite; NOT reverting"*, and *"a concurrent actor is landing
   TASK-044 work in this same checkout in parallel"*. The dual-writer incident recorded live. The
   protocol never asks for this and it is among the most valuable content in either file.

**Proposal.** Keep entries short; add a leading type marker so a successor can tell them apart, which
is the property that made the blanket start-entry ban look necessary in the first place:

```
- <ts> — CODE DONE  step 3/4: <what completed> — <evidence>
- <ts> — CODE START step 4/4: <what is being attempted, and in what order>
- <ts> — CODE NOTE  <anomaly: foreign edit, sibling session, blocked on X>
```

`DONE` keeps the current contract exactly — only finished, verified work. `START` is safe *because it
is labelled*: a successor can never mistake it for a landing, which was the whole objection. `NOTE`
gives the concurrency observations a home. This gets the author's start-entry without the failure
mode I raised, and it costs one word per line rather than more prose.

## `reviewer.md` Steps 0-1

### 58. The Reviewer self-selects its task, the same way the Worker did *(agreed — same fix as item 47)*
Step 0.3: *"**Find the task** — a directory under `.agents/sdlc/tasks/` whose `status.md` says
`AWAITING_REVIEW`. If several match, use the one named in the prompt."*

Scanning is primary; the prompt is the tie-break. That is backwards — the Reviewer prompt template
**always** names the task ("Review roadmap task `<TASK-ID>`"), so scanning is never needed and can
only go wrong. Concurrent sessions share the checkout, and two tasks sitting at `AWAITING_REVIEW`
simultaneously is normal, not exceptional.

Item 47 deleted the Worker's self-selection for exactly this reason. The same edit belongs here:
review the task named in the prompt; if it is absent, stop and say so.

### 59. PLAN and CODE Reviewers are never told to read the governing spec *(agreed — scoped to spec-governed tasks)*
`reviewer.md` Step 0.5 names `ROADMAP.md` as "your source of truth for what the task should
accomplish". Step 1.4 routes the governing spec to the **SPEC** phase only. Nothing tells a PLAN or
CODE Reviewer to read it — yet on a spec-governed task the spec, not the nine-line ROADMAP row, is
what the work was built against, and the Orchestrator commits the two together.

Measured: **41 of 133** PLAN/CODE review files cite a `spec/spec-*` path anyway — Reviewers routing
around the gap on their own, in a third of all reviews. Add the spec to Step 0.5 for every phase, and
note that it interacts with item 22 (there is no channel telling the Reviewer *which* spec file it is).

### 60. ~~In a single-repo project the unaccounted-changes sweep reports the siblings~~ *(WITHDRAWN — my hypothesis, refuted)*
Step 1.4 CODE: run `git status --porcelain` in each Impact Map repo and "list anything changed that
the map does not declare … **Do not review it and do not assume it is the Worker's.**"

Per item 40 the repo scoping stays, but in a single-repo project it degenerates to the whole tree —
so the sweep surfaces every concurrent session's uncommitted file as an "unaccounted change". Measured:
17 review files across 6 tasks carry such reports, and TASK-044's own `progress.md` records a sibling
session writing that same task's files in parallel.

The instruction handles this correctly in principle (report, do not review, do not attribute), and it
should stay. The open question is whether the report is worth its noise in a shared checkout, or
whether it should be scoped to the Impact Map's *paths* plus a bounded neighbourhood rather than the
whole tree. Note the dedicated worktree removes the class entirely.

**Author's scoping on 59 (accepted, and their explanation checks out).** The fix applies only when a
spec governs the task; not all tasks have one. Their hypothesis for the 41 citations — that Reviewers
found the spec because the ROADMAP row links it — is largely confirmed:

- `ROADMAP.md`: **7 of 27** rows carry an explicit `**Spec**:` field (TASK-027, 028, 032, 037, 038 and
  two others), which `reviewer.md` Step 0.5 already routes the Reviewer to.
- `ROADMAP_ALGO.md`: 16 spec references, but mostly inside post-hoc `**Status:** DONE — SDLC task A2
  (spec …)` lines, which may not have existed at review time. Weaker evidence.

**This narrows item 22** ("no channel for the governing spec"), which I overstated. The ROADMAP link
*is* a channel, and `SKILL.md`'s Phase-0 trigger names it explicitly ("the prompt references a
`spec/spec-*.md` **or the ROADMAP task links one**"). The gap only bites when the spec arrives via the
prompt and is **not** linked from the row — TASK-044 is exactly that case: its spec is cited nowhere
in `ROADMAP.md`. So item 22 stands, but as a narrow hole rather than a missing channel, and the
cheapest fix may simply be to require the ROADMAP row to carry the `**Spec**:` field whenever one
governs the task.

### Withdrawal of item 60 — the sweep costs nothing, and it never sees siblings

The author asked what is actually wrong with labelling a sibling session's files unaccounted. Checked:
**nothing, and it has never happened.** Every "unaccounted changes" report in the corpus names the
task's *own* inputs, not another session's work:

- TASK-032 CODE round 1: *"`.agents/skills` (submodule, dirty content — no pointer diff) and
  `spec/spec-20260813-task032-…md` (the SPEC-phase edits, uncommitted since round 2). Both were
  declared licensed in `progress.md`'s pre-flight entries and neither is CODE scope creep."*
- TASK-038 round 3: *"two files the plan's Impact Map does not declare: ` M ROADMAP.md` and
  ` M spec/spec-20260814-…md`. I read both diffs. … **Not scope creep, and not this Worker's CODE-phase
  work.** Flagging it only so the Orchestrator confirms that reading before committing."*

In both, the Reviewer classified correctly, did not review the files, did not attribute them, and did
not block — the `NEEDS_FIXES` verdicts in those rounds were driven by unrelated findings, and both
tasks were `APPROVED` the following round with the same paths still listed. TASK-038's Reviewer even
turned it into value, prompting the Orchestrator to check the diff before staging.

So the sweep is doing its job at zero cost. What it actually surfaces, every time, is the same gap
**item 42** identified — the task's own inputs (new/flipped ROADMAP row, uncommitted governing spec)
are not on the legitimacy list. Fix item 42 and these reports mostly stop. Item 60 is withdrawn.

**Worktree — precise restatement.** My "a dedicated worktree removes the class entirely" was about the
**autonomous** path, where it is already true and already in use: `docs/AUTONOMOUS_RUNS.md` runs
unattended work in `/home/vscode/worktrees/ricci-auto` on branch `auto/pending`, against its own
`ricci_auto` database. It is not available for the **interactive** path, where several sessions share
`/IdeaProjects/Ricci` by design.

What session 1 concluded (item 13) was narrower than "a worktree is wrong for your case": a worktree
isolates the **tree** and does nothing for the **history**, which is what you actually read — so it
does not solve *legibility*, which is why that item landed on a run digest instead. Isolation is a
separate question and the worktree already wins it for autonomous runs, with a second independent
reason recorded in `AUTONOMOUS_RUNS.md`: the `/IdeaProjects` mount is slow enough to produce a
false test failure the fast filesystem does not.

### Author corrections (2026-08-22)

- **59 is conditional, never a mandate.** "Not every task deserves a spec. Some are really simple."
  The `**Spec**:` field is required on the ROADMAP row *only when a spec governs the task*; spec-less
  tasks stay spec-less and the Reviewer reads the ROADMAP row alone. Nothing in this change pushes
  toward writing more specs.
- **Factual correction on the worktree — I overstated it.** I wrote that "your unattended runs already
  use one". They do not. `/home/vscode/worktrees/ricci-auto` was created *in this session*, and its
  only two pipeline runs (TASK-030, TASK-036) were tests of the skill, not user-driven autonomous
  runs. No real unattended run has used it yet.

  Worth naming because it is the **second** time in this session I treated `docs/AUTONOMOUS_RUNS.md`
  as a record of established practice when it is a work in progress written during this same session
  — the first was item 47's original eligibility-rules argument, also withdrawn. That document
  describes an intended setup, not history, and must not be cited as evidence of what has happened.
- **Decision: autonomous runs use the worktree.**

## `reviewer.md` Steps 3-5

### 61. The `BLOCKED` reason vocabulary is split across three files with no canonical list *(agreed)*
Eight reasons exist and no single place lists them:

| Reason | Defined in |
|---|---|
| `MAX_ROUNDS_EXCEEDED`, `MISSING_REQUIREMENTS`, `NEEDS_HUMAN_DECISION`, `SPEC_TOO_AMBIGUOUS` | `reviewer.md:203` |
| `DIRTY_WORKING_TREE`, `DEPENDENCY_NOT_MET` | `worker.md` prose — with **no `reason:` field** (item 52) |
| `WORKER_DID_NOT_SIGNAL`, `REVIEWER_DID_NOT_SIGNAL` | `SKILL.md` round loop |

Item 52 gives the Worker a `BLOCKED` template and item 53 makes the Orchestrator propagate the
Worker's reason instead of overwriting it — both need one canonical vocabulary to write against.
Put the full list in `SKILL.md` beside the status table and have the two protocol files reference it.

### 62. The review template has no `## Verification` section, so 51 reviews invented ten *(agreed)*
`review-code.md` demands the Reviewer independently run every affected suite and `/verify`, and
`SKILL.md` refuses to commit without that evidence — but `reviewer.md` Step 4's template has nowhere
to put it. It appears in `handoff.md` only, which is written *only* on APPROVED or BLOCKED.

Measured across 62 CODE review files: **51 record test/`verify` evidence anyway**, under ten different
headings —

| Heading | Count |
|---|---|
| `## Verification performed` | 11 |
| `## Verification performed (independent, not the Worker's runs)` | 3 |
| `## Verification Notes` / `## Verification I ran` / `## Verification` / `## Test Run` / `## Independent verification performed` | 2 each |
| `` ## `/verify` — what was lifted and what was re-run `` | 1 |
| `` ## `/verify` — re-run by the Reviewer, not credited `` | 1 |

Same failure as item 14 defect 3 (six vocabularies for `orchestrator-notes.md`) and item 23 (two rival
filename conventions): behaviour the protocol requires but never gives a shape, so every agent invents
one. Two consequences beyond untidiness:

1. On `NEEDS_FIXES` rounds the evidence lands nowhere durable — the next Reviewer re-runs everything
   with no record of what the last one already established.
2. The Orchestrator's commit gate looks for a green `/verify` in `handoff.md`. Item 34's carry-forward
   carve-out needs to name *which round* produced the green; that is only checkable if each round's
   evidence has a fixed home.

Add `## Verification` to the Step 4 review template, in every phase (in SPEC and PLAN it records that
no runtime check applied, which is also information).

### 63. Step 6 is an empty section *(agreed — fold into Step 5 and delete)*
"## Step 6: Final status update — Updating `status.md` is your **LAST** action." Step 5 already writes
`status.md` in all three verdict branches, and the same rule is `SKILL.md` Critical Rule 2. Fold the
sentence into Step 5 and delete the heading.

### 64. `handoff.md` on `BLOCKED` — two files disagree about where block details live *(agreed)*
`reviewer.md` Step 5 BLOCKED: *"Write `handoff.md` with the latest plan, all unresolved findings and
disagreements, and a clear statement of what the human must decide."* `SKILL.md`'s blocked outcome:
*"revert the ROADMAP heading to `[PENDING]` (**block details live in `status.md`**)"* — and never
mentions `handoff.md`.

So the Reviewer writes the human-facing explanation into a file the Orchestrator is not told to read,
and the Orchestrator reports from a file that holds one `reason:` token. Since blocking is the path
that *ends* with a human, this is the worst place for the handoff to go unread. Point the Orchestrator
at `handoff.md` on the blocked path.

### 65. Item 4 (the Reviewer-error gate) — SETTLED: evidence floor only *(agreed)*
Session 1 left this undecided and its ranking put **adjudicated contested findings** first and the
**evidence floor** second. The session-2 measurement inverts that, and I am changing my predecessor's
recommendation on the data:

- The feared failure — the Reviewer as judge in its own cause, overriding sound rebuttals — is
  **not what the corpus shows**. Across 46 rulings on Worker rebuttals the Reviewer sided with the
  Worker **43 times (93%)** and re-asserted **3**. It concedes readily.
- Of the 43 concessions, **33 were Observations** — no-fix items, not standoffs.
- Of the 3 re-assertions, one is not a contest at all: TASK-037 round 4 catching a claim that was
  correctly removed in PLAN round 1 and *reappeared* in `docs/CONFIGURATION.md` during CODE. That is
  the Reviewer working, not failing.

So an adjudicator would have fired **twice in 49 tasks** on genuine standoffs. The machinery — a third
agent, a new artifact, a new branch in the round loop — is real; the demonstrated need is not.

**Recommendation: take the evidence floor, skip the adjudicator, revisit if the ❌ rate rises.**
Concretely: every Critical cites a resolvable `file:line` or pasted command output, and `worker.md`
states plainly that an uncited Critical is a legitimate rebuttal. That is a few lines in two files,
it kills fabricated citations outright, and it costs nothing per round. The adjudicator can be built
later from the same `❌` signal if the rate moves — the marker is already in the template and already
machine-countable, so the trigger is measurable without building anything now.

**Explicitly still rejected:** a second full reviewer (doubles cost, same failure mode), and
Orchestrator spot-checks (its value is never reading a diff).

### 66. The three-architects PLAN fan-out has never fired *(agreed — option B, exercise it deliberately once)*
`worker-plan.md` tells a PLAN Worker that when a task "genuinely admits multiple viable
architectures", it should "spawn three `Plan`-type agents in parallel (one message, three `Agent`
calls)" with Minimal / Clean / Pragmatic mandates.

Measured across the whole corpus: **zero `Plan`-type agent spawns.** Every `subagent_type` in
127+2 recorded spawns is `general-purpose` (127) or `claude-code-guide` (2). Of the 18 subagent
sessions that had the three mandates in context — because they read `worker-plan.md` — **16 spawned
no agent at all and 2 spawned exactly one**, never three.

Two readings, and unlike item 41 the corpus does separate them a little: the gate is explicitly
conditional ("Most roadmap tasks extend an existing pattern… If you can't articulate a second
defensible approach in one sentence, there's no fork — don't manufacture one"), and **three** Workers
recorded consciously declining it, each for the same structural reason — the governing spec had
already fixed the design:

- TASK-030 `progress.md`: *"No fan-out: fix (a) is bound by the Orchestrator and admits no second
  architecture."*
- TASK-032 `plan.md:215`: *"No fan-out was run: the spec pins the site…"*
- TASK-038 `plan.md:183`: *"these two forks were the only real architectural choices; no three-way
  `Plan` fan-out was run."*

So the instruction is read and applied, and zero firings looks like correct restraint rather than a
dead mechanism. Note the pattern in the reasons: a task hardened through Phase 0 arrives at PLAN with
its architecture already decided, so the fan-out's precondition is systematically rare in exactly the
tasks this pipeline runs.

What is *not* established is that the branch works: it has never executed, so nothing has tested the
three-way spawn, the comparison step, or how the result reaches `## Approach`. Untested code that
fires rarely is where bugs sit. Cheapest resolution is to leave the instruction alone and note the
status honestly rather than either trusting or deleting it.

## Spec scope, and spot-checks 1-3

### 67. Specs are pinning implementation, and it is measurable *(agreed — option A)*
`worker-spec.md` already forbids this: *"Keep the spec on **what** and **why**. The **how** belongs in
`plan.md`, which comes later — don't let the spec drift into implementation detail."* The instruction
exists and is being violated.

| Spec | Lines | `*.kt` refs | `file:line` refs |
|---|---|---|---|
| TASK-032 plan-geometry-cycle-abort | 381 | **26** | 29 |
| TASK-038 open-anchored-scheduler | 490 | 3 | **43** |
| TASK-044 plain-row-exit-recovery | 253 | 0 | 0 |

Not uniform — TASK-044 is clean — so this is drift, not an inherent property. And it lands in the
sections where it does the most damage:

- TASK-032: 8 `.kt` refs in `## Context`, **7 in `## Acceptance criteria`**.
- TASK-038: 9 line refs in `## Behavior`, **7 in `## Acceptance criteria`**.

Sample criterion: *"(b) The `SELL_SHORT`-reaches-limit-router assertion (`SignalExecutor.kt:219-226`),
deliberately…"* — that is not a product decision, it is a patch site.

**Probable cause is the Reviewer, not the Worker.** `review-spec.md`'s *Verifiable acceptance
criteria* dimension demands every criterion be observable and testable, and the cheapest way to make a
criterion *look* testable is to name the file and line. The dimension pushes exactly the drift
`worker-spec.md` prohibits.

**Consequence already visible:** this is why item 66's fan-out never fires. All three recorded
declines say the same thing — TASK-032 *"the spec pins the site"*, TASK-030 *"admits no second
architecture"*, TASK-038 *"the spec fixes the seam, constants, wiring source and guard shape"*. Phase 0
is doing PLAN's job, so PLAN has no architecture left to choose. The two items are one problem.

**Options:**

- **A (recommended) — a mechanical test, in the same shape as item 10's.** A spec may cite existing
  code in `## Context` as *evidence of the problem*; `## Behavior` and `## Acceptance criteria` must
  state observable outcomes. The test: **"would this criterion still be satisfiable if the implementer
  chose a different file?"** If no, it is over-pinned. Put the test in `worker-spec.md` and, crucially,
  in `review-spec.md`'s Verifiable-criteria dimension, since that is what drives the drift.
- **B — accept it and shrink PLAN.** If specs pin design, PLAN becomes validation rather than design.
  *Refuted by the data:* PLAN rounds are substantive — TASK-030, a nine-line ticket, consumed three
  PLAN rounds each closing a genuine Critical. PLAN is not a rubber stamp today.
- **C — do nothing.** Costs: the fan-out branch stays untested forever, and product decisions stay
  entangled with patch sites in a document the user is asked to approve.

Note A has a knock-on: if specs stop pinning sites, the fan-out precondition stops being rare and an
**untested branch starts executing** (item 66). Decide them together.

### 68. Spot-check 1 — reconciling `## Assumptions` with `## Assumed Decisions` *(agreed — option A)*
Two lists of "decisions made without asking the user" would exist:

| | Written by | Where | Durable? | When |
|---|---|---|---|---|
| `## Assumed Decisions` (item 10, agreed) | Reviewer | `spec-review-round-N.md` | no — gitignored | before the Phase 0 gate |
| `## Assumptions` (exists today) | Worker | the spec file under `spec/` | **yes — committed** | after the gate |

**Proposal (option A, recommended): they are two stages of one fact, and the text should say so.**
The Reviewer's table is the **proposed** set, rendered at the gate so the user can object in one
glance. The Worker's section is the **ratified** set, written into the durable spec after the gate —
the proposed assumptions minus any the user overturned, plus anything new the Worker had to assume
while closing findings. That gives the Worker a rule it currently lacks (today `## Assumptions` is
whatever it happened to guess) and gives the user one durable record instead of two partial ones.

- **B — Reviewer writes straight into the spec's `## Assumptions`.** Rejected: it breaks the
  Worker-writes / Reviewer-reviews separation and makes the Reviewer judge of its own text next round.
- **C — drop the Worker's `## Assumptions`, keep only the review file.** Rejected: review files are
  gitignored and disposable, so the durable record vanishes — the same dead-letter failure as item 26.

### 69. Spot-check 2 — the unreviewed-file hole, and a reconsideration of item 12 *(agreed — option B)*
The hole: `reviewer.md` Step 1.4 reviews Impact Map paths "**and only those**" and is told not to
review unaccounted ones; item 12 moves *staging* to a Worker-maintained `changed-files.md`. Composed,
a legitimate round-2 fix in a file the map does not name is **staged and committed without ever being
reviewed**.

**A reconsideration first, because it may shrink item 12.** `worker-plan.md:117-119` already says:
*"A file the CODE Worker ends up touching that is not listed is either a missed dependency or scope
creep; it gets added to the map with a reason, **in the same session, never silently**."* So the
Impact Map is *already specified* to stay current. Item 12's premise — that the map is a plan artifact
"guaranteed to drift" — is therefore partly wrong: the drift is a **compliance failure against an
existing rule**, not a missing mechanism.

**Options:**

- **A — enforce the existing rule; no new artifact.** The Reviewer already diffs `git status` against
  the map; make map-currency an explicit check, and the Orchestrator keeps staging from the map.
  Cheapest, deletes nothing, adds no file. Loses the one thing `changed-files.md` offers that the map
  does not: a per-file one-clause note of *what changed there*, which is what lets the Orchestrator
  hunk-split a shared file without reading a diff.
- **B — `changed-files.md` as agreed in item 12, plus review-scope union (recommended).** Keep the new
  artifact for its note, and fix the hole by having the Reviewer review the **union** of the Impact Map
  and `changed-files.md`. A path in `changed-files.md` but not the map is reviewed *and* reported as a
  declared deviation — which item 12 already says is a reported deviation, not an automatic block.
  Paths in neither stay reported-not-reviewed-not-attributed, which item 60's evidence shows works.
- **C — block on any file outside the map.** Rejected: round 2 legitimately adds files; this blocks
  normal operation.

### 70. Spot-check 3 — `worker-plan.md`'s Impact Map paragraph states a purpose that becomes false *(agreed — fix; wording follows item 69)*
*"three later steps read this table to stay out of each other's way: the CODE Worker checks the working
tree only in the repos it names, the Reviewer reviews only the paths it names, and **the Orchestrator
stages exactly those paths at commit time**."*

Under item 12 the third clause is false and the second becomes the hole in item 69. Rewrite to match
whichever of 69's options is chosen; if B, the paragraph names `changed-files.md` as the staging list
and the review scope as the union.

**Decided on 67 (author, 2026-08-22): option A.** Code citations are allowed in `## Context` as
evidence of the problem; `## Behavior` and `## Acceptance criteria` state observable outcomes only.
The test — *"would this criterion still be satisfiable if the implementer chose a different file?"* —
lands in **both** `worker-spec.md` and `review-spec.md`, the latter because its Verifiable-criteria
dimension is what drives the drift.

**Open follow-up, carried on item 66:** with specs no longer pinning sites, the fan-out's precondition
stops being systematically rare and a branch that has **never executed in the entire corpus** starts
firing. Nothing has tested the three-way spawn, the comparison step, or how the chosen approach reaches
`## Approach`. Decide before implementation whether to (a) leave it and accept a first live exercise,
(b) test it deliberately on one task, or (c) simplify it to a single-agent "name and reject one
alternative" requirement, which is what the three declining Workers actually did in prose.

---


### 71. Deduplication and read amplification — measured *(author's question; 71a/71b agreed, 71c open)*

The author asked how to deduplicate the two artifact pairs and minimise token use, noting the cost is
**read amplification** — every Worker, Reviewer and Orchestrator reads these artifacts every round.
Measured per-task read cost (roughly 12 agent sessions per task: ~4 SPEC, ~5 PLAN, ~4 CODE):

| Artifact | Size (n, min/median/max lines) | Who reads it | Per-task amplification |
|---|---|---|---|
| `plan.md` | 47, 49 / **251** / 643 | every PLAN + CODE Worker and Reviewer | **~2260 lines** |
| governing spec | 34, 35 / 168 / 490 | SPEC agents today; **+PLAN/CODE under agreed item 59** | **~670 lines NEW** |
| `spec-review-round-N.md` | 51, 30 / 50 / 166 | SPEC agents only | ~200 lines |
| Impact Map | 4 / **12** / 28 rows | already inside `plan.md` | 0 additional |
| `changed-files.md` (proposed) | ~15 rows | Orchestrator + CODE Reviewer | **~45 lines** |

**The headline: both dedup targets are noise.** The Impact Map is 12 rows *already inside* `plan.md`,
and `changed-files.md` would add ~45 lines per task. Together they are under 2% of what `plan.md`
alone costs. Optimising them optimises the wrong artifact.

#### 71a — Impact Map vs `changed-files.md` *(agreed: no delta scheme; manifest is complete)*

- **Rejected — manifest carries only deltas from the map.** Saves ~10 lines. Costs a *join* at commit
  time, turning the Orchestrator's job from "look it up" into "reconcile two lists" — and the union
  cannot express a **deletion** (a file in the map the Worker did not touch would be over-staged).
  Delta rows would also have to re-carry the repo column to be stageable, recovering most of the
  saving.
- **Agreed — the manifest is the complete staging list; the Impact Map keeps its planning role
  (declared intent, reviewed at PLAN) and stops being read at commit time.** One writer and one
  purpose each, no join, no deletion ambiguity.

  **The genuine saving is not tokens, it is *whose* tokens.** Today the Orchestrator opens `plan.md`
  (median 251 lines) to extract 12 staging rows. Under this it opens a ~15-line manifest instead.
  That is a ~94% cut on the one context the skill explicitly protects — *"Never read the diff or edit
  docs yourself — that is what keeps your context flat across many tasks in a row."* The Orchestrator
  is the only agent that persists across every task in a run; it is the right context to spend a
  design decision on.

#### 71b — `## Assumed Decisions` vs `## Assumptions` *(agreed: one full copy, in the durable artifact)*

The two lists are never live at the same time. Pre-gate the spec has no assumptions yet; post-gate the
review table is history. So the flow is one-way and only one full copy is ever needed:

- The Reviewer's `## Assumed Decisions` carries the proposal — decision, recommended answer,
  one-clause rationale — and is rendered at the Phase 0 gate.
- The Worker writes the **ratified** set into the spec's `## Assumptions`, and the review-file table is
  thereafter **superseded**. Later SPEC rounds must be told this explicitly, because
  `reviewer.md` Step 1.2 has them re-read every previous round's file; without the supersession note a
  round-2 Reviewer re-proposes what round 1 already settled.

**The constraint that decides this — and it is load-bearing.** The spec is **committed**; task
directories are **gitignored and disposable**. A pointer from the spec to `spec-review-round-2.md`
dangles permanently the moment the task directory is cleaned. So the durable artifact must always
carry the **full text**, never a reference. Every pointer scheme has to run in the surviving direction
only, and none of them may originate in the spec.

Cost of keeping both full copies: one ~10-line table, read by ~4 SPEC-phase sessions. Negligible, and
the alternative is a dangling reference in a committed file.

#### 71c — Where the tokens actually are *(open — recommended)*

Two findings the measurement surfaced, both larger than either dedup:

1. **`plan.md` runs at roughly double its own stated budget.** `worker-plan.md` says **"50-150 lines
   is the healthy range: under 50 usually means under-specified, over 150 usually means you are
   writing implementation detail that belongs in the code."** Measured: **38 of 47 exceed 150**, 17
   exceed 300, mean **286**. This is the single largest per-round read in the pipeline and the rule
   against it already exists — another compliance failure rather than a missing rule, the same shape
   as the Impact Map currency finding in item 69. Enforcing it (Reviewer checks length as a PLAN
   dimension) would roughly halve the ~2260-line figure.
2. **Agreed item 59 adds ~670 lines of new per-task reading** by routing the governing spec to PLAN
   and CODE agents. That is real and was not priced when it was agreed. It is partly paid for by
   agreed item 67 (option A): TASK-032's spec carries 26 `.kt` refs and TASK-038's 43 line refs, and
   removing implementation detail from `## Behavior` and `## Acceptance criteria` should shrink specs
   materially. Worth re-measuring spec length after 67 lands rather than assuming.

Already-agreed items that cut reads and should be noted as paying part of this bill: **41** (shrink
`worker.md` Step 0.2, read by every Worker every round), **55** (move five code rules out of
`worker.md` into `worker-code.md`), **14.4** (`orchestrator-notes.md` size discipline — "this file
holds only what no other artifact holds", 920 B to 21 KB today).

## Plan length, item 59 re-examined, and the missing spec template

### 72. The plan-length budget — WITHDRAWN, the author's worry is correct *(my proposal, refuted)*
I proposed enforcing `worker-plan.md`'s 50-150 line budget as a PLAN review dimension. The author
objected that cutting length could cut substance. **The corpus agrees with the author, not with me.**

**Length is not accumulation.** Excluding the `## Review Response` / `## Implementation Notes`
sections that later rounds append by design, the *core* plan still runs long: median **237** lines,
**33 of 47** over 150. So the plans themselves are long, not merely grown.

**But length is not bloat either.** The guidance's own stated rationale is *"over 150 usually means you
are writing implementation detail that belongs in the code."* Measured: **43 of 47 plans contain zero
code blocks**; the maximum anywhere is 4. TASK-028's plan is the longest in the corpus at 559 core
lines with **no code at all** — its bulk is `## Approach` (256), `## Test Plan` (67), `## Acceptance
Criteria` (47), `## Risks & Open Questions` (42). That is reasoning and contract, not pasted
implementation. **The rule's diagnosis does not describe what is actually in the long files.**

**And length does not predict defects.** Grouping by core length against CODE-phase outcomes:

| Group | n | mean CODE Criticals | mean CODE rounds |
|---|---|---|---|
| core ≤ 200 lines | 20 | 0.10 | 1.05 |
| core > 200 lines | 27 | 0.33 | 1.41 |

The weak positive association runs the *wrong way* for my proposal and is in any case confounded by
task difficulty — harder tasks get both longer plans and more findings. Decisively, four of the six
longest plans produced **zero** CODE Criticals, including the 559-line one and B21/B22/SESSION-009-C.
There is no evidence in this corpus that long plans are worse plans.

**Answer to the author's mechanism question.** The only defensible test is a *content* test, never a
line count: *does this line state a decision, a constraint, or the evidence for one — or does it
restate code the diff will show?* Measured, the second category barely exists here, so a Reviewer
dimension for it would fire almost never. That is a reason not to add the dimension, not a reason to
add it with a number attached. **A Reviewer must never flag length per se**; there is nothing in the
data that would justify it.

### 73. Fix the 50-150 guidance text instead *(agreed — option B, the author's call over my recommendation of A)*
The rule is not merely unenforced, it is **misleading**, and it costs Workers effort. TASK-038's
Worker wrote: *"plan.md written (247 lines — over the 150 guidance, deliberately: 11 ACs, all
mapped)"* — a Worker spending words apologising to a rule whose rationale does not match its own
situation. TASK-028 exceeded it by 3.7x with a clean CODE phase.

**Options:**
- **A (recommended)** — replace the number with the content test from item 72 and keep a soft floor:
  *"under ~50 lines usually means under-specified. There is no upper bound: length should track the
  task's real complexity. What does not belong is restating code the diff will show."*
- **B** — raise the ceiling to match observed practice (median core 237, so ~250-300) and keep a
  number. Cheaper edit, but re-creates the same apologising behaviour one bracket higher.
- **C** — leave it. Costs: Workers keep justifying themselves against a false rationale, and any future
  reader may try to enforce it as I did.

### 74. Item 59 restated and re-priced *(agreed — option B)*
**What it says:** `reviewer.md` Step 0.5 names `ROADMAP.md` as the Reviewer's "source of truth for what
the task should accomplish"; Step 1.4 routes the governing spec to the **SPEC phase only**. Nothing
tells a PLAN or CODE Reviewer to read the spec, even though on a spec-governed task the spec — not the
nine-line ROADMAP row — is what the work was built against, and the Orchestrator commits the two
together.

**What motivated it:** **41 of 133** PLAN/CODE review files cite a `spec/spec-*` path anyway — a third
of all reviews routing around the gap unaided. The author's explanation covers most of it (7 of 27
`ROADMAP.md` rows carry a `**Spec**:` field that Step 0.5 already routes to), but not all: **TASK-044's
spec is cited nowhere in `ROADMAP.md`**, so that Reviewer had no channel at all.

**What it costs:** the governing spec is median **170** lines (mean 206, max 491, n=34). Routing it to
~4-5 PLAN/CODE Reviewer sessions is **~700-850 lines per task** of new reading. About a third of that
is already being paid voluntarily by the 41 reviews that fetch it today, so the true marginal cost is
nearer **~500 lines/task**.

**Options, priced against the failure it prevents — a Reviewer approving work against the wrong
contract:**
- **A — full spec to PLAN and CODE Reviewers.** Cost ~500 marginal lines/task. Prevents the failure
  completely. Simplest to state.
- **B — only when the ROADMAP row links one**, plus the item-59 requirement that a spec-governed row
  must carry `**Spec**:`. Cost: identical reading when a spec exists; the saving is zero. What it buys
  is that spec-less tasks are never sent hunting. Effectively A with a guard.
- **C — only the outcome sections, skipping `## Context`.** *Not implementable as stated, and this
  refutes my own earlier phrasing* — see item 75. Only **8 of 34** specs have a `## Behavior` section;
  `## Requirements` (17) is the commoner name, and median Behavior+AC is **19.5 lines of 170**, because
  the sections mostly are not there under those names. Cannot be revived without item 75.
- **D — drop it; rely on the ROADMAP row plus the `**Spec**:` link for Reviewers that want it.**
  Cost: zero. Accepts the TASK-044 case, where the row links nothing and the Reviewer reviewed against
  a nine-line summary of a 253-line spec. Note the corpus shows Reviewers fetch the spec unaided when
  they can find it, so D mostly formalises today's behaviour.

**Recommendation: B**, and revisit C after item 75. B costs what A costs but never sends a Reviewer
looking for a document that does not exist, and it pairs with the `**Spec**:` requirement already
agreed. Also note agreed item 67 should shrink specs — TASK-032 carries 26 `.kt` refs, TASK-038 43
line refs — so re-measure before treating the ~500 lines as permanent.

### 75. There is no spec template, and that is the root cause of two other problems *(agreed — option A)*
`worker-spec.md` (36 lines) tells the Worker to edit the spec, keep it on *what* and *why*, and record
assumptions — but **never says what sections a spec has**. Every other artifact in this skill has a
template: `plan.md`, `status.md`, the review file, `handoff.md`, `dispatched.md`. The spec, the only
one that is **committed and permanent**, has none.

Result: 34 specs, **20+ distinct top-level section names**. `## Acceptance criteria` 28/34;
`## Assumptions` 21; `## Value` 19; `## Requirements` 17; `## Why` 14; `## Scope` 9; `## Constraints`
9+5; `## Non-goals` 8+3; `## Behavior` **8**; plus one-offs like `## Root cause`, `## Part …`,
`## Verify against current Alpaca docs at implementation`.

Same failure as item 14 defect 3 (no template → six `orchestrator-notes.md` vocabularies) and item 62
(no `## Verification` section → ten headings). This one is worse because the artifact is durable.

**It also breaks two already-agreed items:**
1. **Item 67** (agreed, option A) is written as "code citations allowed in `## Context`;
   `## Behavior` and `## Acceptance criteria` state observable outcomes only." Only 8 of 34 specs have
   `## Behavior` and few have `## Context`. **The agreed rule must be restated section-agnostically**
   — "any section stating what the system must do" — or the template must come first.
2. **Item 59 option C** (read only the outcome sections) is unimplementable without it.

**Options:**
- **A (recommended)** — add a spec template to `worker-spec.md` with the sections the corpus already
  converged on: `## Value` / `## Why`, `## Requirements`, `## Acceptance criteria`, `## Non-goals`,
  `## Assumptions`, and an optional `## Context` for evidence. This ratifies observed practice rather
  than inventing structure, makes item 67 statable, and revives item 59 option C.
- **B** — restate item 67 section-agnostically and leave specs unstructured. Cheaper; leaves the
  durable artifact as the only untemplated one and keeps option C dead.
- **C** — do nothing. Item 67 as currently worded applies to sections most specs do not have, i.e. it
  would silently no-op.

### Decisions on 73 / 74 / 75 (author, 2026-08-22)

- **73 = option B.** Raise the ceiling to ~250-300 and keep a number. I recommended **A** (replace the
  number with the content test, keep only a soft floor); the author chose B. **Caveat preserved for
  whoever implements it:** a number reproduces the apologising behaviour one bracket higher — TASK-038
  wrote *"247 lines — over the 150 guidance, deliberately"* — and TASK-028's clean 559-line plan would
  still breach a 300 ceiling by 1.9x. Mitigation worth folding into the wording: state the ceiling as
  *guidance about typical complexity, never a review criterion*, and say explicitly that a Reviewer
  must not raise a finding on length (item 72). That keeps the author's number without arming it.
- **74 = option B.** The governing spec is routed to PLAN and CODE Reviewers **only when the ROADMAP
  row links one**, paired with the already-agreed requirement that a spec-governed row must carry a
  `**Spec**:` field. Spec-less tasks send nobody hunting. Re-measure the ~500 line/task cost after
  item 67 lands, since removing implementation detail should shrink specs.
- **75 = option A.** Add the corpus-converged template to `worker-spec.md`: `## Value` / `## Why`,
  `## Requirements`, `## Acceptance criteria`, `## Non-goals`, `## Assumptions`, plus an optional
  `## Context` for evidence. **Agreed item 67 is restated against these sections** — citations allowed
  in `## Context`, with `## Requirements` and `## Acceptance criteria` stating observable outcomes only
  — which removes the no-op risk from 67's original `## Behavior` phrasing. **59 option C stays moot**
  now that 59B is chosen, though the template would make it available if the cost is ever revisited.

---

## Status — 2026-08-27

The walk is complete: `SKILL.md` in session 1 (items 1-20), `worker.md`, `reviewer.md` and the phase
files in session 2 (items 21-75). Header markers were re-scanned rather than recalled, and twelve
were corrected: items 22, 23, 24, 25, 27, 30, 31, 32, 39, 40, 41 and 42 were decided or resolved by
later decisions but still read *open*/*recommended*. They now read correctly.

**Genuinely open — five topics, each with options already recorded:**

| # | Topic | Options |
|---|---|---|
| **21** | Phase 0's first dispatch is illegal by the letter of the protocol; 7/7 Orchestrators fabricate `status.md` to get past it. Item **46** (who owns `status.md` creation) depends on this. | **A (rec.)** ratify it — `SKILL.md` tells the Orchestrator to write `status.md` before the Phase-0 dispatch and the Reviewer template gains a `phase` slot; **B** give the SPEC Reviewer a create-it-yourself branch; **C** dispatch a no-op Worker first (rejected — nothing for it to do) |
| **29** | A Reviewer killed after writing `review-round-N.md` but before `status.md` leaves `AWAITING_REVIEW`; the successor counts files +1 and burns a round on a death | **A (rec.)** idempotency rule — if a review file for the current round exists and no Worker submitted since, replace rather than increment; **B** give the Reviewer a `progress.md` (expensive; reviews are 12.6 min median); **C** nothing |
| **34** | `/verify` carry-forward: 3 of 25 CODE Reviewers approved on an earlier round's green with sound narrow-delta reasoning the protocol forbids, and the Orchestrator's commit gate cannot tell carried-forward from fresh | **A (rec.)** codify it and require `## Verification` to name the round the green came from; **B** forbid it, always re-run; **C** nothing — three approvals stay out of compliance |
| **56 / 57** | `progress.md` entry types. The author declined my start-entry rejection and parked it; the corpus supports them (TASK-044's predecessor wrote a start entry and then died, carrying the intended order to its successor) | **A (rec.)** labelled types — `DONE` / `START` / `NOTE`, one word per line, which makes start entries safe and gives anomaly observations a home; **B** keep milestone-only; **C** milestone-only plus `NOTE` for anomalies |
| **66** | The three-architects PLAN fan-out has **never executed** (0 `Plan`-type spawns in the corpus). Agreed item 67 removes the reason it never fires, so an untested branch starts running | **A** leave it and accept a first live exercise; **B** deliberately test it on one task; **C (rec.)** simplify to a single-agent "name and reject one alternative", which is what the three declining Workers did in prose anyway |

**Withdrawn by measurement, not argument:** item **60** (sibling files in the unaccounted sweep — never
happened in the corpus), item **72** (the plan-length budget — the author's objection was right, and
43 of 47 plans contain zero code blocks), and item **47**'s original eligibility-rules premise. Item
**22** was narrowed by the author's ROADMAP-link explanation before being resolved outright.

**Everything else is agreed.** The list is ready to become a Spec once the five above are settled.

### 34 (expanded) — exactly what the protocol forbids, and what the three Reviewers did

**The rule, verbatim** (`review-code.md:1-11`):

> **First, prove the change actually runs.** Do not take the plan's "tests pass" on faith — you are
> the independent check, so run it yourself. Run every test suite the change can affect… Then run
> `/verify` to exercise the change through its real runtime surface.
>
> **A green `/verify` is a precondition for approval** — any failure here is finding #1, Critical.

And `SKILL.md` step 5: *"confirm `handoff.md` has a `## Verification` section recording a green
`/verify`. If that evidence is missing, the approval is incomplete: do not commit."*

So the letter of the rule is: **the approving Reviewer runs `/verify` itself, in the round it
approves.** Nothing licenses reusing an earlier round's run.

**An important narrowing before judging the three.** All 25 CODE Reviewers ran the **full test suite**
in their own round — that part was never skipped. What the three carried forward was only the runtime
`/verify` exercise. And the rule's stated *rationale* is "do not take the plan's 'tests pass' on
faith — you are the independent check". Reusing **your own** prior green is not taking the Worker's
word. The three violated the letter, not the spirit, which is probably why three capable Reviewers
independently did the same thing.

**The three, verbatim:**

1. **TASK-028 CODE round 2** — *"`/verify` deliberately not re-run, per the narrow-delta scope. Round
   1's `/verify` covered the live Ktor surface (contained tick failures across three ticks,
   kill-switch stickiness over 2.5 minutes, the reset watermark, the 403 off-happy-path probe) and the
   `BacktestCli` surface… The delta touches one catch clause on a pure failure-recovery path plus
   three Markdown files; it cannot change any behavior those runs exercised."*
2. **B15-live CODE round 2** — *"`/verify` … was run green in round 1 and is carried forward: the
   round-1 fixes touched sync/discovery logic and tests only — no drivable boot/validation surface
   changed — so a re-run was judged unnecessary."*
3. **TASK-037 CODE round 5** — the strongest, and it contains its own better rule:
   *"**`/verify`:** not re-run, and deliberately so. The round-1 CODE review ran three independent
   real-surface probes… **No compiled artifact changed this round — proven above from mtimes and the
   diff, not taken from the Worker's word** — so that evidence still describes the shipped binary.
   **If this round had touched any `.kt`/`.xml`/`.kts` file the probes would have had to be
   repeated.**"*

**Proposed codification — lift TASK-037's test, because it is mechanical.** "Narrow delta" (cases 1
and 2) is a judgment call and would license drift. "No compiled artifact changed" is checkable:

- **The test:** if the round's diff touches any file that enters the built binary — source,
  resources, build scripts — the Reviewer re-runs `/verify`. A round whose diff is docs, comments and
  review artifacts only may carry forward.
- **Guardrail 1:** `## Verification` must name **which round** produced the green and state the test
  that licensed the carry-forward, e.g. *"carried forward from CODE round 1; this round's diff is
  three Markdown files, no compiled artifact."*
- **Guardrail 2:** the Orchestrator's commit gate then has something mechanical to read — it checks
  that a round is named, not that prose sounds convincing. It still never reads a diff.
- **Guardrail 3:** the full test suite is **never** carried forward. 25 of 25 already re-run it; the
  carve-out is only for the runtime exercise.

Options remain: **A (recommended)** codify as above; **B** forbid carry-forward outright — costs a
runtime re-run on docs-only rounds and makes three sound approvals retroactively wrong; **C** nothing.

### 66 (expanded) — the fan-out, and why item 67 makes this live

**The mandate, verbatim** (`worker-plan.md:7-27`):

> Most roadmap tasks extend an existing pattern and have one clearly-correct approach… **Fan out only
> when the task genuinely admits multiple viable architectures with real tradeoffs**… If you can't
> articulate a second defensible approach in one sentence, there's no fork — don't manufacture one.
>
> When it does fork, spawn three `Plan`-type agents in parallel (one message, three `Agent` calls),
> each given the same task context but a different mandate: **Minimal changes** … **Clean
> architecture** … **Pragmatic balance** …
>
> Each returns its own design sketch and tradeoffs. Compare them against this task's actual
> constraints… pick the one that fits best — or a hybrid that grafts a specific idea from a runner-up
> onto the winner — and say why.

**It has never executed.** Zero `Plan`-type spawns in the entire corpus; every recorded
`subagent_type` is `general-purpose` (127) or `claude-code-guide` (2). Of the 18 sessions carrying the
three mandates in context, 16 spawned nothing and 2 spawned exactly one agent.

**The gate is working, not being ignored** — three Workers recorded declining it, and all three give
the *same* reason: the spec had already fixed the design. TASK-030 *"admits no second architecture"*;
TASK-032 *"the spec pins the site"*; TASK-038 *"the spec fixes the seam, constants, wiring source and
guard shape"*.

**Why agreed item 67 changes this.** 67 stops specs from pinning implementation. The three declines
are all downstream of exactly that pinning, so removing it removes the reason the fork never appears.
PLAN starts arriving with real architectural choices — and a branch that has never run once starts
running. Untested: the three-way parallel spawn, the comparison step, and how the chosen approach
reaches `## Approach`'s "Alternatives you considered".

**Options and what each costs:**

- **A — leave it; first exercise is on a real task.** Bounded downside: worst case is a poor plan,
  which the PLAN Reviewer catches (that is what the phase is for). Token cost when it fires is real —
  three parallel Plan agents against a Worker-PLAN baseline of ~32 tool calls each, so roughly 100
  extra tool calls on a forked task.
- **B (recommended, changed from my earlier C) — exercise it deliberately once.** Same information as
  A, strictly safer, and it resolves the question with evidence instead of by amputation. Cost: one
  chosen task.
- **C — simplify to a single-agent "name and reject one defensible alternative".** Cheapest and it
  matches what the three declining Workers already did in prose. **What is lost:** genuine parallel
  exploration is the mechanism's whole value proposition — three independent agents can surface an
  approach the single Worker would not have thought of — and that value has never been measured
  because the branch never ran. C forecloses it permanently, at precisely the moment item 67 makes
  architectural choice available again. That timing is what changed my recommendation.

### 66 decided (author, 2026-08-27): option B
Exercise the fan-out deliberately on one chosen task before relying on it. Nothing is amputated, and
the three-way spawn / comparison / "Alternatives you considered" path gets its first execution under
observation rather than mid-run on real work. Do this **after** item 67 lands, since 67 is what makes
a genuine architectural fork reachable in the first place.

### 34 (compressed) — the whole carve-out in three sentences *(agreed — option A)*

The author accepts the substance but not the instruction weight: today's rule is one sentence, simple
but sometimes wasteful. **It compresses without losing anything.** Two of my three guardrails are one
clause each, and the third does not live in `review-code.md` at all.

**Current text** (`review-code.md`, ~35 words):

> Then run `/verify` to exercise the change through its real runtime surface.
> **A green `/verify` is a precondition for approval** — any failure here is finding #1, Critical.

**Proposed replacement** (~50 words, +15):

> **A green `/verify` is a precondition for approval** — run it yourself in any round whose diff
> touches a file that enters the built binary. A round that changed only docs, comments or review
> artifacts may carry an earlier green forward; name the round it came from. The test suite is
> re-run every round, never carried.

Plus **six words** in `SKILL.md` step 5, where guardrail 2 actually belongs: *"…recording a green
`/verify`, **from this round or a named earlier one**."*

**All three guardrails survive:**

| Guardrail | Where it lands | Cost |
|---|---|---|
| 1 — name the round the green came from | clause 2 of the new text | ~7 words |
| 2 — the Orchestrator's gate reads a named round, still never a diff | `SKILL.md` step 5 | ~6 words |
| 3 — the suite is never carried forward | clause 3 | ~11 words |

So the answer to "which guardrail would you sacrifice" is **none — the question does not arise at this
size.** If one had to go it would be guardrail 1, and the cost is disproportionate: without a named
round the Orchestrator's commit gate degrades from a mechanical check into reading prose that
references a run nobody can locate, which is the failure item 34 exists to prevent.

**A simpler alternative considered and rejected:** require `/verify` only in the round the Reviewer
*approves*, skipping it on `NEEDS_FIXES` rounds. That is arguably already the literal reading ("a
precondition for **approval**") and would cut runs on multi-round phases with no artifact test at all.
Rejected because it does not address the observed cases — TASK-028 r5 and TASK-037 r5 were both
**approving** rounds. The waste is precisely in the round this alternative protects.

**Priced options:**

- **A (recommended)** — the three-sentence replacement above. +15 words in `review-code.md`, +6 in
  `SKILL.md`. Recovers the ~12% of CODE review rounds (3 of 25 measured) where a runtime re-run proves
  nothing, and makes three sound approvals compliant instead of retroactively wrong.
- **B** — keep today's one sentence. Simplest possible instruction; costs a full runtime exercise on
  every docs-only approving round, and leaves capable Reviewers choosing between following the rule
  and doing the sensible thing. Note they already chose the sensible thing three times, so the rule is
  not actually being obeyed today.
- **C** — the test only, dropping "name the round". Saves 7 words; costs the mechanical commit gate.

### 34 decided (author, 2026-08-27): option A
The three-sentence replacement in `review-code.md` plus the six-word clause in `SKILL.md` step 5.
+21 words total, all three guardrails intact.

---

## Final state — 2026-08-28

**One decision remains open: items 56/57 (`progress.md` entry types).** It was listed as one of five
open topics; the author ruled on 21, 29, 34 and 66 and did not address this one. Recorded here rather
than assumed closed — twice in this session I asserted something I had not verified, so the tally
below is produced by scanning the headers, and items 1-20 count as agreed because they sit under
session 1's `## Agreed` heading rather than carrying an inline marker.

| Outcome | Count | Items |
|---|---|---|
| agreed | 63 | 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 23, 24, 26, 27, 28, 29, 30, 31, 34, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 50, 52, 53, 54, 55, 58, 59, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 73, 74, 75 |
| resolved by another item | 3 | 22, 25, 32 |
| withdrawn | 2 | 60, 72 |
| informational (no change) | 5 | 33, 35, 43, 49, 51 |
| OPEN | 2 | 56, 57 |

**Total: 75 items — 63 agreed, 2 open.**

### The one open decision: 56/57 — `progress.md` entry types

`worker.md` Step 4 permits only completion entries: *"Append an entry the moment a unit of work is
genuinely finished… Not when you are about to start one."* The author was unconvinced by my defence of
that ban and parked it. The corpus supports the author: TASK-044's predecessor wrote a start entry in
defiance of the rule — *"Starting implementation: schema/domain first, then broker seams, then
BracketOrderManager resolution + submitEngineExit, then SignalExecutor, then tests, then docs"* — and
then died, handing its successor the intended order. Workers also already write a third unsanctioned
kind: TASK-044's *"FOREIGN EDIT observed at 03:21 … adopting, will re-verify; NOT reverting."*

- **A (recommended)** — labelled types, one word per line: `DONE` (today's contract, unchanged),
  `START` (safe *because* labelled — a successor can never mistake it for a landing, which was my only
  real objection), `NOTE` (anomalies: foreign edits, sibling sessions, blocked-on-X).
- **B** — keep milestone-only. Costs the intent signal in exactly the death case the file exists for.
- **C** — milestone-only plus `NOTE`. Captures the concurrency observations without reopening the
  start-entry question.

**Withdrawn or reversed on measurement, not argument** — preserved because each was a proposal the
corpus refuted:

- **60** — the unaccounted-changes sweep would flag sibling sessions. It never has; every report names
  the task's own inputs.
- **72** — enforce `plan.md`'s 50-150 budget. 43 of 47 plans contain zero code blocks, the longest
  (559 lines) had zero CODE Criticals, and length tracks difficulty rather than defects.
- **47's original premise** — a conflict with `docs/AUTONOMOUS_RUNS.md`'s eligibility rules. That
  document is a work in progress from this same session, not evidence of practice. The item survived
  on a different, internal argument.
- **56** — my rejection of start entries, reopened after the author declined it.
- **59 option C** and **67's original wording** — both assumed a `## Behavior` section only 8 of 34
  specs have. Fixed by item 75's template.

**Recommendation reversed by data:** session 1 ranked an adjudicator first for the Reviewer-error
gate; the measured base rate (3 re-assertions in the corpus, 2 of 49 tasks) inverted it to the
evidence floor alone (items 4/65).

**Sequencing constraints the Spec must respect:**

1. **Item 7 (delete the `dispatched:` archaeology) lands with item 21 (Phase-0 dispatch).** Three of
   seven Orchestrators used that legacy key as their only channel for the action string; removing the
   "strip it" instruction first would let stale keys survive into reviews.
2. **Item 2 (the `[DONE]` flip) touches four sites**, including `roadmap-spec.md:48-50`, the one that
   reads as normative. Fixing `reviewer.md` alone relocates the contradiction.
3. **Items 28/36/38/54 (timestamps) touch four sites** and must all land before `SKILL.md`'s
   self-reported-timestamp caveat is deleted.
4. **Item 47 (delete Worker self-selection) lands with the `SKILL.md` mode-table edit**, or the skill
   advertises an entry point its protocol file refuses.
5. **Item 75 (spec template) precedes item 67 (spec scope)**, which is worded against its sections.
6. **Item 66 (exercise the fan-out) comes after item 67**, which is what makes a genuine fork
   reachable.

---

## Spec-drafting decisions (2026-08-27)

### 76. Review scope is the manifest alone; the Impact Map is a completeness checklist *(agreed — supersedes the "union" wording in item 69)*
The author challenged the union. **They are right and "union" was the wrong word** — you cannot
*review* a file that has no diff. The two artifacts answer different questions and only one of them is
a review scope:

| Question | Answered by | Who asks it |
|---|---|---|
| What changed, and what do I read? | **`changed-files.md`** — the Worker's claim, written by the agent that made the edits | CODE Reviewer (read scope), Orchestrator (staging) |
| What was promised, and was any of it silently dropped? | **Impact Map** — declared intent, frozen at PLAN approval | CODE Reviewer (completeness only) |
| Whose is this file I did not expect? | `git status` minus the manifest | CODE Reviewer (report, do not review, do not attribute) |

**What manifest-alone would lose is real: silent omission.** A plan that declares
`docs/CONFIGURATION.md` MODIFY and a Worker that never touches it produces a manifest with no such
row — nothing to notice. The skill already treats this class as blocking in a narrower form: a test
the plan committed to and the code dropped is *always* Critical, never a Recommendation. A **file**
the plan committed to and the code dropped is the same failure, and `review-code.md` already uses the
map this way ("Check the diff against the doc files in the plan's Impact Map").

**And the manifest gets a cross-check it would otherwise lack.** A Worker that forgets or misstates a
row is caught because the file still appears in `git status` and falls into the unaccounted sweep —
the mechanism item 60 measured as working. Manifest and `git status` check each other; the map checks
neither.

**Net effect on reads** (the point of item 71a): the Orchestrator stops opening `plan.md` entirely at
commit time — 251 median lines down to ~15. The map survives for two readers only: the PLAN Reviewer,
who reviews it as intent, and the CODE Reviewer, who checks it for absences.

### 77. Self-hosting the rewrite — the hazard is uncommitted protocol text governing live agents *(agreed — M5 + M7)*
The rewrite runs through the pipeline it is rewriting. Three exposures, only one of them sharp:

1. **Across tasks (benign, and intended).** Task N commits protocol edits; task N+1 runs under them.
   The edits were reviewed and committed. With the right ordering this is the *hardening*, not the
   hazard — see item 78.
2. **The Orchestrator's own stale context (minor).** It read `SKILL.md` at run start and holds it for
   every task. A task that rewrites `SKILL.md` leaves the Orchestrator acting on superseded rules.
3. **Within one task (sharp).** A Worker edits `reviewer.md`; the Reviewer dispatched to judge that
   edit reads the working tree and is **governed by the unreviewed text it is reviewing.** Uncommitted,
   unapproved protocol changes are in force for the agent deciding whether to approve them.

**Mechanisms, priced:**

| # | Mechanism | Cost | Verdict |
|---|---|---|---|
| M1 | Edit a copy of the skill dir, swap at the end | The docs and prompts are full of self-referential paths (`.agents/skills/sdlc/references/worker.md`); a copy needs every path rewritten or it is wrong. `/verify` for a docs change *is* running the pipeline, which would run the live copy | Reject — high friction, and the isolation it buys is mostly re-bought by M5 |
| M2 | Pin the submodule SHA at run start; every dispatch reads the protocol at that SHA | Subagents must read via `git show` rather than opening a file — a bash call instead of Read, and every prompt template changes. Also freezes out the improvements the run is making | Reject |
| M3 | Order tasks so protocol edits land last | Nearly all the work *is* protocol edits | Reject — no purchase |
| **M5** | **When the task under review edits this skill, the Reviewer reads its own protocol from the last committed state, not the working tree** | One conditional sentence, firing only on self-hosting tasks | **Recommend** — targets exposure 3 exactly |
| **M7** | **The Orchestrator re-reads `SKILL.md` at the start of each task when the run is editing the skill** | One sentence | **Recommend** — closes exposure 2 |

M5 + M7 together are two sentences and leave exposure 1, which is the desired behaviour.

### 78. Task breakdown — multiple tasks, one Orchestrator, in a row *(agreed — author's decision on assumption 2)*
Eight tasks, ordered so the six sequencing constraints hold and so each task exercises the rules its
predecessors installed:

| # | Task | Items | Constraint satisfied |
|---|---|---|---|
| T1 | Contradictions and counters | 2, 50, 1, 31, 6, 23, 24, 45 | 2 |
| T2 | Handshake, dispatch and self-selection | 21, 46, 5, 7, 44, 47, 58, 52, 53, 61 | 1, 4 |
| T3 | Timestamps | 11, 28, 36, 38, 54 | 3 (internal) |
| T4 | Recovery and liveness | 3, 15, 17, 18, 19, 20, 29, 14 | — |
| T5 | Scope, staging and the manifest | 12, 25, 69, 70, 76, 39, 40, 41, 42 | — |
| T6 | Dead-letter channels | 26, 27, 30, 37, 48, 62, 64, 13 | — |
| T7 | Spec discipline | 75 → 67 → 10, 32, 68, 22, 59, 74 | 5 (internal) |
| T8 | Review quality, verbosity, inputs | 4/65, 34, 35, 55, 73, 71, 8, 9, 16 | — |
| T9 | Acceptance run + fan-out exercise | 66, criterion 13 | 6 |

**The ordering is itself the hardening.** T1 installs per-phase review filenames and the corrected
round counting, so T2 onwards run under them — every later task is a live test of an earlier one, and
T9 runs under all of it. The corollary is that **T1 and T2 carry the most risk**: a defect there
degrades every subsequent task's pipeline rather than only its own output. Worth running T1 and T2
attended, and the rest unattended.

### 79. "Later tasks test earlier ones" is only true for LOUD failures *(agreed — per-task post-conditions)*
My framing assumed a protocol regression would announce itself. Classifying T1's plausible defects by
what the Orchestrator would actually see during T3:

| T1 defect | Symptom in a later task | Noticed today? |
|---|---|---|
| Review-file read-list not updated with the write-name | Round-2 Reviewer reads **no** previous findings and reviews as if round 1 never happened | **No — silent.** Orchestrator sees a normal `NEEDS_FIXES` |
| Round counting wrong | `MAX_ROUNDS_EXCEEDED` fires early; task blocks | Loud, but **misattributed** ("hard task") unless someone compares round to the file count |
| `MaxRounds` not passed to the Reviewer | Reviewer self-blocks one round early | Loud; checkable by comparing `status.md` round against the configured cap |
| `[DONE]` flip left in two places | Duplicate flip | Benign |
| `[DONE]` flip left in none | Task never marked done | Loud at commit |

**The silent row is the whole problem**, and it is the same class as the death-detection bug that ran
undetected for months precisely because a dead subagent looked like a clean finish. A protocol
regression produces a *plausible* run, not a broken one.

**Detection — each task needs a post-condition on pipeline behaviour, not only on its own diff.**
Cheap greps over the *next* task's artifacts, checked by the Orchestrator before dispatching it:

- after T1: the next task's directory contains phase-named review files and no bare
  `review-round-N.md`; every `status.md` round is ≤ the count of that phase's review files; exactly one
  commit flips the heading to `[DONE]`.
- after T3: every timestamp written in the next task's directory carries `Z` and sits within a few
  minutes of the file's mtime.
- after T5: `changed-files.md` exists and its path set equals the set staged in that task's commit.

Each is a one-line check and each converts a silent failure into a loud one.

**Remediation — stop and escalate; never fix forward.**

- **Rejected: fix forward inside the live task's round.** It puts an unplanned protocol change inside
  another task's scope, and that task's Reviewer would be judging an edit it has no plan for — the
  scope-creep rule exists for exactly this.
- **Rejected: revert everything and re-run.** Later tasks' edits are independent and committed;
  reverting T1 does not undo them. What is suspect is not their *output* but whether they were
  *correctly executed* under the broken rule.
- **Recommended: halt, remediate in a dedicated task, then re-REVIEW (not re-implement) the tasks that
  ran under the defect.** A run whose own protocol is broken is precisely the
  `BLOCKED` / `NEEDS_HUMAN_DECISION` condition the skill already defines. The Orchestrator must not
  self-heal.
- **In-flight handling:** let the live subagent finish rather than killing it (item 18 puts destructive
  actions last), record the halt under `## Interruptions`, revert the in-flight task's heading to
  `[PENDING]`, then run the remediation task. Rounds already spent stay spent; the re-review of
  affected tasks starts a fresh phase round.

### 80. In-place vs a submodule branch — reconsidered properly *(agreed — in-place with the five guards)*
The author asked me to reconsider rather than defend. The serious version of the proposal is not a
copy — it is a **second worktree of the submodule** on a rewrite branch, with the live
`.agents/skills/` checkout pinned at the pre-run SHA and one `checkout`/`merge` as the swap. Git
handles the paths, and the docs' self-references stay correct because they name the *deployed*
location, which is right in both.

| | In-place | Branch worktree |
|---|---|---|
| Silent-defect detection | **8 live tests, one per task, each with a named cause** | **1 test (T9), 8 tasks' changes tangled together** |
| Blast radius of a T1 defect | T2-T8 run under it | Contained; T2-T8 unaffected |
| Remediation | Halt + dedicated task + re-review (item 79) | Branch fixup, no live protocol surgery, no in-flight lock complications |
| Exposure 3 (Reviewer governed by unreviewed text) | Needs mechanism M5 | **Solved by construction** — one fewer rule |
| Revert the whole run | Per-task revert | One submodule checkout |
| Setup cost | None | Worktree, Impact Map paths point at it, a swap step, and `/verify` needs the swap first |

**Recommendation: in-place, guarded.** Three reasons:

1. **The branch's containment argument is weaker than it looks.** A protocol defect does not corrupt
   anything — it makes a task run *badly* (under-reviewed diff, wasted round, false block). Every code
   change here is a reviewed doc edit. The worst case is re-reviewing a task, which is item 79's
   remediation either way.
2. **The dogfooding is not a bonus, it is the only detector.** Under branch mode a silent T1 defect is
   caught by nothing until T9, where eight tasks' changes are entangled and attribution is hardest.
   In-place, T2 catches it with a named cause. The author's own question — *how will we know something
   failed?* — is answered better by the option that runs the new rules eight times.
3. **Risk is concentrated, not spread.** T1 and T2 hold nearly all of it, and they are already planned
   as **attended**. A human watching the two riskiest runs beats structural isolation of all nine.

**Guards that make in-place safe** — the price of this recommendation:

- item 79's per-task post-condition checks, converting silent to loud;
- a tag on each task's submodule commit, so revert points are clean;
- T1 and T2 run attended;
- mechanisms M5 and M7 from item 77;
- halt-and-escalate on any post-condition failure — the Orchestrator never self-heals.

**Where I would switch to the branch:** if T1 or T2 has to be run unattended, or if the run is
extended to changes that are not doc edits.

---

## Approved — 2026-09-05

The author approved the Spec. All 80 items are settled: **70 agreed, 3 resolved by another item,
2 withdrawn on measurement, 5 informational.** Nothing is open.

Delivery: `spec/spec-20260905-sdlc-skill-hardening.md` in the Ricci repo, implemented as
**TASK-051 through TASK-059**, run sequentially under one Orchestrator, in place, with the five
guards from item 80 as conditions. TASK-051 and TASK-052 run attended.

This file is the evidence record behind that Spec and is named in its Impact Map. It is no longer a
working document — further changes belong in the tasks.
