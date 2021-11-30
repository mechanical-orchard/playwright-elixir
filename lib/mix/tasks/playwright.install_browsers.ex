defmodule Mix.Tasks.Playwright.InstallBrowsers do
  @moduledoc """
  Installs playwright browsers.

  ```bash
  $ mix playwright.install_browsers
  ```
  """

  @shortdoc "Installs playwright browsers in OS specific locations"
  use Mix.Task

  @impl true
  def run(_args) do
    Playwright.CLI.install_browsers()
  end
end
