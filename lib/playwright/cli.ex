defmodule Playwright.CLI do
  @moduledoc """
  A wrapper to the Playwright Javascript CLI
  """

  require Logger

  def install_browsers do
    default_cli_path = Path.expand("../../priv/static/playwright_cli.js", __DIR__)
    cli_path = Application.get_env(:playwright, ConnectOptions) |> Keyword.get(:playwright_cli_path, default_cli_path)

    {output_lines, 0} = System.cmd(cli_path, ["install"])

    output_lines
    |> String.split("\n")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&Logger.info(inspect(&1)))
  end
end
