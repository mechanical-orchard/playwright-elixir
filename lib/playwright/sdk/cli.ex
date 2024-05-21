defmodule Playwright.SDK.CLI do
  @moduledoc """
  A wrapper to the Playwright Javascript CLI
  """

  require Logger

  def install do
    Logger.info("Installing playwright browsers")
    cli_path = config_cli() || default_cli()
    {result, exit_status} = System.cmd(cli_path, ["install"])
    Logger.info(result)
    if exit_status != 0, do: raise("Failed to install playwright browsers")
  end

  def install_deps do
    Logger.info("Installing playwright deps")
    cli_path = config_cli() || default_cli()
    {result, exit_status} = System.cmd(cli_path, ["install-deps"])
    Logger.info(result)
    if exit_status != 0, do: raise("Failed to install playwright deps")
  end

  # private
  # ----------------------------------------------------------------------------

  defp config_cli do
    Application.get_env(:playwright, LaunchOptions)[:playwright_cli_path]
  end

  defp default_cli do
    Path.join(:code.priv_dir(:playwright), "static/driver.js")
  end
end
