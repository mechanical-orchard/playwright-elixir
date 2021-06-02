defmodule Playwright.ChannelOwner.Browser do
  use Playwright.ChannelOwner

  # API
  # ---------------------------------------------------------------------------

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def new_context(channel_owner) do
    Channel.send(channel_owner, "newContext", %{noDefaultViewport: false, sdkLanguage: "elixir"})
  end

  def new_page(channel_owner) do
    new_context(channel_owner) |> BrowserContext.new_page()
  end

  def contexts(channel_owner) do
    Playwright.Connection.find(channel_owner.connection, %{
      parent: channel_owner,
      type: "BrowserContext"
    })
  end
end
