# Reviewer — PLAN phase dimensions

No code exists yet. Your job is to catch bad decisions before they are built.

## Does it actually solve the problem?
- Map each acceptance criterion from the ROADMAP task to a specific part of the plan. A criterion
  with no corresponding section is a gap — flag it.
- Does the approach address the root cause, or patch symptoms?
- Which edge cases are *not* mentioned? Could the solution break under unusual inputs, concurrency,
  or resource constraints?

## Architecture
- Does it introduce coupling that shouldn't exist — would a change in one component force changes
  in another?
- Does it violate the project's separation of concerns (e.g. business logic leaking into
  persistence)?
- Are new abstractions justified, or is a simpler approach available? Every interface, base class,
  and indirection layer must earn its existence.
- Does it depend on implementation details rather than stable interfaces?
- Does it follow the existing patterns, or introduce a new one without justification?

## Security
- Does it add attack surface — new endpoints, inputs, privileges, external calls?
- Are authentication and authorization explicitly addressed where required?
- Are there injection risks in the design (SQL, command, template, path traversal)?
- Is sensitive data (credentials, PII, tokens) handled correctly — not logged, not stored
  insecurely?
- Are there timing attacks, TOCTOU races, or other subtle vulnerabilities in the design?

## Performance
- Will it scale under realistic production load?
- Any obvious algorithmic inefficiency (O(n²) where O(n) exists, repeated queries in a loop)?
- Does it put blocking operations in async or reactive paths?
- Unbounded collections, missing pagination, missing resource limits?

## Backward compatibility
- Does it change an existing API contract, serialized format, or database schema in a way that
  breaks current callers or deployed instances?
- If breaking changes are unavoidable, is there a migration path (versioned endpoints,
  backward-compatible schema changes, data migration)?
- Can it deploy incrementally, or does it need a coordinated cutover?

## Deployability
- New environment variables, secrets, infrastructure dependencies, or external services that aren't
  provisioned yet?
- New database migrations — safe against live data (additive-only, no blocking locks on large
  tables)?
- Will it deploy cleanly in every environment, or does it assume configuration that exists in only
  one?

## Scope
- **What is UNNECESSARY** — anything not required by the task. Scope creep introduces unreviewed
  risk; flag whatever goes beyond the ROADMAP task description.
- **What is MISSING** — check every acceptance criterion and constraint. A plan that silently
  ignores part of the requirements is not acceptable.
- Is the test plan adequate — covering each acceptance criterion, error paths, and boundaries, not
  just the happy path?
- Are risks and open questions honestly assessed, or papered over with confident-sounding language?
