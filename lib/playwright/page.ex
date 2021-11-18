defmodule Playwright.Page do
  @moduledoc """
  `Playwright.Page` represents a web page loaded in the Playwright browser
  server.

  ## Selectors

  Some functions in this module accept selectors:

  - By default, selectors are assumed to be CSS: `a[href="/foo"]`
  - If a selector starts with a single or double quote, it is a text selector:
    `"Login"`
  - If a selector starts with `//`, it is an xpath selector: `//html/body`

  Selector types can be made explicit by prefixing with `css=`, `text=`, or
  `xpath=`: `text="Login"`.

  Playwright supports some useful pseudo-selectors:

  - text: `#nav-bar :text("Contact us")`
  - inclusion: `.item-description:has(.item-promo-banner)`
  - position: `input:right-of(:text("Username"))` (also `left-of`, `above`,
    `below`, `near`)
  - visibility: `.login-button:visible`
  - nth match: `:nth-match(:text("Buy"), 3)`
  - match any of the conditions:
    `:is(button:has-text("Log in"), button:has-text("Sign in"))`

  More info on Playwright selectors is available
  [online](https://playwright.dev/docs/selectors).
  """
  use Playwright.Runner.ChannelOwner,
    fields: [:closed, :frames, :main_frame, :owned_context]

  require Logger

  alias Playwright.BrowserContext
  alias Playwright.ElementHandle
  alias Playwright.Extra
  alias Playwright.Frame
  alias Playwright.Page
  alias Playwright.Runner.Channel
  alias Playwright.Runner.ChannelOwner
  alias Playwright.Runner.EventInfo
  alias Playwright.Runner.Helpers

  @impl ChannelOwner
  def new(%{connection: _connection} = parent, args) do
    Map.merge(init(parent, args), %{closed: args.initializer.isClosed})
  end

  @impl ChannelOwner
  def before_event(subject, %EventInfo{type: :close}) do
    {:ok, Map.put(subject, :closed, true)}
  end

  @impl ChannelOwner
  def before_event(subject, %EventInfo{type: :console}) do
    {:ok, subject}
  end

  # delegated to main frame
  # ---------------------------------------------------------------------------

  def url(subject) do
    Playwright.Frame.url(frame(subject))
  end

  # ----------------------------------------------------------------------------

  def context(subject) do
    Channel.get(subject.connection, {:guid, subject.parent.guid})
  end

  def click(subject, selector) do
    frame(subject)
    |> Channel.send("click", %{selector: selector})

    subject
  end

  def close(subject) do
    subject |> Channel.send("close")

    if subject.owned_context do
      BrowserContext.close(subject.owned_context)
    end

    subject
  end

  def evaluate(subject, expression, arg \\ nil) do
    frame(subject)
    |> Channel.send("evaluateExpression", %{
      expression: expression,
      isFunction: Helpers.Expression.function?(expression),
      arg: serialize(arg)
    })
    |> deserialize()
  end

  def evaluate_handle(subject, expression, arg \\ nil) do
    frame(subject)
    |> Channel.send("evaluateExpressionHandle", %{
      expression: expression,
      isFunction: Helpers.Expression.function?(expression),
      arg: serialize(arg)
    })
  end

  def eval_on_selector(subject, selector, expression, arg \\ nil, _options \\ %{}) do
    frame(subject)
    |> Channel.send("evalOnSelector", %{
      selector: selector,
      expression: expression,
      isFunction: Helpers.Expression.function?(expression),
      arg: serialize(arg)
    })
  end

  def expect_event(subject, event, action) when event in ["requestFinished"] do
    parent = Channel.get(subject.connection, {:guid, subject.parent.guid})
    result = Channel.wait_for(parent, event, action)
    result
  end

  def expect_event(subject, event, action) do
    Channel.wait_for(subject, event, action)
  end

  defdelegate wait_for_event(subject, event, action), to: __MODULE__, as: :expect_event

  def fill(subject, selector, value) do
    frame(subject) |> Channel.send("fill", %{selector: selector, value: value})
    subject
  end

  @spec frame(Page.t()) :: Frame.t()
  def frame(subject) do
    Channel.get(subject.connection, {:guid, subject.initializer.mainFrame.guid})
  end

  def get_attribute(subject, selector, name) do
    subject
    |> Page.query_selector!(selector)
    |> ElementHandle.get_attribute(name)
  end

  def goto(subject, url, params \\ %{}) do
    load_state = Map.get(params, :wait_until, "load")
    timeout = Map.get(params, :timeout, 30_000)
    playwright_params = %{"url" => url, "waitUntil" => load_state, "timeout" => timeout}

    case frame(subject) |> Channel.send("goto", playwright_params) do
      %Channel.Error{} = error ->
        raise RuntimeError, message: error.message

      response ->
        response
    end
  end

  def on(subject, event, handler)
      when event in ["request", "response", "requestFinished"] do
    # NOTE: the event/method will be recv'd from Playwright server with
    # the parent BrowserContext as the context/bound :guid. So, we need to
    # add our handlers there, on that (BrowserContext) parent.
    parent = Channel.get(subject.connection, {:guid, subject.parent.guid})
    Channel.on(subject.connection, {event, parent}, handler)
    subject
  end

  def on(subject, event, handler) do
    Channel.on(subject.connection, {event, subject}, handler)
    subject
  end

  def press(subject, selector, key) do
    frame(subject) |> Channel.send("press", %{selector: selector, key: key})
    subject
  end

  def q(subject, selector), do: query_selector(subject, selector)

  # How about these?
  # def q!(subject, selector), do: query_selector!(subject, selector)
  # def q?(subject, selector), do: query_selector?(subject, selector)

  @spec query_selector(Page.t(), binary()) :: {:ok, ElementHandle.t() | nil} | {:error, :timeout}
  def query_selector(subject, selector) do
    frame(subject)
    |> Channel.send("querySelector", %{selector: selector})
    |> hydrate()
  end

  @spec query_selector!(Page.t(), binary()) :: ElementHandle.t() | no_return()
  def query_selector!(subject, selector) do
    case query_selector(subject, selector) do
      {:ok, nil} -> raise "No element found for selector: #{selector}"
      {:ok, element} -> element
    end
  end

  @spec query_selector_all(Page.t(), binary()) :: {:ok, [ElementHandle.t() | nil]} | {:error, :timeout}
  def query_selector_all(subject, selector) do
    frame(subject)
    |> Channel.send("querySelectorAll", %{selector: selector})
    |> hydrate()
  end

  @spec query_selector_all!(Page.t(), binary()) :: [ElementHandle.t()] | no_return()
  def query_selector_all!(subject, selector) do
    {:ok, handles} = query_selector_all(subject, selector)
    handles
  end

  def route(%{connection: _connection} = subject, url_pattern, callback, _options \\ %{}) do
    matcher = Helpers.URLMatcher.new(url_pattern)
    handler = Helpers.RouteHandler.new(matcher, callback)
    listeners = subject.listeners["route"]

    if listeners == nil || Enum.empty?(listeners) do
      Channel.send(subject, "setNetworkInterceptionEnabled", %{enabled: true})
    end

    Channel.on(subject.connection, {"route", subject}, handler)
    subject
  end

  def screenshot(subject, params) do
    case Map.pop(params, "path", nil) do
      {nil, params} ->
        subject |> Channel.send("screenshot", params)

      {path, params} ->
        [_, type] = String.split(path, ".")

        data =
          subject
          |> Channel.send("screenshot", Map.put(params, :type, type))

        File.write!(path, Base.decode64!(data))
        data
    end
  end

  def set_content(subject, content) do
    params = %{
      html: content,
      waitUntil: "load"
    }

    frame(subject) |> Channel.send("setContent", params)
    subject
  end

  def set_viewport_size(subject, params) do
    subject |> Channel.send("setViewportSize", %{viewportSize: params})
    subject
  end

  def text_content(subject, selector) do
    frame(subject) |> Channel.send("textContent", %{selector: selector})
  end

  def title(subject) do
    frame(subject) |> Channel.send("title")
  end

  @spec wait_for_load_state(Page.t(), map()) :: Page.t()
  def wait_for_load_state(subject, state \\ "load", options \\ %{})

  def wait_for_load_state(subject, state, options) when is_binary(state) do
    frame(subject) |> Frame.wait_for_load_state(state, options)
    subject
  end

  def wait_for_load_state(subject, options, _) when is_map(options) do
    wait_for_load_state(subject, "load", options)
  end

  def wait_for_selector(subject, selector, options \\ %{}) do
    frame(subject) |> Channel.send("waitForSelector", Map.merge(%{selector: selector}, options))
  end

  def cookies(subject, urls \\ []) do
    subject.owned_context |> Channel.send("cookies", %{urls: urls})
  end

  def add_cookies(subject, cookies) do
    subject.owned_context |> Channel.send("addCookies", %{cookies: cookies})
  end

  # private
  # ---------------------------------------------------------------------------

  defp deserialize(value) do
    case value do
      %{b: boolean} ->
        boolean

      %{n: number} ->
        number

      %{o: object} ->
        Enum.map(object, fn item ->
          {item.k, deserialize(item.v)}
        end)
        |> Enum.into(%{})
        |> Extra.Map.deep_atomize_keys()

      %{s: string} ->
        string

      %{v: "null"} ->
        nil

      %{v: "undefined"} ->
        nil
    end
  end

  defp hydrate(handle, timeout \\ DateTime.utc_now() |> DateTime.add(30, :second))

  defp hydrate(nil, _timeout) do
    {:ok, nil}
  end

  defp hydrate(%Playwright.ElementHandle{} = handle, timeout) do
    if DateTime.compare(DateTime.utc_now(), timeout) == :gt do
      {:error, :timeout}
    else
      case handle.preview do
        "JSHandle@node" ->
          :timer.sleep(5)
          hydrate(Channel.get(handle.connection, {:guid, handle.guid}), timeout)

        _hydrated ->
          {:ok, handle}
      end
    end
  end

  defp hydrate(handles, timeout) when is_list(handles) do
    handles
    |> Enum.map(&hydrate(&1, timeout))
    |> Enum.reduce_while({:ok, []}, fn
      {:ok, handle}, {:ok, acc} ->
        {:cont, {:ok, acc ++ [handle]}}

      {:error, _reason} = error, _acc ->
        {:halt, error}
    end)
  end

  defp serialize(arg) do
    {value, handles} = serialize(arg, [], 0)
    %{value: Extra.Map.deep_atomize_keys(value), handles: handles}
  end

  defp serialize(_value, _handles, depth) when depth > 100 do
    raise ArgumentError, message: "Maximum argument depth exceeded"
  end

  defp serialize(nil, handles, _depth) do
    {%{v: "null"}, handles}
  end

  defp serialize(%Playwright.ElementHandle{} = value, handles, _depth) do
    index = length(handles)
    {%{h: index}, handles ++ [%{guid: value.guid}]}
  end

  defp serialize(%Playwright.JSHandle{} = value, handles, _depth) do
    index = length(handles)
    {%{h: index}, handles ++ [%{guid: value.guid}]}
  end

  defp serialize(value, _handles, _depth) when is_float(value) do
    Logger.error("not implemented: `serialize` for float: #{inspect(value)}")
  end

  defp serialize(value, handles, _depth) when is_integer(value) do
    {%{n: value}, handles}
  end

  defp serialize(%DateTime{} = value, _handles, _depth) do
    Logger.error("not implemented: `serialize` for datetime: #{inspect(value)}")
  end

  defp serialize(value, handles, _depth) when is_boolean(value) do
    {%{b: value}, handles}
  end

  defp serialize(value, handles, _depth) when is_binary(value) do
    {%{s: value}, handles}
  end

  defp serialize(value, handles, depth) when is_list(value) do
    {_, result} =
      Enum.map_reduce(value, %{handles: handles, items: []}, fn e, acc ->
        {value, handles} = serialize(e, acc.handles, depth + 1)

        {
          {value, handles},
          %{handles: handles, items: acc.items ++ [value]}
        }
      end)

    {%{a: result.items}, result.handles}
  end

  defp serialize(value, handles, depth) when is_map(value) do
    {_, result} =
      Enum.map_reduce(value, %{handles: handles, objects: []}, fn {k, v}, acc ->
        {value, handles} = serialize(v, acc.handles, depth + 1)

        {
          {%{k: k, v: value}, handles},
          %{handles: handles, objects: acc.objects ++ [%{k: k, v: value}]}
        }
      end)

    {%{o: result.objects}, result.handles}
  end

  defp serialize(_other, handles, _depth) do
    {%{v: "undefined"}, handles}
  end
end
