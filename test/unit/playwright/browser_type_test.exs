defmodule Test.Unit.Playwright.BrowserTypeTest do
  use ExUnit.Case

  alias Playwright.BrowserType

  describe "connect" do
    test "includes the websocket endpoint in the error message when there is a failure" do
      assert {
               :error,
               {~s|Error connecting to "ws://example.com/server"|, {{_, {_, {_, {:error, 404}}}}, _}}
             } = BrowserType.connect("ws://example.com/server")
    end
  end
end
