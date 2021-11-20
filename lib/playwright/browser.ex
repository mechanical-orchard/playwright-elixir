defmodule Playwright.Browser do
  @moduledoc """
  `Playwright.Browser` represents a launched web browser instance managed by
  Playwright.

  A `Playwright.Browser` is created via:

  - `Playwright.BrowserType.launch/0`, when using the "driver" transport.
  - `Playwright.BrowserType.connect/1`, when using the "websocket" transport.
  """
  use Playwright.ChannelOwner, fields: [:name, :version]
  alias Playwright.{Browser, BrowserContext, ChannelOwner, Extra, Page}
  alias Playwright.Runner.Channel

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(owner, _initializer) do
    # Channel.bind(owner, :close, fn event ->
    #   {:patch, }
    # end)

    {:ok, %{owner | version: cut_version(owner.version)}}
  end

  @doc false
  def contexts(subject) do
    Channel.all(subject.connection, %{
      parent: subject,
      type: "BrowserContext"
    })
  end

  require Logger

  @doc """
  Create a new BrowserContext for this Browser. A BrowserContext is somewhat
  equivalent to an "incognito" browser "window".
  """
  def new_context(%Browser{} = owner, options \\ %{}) do
    params = Map.merge(%{no_default_viewport: false, sdk_language: "elixir"}, options)
    Channel.post(owner, :new_context, prepare(params))
  end

  @doc """
  Create a new Page for this Browser. A Page is somewhat equivalent to a "tab"
  in a browser "window".

  Note that `Playwright.Browser.new_page/1` will also create a new
  `Playwright.BrowserContext`. That `BrowserContext` becomes, both, the
  *parent* the `Page`, and *owned by* the `Page`. When the `Page` closes,
  the context goes with it.
  """
  @spec new_page(Browser.t()) :: {:ok, Page.t()}
  def new_page(%Browser{connection: connection} = subject) do
    {:ok, context} = new_context(subject)
    {:ok, page} = BrowserContext.new_page(context)

    {:ok, _} = Channel.patch(connection, context.guid, %{owner_page: page})
    {:ok, _} = Channel.patch(connection, page.guid, %{owned_context: context})
  end

  # private
  # ----------------------------------------------------------------------------

  # Chromium version is \d+.\d+.\d+.\d+, but that doesn't parse well with
  # `Version`. So, until it causes issue we're cutting it down to
  # <major.minor.patch>.
  defp cut_version(version) do
    version |> String.split(".") |> Enum.take(3) |> Enum.join(".")
  end

  defp prepare(%{extra_http_headers: headers}) do
    %{
      extraHTTPHeaders:
        Enum.reduce(headers, [], fn {k, v}, acc ->
          [%{name: k, value: v} | acc]
        end)
    }
  end

  defp prepare(opts) when is_map(opts) do
    Enum.reduce(opts, %{}, fn {k, v}, acc -> Map.put(acc, prepare(k), v) end)
  end

  defp prepare(atom) when is_atom(atom) do
    Extra.Atom.to_string(atom)
    |> Recase.to_camel()
    |> Extra.Atom.from_string()
  end
end
