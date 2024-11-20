# Getting Started

- [Release Notes](/basics-release-notes.html)
- [System Requirements](#system-requirements)

## Installation

The package can be installed by adding `playwright` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:playwright, "~> 1.18.0-alpha.1"}
  ]
end
```

To ensure Playwright's runtime dependencies (e.g., browsers) are available, execute the following:

```bash
$ mix playwright.install
```

## Usage

Once installed, you can `alias` and/or `import` Playwright in your Elixir module, and launch any of the 3 browsers (`chromium`, `firefox` and `webkit`).

```elixir
{:ok, session, browser} = Playwright.launch(:chromium)
page =
  browser |> Playwright.Browser.new_page()

page
  |> Playwright.Page.goto("http://example.com")

page
  |> Playwright.Page.title()
  |> IO.puts()

browser
  |> Playwright.Browser.close()
```

## System requirements

TBD
