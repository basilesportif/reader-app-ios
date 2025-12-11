# Reader App

A multi-platform app for querying book pages using vision-capable LLMs (Claude, OpenAI, Gemini).

## Structure

- `ios/` - iOS app (SwiftUI, iOS 17+)
- `web/` - Web frontend (React + Vite)
- `worker/` - Cloudflare Worker API proxy
- `scripts/` - Setup and deployment scripts

## Setup

### Secrets

API keys are managed centrally. See [SECRETS.md](SECRETS.md) for full details.

```bash
cp .env.example .env
# Edit .env with your API keys
./scripts/setup-secrets.sh worker-dev  # For local development
```

### Web Development

```bash
# Terminal 1: Start worker
cd worker && npm install && npm run dev

# Terminal 2: Start frontend
cd web && npm install && npm run dev
```

Open http://localhost:5173

### iOS Development

1. Open `ios/ReaderApp.xcodeproj` in Xcode
2. Run `./scripts/setup-secrets.sh ios` to generate Secrets.swift
3. Build and run on your device

## See Also

- [SECRETS.md](SECRETS.md) - API key management
- [spec.md](spec.md) - Full specification
