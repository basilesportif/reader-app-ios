# Reader App Backend

This directory is reserved for future backend implementation.

## Purpose

When needed, a backend can:
1. Keep API keys off the device
2. Route requests to multiple providers
3. Add caching, rate limiting, logging
4. Enable complex processing (DSPy, chaining)

## Expected API Contract

```
POST /query
Content-Type: application/json

{
  "image": "<base64>",
  "prompt": "string",
  "provider": "claude" | "openai" | "gemini" (optional),
  "model": "string" (optional)
}

Response:
{
  "response": "string",
  "provider": "string",
  "model": "string"
}
```

See `spec.md` in the project root for full details.
