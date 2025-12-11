---
name: screenshot
description: Take screenshots of websites using Playwright MCP and analyze their content. Use when the user asks to screenshot, capture, or view a website.
---

# Screenshot Skill

## Overview

This skill uses the Playwright MCP server to take screenshots of websites and analyze their content.

## Available Tools

The following Playwright MCP tools are available:
- `mcp__playwright__browser_navigate` - Navigate to a URL
- `mcp__playwright__browser_take_screenshot` - Capture a screenshot
- `mcp__playwright__browser_close` - Close the browser
- `mcp__playwright__browser_snapshot` - Get accessibility snapshot (better than screenshot for actions)
- `mcp__playwright__browser_click` - Click elements
- `mcp__playwright__browser_type` - Type text into elements
- `mcp__playwright__browser_press_key` - Press keyboard keys
- `mcp__playwright__browser_hover` - Hover over elements
- `mcp__playwright__browser_select_option` - Select dropdown options
- `mcp__playwright__browser_fill_form` - Fill multiple form fields
- `mcp__playwright__browser_tabs` - Manage browser tabs
- `mcp__playwright__browser_wait_for` - Wait for text/time
- `mcp__playwright__browser_console_messages` - Get console messages
- `mcp__playwright__browser_network_requests` - Get network requests
- `mcp__playwright__browser_evaluate` - Execute JavaScript
- `mcp__playwright__browser_install` - Install browser if needed

## Instructions

1. Use `mcp__playwright__browser_navigate` to navigate to the URL
2. Use `mcp__playwright__browser_take_screenshot` to capture the screenshot
3. Analyze the screenshot and describe what's on the page
4. **Important**: After answering the user's questions about the screenshot and when it's no longer needed:
   - Delete the screenshot file to clean up
   - Close the browser window using `mcp__playwright__browser_close`

## Cleanup

Always clean up after use:
- Screenshots are saved to `.playwright-mcp/` directory
- Use `rm` to delete the file once you've answered all questions about it
- If the user asks follow-up questions, keep the screenshot and browser open until they're done
- When the conversation moves on or the user is satisfied:
  1. Delete the screenshot image file
  2. Close the browser window with `mcp__playwright__browser_close`

## Example

```
User: Take a screenshot of example.com

1. Navigate to https://example.com
2. Take screenshot (saved to .playwright-mcp/page-{timestamp}.png)
3. Describe the page content
4. After user is done asking questions:
   - Delete the screenshot file with rm
   - Close browser with mcp__playwright__browser_close
```
