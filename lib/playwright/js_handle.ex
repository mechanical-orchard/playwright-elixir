defmodule Playwright.JSHandle do
  @moduledoc false
  use Playwright.Client.ChannelOwner

  # API
  # ---------------------------------------------------------------------------

  def new(parent, args) do
    channel_owner(parent, args)
  end
end
