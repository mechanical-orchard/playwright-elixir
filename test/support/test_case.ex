defmodule Playwright.TestCase do
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
