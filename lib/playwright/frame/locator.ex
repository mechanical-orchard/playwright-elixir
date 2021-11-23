defmodule Playwright.Frame.Locator do
  @moduledoc """
  `Playwright.Frame.Locator` represents a view to the element(s) on the page.
  It captures the logic sufficient to retrieve the element at any given moment.
  `Locator` can be created with the `Playwright.Frame.Locator.new/2` function.

  ## Example

      locator = Frame.Locator.new(frame, "a#exists")
      Frame.Locator.click(locator)

  The difference between the `Locator` and `Playwright.ElementHandle`
  is that the latter points to a particular element, while `Locator` captures
  the logic of how to retrieve that element.

  ## ElementHandle Example

  In the example below, `handle` points to a particular DOM element on page. If
  that element changes text or is used by React to render an entirely different
  component, `handle` is still pointing to that very DOM element. This can lead
  to unexpected behaviors.

      {:ok, handle} = Page.query_selector(page, "text=Submit")
      ElementHandle.hover(handle)
      ElementHandle.click(handle)

  ## Locator Example

  With the locator, every time the element is used, up-to-date DOM element is
  located in the page using the selector. So in the snippet below, underlying
  DOM element is going to be located twice.

      locator = Frame.Locator.new(frame, "a#exists")
      :ok = Frame.Locator.hover(locator)
      :ok = Frame.Locator.click(locator)
  """
  alias Playwright.Frame.Locator
  alias Playwright.Runner.Channel

  @enforce_keys [:frame, :selector]
  defstruct [:frame, :selector]

  @type t() :: %__MODULE__{
    frame: Playwright.Frame.t(),
    selector: String.t()
  }

  @type options() :: %{optional(:timeout) => non_neg_integer()}

  def new(frame, selector) do
    %__MODULE__{
      frame: frame,
      selector: selector
    }
  end

  @doc """
  Clicks the element by performing the following steps:

  1. Wait for actionability checks on the element, unless force option is set.
  2. Scroll the element into view if needed.
  3. Use page.mouse to click in the center of the element, or the specified position.
  4. Wait for initiated navigations to either succeed or fail, unless noWaitAfter option is set.

  If the element is detached from the DOM at any moment during the action, this method throws.

  When all steps combined have not finished during the specified timeout, this method throws a
  `Playwright.Runner.Channel.Error.t()`. Passing zero timeout disables this.
  """
  @spec click(Locator.t(), options()) :: :ok | {:error, Playwright.Runner.Channel.Error.t()}
  def click(locator, options \\ %{}) do
    case Channel.post(locator.frame, :click, Map.merge(options, %{selector: locator.selector})) do
      {:ok, %{id: _id}} -> :ok
      {:error, error} -> {:error, error}
    end
  end
end
