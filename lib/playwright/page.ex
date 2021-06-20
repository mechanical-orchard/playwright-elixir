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
  use Playwright.Runner.ChannelOwner, [:owned_context]

  alias Playwright.BrowserContext
  alias Playwright.ElementHandle
  alias Playwright.Runner.Channel
  alias Playwright.Runner.Connection
  alias Playwright.Page

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def context(subject) do
    Connection.get(subject.connection, {:guid, subject.parent.guid})
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

  def evaluate(subject, expression) do
    function? = String.starts_with?(expression, "function")

    frame(subject)
    |> Channel.send("evaluateExpression", %{
      expression: expression,
      isFunction: function?,
      arg: %{
        value: %{v: "undefined"},
        handles: []
      }
    })
    |> case do
      %{s: result} ->
        result

      %{n: result} ->
        result

      %{v: "undefined"} ->
        nil
    end
  end

  def fill(subject, selector, value) do
    frame(subject) |> Channel.send("fill", %{selector: selector, value: value})
    subject
  end

  def get_attribute(subject, selector, name) do
    subject |> Page.query_selector!(selector) |> ElementHandle.get_attribute(name)
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
    Connection.on(subject.connection, event, handler)
    subject
  end

  def press(subject, selector, key) do
    frame(subject) |> Channel.send("press", %{selector: selector, key: key})
    subject
  end

  def q(subject, selector), do: query_selector(subject, selector)

  def query_selector(subject, selector) do
    frame(subject) |> Channel.send("querySelector", %{selector: selector})
  end

  def query_selector!(subject, selector) do
    case query_selector(subject, selector) do
      nil -> raise "No element found for selector: #{selector}"
      element -> element
    end
  end

  def query_selector_all(subject, selector) do
    frame(subject) |> Channel.send("querySelectorAll", %{selector: selector})
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

  # private
  # ---------------------------------------------------------------------------

  defp frame(subject) do
    Connection.get(subject.connection, {:guid, subject.initializer.mainFrame.guid})
  end
end
