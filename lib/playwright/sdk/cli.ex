defmodule Playwright.SDK.CLI do
  @moduledoc """
  A wrapper to the Playwright Javascript CLI
  """

  require Logger

  def install do
    Logger.info("Installing playwright browsers and dependencies")
    cli_path = config_cli() || default_cli()
    {result, exit_status} = System.cmd(cli_path, ["install", "--with-deps"])
    Logger.info(result)
    if exit_status != 0, do: raise("Failed to install playwright browsers")
  end

  # private
  # ----------------------------------------------------------------------------

  defp config_cli do
    Application.get_env(:playwright, LaunchOptions)[:driver_path]
  end

  defp default_cli do
    Path.join(:code.priv_dir(:playwright), "static/driver.js")
  end
end
