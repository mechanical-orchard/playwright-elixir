# THIS(+1)
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

  alias Playwright.BrowserContext
  alias Playwright.ElementHandle
  alias Playwright.Extra
  alias Playwright.Page
  alias Playwright.Runner.Channel
  alias Playwright.Runner.ChannelOwner
  alias Playwright.Runner.Helpers

  @impl ChannelOwner
  def new(%{connection: _connection} = parent, args) do
    Map.merge(init(parent, args), %{closed: args.initializer.isClosed})
  end

  @impl ChannelOwner
  def before_event(subject, %Channel.Event{type: :close}) do
    {:ok, Map.put(subject, :closed, true)}
  end

  @impl ChannelOwner
  def before_event(subject, %Channel.Event{type: :console}) do
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

  # # default timeout: 30s
  # def expect_event(subject, event, fun, _predicate \\ nil) do
  #   # do pre-send stuff (maybe modifying `subject`)
  #   timeout = 30000
  #   helper = Channel.WaitHelper.new(subject, event, fun)
  #   # Channel.WaitHelper.reject_on_timeout(helper, timeout, "Timeout while waiting for event #{inspect(event)}")

  #   # if event != "crash" do
  #   #   Channel.WaitHelper.reject_on_event(helper, "crash", "Page crashed while waiting for event #{inspect(event)}")
  #   # end
  #   # if event != "close" do
  #   #   Channel.WaitHelper.reject_on_event(helper, "close", "Page closed while waiting for event #{inspect(event)}")
  #   # end

  #   # # fun.(subject)
  #   Channel.WaitHelper.wait_for_event(helper)
  #   # |> Channel.WaitHelper.result()
  # end

  require Logger

  def expect_event(subject, event, fun) when event in ["requestFinished"] do
    parent = Channel.get(subject.connection, {:guid, subject.parent.guid})
    # Logger.info("waiting.............................................")
    result = Channel.wait_for(parent, event, fun)
    # Logger.info("COMPLETED waiting w/ #{inspect(result)}")
    result
  end
  def expect_event(subject, event, fun) do
    Channel.wait_for(subject, event, fun)
  end
  defdelegate wait_for_event(subject, event, fun), to: __MODULE__, as: :expect_event

  # def on(subject, event, handler)
  #     when event in ["request", "response", "requestFinished"] do
  #   # NOTE: the event/method will be recv'd from Playwright server with
  #   # the parent BrowserContext as the context/bound :guid. So, we need to
  #   # add our handlers there, on that (BrowserContext) parent.
  #   parent = Channel.get(subject.connection, {:guid, subject.parent.guid})
  #   Channel.on(subject.connection, {event, parent}, handler)
  #   subject
  # end

  #   def expect_event(
#     self,
#     event: str,
#     predicate: Callable = None,
#     timeout: float = None,
# ) -> EventContextManagerImpl:
#     return self._expect_event(
#         event, predicate, timeout, f'waiting for event "{event}"'
#     )

# def _expect_event(
#     self,
#     event: str,
#     predicate: Callable = None,
#     timeout: float = None,
#     log_line: str = None,
# ) -> EventContextManagerImpl:
#     if timeout is None:
#         timeout = self._timeout_settings.timeout()
#     wait_helper = WaitHelper(self, f"page.expect_event({event})")
#     wait_helper.reject_on_timeout(
#         timeout, f'Timeout while waiting for event "{event}"'
#     )
#     if log_line:
#         wait_helper.log(log_line)
#     if event != Page.Events.Crash:
#         wait_helper.reject_on_event(self, Page.Events.Crash, Error("Page crashed"))
#     if event != Page.Events.Close:
#         wait_helper.reject_on_event(self, Page.Events.Close, Error("Page closed"))
#     wait_helper.wait_for_event(self, event, predicate)
#     return EventContextManagerImpl(wait_helper.result())

# async waitForEvent(event: string, optionsOrPredicate: WaitForEventOptions = {}): Promise<any> {
#   return this._wrapApiCall(async channel => {
#     return this._waitForEvent(channel, event, optionsOrPredicate, `waiting for event "${event}"`);
#   });
# }

# private async _waitForEvent(channel: channels.EventTargetChannel, event: string, optionsOrPredicate: WaitForEventOptions, logLine?: string): Promise<any> {
#   const timeout = this._timeoutSettings.timeout(typeof optionsOrPredicate === 'function' ? {} : optionsOrPredicate);
#   const predicate = typeof optionsOrPredicate === 'function' ? optionsOrPredicate : optionsOrPredicate.predicate;
#   const waiter = Waiter.createForEvent(channel, event);
#   if (logLine)
#     waiter.log(logLine);
#   waiter.rejectOnTimeout(timeout, `Timeout while waiting for event "${event}"`);
#   if (event !== Events.Page.Crash)
#     waiter.rejectOnEvent(this, Events.Page.Crash, new Error('Page crashed'));
#   if (event !== Events.Page.Close)
#     waiter.rejectOnEvent(this, Events.Page.Close, new Error('Page closed'));
#   const result = await waiter.waitForEvent(this, event, predicate as any);
#   waiter.dispose();
#   return result;
# }

  def fill(subject, selector, value) do
    frame(subject) |> Channel.send("fill", %{selector: selector, value: value})
    subject
  end

  def get_attribute(subject, selector, name) do
    subject
    |> Page.query_selector!(selector)
    |> ElementHandle.get_attribute(name)
  end

  def goto(subject, "about:blank" = url) do
    frame(subject) |> Channel.send("goto", %{url: url, waitUntil: "load"})
  end

  def goto(subject, url, _params \\ %{}) do
    case frame(subject) |> Channel.send("goto", %{url: url, waitUntil: "load"}) do
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

  require Logger

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

  def query_selector(subject, selector) do
    frame(subject)
    |> Channel.send("querySelector", %{selector: selector})
    |> hydrate()
  end

  def query_selector!(subject, selector) do
    case query_selector(subject, selector) do
      nil -> raise "No element found for selector: #{selector}"
      element -> element
    end
  end

  def query_selector_all(subject, selector) do
    frame(subject)
    |> Channel.send("querySelectorAll", %{selector: selector})
    |> hydrate()
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

  def wait_for_selector(subject, selector, options \\ %{}) do
    frame(subject) |> Channel.send("waitForSelector", Map.merge(%{selector: selector}, options))
  end

  def cookies(subject, urls \\ []) do
    subject.owned_context |> Channel.send("cookies", %{ urls: urls })
  end

  def add_cookies(subject, cookies) do
    subject.owned_context |> Channel.send("addCookies", %{ cookies: cookies })
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

  defp frame(subject) do
    Channel.get(subject.connection, {:guid, subject.initializer.mainFrame.guid})
  end

  require Logger

  defp hydrate(nil) do
    nil
  end

  defp hydrate(%Playwright.ElementHandle{} = handle) do
    case handle.preview do
      "JSHandle@node" ->
        :timer.sleep(5)
        hydrate(Channel.get(handle.connection, {:guid, handle.guid}))

      _hydrated ->
        handle
    end
  end

  defp hydrate(handles) when is_list(handles) do
    Enum.map(handles, &hydrate/1)
  end

  require Logger

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
