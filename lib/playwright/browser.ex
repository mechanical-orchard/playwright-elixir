defmodule Playwright.Browser do
  @moduledoc """
  `Playwright.Browser` represents a launched web browser instance managed by
  Playwright.

  A `Playwright.Browser` is created via:

  - `Playwright.BrowserType.launch/0`, when using the "driver" transport.
  - `Playwright.BrowserType.connect/1`, when using the "websocket" transport.
  """
  use Playwright.Runner.ChannelOwner, [:name, :version]
  alias Playwright.Runner.Channel
  alias Playwright.Runner.Connection

  @doc false
  def new(parent, %{initializer: %{version: version} = initializer} = args) do
    args = %{args | initializer: Map.put(initializer, :version, cut_version(version))}
    channel_owner(parent, args)
  end

  @doc false
  def contexts(subject) do
    Connection.find(subject.connection, %{
      parent: subject,
      type: "BrowserContext"
    })
  end

  @doc """
  Create a new BrowserContext for this Browser. A BrowserContext is somewhat
  equivalent to an "incognito" browser "window".
  """
  def new_context(%Playwright.Browser{} = subject) do
    context =
      Channel.send(subject, "newContext", %{
        noDefaultViewport: false,
        sdkLanguage: "elixir"
      })

    case context do
      %Playwright.BrowserContext{} ->
        Connection.patch(context.connection, {:guid, context.guid}, %{browser: subject})

      _other ->
        raise("expected new_context to return a  Playwright.BrowserContext, received: #{inspect(context)}")
    end
  end

  @doc """
  Create a new Page for this Browser. A Page is somewhat equivalent to a "tab"
  in a browser "window".

  Note that `Playwright.Browser.new_page/1` will also create a new
  `Playwright.BrowserContext`. That `BrowserContext` becomes, both, the
  *parent* the `Page`, and *owned by* the `Page`. When the `Page` closes,
  the context goes with it.
  """
  @spec new_page(Playwright.Browser.t()) :: Playwright.Page.t()
  def new_page(subject) do
    context = new_context(subject)
    page = Playwright.BrowserContext.new_page(context, %{owned_context: context})

    Connection.patch(context.connection, {:guid, context.guid}, %{owner_page: page})

    case page do
      %Playwright.Page{} -> page
      _other -> raise("expected new_page to return a  Playwright.Page, received: #{inspect(page)}")
    end
  end

  # private
  # ----------------------------------------------------------------------------

  # Chromium version is \d+.\d+.\d+.\d+, but that doesn't parse well with
  # `Version`. So, until it causes issue we're cutting it down to
  # <major.minor.patch>.
  defp cut_version(version) do
    version |> String.split(".") |> Enum.take(3) |> Enum.join(".")
  end
end
