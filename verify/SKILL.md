---
name: verify
description: Verify a code change by running the app and observing its behavior at the real surface — not by running tests or typechecking. Reads a project-local verify.md (if present) for this repo's build/launch/drive recipe. Use before committing a nontrivial change, or when asked to confirm something actually works.
---

# Verify — observe the running app

Verification is **runtime observation**. Build the app, run it, drive it to where the
changed code executes, and capture what you see. That capture is the evidence — nothing
else is.

**Do not run the test suite or the typechecker as your verification.** They prove CI
passes, not that the change works. Reading a test to learn what to check is fine; then go
run the app. A diff that touches only tests/docs/config with no runtime surface → report
**SKIP** with one line, don't manufacture a run.

## First: read the project recipe

If the repo root has a **`verify.md`**, read it before doing anything else — it holds this
project's build/launch/drive handle (how to get a runnable image, which surface each kind
of change reaches, seeding/fixtures, and the gotchas that would otherwise cost you an hour).
This skill stays generic on purpose; the project specifics live in `verify.md` so they don't
leak across repos. If there's no `verify.md`, cold-start from the README/build files, and
once you find a recipe that works, **write it to `verify.md`** so the next run skips the
cold start.

## The loop

1. **Find the change** — establish the real diff range (`git diff`, the branch, or the PR),
   not just `HEAD~1`. The diff is ground truth; any description is a claim about it.
2. **Pick the surface** — CLI → type the command; server/API → send the request; GUI →
   drive it and screenshot; library → call the public export. An internal function is not a
   surface; follow it out to the CLI/route/render that reaches it.
3. **Drive it** — the smallest path that makes the changed code execute. Changed a flag,
   run with it; a handler, hit that route; an error path, trigger the error.
4. **Push on it** — one probe off the happy path (empty/blank input, a conflicting combo, a
   bad token, do-it-twice). Confirming is half the job; the value is what the author didn't test.
5. **Capture & report** — the app's own output (stdout, response body, screenshot). Verdict
   is **PASS / FAIL / BLOCKED / SKIP**; the observations are the signal. Lead with anything
   that made you pause.

Destructive path with no dry-run or safe target → don't drive it live; verify around it and
say which path you didn't exercise and why.
