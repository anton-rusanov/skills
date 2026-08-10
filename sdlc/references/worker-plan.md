# Worker — PLAN phase

Read only the files you need to understand the problem — be surgical. Start from the context
pointers you recorded in Step 1 and follow type/interface references from there. Do not read the
whole codebase.

## When the approach isn't obvious, fan out before committing to one

Most roadmap tasks extend an existing pattern and have one clearly-correct approach — for those,
skip straight to **Plan dimensions** below. Fan out only when the task genuinely admits multiple
viable architectures with real tradeoffs (a new abstraction, a cross-cutting change, or more than
one existing pattern it could reasonably follow). If you can't articulate a second defensible
approach in one sentence, there's no fork — don't manufacture one.

When it does fork, spawn three `Plan`-type agents in parallel (one message, three `Agent` calls),
each given the same task context but a different mandate:

- **Minimal changes** — smallest diff, maximum reuse of what's already there.
- **Clean architecture** — optimizes for maintainability and clear boundaries, even if it touches
  more files.
- **Pragmatic balance** — the middle path: reasonable boundaries without excessive refactoring.

Each returns its own design sketch and tradeoffs. Compare them against this task's actual
constraints (not in the abstract), pick the one that fits best — or a hybrid that grafts a specific
idea from a runner-up onto the winner — and say why. This comparison becomes the `Approach`
section's "Alternatives you considered" below; the Reviewer should be able to see you considered
real alternatives, not just the one you happened to think of first.

## Plan dimensions

Work through every dimension below **before** writing `plan.md`, and again as your gate before
handing off. These are the same questions the Reviewer will ask — catch the problems now. If you
cannot answer one, the plan is not ready.

**Does it actually solve the problem?**
- [ ] Every acceptance criterion maps to a specific, concrete part of the approach — none is
      silently missing.
- [ ] The approach fixes the root cause, not a symptom (fixing a calculation ≠ fixing where the
      wrong value originates).
- [ ] At least three edge cases — unusual inputs, states, or timing — are identified and handled.

**Architecture**
- [ ] It fits the project's existing layers and separation of concerns (e.g. a zero-dependency
      domain layer stays that way).
- [ ] It follows the patterns found in Step 0; anything new is justified by why the existing
      patterns are insufficient.
- [ ] Every new interface/abstraction earns its keep — no indirection "just in case". Simpler wins.
- [ ] No new coupling: a change here does not force a change there.

**Security**
- [ ] Every new input surface (endpoint, parameter, file read, external call) is named, and its
      validation, authentication, and authorization are described.
- [ ] Credentials, tokens, and PII are excluded from logs, error messages, and responses.
- [ ] No injection risk (SQL, command, path traversal) in the design.

**Performance**
- [ ] The approach stays efficient at the real data scale.
- [ ] No I/O or DB calls inside loops without explicit justification (each is a potential N+1).
- [ ] No unbounded result sets that should be paginated.
- [ ] Any new cache has a defined invalidation strategy and a stated consequence for stale reads.

**Backward compatibility**
- [ ] Every change to an existing API contract, method signature, schema, or serialized format is
      identified — with a migration path if it breaks.
- [ ] Old and new code can coexist safely during a rolling deploy.

**Deployability**
- [ ] New env vars, secrets, or infrastructure are named, defaulted sensibly, documented, and
      available in every environment.
- [ ] Any new DB migration is additive-only and safe against live data.

**Scope**
- [ ] Every element traces to an acceptance criterion or explicit requirement. "Related but not
      required" gets cut.
- [ ] Nothing from the task description is silently omitted.
- [ ] The test plan covers every criterion — error paths and boundaries, not just the happy path.

**Documentation**
- [ ] Every doc file the change requires is listed in the Impact Map. If the change alters
      structure, an API contract, configuration, or documented behavior, the docs are part of this
      task. `README.md` is a hub — update the linked file that owns the topic, and the README
      itself only if the summary it carries changed. An omitted doc update is a finding waiting to
      happen; if no doc change is needed, say so explicitly so the Reviewer knows it was a decision.

## Write `plan.md`

```markdown
# Implementation Plan: <TASK-ID>

## Task
<Paste or summarize the task description from ROADMAP.md>

## Acceptance Criteria
<Numbered list of every explicit "done" condition, copied verbatim from the task.>

## Analysis
<What you learned from reading the relevant code>
<Key interfaces, data flows, and dependencies>
<Existing patterns you are following and where you found them>

## Approach
<Your proposed solution — what changes, where, and why>
<Alternatives you considered and why you rejected them>
<For each acceptance criterion: which part of the approach satisfies it>

## Impact Map
| Repo       | Target File           | Change Type | Dependencies | Breaking Changes |
|------------|-----------------------|-------------|--------------|------------------|
| backend    | Foo.kt                | MODIFY      | Bar.kt       | None             |
| backend    | Baz.kt                | NEW         | None         | New env var      |
| (umbrella) | docs/CONFIGURATION.md | MODIFY      | None         | None             |

The Impact Map is this task's **declared scope**, not documentation. Concurrent sessions share this
checkout, and three later steps read this table to stay out of each other's way: the CODE Worker
checks the working tree only in the repos it names, the Reviewer reviews only the paths it names,
and the Orchestrator stages exactly those paths at commit time. Name the repo for every row —
`backend`, `frontend`, `mls-integration`, or `(umbrella)`. A file the CODE Worker ends up touching
that is not listed is either a missed dependency or scope creep; it gets added to the map with a
reason, in the same session, never silently.

## Test Plan
<For each acceptance criterion: what test covers it>
<What error paths and boundary conditions are tested>
<What the tests verify — not just that they exist, but what behavior they assert>

## Risks & Open Questions
<Anything you're uncertain about — be honest, not confident-sounding>
<Edge cases you identified but are not explicitly handling, and why>
```

A Reviewer who never saw your reasoning must be able to judge whether the approach is sound from
this alone. **50–150 lines** is the healthy range: under 50 usually means under-specified, over 150
usually means you are writing implementation detail that belongs in the code.

## Addressing PLAN-phase review findings

For each finding, either fix the plan or rebut it in a `## Review Response — Round N` section of
`plan.md` explaining why the current approach is correct, what property of the system makes the
concern inapplicable, and what tradeoff you are accepting. "I disagree", "later", "out of scope",
and "it works" are not rebuttals. Then re-run the dimension gate above.
