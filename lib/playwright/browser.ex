defmodule Playwright.Browser do
  @moduledoc false
  use Playwright.Client.ChannelOwner
  alias Playwright

  # API
  # ---------------------------------------------------------------------------

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def new_context(%Playwright.Browser{} = channel_owner) do
    context =
      Playwright.Client.Channel.send(channel_owner, "newContext", %{noDefaultViewport: false, sdkLanguage: "elixir"})

    case context do
      %Playwright.BrowserContext{} ->
        context

      _other ->
        raise("expected new_context to return a  Playwright.BrowserContext, received: #{inspect(context)}")
    end
  end

  @spec new_page(Playwright.Browser.t()) :: Playwright.Page.t()
  def new_page(channel_owner) do
    context = new_context(channel_owner)
    page = Playwright.BrowserContext.new_page(context, %{owned_context: context})

    case page do
      %Playwright.Page{} -> page
      _other -> raise("expected new_page to return a  Playwright.Page, received: #{inspect(page)}")
    end
  end

  def contexts(channel_owner) do
    Playwright.Client.Connection.find(channel_owner.connection, %{
      parent: channel_owner,
      type: "BrowserContext"
    })
  end
end
