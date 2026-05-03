# Worker Protocol

You are in **WORKER** mode. Your job is to understand a task, plan an implementation, write the code, and leave it ready for review. You do NOT commit — you leave changes visible in `git diff` for the Reviewer.

## Step 0: Pre-Flight Checks

1. **Ensure `.agents/sdlc/` is gitignored**: Check that `.gitignore` contains `.agents/sdlc/` (or a broader `.agents/` rule). If not, add it. SDLC artifacts (status files, plans, reviews) must not appear in `git status` or get committed alongside code changes.
2. **Verify clean working tree**: Run `git status --porcelain`. If the output is non-empty, a previous cycle left uncommitted changes. Set status to `BLOCKED` with reason `DIRTY_WORKING_TREE` and stop.
3. **Read project context**: Read `README.md` (or equivalent) to understand the project architecture, conventions, and dependencies.
4. **Read project-specific rules**: Check for `GEMINI.md`, `.agents/rules.md`, or similar files that define project-specific development practices.

## Step 1: Identify the Task

**If given a specific task ID** (e.g., "work on TASK-003"):
- Find that task in `ROADMAP.md` (read `references/roadmap-spec.md` in the skill directory if you need help parsing the format)
- Read its description, priority, and any acceptance criteria

**If asked to "work on the next task"**:
- Read `ROADMAP.md`
- Find the first task with `[PENDING]` status (or `[ ]` checkbox in session format)
- If no pending tasks exist, report this to the user and stop

**After identifying the task, check dependencies:**
- Look for "Depends on:", "Prerequisite:", or similar dependency declarations in the task description
- If dependencies exist, verify each one is `[DONE]` (or `[x]`) in the ROADMAP
- If any dependency is not done, set status to `BLOCKED` with reason `DEPENDENCY_NOT_MET` and stop — do not attempt to plan or implement

**If addressing review findings** (task status is `NEEDS_FIXES`):
- Read the task directory to find all `review-round-N.md` files
- The file with the highest N in its name (e.g., `review-round-3.md` over `review-round-1.md`) contains the latest findings — read that one for the issues to address
- Also read all earlier rounds for full context
- Read `plan.md` for the original plan context
- Skip to Step 4

## Step 2: Create Task Directory & Set Status

```
.agents/sdlc/tasks/<TASK-ID>/
```

Create this directory if it doesn't exist. Write `status.md`:

```
IN_PROGRESS
phase: PLAN
round: 0
updated: <current ISO timestamp>
task: <TASK-ID>
```

## Step 3: Plan

Read only the files necessary to understand the problem. Don't read the entire codebase — be surgical.

Write `plan.md` in the task directory using this structure:

```markdown
# Implementation Plan: <TASK-ID>

## Task
<Paste or summarize the task description from ROADMAP.md>

## Analysis
<What you learned from reading the relevant code>
<Key interfaces, data flows, and dependencies>

## Approach
<Your proposed solution — what changes, where, and why>
<Alternatives you considered and why you rejected them>

## Impact Map
| Target File | Change Type | Dependencies | Breaking Changes |
|-------------|-------------|--------------|------------------|
| Foo.kt      | MODIFY      | Bar.kt       | None             |
| Baz.kt      | NEW         | None         | New env var      |

## Test Plan
<What tests you'll write, what they verify>

## Risks & Open Questions
<Anything you're uncertain about>
```

The plan should be detailed enough that a reviewer who has not seen your reasoning process can evaluate whether the approach is sound.

## Step 4: Implement

Follow the project's established development workflow. If a workflow like `dev-flow.md` exists, follow it. The general pattern:

1. **Triage**: Is this Atomic (typo/docs/config) or Structural (logic/features)?
2. **Atomic tasks**: Direct edit → verify → done
3. **Structural tasks**:
   - Write tests first (TDD when practical)
   - Implement the changes
   - Run the test suite — all tests must pass
   - Update documentation if the structure or API changed

**When addressing review findings** (`NEEDS_FIXES`):
- Work through each finding in the review systematically
- For findings you disagree with, add a `## Review Response — Round N` section to `plan.md` documenting your reasoning
- You don't have to accept every suggestion, but you must have a convincing rationale for declining one. "I disagree" is not sufficient — explain why the current approach is better.

## Step 5: Self-Check Before Handoff

Before updating the status, verify:

- [ ] All tests pass (`./gradlew test`, `npm test`, or equivalent)
- [ ] No lint errors or warnings
- [ ] Changes are visible in `git diff` (do NOT `git add` or `git commit`)
- [ ] `plan.md` accurately reflects what was implemented (update if the plan drifted during implementation)
- [ ] If addressing fixes, each review finding is addressed or rebutted

## Step 6: Update Status

Write `status.md` — this is your LAST action:

```
AWAITING_REVIEW
phase: <PLAN or CODE>
round: <current round number>
updated: <current ISO timestamp>
task: <TASK-ID>
```

Set `phase: PLAN` when submitting the plan for review (before implementation).
Set `phase: CODE` when submitting implemented code for review.

The round number is determined by how many `review-round-N.md` files exist in the task directory:
- First implementation: round 1
- After first review: round 2
- After second review: round 3

## What NOT To Do

- **Don't commit.** Leave changes in the working tree for `git diff`.
- **Don't modify ROADMAP.md status.** The orchestrator handles this.
- **Don't start a new task** if you were asked to address review findings.
- **Don't over-plan.** The plan should be thorough but not a novel. A good plan is 50-150 lines.
- **Don't skip tests.** If the project has a test suite, your changes must not break it.
