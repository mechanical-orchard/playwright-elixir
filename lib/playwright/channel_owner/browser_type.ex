defmodule Playwright.ChannelOwner.BrowserType do
  use Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def launch(channel_owner) do
    Channel.send(channel_owner, "launch", %{ignoreAllDefaultArgs: false, headless: false})
  end

  # WARN! Likely broken at the moment. Use `Browser.new_page` instead.
  def new_context(channel_owner) do
    Channel.send(channel_owner, "newContext", %{ignoreAllDefaultArgs: false, headless: false})
  end
end
