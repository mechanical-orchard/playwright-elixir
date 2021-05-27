defmodule Playwright.ChannelOwner.BrowserContext do
  use Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def new_page(channel_owner) do
    Channel.send(channel_owner, "newPage")
  end
end
