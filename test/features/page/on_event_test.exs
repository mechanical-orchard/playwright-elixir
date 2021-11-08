defmodule Test.Features.Page.OnEventTest do
  use Playwright.TestCase, async: true

  describe "Page.on/3" do
    @tag exclude: [:page]
    test "on 'close'", %{browser: browser} do
      page = Playwright.Browser.new_page(browser)
      this = self()
      guid = page.guid

      Playwright.Page.on(page, "close", fn event ->
        send(this, event)
      end)

      Playwright.Page.close(page)
      assert_received({:on, :close, %Playwright.Page{guid: ^guid, initializer: %{isClosed: true}}})
    end

    # NOTE: this is really about *any* `on` event handling
    test "on 'close' of one Page does not affect another", %{browser: browser} do
      this = self()

      %{guid: guid_one} = page_one = Playwright.Browser.new_page(browser)
      %{guid: guid_two} = page_two = Playwright.Browser.new_page(browser)

      Playwright.Page.on(page_one, "close", fn {:on, :close, page} ->
        send(this, page.guid)
      end)

      Playwright.Page.close(page_one)
      Playwright.Page.close(page_two)

      assert_received(^guid_one)
      refute_received(^guid_two)
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
