defmodule PlaywrightTest.Page do
  @moduledoc """
  `PlaywrightTest.Page` provides a shorthand for preparing a `Playwright.Page`.

  This is useful, for example, in making `doctest` examples more concise.
  """
  def setup() do
    {_, browser} = Playwright.BrowserType.launch()
    Playwright.Browser.new_page(browser)
  end
end
