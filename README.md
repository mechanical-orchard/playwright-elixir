# Playwright for Elixir

**NOTE:** This package is currently in "preview". The features are not yet at parity with other Playwright implementations. Once `playwright-elixir` is at or near parity with [`playwright`](https://github.com/microsoft/playwright), the version number will be updated to mirror the supported version of `playwright`.

## Overview

[Playwright](https://github.com/geometerio/playwright-elixir) is an Elixir library to automate Chromium, Firefox and WebKit with a single API. Playwright is built to enable cross-browser web automation that is **ever-green**, **capable**, **reliable** and **fast**. [See how Playwright is better](https://playwright.dev/docs/why-playwright).

## Installation

The package can be installed by adding `playwright` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:playwright, "~> 1.18.0-alpha.1"}
  ]
end
```

## Usage

- [README](https://hexdocs.pm/playwright/README.html)
- [Getting started](https://hexdocs.pm/playwright/basics-getting-started.html)
- [API Reference](https://hexdocs.pm/playwright/api-reference.html)

## Example

```elixir
defmodule Test.ExampleTest do
  use ExUnit.Case, async: true
  use PlaywrightTest.Case

  describe "Navigating to playwright.dev" do
    test "works", %{browser: browser} do
      page = Playwright.Browser.new_page(browser)

      Playwright.Page.goto(page, "https://playwright.dev")
      text = Playwright.Page.text_content(page, ".navbar__title")

      assert text == "Playwright"
      Playwright.Page.close(page)
    end
  end
end
```

## Contributing

### Getting started

1. Clone the repo
2. Run `bin/dev/doctor` and for each problem, either use the suggested remedies or fix it some other way
3. Run `bin/dev/test` to run the test suite make sure everything is working

### Day-to-day

- Get latest code: `bin/dev/update`
- Run tests: `bin/dev/test`
- Start server: `bin/dev/start`
- Run tests and push: `bin/dev/shipit`

### Building assets for a release

`mix assets.build`
