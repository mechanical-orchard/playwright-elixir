defmodule Test.Features.Page.OnEventTest do
  use Playwright.TestCase, async: true

  alias Playwright.{Browser, Page}
  alias Playwright.Runner.EventInfo

  describe "Page.on/3" do
    @tag exclude: [:page]
    test "on 'close'", %{browser: browser} do
      page = Browser.new_page(browser)
      this = self()
      guid = page.guid

      Page.on(page, "close", fn event ->
        send(this, event)
      end)

      Page.close(page)

      assert_received(%EventInfo{params: %{}, target: %Page{guid: ^guid, closed: true}, type: :close})
    end

    # NOTE: this is really about *any* `on` event handling
    @tag exclude: [:page]
    test "on 'close' of one Page does not affect another", %{browser: browser} do
      this = self()

      %{guid: guid_one} = page_one = Browser.new_page(browser)
      %{guid: guid_two} = page_two = Browser.new_page(browser)

      Page.on(page_one, "close", fn %{target: target} ->
        send(this, target.guid)
      end)

      Page.close(page_one)
      Page.close(page_two)

      assert_received(^guid_one)
      refute_received(^guid_two)
    end

    test "on 'console'", %{page: page} do
      test_pid = self()

      Page.on(page, "console", fn event ->
        send(test_pid, event)
      end)

      Page.evaluate(page, "function () { console.info('lala!'); }")
      Page.evaluate(page, "console.error('lulu!')")

      assert_received(%EventInfo{params: %{message: %{message_text: "lala!", message_type: "info"}}, type: :console})
      assert_received(%EventInfo{params: %{message: %{message_text: "lulu!", message_type: "error"}}, type: :console})
    end
  end
end
