defmodule Playwright.ChannelOwner.BrowserType do
  use Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def launch(channel_owner) do
    Channel.send(channel_owner, "launch", %{ignoreAllDefaultArgs: false})
  end
end
