# Secrets Management

This project uses API keys for Claude, OpenAI, and Gemini vision APIs. Keys are stored in a single `.env` file and distributed to each target (worker, iOS) via a setup script.

## Quick Start

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```

2. Add your API keys to `.env`:
   ```
   CLAUDE_API_KEY=sk-ant-api03-...
   OPENAI_API_KEY=sk-...
   GEMINI_API_KEY=AI...
   ```

3. Run the setup script for your target:
   ```bash
   ./scripts/setup-secrets.sh worker-dev  # Local development
   ./scripts/setup-secrets.sh worker      # Production (Cloudflare)
   ./scripts/setup-secrets.sh ios         # iOS app
   ./scripts/setup-secrets.sh all         # All targets
   ```

## Targets

### Worker (Local Development)

```bash
./scripts/setup-secrets.sh worker-dev
```

Generates `worker/.dev.vars` which Wrangler loads automatically during `npm run dev`.

### Worker (Production)

```bash
./scripts/setup-secrets.sh worker
```

Deploys secrets to Cloudflare using `wrangler secret put`. Requires Wrangler CLI to be authenticated.

### iOS App

```bash
./scripts/setup-secrets.sh ios
```

Generates `ios/ReaderApp/Secrets.swift`. After running:
1. Add `Secrets.swift` to your Xcode project (if not already added)
2. Add `SECRETS_AVAILABLE` to Build Settings > Swift Compiler - Custom Flags > Active Compilation Conditions

## Getting API Keys

- **Claude**: https://console.anthropic.com/settings/keys
- **OpenAI**: https://platform.openai.com/api-keys
- **Gemini**: https://aistudio.google.com/app/apikey

## Security Notes

- Never commit `.env`, `.dev.vars`, or `Secrets.swift`
- All three are in `.gitignore`
- Rotate keys if accidentally exposed
- Use minimal permissions when creating keys
