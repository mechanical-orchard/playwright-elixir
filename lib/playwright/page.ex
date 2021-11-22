# A thought:
# Would it be useful to have "getter" functions that match the fields in these
# `ChannelOwner` implementations, and pull from the `Catatlog`?
defmodule Playwright.Page do
  @moduledoc """
  ...
  """
  use Playwright.ChannelOwner,
    fields: [:is_closed, :main_frame, :owned_context, :viewport_size]

  alias Playwright.{BrowserContext, Page, Frame}
  alias Playwright.ChannelOwner
  alias Playwright.Runner.Helpers

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

  defdelegate expect_event(owner, event, trigger),
    to: Playwright.BrowserContext

  defdelegate click(page, selector, options \\ %{}),
    to: Playwright.Frame

  defdelegate evaluate(page, expression, arg \\ nil),
    to: Playwright.Frame

  defdelegate evaluate_handle(page, expression, arg \\ nil),
    to: Playwright.Frame

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

  defdelegate url(page),
    to: Playwright.Frame

  defdelegate wait_for_selector(page, selector, options),
    to: Playwright.Frame

  # API
  # ---------------------------------------------------------------------------

  @spec close(struct()) :: :ok
  def close(%Page{} = owner) do
    Channel.post(owner, :close)

    # NOTE: this *might* prefer to be done on `__dispose__`
    # ...OR, `.on(_, "close", _)`
    if owner.owned_context do
      context(owner) |> BrowserContext.close()
    end

    :ok
  end

  @doc false
  def close({:ok, owner}) do
    close(owner)
  end

  @spec context(struct()) :: {:ok, BrowserContext.t()}
  def context(%Page{} = owner) do
    Channel.find(owner, owner.parent)
  end

  @spec eval_on_selector(Page.t(), binary(), binary(), term(), map()) :: term()
  def eval_on_selector(owner, selector, expression, arg \\ nil, options \\ %{})

  def eval_on_selector(%Page{} = owner, selector, expression, arg, options) do
    main_frame(owner)
    |> Frame.eval_on_selector(selector, expression, arg, options)
  end

  @doc false
  def eval_on_selector({:ok, owner}, selector, expression, arg, options) do
    eval_on_selector(owner, selector, expression, arg, options)
  end

  # NOTE: the event/method will be recv'd from Playwright server with
  # the parent BrowserContext as the context/bound :guid. So, we need to
  # add our handlers there, on that (BrowserContext) parent.
  def on(%Page{} = owner, event, callback)
      when event in [:request, :response, :request_finished, "request", "response", "requestFinished"] do
    {:ok, ctx} = context(owner)
    Channel.bind(ctx, event, callback)
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

    handler = fn %{params: %{request: request, route: route}} ->
      if Helpers.URLMatcher.matches(matcher, request.url) do
        Task.start_link(fn ->
          callback.(route, request)
        end)
      end
    end

    if Enum.empty?(owner.listeners["route"] || []) do
      Channel.post(owner, :set_network_interception_enabled, %{enabled: true})
    end

    Channel.bind(owner, :route, handler)
  end

  @doc false
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

  @doc false
  def screenshot({:ok, owner}, options) do
    screenshot(owner, options)
  end

  @spec wait_for_load_state(Page.t(), binary(), options()) :: {:ok, Page.t()}
  def wait_for_load_state(owner, state \\ "load", options \\ %{})

  def wait_for_load_state(%Page{} = owner, state, _options)
      when is_binary(state)
      when state in ["load", "domcontentloaded", "networkidle", "commit"] do
    Logger.warn("Page.wait_for_load_state")

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

  defp main_frame(owner) do
    {:ok, frame} = Channel.find(owner, owner.main_frame)
    frame
  end
end
