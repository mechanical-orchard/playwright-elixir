defmodule Playwright.ChannelOwner.JSHandle do
  use Playwright.ChannelOwner

  # API
  # ---------------------------------------------------------------------------

  def new(parent, args) do
    channel_owner(parent, args)
  end
end
