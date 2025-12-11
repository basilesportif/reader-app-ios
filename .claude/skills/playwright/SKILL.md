---
name: playwright
description: Browser automation for testing. Always close browser when done with browser_close.
---

# Playwright Skill

Use Playwright MCP tools for browser automation and testing.

## Important Rules

1. **Always close the browser** when you're done with Playwright testing using `browser_close`
2. Start fresh with `browser_navigate` for each test session
3. Use `browser_snapshot` to get page state before interactions
4. Use `browser_wait_for` when waiting for async operations

## Typical Test Flow

```
1. browser_navigate - Go to the URL
2. browser_snapshot - Get current state
3. browser_click / browser_type / browser_select_option - Interact
4. browser_wait_for - Wait if needed
5. browser_snapshot - Verify result
6. browser_close - ALWAYS close when done
```

## Cleanup

After completing any Playwright testing session, always run:
- `browser_close` to close the page and free resources
