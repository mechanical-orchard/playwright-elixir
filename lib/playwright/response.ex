defmodule Playwright.Response do
  @moduledoc false
  use Playwright.Runner.ChannelOwner, fields: [ok: true]

  def new(parent, args) do
    channel_owner(parent, args)
  end
end
