defmodule Playwright.Page do
  @moduledoc """

  A web page.

  ## Selectors

  Some functions in this module accept selectors:
  * By default, selectors are assumed to be CSS: `a[href="/foo"]`
  * If a selector starts with a single or double quote, it is a text selector: `"Login"`
  * If a selector starts with `//`, it is an xpath selector: `//html/body`

  Selector types can be made explicit by prefixing with `css=`, `text=`, or `xpath=`: `text="Login"`.

  Playwright supports some useful psudeoselectors:
  * text: `#nav-bar :text("Contact us")`
  * inclusion: `.item-description:has(.item-promo-banner)`
  * position: `input:right-of(:text("Username"))` (also `left-of`, `above`, `below`, `near`)
  * visibility: `.login-button:visible`
  * nth match: `:nth-match(:text("Buy"), 3)`
  * match any of the conditions: `:is(button:has-text("Log in"), button:has-text("Sign in"))`

  More info: https://playwright.dev/docs/selectors
  """

  use Playwright.Client.ChannelOwner, owned_context: nil

  alias Playwright.BrowserContext
  alias Playwright.ElementHandle
  alias Playwright.Page

  def new(parent, args) do
    channel_owner(parent, args)
  end

  def click(channel_owner, selector) do
    frame(channel_owner)
    |> Playwright.Client.Channel.send("click", %{selector: selector})

    channel_owner
  end

  def close(channel_owner) do
    channel_owner |> Playwright.Client.Channel.send("close")

    if channel_owner.owned_context do
      BrowserContext.close(channel_owner.owned_context)
    end

    channel_owner
  end

  def evaluate(channel_owner, expression) do
    frame(channel_owner)
    |> Playwright.Client.Channel.send("evaluateExpression", %{
      expression: expression,
      isFunction: true,
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

  def fill(channel_owner, selector, value) do
    frame(channel_owner) |> Playwright.Client.Channel.send("fill", %{selector: selector, value: value})
    channel_owner
  end

  def get_attribute(channel_owner, selector, name) do
    channel_owner |> Page.query_selector(selector) |> ElementHandle.get_attribute(name)
  end

  def goto(channel_owner, url) do
    frame(channel_owner) |> Playwright.Client.Channel.send("goto", %{url: url, waitUntil: "load"})
    channel_owner
  end

  def press(channel_owner, selector, key) do
    frame(channel_owner) |> Playwright.Client.Channel.send("press", %{selector: selector, key: key})
    channel_owner
  end

  def q(channel_owner, selector), do: query_selector(channel_owner, selector)

  def query_selector(channel_owner, selector) do
    frame(channel_owner) |> Playwright.Client.Channel.send("querySelector", %{selector: selector})
  end

  def query_selector_all(channel_owner, selector) do
    frame(channel_owner) |> Playwright.Client.Channel.send("querySelectorAll", %{selector: selector})
  end

  def screenshot(channel_owner, params) do
    case Map.pop(params, "path", nil) do
      {nil, params} ->
        channel_owner |> Playwright.Client.Channel.send("screenshot", params)

      {path, params} ->
        [_, type] = String.split(path, ".")

        data =
          channel_owner
          |> Playwright.Client.Channel.send("screenshot", Map.put(params, :type, type))

        File.write!(path, Base.decode64!(data))
        data
    end
  end

  def set_content(channel_owner, content) do
    params = %{
      html: content,
      waitUntil: "load"
    }

    frame(channel_owner) |> Playwright.Client.Channel.send("setContent", params)
    channel_owner
  end

  def set_viewport_size(channel_owner, params) do
    channel_owner |> Playwright.Client.Channel.send("setViewportSize", %{viewportSize: params})
    channel_owner
  end

  def text_content(channel_owner, selector) do
    frame(channel_owner) |> Playwright.Client.Channel.send("textContent", %{selector: selector})
  end

  def title(channel_owner) do
    frame(channel_owner) |> Playwright.Client.Channel.send("title")
  end

  def wait_for_selector(channel_owner, selector, options \\ %{}) do
    frame(channel_owner) |> Playwright.Client.Channel.send("waitForSelector", Map.merge(%{selector: selector}, options))
  end

  # private
  # ---------------------------------------------------------------------------

  defp frame(channel_owner) do
    Connection.get(channel_owner.connection, {:guid, channel_owner.initializer.mainFrame.guid})
  end
end
