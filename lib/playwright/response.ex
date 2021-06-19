defmodule Playwright.Response do
  @moduledoc false
  use Playwright.Runner.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end
end
