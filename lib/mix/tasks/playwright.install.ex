defmodule Mix.Tasks.Playwright.Install do
  @moduledoc """
  Installs Playwright browsers.

  ```bash
  $ mix playwright.install
  ```
  """

  @shortdoc "Installs Playwright browsers in OS specific locations"
  use Mix.Task

  @impl true
  def run(_args) do
    Playwright.CLI.install()
  end
end
