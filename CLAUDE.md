# Claude Code Project Instructions

## Secrets Protection

NEVER read or display the contents of these files - they contain API keys:
- `.env`
- `.dev.vars`
- `worker/.dev.vars`
- `ios/ReaderApp/Secrets.swift`
- Any file matching `*.local` or `*secrets*`

If asked about secrets, explain how they work by referencing SECRETS.md, but never read the actual secret files.

## Tool Usage

When a skill is available that covers a task, ALWAYS use the Skill tool to invoke it instead of using lower-level tools directly. Skills provide higher-level, project-specific workflows and should take precedence over raw MCP tools or other lower-level alternatives.

