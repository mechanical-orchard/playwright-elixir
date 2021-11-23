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
  import Playwright.Runner.Helpers.Macros
  alias Playwright.Frame.Locator
  # alias Playwright.Runner.Channel

  @enforce_keys [:frame, :selector]
  defstruct [:frame, :selector]

  @type t() :: %__MODULE__{
          frame: Playwright.Frame.t(),
          selector: selector()
        }

  @type options() :: %{optional(:timeout) => non_neg_integer()}
  @type selector() :: String.t()

  @doc """
  Returns a new `Playwright.Frame.Locator`.
  """
  @spec new(Playwright.Frame.t(), selector()) :: Locator.t()
  def new(frame, selector) do
    %__MODULE__{
      frame: frame,
      selector: selector
    }
  end

  @doc """
  Checks the element by performing the following steps:

  1. Ensure that element is a checkbox or a radio input. If not, this method
     throws. If the element is already checked, this method returns immediately.
  2. Wait for actionability checks on the element, unless force option is set.
  3. Scroll the element into view if needed.
  4. Use `Playwright.Page.Mouse` to click in the center of the element.
  5. Wait for initiated navigations to either succeed or fail, unless
    `option: no_wait_after` is set.
  6. Ensure that the element is now checked. If not, this method throws.

  If the element is detached from the DOM at any moment during the action,
  this method throws.

  When all steps combined have not finished during the specified timeout, this
  method throws a TimeoutError. Passing zero timeout disables this.
  """
  def_locator(:check, :check)

  @doc """
  Clicks the element by performing the following steps:

  1. Wait for actionability checks on the element, unless `option: force` is set.
  2. Scroll the element into view if needed.
  3. Use `Playwright.Page.Mouse` to click in the center of the element, or
     the specified position.
  4. Wait for initiated navigations to either succeed or fail, unless
     `option: no_wait_after` is set.

  If the element is detached from the DOM at any moment during the action, this method throws.

  When all steps combined have not finished during the specified timeout, this method throws a
  `Playwright.Runner.Channel.Error.t()`. Passing zero timeout disables this.
  """
  def_locator(:click, :click)

  # ----> SEND {
  #   id: 6,
  #   guid: 'frame@08dddac500593477563b77a2a1317b15',
  #   method: 'evalOnSelectorAll',
  #   params: {
  #     selector: 'id=exists',
  #     expression: 'ee => ee.length',
  #     isFunction: true,
  #     arg: { value: {v: "undefined"}, handles: [] }
  #   }
  # }
  # def_locator(:eval_on_selector_all, :eval_on_selector_all)

  # def count(locator) do
  #   eval_on_selector_all(locator, %{
  #     expression: "ee => ee.length",
  #     is_function: true,
  #     # arg: %{ value: %{v: "undefined"}, handles: [] }
  #   })
  # end

  @doc """
  Returns when element specified by locator satisfies the `:state` option.

  If target element already satisfies the condition, the method returns
  immediately. Otherwise, waits for up to `option: timeout` milliseconds until
  the condition is met.
  """
  def_locator(:wait_for, :wait_for_selector)

  # private
  # ---------------------------------------------------------------------------

  # evaluate
  # fill
  # first
  # get_attribute
  # inner_html
  # inner_text
  # last
  # text_content
end
