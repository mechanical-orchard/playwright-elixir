defmodule Playwright.CLI do
  @moduledoc """
  A wrapper to the Playwright Javascript CLI
  """

  require Logger

  def install_browsers do
    Logger.info("Installing playwright browsers")
    cli_path = Application.get_env(:playwright, LaunchOptions)[:playwright_cli_path]
    {result, exit_status} = System.cmd(cli_path, ["install"])
    Logger.info(result)
    if exit_status != 0, do: raise("Failed to install playwright browsers")
  end
end
