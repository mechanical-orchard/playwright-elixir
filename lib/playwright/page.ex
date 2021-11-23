defmodule Playwright.Page do
  @moduledoc """
  `Page` provides methods to interact with a single tab in a
  `Playwright.Browser`, or an [extension background page](https://developer.chrome.com/extensions/background_pages)
  in Chromium.

  One `Playwright.Browser` instance might have multiple `Page` instances.

  ## Example

  Create a page, navigate it to a URL, and save a screenshot:

      {:ok, page} = Browser.new_page(browser)
      {:ok, resp} = Page.goto(page, "https://example.com")

      {:ok _} = Page.screenshot(page, %{path: "screenshot.png"})

      :ok = Page.close(page)

  The Page module is capable of hanlding various emitted events (described below).

  ## Example

  Log a message for a single page load event (WIP: `once` is not yet implemented):

      Page.once(page, :load, fn e ->
        IO.puts("page loaded!")
      end)

  Unsubscribe from events with the `remove_lstener` function (WIP: `remove_listener` is not yet implemented):

      def log_request(request) do
        IO.inspect(label: "A request was made")
      end

      Page.on(page, :request, fn e ->
        log_request(e.pages.request)
      end)

      Page.remove_listener(page, log_request)
  """
  use Playwright.ChannelOwner

  alias Playwright.{BrowserContext, Frame, Page}
  alias Playwright.ChannelOwner
  alias Playwright.Runner.Helpers

  @property :is_closed
  @property :main_frame
  @property :owned_context

  @type function_or_options :: fun() | options() | nil
  @type options :: map()

  require Logger

  # callbacks
  # ---------------------------------------------------------------------------

  @impl ChannelOwner
  def init(owner, _intializer) do
    Channel.bind(owner, :close, fn event ->
      {:patch, %{event.target | is_closed: true}}
    end)

    {:ok, owner}
  end

  # delegates
  # ---------------------------------------------------------------------------

  defdelegate click(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate evaluate(page, expression, arg \\ nil),
    to: Playwright.Frame

  defdelegate evaluate_handle(page, expression, arg \\ nil),
    to: Playwright.Frame

  defdelegate expect_event(owner, event, trigger),
    to: Playwright.BrowserContext

  defdelegate fill(page, selector, value),
    to: Playwright.Frame

  defdelegate get_attribute(page, selector, name, options \\ %{}),
    to: Playwright.Frame

  defdelegate goto(page, url, params \\ %{}),
    to: Playwright.Frame

  defdelegate press(page, selector, key, options \\ %{}),
    to: Playwright.Frame

  defdelegate q(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate q!(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate query_selector(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate query_selector!(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate qq(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate query_selector_all(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate set_content(page, html, options \\ %{}),
    to: Playwright.Frame

  defdelegate text_content(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate title(page),
    to: Playwright.Frame

  defdelegate wait_for_selector(page, selector, options),
    to: Playwright.Frame

  # API
  # ---------------------------------------------------------------------------

  # ---

  # @spec add_init_script(Page.t(), binary(), options()) :: :ok
  # def add_init_script(owner, script, options \\ %{})

  # @spec add_script_tag(Page.t(), options()) :: {:ok, ElementHandle.t()}
  # def add_script_tag(owner, options \\ %{})

  # @spec add_style_tag(Page.t(), options()) :: {:ok, ElementHandle.t()}
  # def add_style_tag(owner, options \\ %{})

  # @spec bring_to_front(Page.t()) :: :ok
  # def bring_to_front(owner)

  # @spec check(Page.t(), binary(), options()) :: :ok
  # def check(owner, selector, options \\ %{})

  # ---

  @doc """
  Closes the `Page`.

  If the `Page` has an "owned context" (1-to-1 co-dependency with a
  `Playwright.BrowserContext`), that context is closed as well.

  If `option: run_before_unload` is false, does not run any unload handlers and
  waits for the page to be closed. If `option: run_before_unload` is `true`
  the function will run unload handlers, but will not wait for the page to
  close. By default, `Playwright.Page.close/1` does not run `:beforeunload`
  handlers.

  ## Returns

    - `:ok`

  ## Arguments

  | key / name          | type   |             | description |
  | ------------------- | ------ | ----------- | ----------- |
  | `run_before_unload` | option | `boolean()` | Whether to run the before unload page handlers. `(default: false)` |

  ## NOTE

  > if `option: run_before_unload` is passed as `true`, a `:beforeunload`
  > dialog might be summoned and should be handled manually via
  > `Playwright.Page.on/3`.
  """
  @spec close(t() | {:ok, t()}, options()) :: :ok
  def close(owner, options \\ %{})

  def close(%Page{} = owner, options) do
    Channel.post(owner, :close, options)

    # NOTE: this *might* prefer to be done on `__dispose__`
    # ...OR, `.on(_, "close", _)`
    if owner.owned_context do
      context(owner) |> BrowserContext.close()
    end

    :ok
  end

  def close({:ok, owner}, options) do
    close(owner, options)
  end

  @doc """
  Get the full HTML contents of the page, including the doctype.
  """
  @spec content(t() | {:ok, t()}) :: {:ok, binary()}
  def content(owner)

  def content(%Page{} = owner) do
    Channel.post(owner, :content)
  end

  def content({:ok, owner}) do
    content(owner)
  end

  @doc """
  Get the `Playwright.BrowserContext` that the page belongs to.
  """
  @spec context(t() | {:ok, t()}) :: BrowserContext.t()
  def context(owner)

  def context(%Page{} = owner) do
    {:ok, ctx} = Channel.find(owner, owner.parent)
    ctx
  end

  def context({:ok, owner}) do
    context(owner)
  end

  # ---

  # @spec add_init_script(Page.t(), binary(), options()) :: :ok
  # def add_init_script(owner, script, options \\ %{})

  # ---

  @spec eval_on_selector(Page.t(), binary(), binary(), term(), map()) :: term()
  def eval_on_selector(owner, selector, expression, arg \\ nil, options \\ %{})

  def eval_on_selector(%Page{} = owner, selector, expression, arg, options) do
    main_frame(owner)
    |> Frame.eval_on_selector(selector, expression, arg, options)
  end

  def eval_on_selector({:ok, owner}, selector, expression, arg, options) do
    eval_on_selector(owner, selector, expression, arg, options)
  end

  # NOTE: these events will be recv'd from Playwright server with
  # the parent BrowserContext as the context/bound :guid. So, we need to
  # add our handlers there, on that (BrowserContext) parent.
  def on(%Page{} = owner, event, callback)
      when event in [:request, :response, :request_finished, "request", "response", "requestFinished"] do
    context(owner) |> Channel.bind(event, callback)
  end

  def on(%Page{} = owner, event, callback) do
    Channel.bind(owner, event, callback)
  end

  def on({:ok, owner}, event, callback) do
    on(owner, event, callback)
  end

  @spec route(Page.t(), binary(), function(), map()) :: {atom(), Page.t()}
  def route(owner, pattern, callback, options \\ %{})

  def route(%Page{} = owner, pattern, callback, _options) do
    matcher = Helpers.URLMatcher.new(pattern)

    if Enum.empty?(owner.listeners["route"] || []) do
      Channel.post(owner, :set_network_interception_enabled, %{enabled: true})
    end

    Channel.bind(owner, :route, &Page.exec_callback_on_route(&1, matcher, callback))
  end

  def route({:ok, owner}, pattern, callback, options) do
    route(owner, pattern, callback, options)
  end

  @spec screenshot(Page.t(), map()) :: {:ok, binary()}
  def screenshot(owner, options \\ %{})

  def screenshot(%Page{} = owner, options) do
    case Map.pop(options, :path) do
      {nil, params} ->
        Channel.post(owner, :screenshot, params)

      {path, params} ->
        [_, filetype] = String.split(path, ".")

        {:ok, data} = Channel.post(owner, :screenshot, Map.put(params, :type, filetype))
        File.write!(path, Base.decode64!(data))
        {:ok, data}
    end
  end

  def screenshot({:ok, owner}, options) do
    screenshot(owner, options)
  end

  def url(page) do
    main_frame(page) |> Frame.url()
  end

  @spec wait_for_load_state(Page.t(), binary(), options()) :: {:ok, Page.t()}
  def wait_for_load_state(owner, state \\ "load", options \\ %{})

  def wait_for_load_state(%Page{} = owner, state, _options)
      when is_binary(state)
      when state in ["load", "domcontentloaded", "networkidle", "commit"] do
    Logger.warn("Page.wait_for_load_state (not fully implemented)")

    {:ok, _} =
      main_frame(owner)
      |> Frame.wait_for_load_state(state)

    {:ok, owner}
  end

  def wait_for_load_state(%Page{} = owner, state, options) when is_binary(state) do
    wait_for_load_state(owner, state, options)
  end

  def wait_for_load_state(%Page{} = owner, options, _) when is_map(options) do
    wait_for_load_state(owner, "load", options)
  end

  # private
  # ---------------------------------------------------------------------------

  @doc false
  def exec_callback_on_route(%{params: %{request: request, route: route}}, matcher, callback) do
    if Helpers.URLMatcher.matches(matcher, request.url) do
      Task.start_link(fn ->
        callback.(route, request)
      end)
    end
  end
end
