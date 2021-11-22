defmodule Playwright.Browser do
  @moduledoc """
  A `Playwright.Browser` instance is createed via:

    - `Playwright.BrowserType.launch/0`, when using the "driver" transport.
    - `Playwright.BrowserType.connect/1`, when using the "websocket" transport.

  An example of using a `Playwright.Browser` to create a `Playwright.Page`:

      alias Playwright.{Browser, Page}

      {:ok, browser} = Playwright.launch(:chromium)
      {:ok, page} = Browser.new_page(browser)

      Page.goto(page, "https://example.com")
      Browser.close(browser)

  ## Properties

    - `:name`
    - `:version`
  """
  use Playwright.ChannelOwner,
    fields: [:name, :version]
  alias Playwright.{Browser, BrowserContext, ChannelOwner, Extra, Page}
  alias Playwright.Runner.Channel

  @typedoc "Supported events"
  @type event :: :disconnected

  @typedoc "A map/struct providing call options"
  @type options :: map()

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(owner, _initializer) do
    # Channel.bind(owner, :close, fn event ->
    #   {:patch, }
    # end)

    {:ok, %{owner | version: cut_version(owner.version)}}
  end

  # API
  # ---------------------------------------------------------------------------

  # @spec close(Browser.t()) :: :ok
  # def close(owner)

  @doc """
  Returns an array of all open browser contexts. In a newly created browser,
  this will return zero browser contexts.

  ## Example

      {:ok, contexts} = Browser.contexts(browser)
      asset Enum.empty?(contexts)

      Browser.new_context(browser)

      {:ok, contexts} = Browser.contexts(browser)
      assert length(contexts) == 1
  """
  @spec contexts(Browser.t()) :: {:ok, [BrowserContext.t()]}
  def contexts(%Browser{} = owner) do
    result = Channel.all(owner.connection, %{
      parent: owner,
      type: "BrowserContext"
    })
    {:ok, result}
  end

  # ---

  # @spec is_connected(BrowserContext.t()) :: boolean()
  # def is_connected(owner)

  # @spec new_browser_cdp_session(BrowserContext.t()) :: {:ok, Playwright.CDPSession.t()}
  # def new_browser_cdp_session(owner)

  # ---

  @doc """
  Create a new `Playwright.BrowserContext` for this `Playwright.Browser`.

  A `BrowserContext` does not share cookies/cache with other `BrowserContexts`
  and is somewhat equivalent to an "incognito" browser "window".

  ## Example

      # create a new "incognito" browser context.
      {:ok, context} = Browser.new_context(browser)

      # create a new page in a pristine context.
      {:ok, page} = BrowserContext.new_page(context)

      Page.goto(page, "https://example.com")

  ## Returns

    - `{:ok, Playwright.BrowserContext.t()}`

  ## Arguments

  | key / name         | type   |             | description |
  | ------------------ | ------ | ----------- | ----------- |
  | `accept_downloads` | option | `boolean()` | Whether to automatically download all the attachments. If false, all the downloads are canceled. `(default: false)` |
  | `...`              | option | `...`       | ... |
  """
  @spec new_context(Browser.t(), options()) :: {:ok, BrowserContext.t()}
  def new_context(%Browser{} = owner, options \\ %{}) do
    Channel.post(owner, :new_context, prepare(options))
  end

  @doc """
  Create a new `Playwright.Page` for this Browser, within a new "owned"
  `Playwright.BrowserContext`.

  Closing this page will close the context as well.

  This is a convenience API function that should only be used for single-page
  scenarios and short snippets. Production code and testing frameworks should
  explicitly create via `Playwright.Browser.new_context/2` followed by
  `Playwright.BrowserContext.new_page/2`, given the new context, to manage
  resource lifecycles.
  """
  @spec new_page(Browser.t()) :: {:ok, Page.t()}
  def new_page(%Browser{connection: connection} = owner) do
    {:ok, context} = new_context(owner)
    {:ok, page} = BrowserContext.new_page(context)

    # establish co-dependency
    {:ok, _} = Channel.patch(connection, context.guid, %{owner_page: page})
    {:ok, _} = Channel.patch(connection, page.guid, %{owned_context: context})
  end

  # ---

  # @spec on(Browser.t(), event(), function()) :: {:ok, Browser.t()}
  # def on(owner, event, callback)

  # @spec start_tracing(Browser.t(), Page.t(), options()) :: :ok
  # def start_tracing(owner, page \\ nil, options \\ %{})

  # @spec stop_tracing(Browser.t()) :: {:ok, binary()}
  # def stop_tracing(owner)

  # ---

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
