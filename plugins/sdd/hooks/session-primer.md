## SDD workflow — reach for these instead of ad-hoc bd/git

- `/specify <description>` — author a NEW story or epic from a problem/goal not yet in bd. Frontier-tier only.
- `/refine <story-id>` — revise an EXISTING story's contract (e.g. labelled needs-refinement). Frontier-tier only, WHAT-only, never touches code.
- `/solve [<story-id>]` — implement one ready story in an isolated worktree+branch, ending at needs-review. Any tier — matched to the story's complexity call.
- `/validate [<story-id>] [--approve|--review|--note]` — human review gate: reviews a needs-review story at effort `high`, then merges on your approval. `--approve` skips the review pass.
- `/board [<story-id>]` — read-only backlog view, any model tier. Default here when unsure what's in flight.
- `/orchestrate <epic-id> [--dry-run]` — automate the solve → review → land loop across a whole epic's stories, ending at one PR for human review. Frontier-tier only.
