defmodule Playwright.MixProject do
  use Mix.Project

  @source_url "https://github.com/geometerio/playwright-elixir"

  def project do
    [
      app: :playwright,
      deps: deps(),
      description:
        "Playwright is an Elixir library to automate Chromium, Firefox and WebKit browsers with a single API. Playwright delivers automation that is ever-green, capable, reliable and fast.",
      dialyzer: dialyzer(),
      docs: docs(),
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      homepage_url: @source_url,
      package: package(),
      preferred_cli_env: [credo: :test, dialyzer: :test, docs: :docs],
      source_url: @source_url,
      start_permanent: Mix.env() == :prod,
      version: "0.1.0-preview"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Playwright, []},
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
      {:cowlib, "~> 2.11.0"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:gun, "~> 2.0.0-rc.2"},
      {:jason, "~> 1.2"},
      {:json_diff, "~> 0.1.3"},
      {:mix_audit, "~> 0.1", only: [:dev, :test], runtime: false},
      {:plug, "~> 1.11.1", only: [:dev, :test]},
      {:recase, "~> 0.7.0"},
      {:plug_cowboy, "~> 2.5.0", only: [:dev, :test]}
    ]
  end

  defp docs do
    [
      name: "Playwright",
      source_url: @source_url,
      homepage_url: @source_url,
      main: "Playwright",
      groups_for_modules: [
        "Features (usage)": [
          Playwright.Browser,
          Playwright.BrowserContext,
          Playwright.BrowserType,
          Playwright.ElementHandle,
          Playwright.Page,
          Playwright.Playwright,
          Playwright.RemoteBrowser
        ],
        "Helpers (usage)": [
          PlaywrightTest.Case
        ],
        "Runner (internal)": [
          Playwright.Runner.Config,
          Playwright.Runner.Config.Types,
          Playwright.Runner.Channel.Command,
          Playwright.Runner.Transport.Driver,
          Playwright.Runner.Transport.DriverMessage,
          Playwright.Runner.Transport.WebSocket
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
      }
    ]
  end
end
