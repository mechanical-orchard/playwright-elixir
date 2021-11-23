defmodule Playwright.Page.Locator do
  @moduledoc """
  `Playwright.Page.Locator` wraps `Playwright.Frame.Locator`, using the main
  frame of the page.
  """
  alias Playwright.{Frame, Page}

  @doc """
  Returns an element locator that can be used to perform actions on the page.
  This locator is resolved immediately before performing an action, so a series
  of actions on the same locator can in fact be performed on different DOM
  elements, as may happen when the DOM structure changes between actions.
  """
  def new(page, selector) do
    Frame.Locator.new(Page.main_frame(page), selector)
  end

  defdelegate click(locator, options \\ %{}), to: Frame.Locator
end
