defmodule Test.Features.ElementHandleTest do
  use ExUnit.Case
  use PlaywrightTest.Case, transport: :driver

  alias Playwright.ChannelOwner.ElementHandle

  setup %{browser: browser, server: server} do
    page =
      browser
      |> Browser.new_page()
      |> Page.goto(server.prefix <> "/dom.html")

    [page: page]
  end

  describe "get_attribute" do
    test "get_attribute/2", %{page: page} do
      element = page |> Page.query_selector("#outer")
      assert element |> ElementHandle.get_attribute("name") == "value"
      assert element |> ElementHandle.get_attribute("foo") == nil
    end

    test "Page delegates to this get_attribute", %{page: page} do
      assert Page.get_attribute(page, "#outer", "name") == "value"
      assert Page.get_attribute(page, "#outer", "foo") == nil
    end
  end

  describe "text_content" do
    test "text_content/1", %{page: page} do
      assert page
             |> Page.query_selector("css=#inner")
             |> ElementHandle.text_content() == "Text,\nmore text"

      Page.close(page)
    end
  end
end
