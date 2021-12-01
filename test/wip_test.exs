defmodule Playwright.WIPTest do
  use ExUnit.Case
  use PlaywrightTest.Case
  alias Playwright.{Browser, Page, Response}

  describe "WIP" do
    test "..." do
      assert Playwright.launch()
             |> Browser.new_page()
             |> Page.goto("http://example.com")
             |> Response.ok()
    end
  end
end
