---
description: Software development using documentation-led planning and TDD workflow.
paths:
 - "src/*"
---

1. Triage: Categorize task as Atomic (typos/docs/linting) or Structural (logic/features).

2. Fast-Track (Atomic Only): >
   - Direct edit of the target file.
   - Verify syntax/linting.
   - Run the tests.
   - Finish. 

3. Architectural Alignment (Structural Only): Align task with data flow and config you learned from README.md. Propose an Impact Map (Target Files, Dependencies, Config, Breaking Changes). Wait for approval.

4. TDD Loop (Structural Only): > 
   - Propose tests. Wait for approval.
   - Red-Green-Refactor cycle (Max 3 iterations).

5. Doc & Audit: Sync README.md if structure or logic changed. Confirm all files in the Impact Map were addressed.