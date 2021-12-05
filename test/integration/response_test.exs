defmodule Playwright.ResponseTest do
  use Playwright.TestCase

  alias Playwright.Page
  alias Playwright.Response

  describe "Response.ok/1" do
    test "works", %{assets: assets, page: page} do
      response = Page.goto(page, assets.prefix <> "/dom.html")
      assert Response.ok(response)
    end
  end

  describe "Response.body/1" do
    test "for a simple HTML page", %{assets: assets, page: page} do
      response = Page.goto(page, assets.prefix <> "/title.html")
      assert Response.body(response) == "<title>Woof-Woof</title>\n"
    end
  end
end
