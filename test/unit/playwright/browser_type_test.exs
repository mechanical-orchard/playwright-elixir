defmodule Playwright.BrowserTypeTest do
  use ExUnit.Case, async: true

  alias Playwright.BrowserType

  describe "connect" do
    test "includes the websocket endpoint in the error message when there is a failure" do
      assert {
               :error,
               {~s|Error connecting to "ws://example.com/server"|, _detail}
             } = BrowserType.connect("ws://example.com/server")
    end
  end
end
