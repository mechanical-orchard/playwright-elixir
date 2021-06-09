defmodule Playwright.TestCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use PlaywrightTest.Case, transport: :driver
    end
  end

  setup %{transport: transport} do
    prefix =
      case transport do
        :driver -> "http://localhost:3002"
        :websocket -> "http://host.docker.internal:3002"
      end

    [
      server: %{
        prefix: prefix
      }
    ]
  end
end
