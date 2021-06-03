defmodule Playwright.MixProject do
  use Mix.Project

  def project do
    [
      app: :playwright,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Playwright.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.2"},
      {:plug, "~> 1.11.1", only: [:dev, :test]},
      {:plug_cowboy, "~> 2.5.0", only: [:dev, :test]},
      {:websockex, "~> 0.4.3"}
    ]
  end
end
