# Reviewer — CODE phase dimensions

**First, prove the change actually runs.** Do not take the plan's "tests pass" on faith — you are
the independent check, so run it yourself. Run every test suite the change can affect, not just the
changed module's unit tests (a change in one module breaks another module's integration or e2e
suite): `./gradlew test`, `npm test`, … per affected module. Then run `/verify` to exercise the
change through its real runtime surface.

**A green `/verify` is a precondition for approval** — any failure here is finding #1, Critical.
When you approve, record what you ran and its outcome in `handoff.md` under `## Verification`; the
Orchestrator refuses to commit without it.

Then work through every dimension.

## Correctness
- Does the code implement what the approved plan described? Flag deviations **even when they are
  improvements** — undiscussed changes are unreviewed risk.
- Logic errors, off-by-one mistakes, wrong operators, inverted conditions?
- What happens on every error path — null returns, empty collections, network failures, partial
  writes? Trace each one.
- Edge cases the plan acknowledged but the code doesn't cover?
- Are concurrent or async operations safe — races, missing locks, shared mutable state, misused
  async primitives?

## Architecture
- Coupling that shouldn't exist; violations of the project's layering or module boundaries.
- Are new classes/interfaces/abstractions justified by the complexity they manage, or just
  indirection?
- Is the change localized to the right layers, or do concerns leak across boundaries (HTTP details
  in business logic, SQL in service code)?
- Do dependencies flow toward stable interfaces rather than volatile implementations?
- God objects, feature envy, or other structural smells?
- Is it structured to be testable — side effects isolated, dependencies injectable, pure logic
  separated from I/O?

## Security
- Are all external inputs validated before use — HTTP parameters, headers, file paths, deserialized
  data?
- SQL / command / template injection or path traversal risks?
- Is authentication checked before protected resources are touched, and authorization at the right
  granularity?
- Is sensitive data (passwords, tokens, PII) excluded from logs, responses, and error messages?
- Approved crypto algorithms and libraries — no home-rolled crypto, no MD5/SHA1 for security?
- New third-party dependencies: well-maintained, free of known critical CVEs?

## Performance
- Algorithmic complexity of the hot paths — justified?
- Database or I/O calls inside loops (each a potential N+1)?
- Unbounded result sets that should be paginated?
- Are expensive operations cached where appropriate, and is the invalidation correct?
- Are resources (connections, file handles, streams) closed on **all** paths, including errors?

## Readability
- Can a developer unfamiliar with the task understand what the code does and why, without the plan?
- Are names precise and consistent with the codebase vocabulary?
- Deeply nested logic that early returns or extracted functions would flatten?
- Magic numbers, hardcoded strings, or implicit assumptions left unnamed and unexplained?
- Do complex algorithms and non-obvious decisions carry a comment explaining the *why*?

## What's unnecessary
- Dead code — functions, branches, imports, variables defined but never used.
- Commented-out code.
- Defensive code for conditions the system's invariants forbid.
- New dependencies, config keys, or env vars the change doesn't actually need.
- Anything over-engineered for hypothetical future requirements.

## What's missing
- Is every acceptance criterion from the ROADMAP task demonstrably implemented?
- Error conditions with no handling — silent failures, swallowed exceptions, missing rollback?
- Are new public APIs, configuration values, and env vars documented?
- Tests for the happy path, the error paths, **and** the boundaries?
- **Did the implementation drop any test the approved plan or spec committed to?** Cross-check every
  acceptance criterion and every explicitly promised test against the diff. A committed test that is
  missing is a **Critical** finding — block on it even if the Worker argues the behavior is covered
  by composing separately-tested pieces.
- If the change affects structure, an API contract, configuration, or documented behavior, are the
  docs updated? Check the diff against the doc files in the plan's Impact Map. `README.md` is a hub
  linking deeper docs — verify the file that *owns* the affected topic was updated, not just the
  README. Shipping a behavioral change with stale docs is a finding, not an observation.

## Observability
- Enough logging to diagnose a production failure without a debugger? Do error logs say what
  failed, why, and on which input?
- Are new operations instrumented with metrics or traces where the rest of the system is?
- Are log levels appropriate — errors at ERROR, expected conditions at INFO/DEBUG?
- Do any log statements expose credentials, PII, tokens, or secrets?

## Backward compatibility
- Does it break an existing API contract, serialized format, or schema that current callers depend
  on?
- Could old and new versions run simultaneously during a rolling deploy without corrupting state?
- Are schema changes additive-only? Renames, type changes, and deletions break code still running
  on the previous version.
- If breaking changes exist, is the migration path documented **and implemented**?

## Data integrity
- Are writes that must be atomic wrapped in transactions, with the boundary neither too wide
  (performance) nor too narrow (partial updates)?
- Lost-update races — read-modify-write without protection against concurrent writers?
- If an operation fails partway, is the data left consistent? Is there rollback or compensation?
- Are uniqueness and referential integrity enforced at the database level, not only in application
  code?

## Deployability
- Are new env vars, secrets, and infrastructure dependencies documented and available everywhere?
- Are migrations safe against live data — non-blocking, reversible, not dependent on code that
  hasn't deployed yet?
- Will it deploy cleanly to all environments, or does it assume local-only configuration?

## Domain compliance
- Check the project's rules file for domain-specific requirements.
- Money handled with exact types (`BigDecimal`, not `Double`/`Float`) if the project mandates it.
- External-service calls: failures handled gracefully, retries bounded.
- Flag anything touching regulated operations (financial transactions, audit logs, data retention,
  access control).
