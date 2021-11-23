defmodule Playwright.Page.Locator do
  alias Playwright.{Frame, Page}

  def new(page, selector) do
    Frame.Locator.new(Page.main_frame(page), selector)
  end

  defdelegate click(locator, options \\ %{}), to: Frame.Locator
end
