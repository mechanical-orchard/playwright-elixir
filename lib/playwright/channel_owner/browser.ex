defmodule Playwright.ChannelOwner.Browser do
  use Playwright.ChannelOwner

  # API
  # ---------------------------------------------------------------------------

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def new_context(channel_owner) do
    Channel.send(channel_owner, "newContext")
  end

  def new_page(channel_owner) do
    new_context(channel_owner) |> BrowserContext.new_page()
  end
end
