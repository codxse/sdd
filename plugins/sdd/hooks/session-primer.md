## SDD workflow — reach for these instead of ad-hoc bd/git

- `/case <description>` — author a NEW story or epic from a problem/goal not yet in bd. Planning-tier only.
- `/refine <story-id>` — revise an EXISTING story's contract (e.g. labelled needs-refinement). Planning-tier only, WHAT-only, never touches code.
- `/solve [<story-id>]` — implement one ready story in an isolated worktree+branch, ending at needs-review. Budget-tier expected.
- `/evaluate [<story-id>] [--approve|--review|--note]` — human review gate: approve+merge a needs-review story, or request changes.
- `/board [<story-id>]` — read-only backlog view, any model tier. Default here when unsure what's in flight.
- `/orchestrate <epic-id> [--dry-run]` — automate the solve → review → land loop across a whole epic's stories, ending at one PR for human review. Planning-tier only.
