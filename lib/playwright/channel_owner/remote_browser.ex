defmodule Playwright.ChannelOwner.RemoteBrowser do
  use Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end
end
