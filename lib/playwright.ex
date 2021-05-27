defmodule Playwright do
  alias Playwright.Client.BrowserType

  # __DEBUG__ (playground)
  # ---------------------------------------------------------------------------

  def start() do
    {:ok, _} = BrowserType.start_link([])
  end

  def launch() do
    {connection, browser} = BrowserType.launch("assets/node_modules/playwright/lib/cli/cli.js")
    {connection, browser}
  end

  def connect(ws_endpoint) do
    {connection, browser} = BrowserType.connect(ws_endpoint)
    {connection, browser}
  end
end
