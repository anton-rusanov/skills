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

---

# Session 2 — `worker.md` / `reviewer.md`

Second design session, 2026-08-20. Everything below is the **design partner's own read before the
author walked the files** — marked *recommended* or *open*, none of it decided. It is written down
up front only so a container death cannot lose it again. Numbering continues from 20.

## Recommended / open — not yet walked with the author

### 21. Phase 0's first dispatch contradicts the Reviewer's own start-up guard *(open)*
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

### 22. There is no channel for naming the governing spec *(open)*
`SKILL.md` triggers Phase 0 when "the prompt references a `spec/spec-*.md` **or** the ROADMAP task
links one" — but if it came from the prompt, neither Worker nor Reviewer ever learns which file.
Both protocols only say "the spec file the task references". Agents plugged the hole themselves: **8
of 47** `status.md` files carry an invented `spec:` key (A5, A7, B9, B11, B15-live, B20, S22,
SESSION-10), and one carries `plan:`/`review:`/`summary:` as well. The handshake schema is five keys;
agents needed six.

### 23. Item 6 lands harder than recorded — two rival conventions, not one improvisation *(recommended)*
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

### 24. `worker.md` Step 5's round rule is arithmetically wrong *(recommended)*
Step 5: "The round number is the count of existing review files for **this phase** — …otherwise
`review-round-N.md`. First submission is round 1." With the shared counter, a CODE Worker's first
submission after 3 PLAN rounds counts 3 files and writes `round: 3`. The rule contradicts its own
next sentence. `reviewer.md` Step 2 has the identical defect ("count of existing review files for
this phase, plus 1"). Both are *unexecutable* today — you cannot tell a file's phase from its name.
This is the same defect `SKILL.md` currently papers over with a warning paragraph; item 6 deletes the
cause in all three files at once.

### 25. Files outside the Impact Map are reported but never reviewed — and then staged *(open)*
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

### 27. `## Observations for Future Tasks` is not in the `plan.md` template *(recommended)*
Two files instruct the Worker to write into a section `worker-plan.md`'s template never defines.

### 28. Item 11's premise is only half true — the Reviewer has no clock *(agreed — see item 38 for the final form)*
Item 11 deletes `SKILL.md`'s self-reported-timestamp caveat because `worker.md` now mandates running
`date -u +%Y-%m-%dT%H:%M` and pasting stdout. That mandate exists **only in `worker.md`**.
`reviewer.md` Steps 2/5 and `SKILL.md`'s `dispatched_at` both just say "current ISO timestamp" — so
Reviewer and Orchestrator timestamps are still composed. Every terminal `status.md` in the corpus
ends in `:00` seconds, and TASK-032's `DONE` claims `12:05` against review files written at `05:57`.
Propagate the mandate to `reviewer.md` and to the Orchestrator's `dispatched.md` before deleting the
caveat — otherwise item 11 deletes a warning that is still accurate for two of the three roles.

### 29. The Reviewer has no crash story *(open)*
`worker.md` Step 4 gives the Worker `progress.md` and an explicit "your session can end without
warning". `reviewer.md` has no equivalent. Concretely: a Reviewer killed *after* writing
`review-round-N.md` but *before* rewriting `status.md` leaves `AWAITING_REVIEW` on disk. The
re-dispatched Reviewer counts existing files **plus 1** and writes round N+1 — spending a round on a
review that was already done, and burning the round budget on a death. Needs a rule: if a review file
for the current round already exists and no Worker has submitted since, replace it rather than
increment.

### 30. `reviewer.md` never mentions `orchestrator-notes.md` or `progress.md` *(open)*
Item 14 establishes `orchestrator-notes.md` as the only surviving record of in-session user decisions,
round-budget corrections, and pre-authorized scope. The Worker is told to honor an `## Interruptions`
entry. The Reviewer is told nothing — so a Reviewer can block on a deviation the user explicitly
pre-authorized, or flag a partial tree the Orchestrator already logged. At minimum the Reviewer
should read it in Step 0.

### 31. Item 1 and item 10 each have a second site in the phase files *(recommended)*
- Item 1 (round cap): the hardcoded `3` is in `reviewer.md` at Step 5 NEEDS_FIXES, Step 5 BLOCKED,
  and the "Don't approve because it's round 3" rule — three sites, all needing `MaxRounds` passed in.
- Item 10 (`SPEC_TOO_AMBIGUOUS`): the cap-of-5 is duplicated in **`review-spec.md`** ("Cap
  escalations at 5") as well as `reviewer.md`. Item 10's mechanical ask/assume test and its
  `## Assumed Decisions` table belong in `review-spec.md`'s Triage section, which is where the
  Reviewer actually makes the call.

### 32. Item 10 collides with an existing `## Assumptions` section *(open)*
`worker-spec.md` already tells the SPEC Worker to record what it guessed in an `## Assumptions`
section **inside the spec file**, calling it "the user's cheap second catch". Item 10 puts an
`## Assumed Decisions` table in `spec-review-round-N.md`, written by the **Reviewer**, surfaced at the
Phase-0 gate. Both can stand, but they must be reconciled explicitly: the Reviewer's table is the
gate-time render of decisions *not yet made*, the Worker's section is the durable record of decisions
*it made*, and each needs to say so or they will drift into two half-kept lists.

### 33. Item 13's digest premise is stronger than recorded *(informational)*
The terminal artifact exists in **45 of 47** task dirs (`summary.md` × 41 before the rename,
`handoff.md` × 4 after). A run digest assembled from them has near-complete source coverage.

### 34. `/verify` carry-forward is an undocumented carve-out agents invented *(recommended)*
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
