defmodule Playwright do
  alias Playwright.Client.BrowserType

  # __DEBUG__ (playground)
  # ---------------------------------------------------------------------------

  def start() do
    {:ok, _bt} = BrowserType.start_link([])
  end

  def connect() do
    {connection, browser} = BrowserType.connect("ws://localhost:3000/playwright")
    {connection, browser}
  end

  def newContex(browser) do
    Playwright.ChannelOwner.BrowserType.new_context(browser)
  end

  def newPage(context) do
    Playwright.ChannelOwner.BrowserContext.new_page(context)
  end

  def show(conn) do
    GenServer.call(conn, :show)
  end
end
