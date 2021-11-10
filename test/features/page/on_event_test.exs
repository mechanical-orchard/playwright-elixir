defmodule Test.Features.Page.OnEventTest do
  use Playwright.TestCase, async: true

  alias Playwright.Page
  alias Playwright.Runner.Channel

  describe "Page.on/3" do
    @tag exclude: [:page]
    test "on 'close'", %{browser: browser} do
      page = Playwright.Browser.new_page(browser)
      this = self()
      guid = page.guid

      Page.on(page, "close", fn p, event ->
        send(this, {p, event})
      end)

      Page.close(page)

      assert_received({
        %Page{guid: ^guid, closed: true},
        %Channel.Event{params: %{}, type: :close}
      })
    end

    # NOTE: this is really about *any* `on` event handling
    test "on 'close' of one Page does not affect another", %{browser: browser} do
      this = self()

      %{guid: guid_one} = page_one = Playwright.Browser.new_page(browser)
      %{guid: guid_two} = page_two = Playwright.Browser.new_page(browser)

      Page.on(page_one, "close", fn p, _event ->
        send(this, p.guid)
      end)

      Page.close(page_one)
      Page.close(page_two)

      assert_received(^guid_one)
      refute_received(^guid_two)
    end

    test "on 'console'", %{page: page} do
      test_pid = self()

      Page.on(page, "console", fn _, event ->
        send(test_pid, event)
      end)

      Page.evaluate(page, "function () { console.info('lala!'); }")
      Page.evaluate(page, "console.error('lulu!')")

      assert_received(%Channel.Event{params: %{text: "lala!", type: "info"}, type: :console})
      assert_received(%Channel.Event{params: %{text: "lulu!", type: "error"}, type: :console})
    end
  end
end
