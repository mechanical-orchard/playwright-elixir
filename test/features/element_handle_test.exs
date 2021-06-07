defmodule Test.Features.ElementHandleTest do
  use ExUnit.Case
  use PlaywrightTest.Case, transport: :driver

  alias Playwright.ChannelOwner.ElementHandle

  describe "ElementHandle" do
    test "text_content/1", %{browser: browser, server: server} do
      page =
        browser
        |> Browser.new_page()
        |> Page.goto(server.prefix <> "/dom.html")

      assert page
             |> Page.query_selector("css=#inner")
             |> ElementHandle.text_content() == "Text,\nmore text"

      Page.close(page)
    end
  end
end
