---
name: secrets
description: Load and distribute API keys from .env to worker and iOS targets. Run at session start.
---

# Secrets Skill

Manages API keys for Claude, OpenAI, and Gemini across all targets.

## When to Use

**Always run at the start of a new session** before starting dev servers or running tests. Keys may have been rotated.

## Commands

```bash
# Generate .dev.vars for local worker development
./scripts/setup-secrets.sh worker-dev

# Deploy secrets to Cloudflare Worker (production)
./scripts/setup-secrets.sh worker

# Generate iOS Secrets.swift file
./scripts/setup-secrets.sh ios

# All targets
./scripts/setup-secrets.sh all
```

## Typical Session Start

```bash
# 1. Refresh secrets (in case keys were rotated)
./scripts/setup-secrets.sh worker-dev

# 2. Start the worker
cd worker && npm run dev &

# 3. Start the web frontend
cd web && npm run dev &
```

## Files

- `.env` - Source of truth (never committed)
- `.env.example` - Template showing required keys
- `worker/.dev.vars` - Generated for local worker dev (never committed)
- `ios/ReaderApp/Secrets.swift` - Generated for iOS (never committed)

## Required Keys

```
CLAUDE_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=AI...
```

Not all keys are required - only the providers you want to use.
