defmodule Playwright.TestCase do
  @moduledoc """
  `TestCase` is a helper module intended for use by the tests *of* Playwright.

  When using Playwright to write tests for some other project, consider using `PlaywrightTest.Case`.
  """
  use ExUnit.CaseTemplate

  using(options) do
    quote do
      use PlaywrightTest.Case, unquote(options)
    end
  end

  setup %{transport: transport} do
    prefix =
      case transport do
        :driver -> "http://localhost:3004"
        :websocket -> "http://playwright-assets:3002"
      end

    [
      assets: %{
        blank: "about:blank",
        prefix: prefix,
        empty: prefix <> "/empty.html"
      }
    ]
  end
end
