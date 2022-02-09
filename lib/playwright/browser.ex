defmodule Playwright.Browser do
  @moduledoc """
  A `Playwright.Browser` instance is createed via:

    - `Playwright.BrowserType.launch/0`, when using the "driver" transport.
    - `Playwright.BrowserType.connect/1`, when using the "websocket" transport.

  An example of using a `Playwright.Browser` to create a `Playwright.Page`:

      alias Playwright.{Browser, Page}

      browser = Playwright.launch(:chromium)
      page = Browser.new_page(browser)

      Page.goto(page, "https://example.com")
      Browser.close(browser)

  ## Properties

    - `:name`
    - `:version`
  """
  use Playwright.ChannelOwner
  alias Playwright.{Browser, BrowserContext, ChannelOwner, Extra, Page}
  alias Playwright.Channel

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
    {:ok, %{browser | version: cut_version(browser.version)}}
  end

  # API
  # ---------------------------------------------------------------------------

  @doc """
  Closes the browser.

  Given a `Playwright.Browser` obtained from `Playwright.BrowserType.launch/2`,
  closes the `Browser` and all of its `Pages` (if any were opened).

  Given a `Playwright.Browser` obtained via `Playwright.BrowserType.connect/2`,
  clears all created `Contexts` belonging to this `Browser` and disconnects
  from the browser server.

  The Browser object itself is considered to be disposed and cannot be used anymore.

  ## Returns

    - `:ok`

  """
  def close(%Browser{session: session} = browser) do
    case Channel.post(session, {:guid, browser.guid}, :close) do
      :ok ->
        :ok

      {:error, %Channel.Error{message: "Target page, context or browser has been closed"}} ->
        :ok
    end
  end

  @doc """
  Returns an array of all open browser contexts. In a newly created browser,
  this will return zero browser contexts.

  ## Example

      contexts = Browser.contexts(browser)
      asset Enum.empty?(contexts)

      Browser.new_context(browser)

      contexts = Browser.contexts(browser)
      assert length(contexts) == 1
  """
  @spec contexts(t()) :: [BrowserContext.t()]
  def contexts(%Browser{} = browser) do
    Channel.list(browser.session, {:guid, browser.guid}, "BrowserContext")
  end

  # ---

  # @spec is_connected(BrowserContext.t()) :: boolean()
  # def is_connected(browser)

  # @spec new_browser_cdp_session(BrowserContext.t()) :: Playwright.CDPSession.t()
  # def new_browser_cdp_session(browser)

  # ---

  @doc """
  Create a new `Playwright.BrowserContext` for this `Playwright.Browser`.

  A `BrowserContext` does not share cookies/cache with other `BrowserContexts`
  and is somewhat equivalent to an "incognito" browser "window".

  ## Example

      # create a new "incognito" browser context.
      context = Browser.new_context(browser)

      # create a new page in a pristine context.
      page = BrowserContext.new_page(context)

      Page.goto(page, "https://example.com")

  ## Returns

    - `Playwright.BrowserContext.t()`

  ## Arguments

  | key/name         | type   |             | description |
  | ------------------ | ------ | ----------- | ----------- |
  | `accept_downloads` | option | `boolean()` | Whether to automatically download all the attachments. If false, all the downloads are canceled. `(default: false)` |
  | `...`              | option | `...`       | ... |
  """
  @spec new_context(t(), options()) :: BrowserContext.t()
  def new_context(%Browser{guid: guid} = browser, options \\ %{}) do
    Channel.post(browser.session, {:guid, guid}, :new_context, prepare(options))
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

  def new_page(%Browser{session: session} = browser, options) do
    context = new_context(browser, options)
    page = BrowserContext.new_page(context)

    # establish co-dependency
    Channel.patch(session, {:guid, context.guid}, %{owner_page: page})
    Channel.patch(session, {:guid, page.guid}, %{owned_context: context})
  end

  # ---

  # test_browsertype_connect.py
  # @spec on(t(), event(), function()) :: Browser.t()
  # def on(browser, event, callback)

  # test_chromium_tracing.py
  # @spec start_tracing(t(), Page.t(), options()) :: :ok
  # def start_tracing(browser, page \\ nil, options \\ %{})

  # test_chromium_tracing.py
  # @spec stop_tracing(t()) :: binary()
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

  defp prepare(string) when is_binary(string) do
    string
  end

  defp prepare(atom) when is_atom(atom) do
    Extra.Atom.to_string(atom)
    |> Recase.to_camel()
    |> Extra.Atom.from_string()
  end
end
