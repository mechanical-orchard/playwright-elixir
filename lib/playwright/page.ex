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
    fields: [:frames, :main_frame, :owned_context]

  alias Playwright.BrowserContext
  alias Playwright.ElementHandle
  alias Playwright.Extra
  alias Playwright.Page
  alias Playwright.Runner.Channel

  def new(parent, args) do
    channel_owner(parent, args)
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
    function? = String.starts_with?(expression, "function")

    frame(subject)
    |> Channel.send("evaluateExpression", %{
      expression: expression,
      isFunction: function?,
      arg: serialize(arg)
    })
    |> deserialize()
  end

  def evaluate_handle(subject, expression, arg \\ nil) do
    function? = String.starts_with?(expression, "function")

    frame(subject)
    |> Channel.send("evaluateExpressionHandle", %{
      expression: expression,
      isFunction: function?,
      arg: serialize(arg)
    })
  end

  def eval_on_selector(subject, selector, expression, arg \\ nil, _options \\ %{}) do
    function? = String.starts_with?(expression, "function")

    frame(subject)
    |> Channel.send("evalOnSelector", %{
      selector: selector,
      expression: expression,
      isFunction: function?,
      arg: serialize(arg)
    })
  end

  def fill(subject, selector, value) do
    frame(subject) |> Channel.send("fill", %{selector: selector, value: value})
    subject
  end

  def get_attribute(subject, selector, name) do
    subject
    |> Page.query_selector!(selector)
    |> ElementHandle.get_attribute(name)
  end

  def goto(subject, url) do
    if Playwright.Extra.URI.absolute?(url) do
      frame(subject) |> Channel.send("goto", %{url: url, waitUntil: "load"})
      subject
    else
      raise "Expected an absolute URL, got: #{inspect(url)}"
    end
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

  # .channel__on (things that might want to move to Channel)
  # ----------------------------------------------------------------------------

  @doc false
  def channel__on(subject, "close") do
    %{subject | initializer: Map.put(subject.initializer, :isClosed, true)}
  end

  @doc false
  def channel__on(subject, other)
      when other in ["console"] do
    subject
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
