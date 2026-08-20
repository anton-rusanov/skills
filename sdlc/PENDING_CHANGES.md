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

### 4. A real gate on Reviewer errors
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
