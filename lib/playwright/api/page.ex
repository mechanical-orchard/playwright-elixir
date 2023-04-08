defmodule Playwright.API.Page do
  @moduledoc """
  `Playwright.API.Page` is the upcoming replacement for `Playwright.Page`.

  Stay tuned.
  """

  def goto(page, url, options \\ %{}) do
    {:ok, Playwright.Page.goto(page, url, options)}
  end
end
