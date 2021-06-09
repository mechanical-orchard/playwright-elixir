defmodule Playwright.ChannelOwner.Browser do
  @moduledoc false
  use Playwright.ChannelOwner
  alias Playwright.ChannelOwner

  # API
  # ---------------------------------------------------------------------------

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def new_context(%ChannelOwner.Browser{} = channel_owner) do
    context = Channel.send(channel_owner, "newContext", %{noDefaultViewport: false, sdkLanguage: "elixir"})

    case context do
      %ChannelOwner.BrowserContext{} ->
        context

      _other ->
        raise("expected new_context to return a Playwright.ChannelOwner.BrowserContext, received: #{inspect(context)}")
    end
  end

  @spec new_page(ChannelOwner.Browser.t()) :: ChannelOwner.Page.t()
  def new_page(channel_owner) do
    context = new_context(channel_owner)
    page = BrowserContext.new_page(context, %{owned_context: context})

    case page do
      %ChannelOwner.Page{} -> page
      _other -> raise("expected new_page to return a Playwright.ChannelOwner.Page, received: #{inspect(page)}")
    end
  end

  def contexts(channel_owner) do
    Playwright.Connection.find(channel_owner.connection, %{
      parent: channel_owner,
      type: "BrowserContext"
    })
  end
end
