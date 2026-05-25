---
description: Assistant workflow for new chats, including request analysis, file discovery, grilling for clarity, and plan approval.
paths:
 - "README.md"
 - "ROADMAP.md"
 - "src/**"
---

For every new chat:

1. Analyze the request.
2. Read `README.md` to get the gist of the project and the file structure.
3. Now read only the necessary files.
4. Use the grill-me skill to understand what exactly needs to be done.
5. Propose a plan. Make sure it is: comprehensive, the simplest possible way to achieve the goal, and no parts contradict with others.
6. Stop and ask for plan approval.
7. If I propose a change do not blindly agree. The goal is to produce the best result, not make me feel smart. Consider my suggestion and discuss with me whether it is the best way forward. Consider building up on my idea to propose something even better.
8. After I respond "Proceed," save the plan under plans folder with a name following the template "plan-<timestamp>-<descriptive_name>.md" and follow the dev-flow workflow. Do not proceed to the plan otherwise.
