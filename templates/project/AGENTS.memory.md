<!-- opencode-memory-kit:start -->
## Thin Main Thread

Use OpenCode's built-in `plan` and `build` agents as the main conversation thread.

- Keep the main thread thin: clarify the goal, choose the next move, delegate broader work, and return with a short synthesis.
- Prefer the built-in `explore` subagent for codebase search, reading 4+ files, understanding architecture, tracing behavior, or comparing options.
- Prefer the built-in `general` subagent for multi-step execution, multi-file changes, tests, builds, and non-trivial bash.
- Keep work inline only when it is small and obvious: 1-3 quick reads, one narrow answer, or a mechanical single-file tweak.
- When delegating, ask for a compact handoff instead of a full transcript.
- Use a soft handoff rubric for subagent replies and omit sections that do not apply:
  - `Findings` or `Outcome`
  - `Files`
  - `Risks` or `Blockers`
  - `Verification`
  - `Next step`
- Keep subagent returns brief: about 5-8 bullets, no long logs, and no narration of every tool call.

## Project Memory Workflow

This project uses a durable AI memory layer stored in `docs/ai-memory/`.

### Persistent Memory

- Durable memory is for the repo's long-lived truth, not for temporary task handoffs.
- Use `docs/ai-memory/INDEX.md` as the entry point.
- For explicit manual lookup, use `/recall-feature <query>`.
- Memory is intentionally lazy-loaded. Do not read every file in `docs/ai-memory/` by default.
- When a task mentions existing functionality, prior decisions, regressions, previous bugs, or continuing work from a past session:
  1. Read `docs/ai-memory/INDEX.md`.
  2. Use `grep` on `docs/ai-memory/**/*.md` for relevant feature names, file paths, tags, and error strings.
  3. Read only the matching notes.
- Prefer `docs/ai-memory/features/*.md` for feature-specific implementation context.
- Prefer `docs/ai-memory/decisions.md` for durable cross-feature decisions and constraints.
- Prefer `docs/ai-memory/troubleshooting.md` for recurring errors, exact messages, root causes, and fixes.
- If previous work matters for a delegated task, look up the relevant memory first and pass only the useful summary or exact note paths to the subagent.
- `explore` may read memory when prior work, decisions, regressions, or recurring bugs are central to the task.
- `general` should prefer caller-provided memory summaries or exact note paths over broad memory searches.

### Updating Memory

- After a feature is implemented, iterated on, and accepted, persist durable context with `/remember-feature <kebab-case-slug>`.
- After a large refactor, feature removal, or cleanup pass, review stale memory with `/review-memory [scope]`.
- `docs/ai-memory/` should represent the current truth of the repo, not a historical archive.
- Only write durable memory when work is accepted or a real cleanup pass is happening.
- `/remember-feature` and `/review-memory` may automatically rewrite or trim stale notes when confidence is high.
- Deletions from the active memory tree require a brief review before removal.
- The memory update should capture only long-lived project knowledge:
  - relevant behavior now implemented
  - important files or modules touched
  - decisions that future work must respect
  - reusable debugging knowledge
- Do not store raw conversation logs, temporary speculation, large diff narration, or subagent handoff notes.

### Memory Quality Bar

- Keep notes concise and searchable.
- Include exact file paths and exact error strings when useful.
- Update existing notes in place instead of creating duplicates.
- Remove obsolete sections once they stop being true.
- Use Git history for old context instead of keeping dead notes under `docs/ai-memory/`.
<!-- opencode-memory-kit:end -->
