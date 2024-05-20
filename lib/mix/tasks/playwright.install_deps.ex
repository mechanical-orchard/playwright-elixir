defmodule Mix.Tasks.Playwright.InstallDeps do
  @moduledoc """
  Installs playwright deps.

  ```bash
  $ mix playwright.install_deps
  ```
  """

  @shortdoc "Installs playwright deps in OS specific locations"
  use Mix.Task

  @impl true
  def run(_args) do
    Playwright.SDK.CLI.install_deps()
  end
end
