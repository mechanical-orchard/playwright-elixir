defmodule Playwright.MixProject do
  use Mix.Project

  @source_url "https://github.com/geometerio/playwright-elixir"

  def project do
    [
      app: :playwright,
      consolidate_protocols: Mix.env() != :dev,
      deps: deps(),
      description:
        "Playwright is an Elixir library to automate Chromium, Firefox and WebKit browsers with a single API. Playwright delivers automation that is ever-green, capable, reliable and fast.",
      dialyzer: dialyzer(),
      docs: docs(),
      aliases: aliases(),
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: @source_url,
      package: package(),
      preferred_cli_env: [credo: :test, dialyzer: :test, docs: :docs],
      source_url: @source_url,
      start_permanent: Mix.env() == :prod,
      version: "1.32.0-alpha.1"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Playwright.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:ex_unit, :mix],
      plt_add_deps: :app_tree,
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowlib, "~> 2.7.0"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:gun, "~> 1.3.3"},
      {:jason, "~> 1.2"},
      {:mix_audit, "~> 1.0", only: [:dev, :test], runtime: false},
      {:playwright_assets, "~> 1.32.0", only: [:test]},
      {:recase, "~> 0.7"},
      {:uuid, "~> 1.1"}
    ]
  end

  # :nest_modules_by_prefix
  defp docs do
    [
      name: "Playwright",
      source_url: @source_url,
      homepage_url: @source_url,
      main: "README",
      extras: [
        "README.md": [title: "Read Me"],
        # basics...
        "man/basics/getting-started.md": [filename: "basics-getting-started"],
        "man/basics/inspector.md": [filename: "basics-inspector"],
        "man/basics/trace-viewer.md": [filename: "basics-trace-viewer"],
        "man/basics/test-generator.md": [filename: "basics-test-generator"],
        "man/basics/debugging-tools.md": [filename: "basics-debugging-tools"],
        "man/basics/release-notes.md": [filename: "basics-release-notes"],
        # guides...
        "man/guides/assertions.md": [filename: "guides-assertions"],
        "man/guides/authentication.md": [filename: "guides-authentication"],
        "man/guides/auto-waiting.md": [filename: "guides-auto-waiting"],
        "man/guides/browser-contexts.md": [filename: "guides-browser-contexts"],
        "man/guides/browsers.md": [filename: "guides-browsers"],
        "man/guides/chrome-extensions.md": [filename: "guides-chrome-extensions"],
        "man/guides/command-line-tools.md": [filename: "guides-command-line-tools"],
        "man/guides/dialogs.md": [filename: "guides-dialogs"],
        "man/guides/downloads.md": [filename: "guides-downloads"],
        "man/guides/emulation.md": [filename: "guides-emulation"],
        "man/guides/evaluating-javascript.md": [filename: "guides-evaluating-javascript"],
        "man/guides/events.md": [filename: "guides-events"],
        "man/guides/extensibility.md": [filename: "guides-extensibility"],
        "man/guides/frames.md": [filename: "guides-frames"],
        "man/guides/handles.md": [filename: "guides-handles"],
        "man/guides/input.md": [filename: "guides-input"],
        "man/guides/locators.md": [filename: "guides-locators"],
        "man/guides/navigations.md": [filename: "guides-navigations"],
        "man/guides/network.md": [filename: "guides-network"],
        "man/guides/page-object-models.md": [filename: "guides-page-object-models"],
        "man/guides/pages.md": [filename: "guides-pages"],
        "man/guides/screenshots.md": [filename: "guides-screenshots"],
        "man/guides/selectors.md": [filename: "guides-selectors"],
        "man/guides/verification.md": [filename: "guides-verification"],
        "man/guides/videos.md": [filename: "guides-videos"]
      ],
      groups_for_extras: [
        # Basics: ["README.md"] ++ Path.wildcard("man/basics/*.md"),
        Basics: Path.wildcard("man/basics/*.md"),
        Guides: Path.wildcard("man/guides/*.md")
      ],
      groups_for_modules: [
        "Capabilities (API)": [
          Playwright,
          Playwright.APIRequestContext,
          Playwright.Browser,
          Playwright.BrowserContext,
          Playwright.BrowserType,
          Playwright.ConsoleMessage,
          Playwright.ElementHandle,
          Playwright.Frame,
          Playwright.Locator,
          Playwright.Page,
          Playwright.JSHandle,
          Playwright.Page.Accessibility,
          Playwright.Page.Locator,
          Playwright.RemoteBrowser,
          Playwright.Request,
          Playwright.Response,
          Playwright.Route,
          Playwright.Selectors,
          Playwright.WebSocket,
          Playwright.Worker
        ],
        Runner: [
          Playwright.Channel.Catalog,
          Playwright.SDK.Config
        ],
        Utilities: [
          Playwright.SDK.CLI
        ],
        "Test Helpers": [
          PlaywrightTest.Case,
          PlaywrightTest.Page
        ]
      ]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        homepage: @source_url,
        source: @source_url
      },
      files: ~w(lib priv LICENSE mix.exs README.md)
    ]
  end

  # NOTES:
  # - the `api.json` file is created to satisfy a `require('../../api.json')`
  #   call found in Playwright's `driver.js` file. We don't actually have any
  #   use for the "print-api-json" command, so an empty `api.json` works.
  defp aliases do
    [
      "assets.build": [
        "cmd mkdir -p priv/static/node_modules ; cp -r assets/node_modules/ws priv/static/node_modules",
        "cmd echo '{}' > assets/node_modules/playwright-core/api.json",
        "esbuild cli"
      ],
      "assets.watch": ["esbuild module --watch"]
    ]
  end
end
