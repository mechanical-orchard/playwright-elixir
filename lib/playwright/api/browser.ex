defmodule Playwright.API.Browser do
  @moduledoc """
  `Playwright.API.Browser` is the upcoming replacement for `Playwright.Browser`.

  Stay tuned.
  """

  def close(browser) do
    {:ok, Playwright.Browser.close(browser)}
  end

  def new_page(browser, options \\ %{}) do
    {:ok, Playwright.Browser.new_page(browser, options)}
  end
end
