defmodule Playwright.TestCase do
  @moduledoc """
  `TestCase` is a helper module intended for use by the tests *of* Playwright.
  When using Playwright to wright tests for some other project, consider using
  `PlaywrightTest.Case`.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      use PlaywrightTest.Case
    end
  end

  setup %{transport: transport} do
    prefix =
      case transport do
        :driver -> "http://localhost:3002"
        :websocket -> "http://playwright-assets:3002"
      end

    [
      assets: %{
        prefix: prefix
      }
    ]
  end
end
