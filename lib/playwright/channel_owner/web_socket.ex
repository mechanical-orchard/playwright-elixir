defmodule Playwright.ChannelOwner.WebSocket do
  @moduledoc false
  use Playwright.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end
end
