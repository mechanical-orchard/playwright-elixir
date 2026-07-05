defmodule Playwright.Browser do
  @moduledoc """
  A `Playwright.Browser` instance is created via:

    - `Playwright.BrowserType.launch/0`, when using the "driver" transport.
    - `Playwright.BrowserType.connect/1`, when using the "websocket" transport.

  An example of using a `Playwright.Browser` to create a `Playwright.Page`:

      alias Playwright.{Browser, Page}

      {:ok, browser} = Playwright.launch(:chromium)
      page = Browser.new_page(browser)

      Page.goto(page, "https://example.com")
      Browser.close(browser)

  ## Properties

    - `:name`
    - `:version`
  """
  use Playwright.SDK.ChannelOwner
  alias Playwright.{Browser, BrowserContext, BrowserType, CDPSession, Page}
  alias Playwright.SDK.{Channel, ChannelOwner, Extra}

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
  Returns the BrowserType that was used to launch this browser.

  ## Returns

  - `BrowserType.t()`
  """
  @spec browser_type(t()) :: BrowserType.t()
  def browser_type(%Browser{parent: parent}), do: parent

  @doc """
  Returns whether the browser is still connected.

  Returns `false` after the browser has been closed.

  ## Returns

  - `boolean()`
  """
  @spec is_connected(t()) :: boolean()
  def is_connected(%Browser{session: session, guid: guid}) do
    case Channel.find(session, {:guid, guid}, %{timeout: 100}) do
      %Browser{} -> true
      {:error, _} -> false
    end
  end

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
    case Channel.find(session, {:guid, browser.guid}, %{timeout: 10}) do
      %Browser{} ->
        Channel.post(session, {:guid, browser.guid}, :close)
        :ok

      {:error, _} ->
        :ok
    end
  end

  @doc """
  Returns a list of all open browser contexts. In a newly created browser,
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
  `Playwright.BrowserContext.new_page/1`, given the new context, to manage
  resource lifecycles.
  """
  @spec new_page(t(), options()) :: {:ok, Page.t()} | {:error, term()}
  def new_page(browser, options \\ %{})

  def new_page(%Browser{session: session} = browser, options) do
    with context when is_struct(context) <- new_context(browser, options),
         page when is_struct(page) <- BrowserContext.new_page(context) do
      # establish co-dependency
      Channel.patch(session, {:guid, context.guid}, %{owner_page: page})
      Channel.patch(session, {:guid, page.guid}, %{owned_context: context})
      {:ok, page}
    end
  end

  # ---

  @doc """
  Start tracing for Chromium browser.

  Records a trace that can be viewed in Chrome DevTools or Playwright Trace Viewer.

  ## Arguments

  | key/name       | type          | description                              |
  | -------------- | ------------- | ---------------------------------------- |
  | `page`         | `Page.t()`    | Optional page to trace (default: all)    |
  | `:screenshots` | `boolean()`   | Capture screenshots during trace         |
  | `:categories`  | `[binary()]`  | Trace categories to record               |

  ## Returns

  - `:ok`

  ## Example

      Browser.start_tracing(browser)
      # ... perform actions ...
      trace = Browser.stop_tracing(browser)
      File.write!("trace.json", trace)

  ## Note

  Only supported on Chromium browsers.
  """
  @spec start_tracing(t(), Page.t() | nil, options()) :: :ok
  def start_tracing(%Browser{session: session, guid: guid}, page \\ nil, options \\ %{}) do
    params = %{}
    params = if page, do: Map.put(params, :page, %{guid: page.guid}), else: params
    params = if options[:screenshots], do: Map.put(params, :screenshots, options[:screenshots]), else: params
    params = if options[:categories], do: Map.put(params, :categories, options[:categories]), else: params

    Channel.post(session, {:guid, guid}, :start_tracing, params)
    :ok
  end

  @doc """
  Stop tracing and return the trace data.

  Returns the trace data as binary which can be saved to a file.

  ## Returns

  - `binary()` - Trace data (JSON format, save as .json file)

  ## Example

      Browser.start_tracing(browser, page, %{screenshots: true})
      Page.goto(page, "https://example.com")
      trace = Browser.stop_tracing(browser)
      File.write!("trace.json", trace)
  """
  @spec stop_tracing(t()) :: binary()
  def stop_tracing(%Browser{session: session, guid: guid}) do
    artifact =
      case Channel.post(session, {:guid, guid}, :stop_tracing, %{}) do
        %{artifact: %{guid: artifact_guid}} ->
          Channel.find(session, {:guid, artifact_guid})

        %Playwright.Artifact{} = art ->
          art
      end

    # Save to temp file, read contents, then clean up
    temp_path = Path.join(System.tmp_dir!(), "pw_trace_#{:erlang.unique_integer([:positive])}.json")
    Playwright.Artifact.save_as(artifact, temp_path)
    data = File.read!(temp_path)
    File.rm(temp_path)
    Playwright.Artifact.delete(artifact)
    data
  end

  @doc """
  Creates a new CDP session attached to the browser.

  This is Chromium-specific.

  ## Returns

  - `CDPSession.t()`

  ## Example

      session = Browser.new_browser_cdp_session(browser)
      # Use CDP commands...
      CDPSession.detach(session)
  """
  @spec new_browser_cdp_session(t()) :: CDPSession.t()
  def new_browser_cdp_session(%Browser{session: session, guid: guid}) do
    Channel.post(session, {:guid, guid}, "newBrowserCDPSession")
  end

  # @spec version(BrowserContext.t()) :: binary
  # def version(browser)

  # ---

  # events
  # ----------------------------------------------------------------------------

  # test_browsertype_connect.py
  # @spec on(t(), event(), function()) :: Browser.t()
  # def on(browser, event, callback)

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
