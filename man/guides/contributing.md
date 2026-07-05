# Contributing

This document outlines known issues, improvement opportunities, and areas where contributions are welcome.

## Critical Issues

These should be addressed with priority:

### Error Handling in `Browser.new_page/2`

**File:** `lib/playwright/browser.ex:155`

The `new_page/2` function doesn't handle errors from `new_context/2` or `BrowserContext.new_page/1`:

```elixir
def new_page(%Browser{session: session} = browser, options) do
  context = new_context(browser, options)
  page = BrowserContext.new_page(context)
  # crashes if context or page is an error tuple
end
```

**Fix:** Wrap in `with` statement to handle error tuples.

### Unsafe Atom Creation in `Page.on/3`

**File:** `lib/playwright/page.ex:501`

```elixir
def on(%Page{} = page, event, callback) when is_binary(event) do
  on(page, String.to_atom(event), callback)
end
```

**Risk:** Arbitrary string-to-atom conversion can exhaust atom table.

**Fix:** Validate against known event atoms or use `String.to_existing_atom/1`.

### Module Resolution Exit

**File:** `lib/playwright/sdk/channel_owner.ex:133`

```elixir
defp module(%{type: type}) do
  String.to_existing_atom("Elixir.Playwright.#{type}")
rescue
  ArgumentError ->
    exit("ChannelOwner of type #{inspect(type)} is not yet defined")
end
```

**Fix:** Return `{:error, reason}` instead of calling `exit/1`.

## Code Quality Improvements

### Naive Glob Implementation

**File:** `lib/playwright/sdk/helpers/url_matcher.ex:50`

Current implementation only handles `**` patterns:

```elixir
defp glob_to_regex(pattern) do
  String.replace(pattern, ~r/\*{2,}/, ".*")
end
```

**Missing:** `*` (single segment), `?` (single char), `[abc]` (character classes).

**Suggestion:** Use a proper glob library like [path_glob](https://github.com/jonleighton/path_glob).

### Duplicate Channel.find Call

**File:** `lib/playwright/sdk/channel_owner.ex:108`

```elixir
defp with_latest(subject, task) do
  Channel.find(subject.session, {:guid, subject.guid}) |> task.()
  Channel.find(subject.session, {:guid, subject.guid})  # Called twice
end
```

**Fix:** Store result of first call and return it.

### HACK Comments

These indicate fragile code that may break with Playwright updates:

| File | Line | Description |
|------|------|-------------|
| `lib/playwright/route.ex` | 24, 47 | Workaround for v1.33.0 changes |
| `lib/playwright/page.ex` | 513 | Event name conversion hack |

## Dead Code

These modules are empty stubs and can be removed:

| File | Notes |
|------|-------|
| `lib/playwright/local_utils.ex` | Marked "obsolete?" - 6 lines |
| `lib/playwright/fetch_request.ex` | Marked "obsolete?" - 6 lines |

## Unimplemented Features

### Config Options

**File:** `lib/playwright/sdk/config.ex`

These options are documented but silently ignored:

- `env` - Environment variables for browser process
- `downloads_path` - Custom downloads directory

### Skipped Tests

| File | Reason |
|------|--------|
| `test/api/page/accessibility_test.exs` | Needs `Page.wait_for_function` implementation |
| `test/api/browser_context/expect_test.exs` | Multiple tests unreachable |

## TODO/FIXME Items

| File | Line | Comment |
|------|------|---------|
| `lib/playwright/route.ex` | 22 | "figure out what's up with is_fallback" |
| `lib/playwright/browser.ex` | 159 | "handle the following, for page" |
| `lib/playwright/frame.ex` | 934 | FIXME: incorrect documentation |
| `lib/playwright/sdk/helpers/url_matcher.ex` | 49 | Replace with proper glob library |
| `lib/playwright/api_request_context.ex` | 66 | "move to APIResponse.body, probably" |
| `lib/playwright/sdk/channel/event.ex` | 14 | "consider promoting params as top-level fields" |

## Refactoring Candidates

Large files that could benefit from splitting:

| File | Lines | Suggestion |
|------|-------|------------|
| `lib/playwright/locator.ex` | 1365 | Split into Locator.Input, Locator.Navigation, etc. |
| `lib/playwright/frame.ex` | 1044 | Extract common patterns |
| `lib/playwright/page.ex` | 778 | Well-organized but large |

## Documentation Gaps

- ~516 public functions lack `@doc` annotations
- Many SDK modules have `@moduledoc false` but could use internal docs
- Commented-out function stubs (527 total) indicate unimplemented API surface

## Running Tests

```bash
# Run all tests
mix test

# Run with browser visible
PLAYWRIGHT_HEADLESS=false mix test

# Run specific test file
mix test test/api/page_test.exs
```

## Code Style

The project uses:

- `mix format` for formatting
- `mix credo` for linting
- `mix dialyzer` for type checking

Run all checks before submitting PRs:

```bash
mix format --check-formatted
mix credo --strict
mix dialyzer
```
