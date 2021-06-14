defmodule Playwright.Electron do
  @moduledoc false
  use Playwright.Client.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end
end
