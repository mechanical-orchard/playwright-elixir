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

  def new_context(browser) do
    Playwright.ChannelOwner.BrowserType.new_context(browser)
  end

  def new_page(context) do
    Playwright.ChannelOwner.BrowserContext.new_page(context)
  end

  def show(conn) do
    GenServer.call(conn, :show)
  end
end
