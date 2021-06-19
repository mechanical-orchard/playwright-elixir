defmodule Test.Features.Page.OnTest do
  use Playwright.TestCase

  describe "Page.on/3" do
    test "on 'close'", %{browser: browser} do
      test_pid = self()

      page =
        browser
        |> Playwright.Browser.new_page()
        |> Playwright.Page.on("close", fn event ->
          send(test_pid, event)
        end)

      Playwright.Page.close(page)
      assert_received({:on, :close, %Playwright.Page{initializer: %{isClosed: true}}})
    end

    test "on 'console'", %{browser: browser} do
      test_pid = self()

      page =
        browser
        |> Playwright.Browser.new_page()
        |> Playwright.Page.on("console", fn event ->
          send(test_pid, event)
        end)

      Playwright.Page.evaluate(page, "function () { console.info('lala!'); }")
      Playwright.Page.evaluate(page, "console.error('lulu!')")

      assert_received({:on, :console, %Playwright.ConsoleMessage{initializer: %{text: "lala!", type: "info"}}})
      assert_received({:on, :console, %Playwright.ConsoleMessage{initializer: %{text: "lulu!", type: "error"}}})

      Playwright.Page.close(page)
    end
  end
end

# page.on('close')
# page.on('console')
# page.on('crash')
# page.on('dialog')
# page.on('domcontentloaded')
# page.on('download')
# page.on('filechooser')
# page.on('frameattached')
# page.on('framedetached')
# page.on('framenavigated')
# page.on('load')
# page.on('pageerror')
# page.on('popup')
# page.on('request')
# page.on('requestfailed')
# page.on('requestfinished')
# page.on('response')
# page.on('websocket')
# page.on('worker')
