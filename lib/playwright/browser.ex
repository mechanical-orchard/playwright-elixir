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
  use Playwright.ChannelOwner
  alias Playwright.{Browser, BrowserContext, ChannelOwner, Extra, Page}
  alias Playwright.Runner.Channel

  @property :name
  @property(:version, %{doc: "Returns the browser version"})

  @typedoc "Supported events"
  @type event :: :disconnected

  @typedoc "A map/struct providing call options"
  @type options :: map()

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(browser, _initializer) do
    # Channel.bind(browser, :close, fn event ->
    #   {:patch, }
    # end)

    {:ok, %{browser | version: cut_version(browser.version)}}
  end

  # API
  # ---------------------------------------------------------------------------

  # ---

  # test_launcher.py
  # @spec close(t()) :: :ok
  # def close(browser)

  # ---

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
  @spec contexts(t()) :: {:ok, [BrowserContext.t()]}
  def contexts(%Browser{} = browser) do
    result =
      Channel.all(browser.connection, %{
        parent: browser,
        type: "BrowserContext"
      })

    {:ok, result}
  end

  # ---

  # @spec is_connected(BrowserContext.t()) :: boolean()
  # def is_connected(browser)

  # @spec new_browser_cdp_session(BrowserContext.t()) :: {:ok, Playwright.CDPSession.t()}
  # def new_browser_cdp_session(browser)

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
  @spec new_context(t(), options()) :: BrowserContext.t()
  def new_context(%Browser{} = browser, options \\ %{}) do
    Channel.post!(browser, :new_context, prepare(options))
  end

  @doc """
  Create a new `Playwright.Page` for this Browser, within a new "owned"
  `Playwright.BrowserContext`.

  That is, `Playwright.Browser.new_page/2` will also create a new
  `Playwright.BrowserContext`. That `BrowserContext` becomes, both, the
  *parent* of the `Page`, and *owned by* the `Page`. When the `Page` closes,
  the context goes with it.

  This is a convenience API function that should only be used for single-page
  scenarios and short snippets. Production code and testing frameworks should
  explicitly create via `Playwright.Browser.new_context/2` followed by
  `Playwright.BrowserContext.new_page/2`, given the new context, to manage
  resource lifecycles.
  """
  @spec new_page(t(), options()) :: Page.t()
  def new_page(browser, options \\ %{})

  def new_page(%Browser{connection: connection} = browser, options) do
    context = new_context(browser, options)
    page = BrowserContext.new_page(context)

    # establish co-dependency
    Channel.patch(connection, context.guid, %{owner_page: page})
    Channel.patch(connection, page.guid, %{owned_context: context})
  end

  # ---

  # test_browsertype_connect.py
  # @spec on(t(), event(), function()) :: {:ok, Browser.t()}
  # def on(browser, event, callback)

  # test_chromium_tracing.py
  # @spec start_tracing(t(), Page.t(), options()) :: :ok
  # def start_tracing(browser, page \\ nil, options \\ %{})

  # test_chromium_tracing.py
  # @spec stop_tracing(t()) :: {:ok, binary()}
  # def stop_tracing(browser)

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
