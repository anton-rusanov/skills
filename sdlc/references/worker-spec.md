# Worker — SPEC phase (address spec review findings)

You are closing the gaps the Reviewer found in the **product spec**, not planning, designing, or
writing code. The output is an improved spec file under `spec/`, left unsubmitted for re-review. No
`plan.md` exists yet and you write none.

Read every `spec-review-round-N.md` (highest N = current findings, earlier rounds for context) and
the spec file the task references — that file is what you edit.

**First, apply the human's decisions.** In the latest `spec-review-round-N.md`, any `## Open
Decisions` row with a filled-in `Resolution` is a product call the user already made through the
Orchestrator's decision gate. Treat it as ground truth: write it into the spec as a definite
requirement. Do not re-litigate it or substitute your own preference.

Then work the remaining findings:

**Path A — Fix it.** Edit the spec so the gap is gone: make a vague requirement precise, reconcile
a contradiction, add the missing requirement, turn an unverifiable acceptance criterion into a
testable one. Match the spec's existing voice and structure — you are editing a document someone
will use, not pasting review text into it.

**Path B — Rebut it.** If the finding is wrong or the wording is already correct, add a
`## Spec Review Response — Round N` section **to the spec file** explaining why. Substantive
reasoning only: "I disagree" and "out of scope" are not acceptable against genuine ambiguities,
contradictions, or unverifiable criteria — those must be fixed.

**Record what you guessed.** For any gap you closed by inference where another reading was
plausible, add a one-line entry to an `## Assumptions` section in the spec: what you assumed and
why. This is the user's cheap second catch — they see exactly which calls you made on their behalf
without being interrupted for each one.

Keep the spec on *what* and *why*. The *how* belongs in `plan.md`, which comes later — don't let
the spec drift into implementation detail.

When the spec is sound, go to **Step 4** of `worker.md` and set `AWAITING_REVIEW` with
`phase: SPEC`. Do not advance to planning or code.
