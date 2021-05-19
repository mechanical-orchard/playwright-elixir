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

  def browser() do
    {_, browser} = connect()
    browser
  end

  def context(browser) do
    Playwright.ChannelOwner.BrowserType.new_context(browser)
  end

  def page(context) do
    Playwright.ChannelOwner.BrowserContext.new_page(context)
  end

  def goto(page, url) do
    Playwright.ChannelOwner.Page.goto(page, url)
  end

  def text_content(_page, _selector) do
    ""
  end

  def show(conn) do
    GenServer.call(conn, :show)
  end
end
