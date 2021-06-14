# Playwright

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `playwright` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:playwright, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/playwright](https://hexdocs.pm/playwright).

## Usage

These are a collection of examples of the same usage scenarios in multiple languages to use as inspiration for this Elixir library. The following is all work in progress and/or examples of what we'd like to accomplish with this library.

## Playwright Example - Simple

### TypeScript

```typescript
import * as playwright from "playwright";

(async () => {
  const endpoint = "ws://localhost:3000";
  const browser = await playwright.chromium.connect({ wsEndpoint: endpoint });
  const context = await browser.newContext();
  const page = await context.newPage();

  await page.goto("https://playwright.dev");
  await page.screenshot({ path: `screenshots/typescript.png` });
  await browser.close();
})();
```

### Python

```python
import asyncio
from playwright.async_api import async_playwright

async def main():
    async with async_playwright() as playwright:
      endpoint = "ws://localhost:3000"
      browser  = await playwright.chromium.connect(wsEndpoint=endpoint)
      context  = await browser.new_context()
      page     = await context.new_page()

      await page.goto("https://playwright.dev)
      await page.screenshot(path=f'screenshots/python.png')
      await browser.close()

asyncio.run(main())
```

### Elixir

```elixir
endpoint = "ws:/localhost:3000"
browser  = Playwright.Chromium.connect([wsEndpoint: endpoint])
context  = Playwright.Browser.new_context(browser)
page     = Playwright.BrowserContext.new_page(context)

Playwright.Chromium.connect()
|> Playwright.Context.new()
|> Playwright.Page.goto(...)
|> Playwright.Page.click(...)

page
|> goto("https://playwright.dev")
|> screenshot(...)

Playwright.Browser.close(browser)
```

## Playwright Example - Video Conference (using Jitsi)

### TypeScript

See [playwright-example-ts](https://github.com/geometerio/playwright-example-ts)

### Elixir (potential, using `playwright-elixir`)

```elixir
defmodule Application.Features.MultiUserTest do
	use ExUnit.Case, async: true
	use Playwright # or, `import Playwright`?

	describe "A multi-user video room" do
		setup_all do
			# ...
			endpoint = "ws://..."
			{:ok, browser} = Playwright.Chromium.connect(ws_endpoint: endpoint)

			on_exit(fn -> Playwright.Browser.close(browser) end)
			%{browser: browser, users: ["user-0", "user-1", "user-2", "user-3"]}
		end

		setup [:setup_page, :setup_room, :setup_steps]

		test "is successful", ctx do
			# port: `await Promise.all(ctx.users.map(async (user: string) => {...`
			# NOTE:
			# - It will probably be something using `Task.async` and Task.await`
			# - If so, that's pretty great!
			# - Assuming so, the next best thing for me to do is to continue with
			#   my two current primary learning threads:
			#   - "Mix and OTP" on elixir-lang.org
			#   - Dave Thomas' course
			# - Should also check out other recommended and compelling resources, such as:
			#   - elixirschool.com
			#   - the training service that Greg sent me: grox.io
			#   - Manning books

			# move to a setup...
			# context = Playwright.BrowserContext.init(browser)
			# page = Playwright.Page.init(context)

			# port: `for (var step of steps) {...`
			step(ctx.steps, ctx)
		end
	end

	# ---

	def setup_page(ctx) do
		page = ctx.browser
		|> Playwright.BrowserContext.init
		|> Playwright.Page.init

		%{page: page}
	end

	# ---

	defp step([], ctx) do
	end

	defp step([next | rest], ctx) do
		next(ctx)
		step(rest, ctx)
	end

	defmodule Steps do
		def enter_room(ctx) do
			ctx.page
			|> goto(ctx.room)
			|> fill("css=input.field", ctx.user)
			|> click("css=button.join")

			assert ...
		end

		def leave_room(ctx) do
		end
	end
end
```

## Contributing/development

### Getting started

1. Clone the repo
2. Run `bin/dev/doctor` and for each problem, either use the suggested remedies or fix it some other way
3. Run `bin/dev/test` and then `bin/dev/start` to make sure everything is working

### Day-to-day

- Get latest code: `bin/dev/update`
- Run tests: `bin/dev/test`
- Start server: `bin/dev/start`
- Run tests and push: `bin/dev/shipit`
