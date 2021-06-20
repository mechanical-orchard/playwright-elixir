defmodule Test.Features.Page.OnTest do
  use Playwright.TestCase

  describe "Page.on/3" do
    test "on 'close'", %{page: page} do
      test_pid = self()

      Playwright.Page.on(page, "close", fn event ->
        send(test_pid, event)
      end)

      Playwright.Page.close(page)
      assert_received({:on, :close, %Playwright.Page{initializer: %{isClosed: true}}})
    end

    test "on 'console'", %{page: page} do
      test_pid = self()

      Playwright.Page.on(page, "console", fn event ->
        send(test_pid, event)
      end)

      Playwright.Page.evaluate(page, "function () { console.info('lala!'); }")
      Playwright.Page.evaluate(page, "console.error('lulu!')")

      assert_received({:on, :console, %Playwright.ConsoleMessage{initializer: %{text: "lala!", type: "info"}}})
      assert_received({:on, :console, %Playwright.ConsoleMessage{initializer: %{text: "lulu!", type: "error"}}})
    end
  end
end
