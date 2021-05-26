defmodule Playwright.Test do
  use ExUnit.Case
  use PlaywrightTest.Case
  doctest Playwright

  setup_all do
    {:ok, _} = Playwright.start()
    {:ok, _} = Playwright.Test.Support.AssetsServer.start(nil, nil)

    # {connection, browser} = Playwright.connect("ws://localhost:3000/playwright")
    {connection, browser} = launch()

    [
      connection: connection,
      browser: browser
    ]
  end

  describe "Usage" do
    test "against a public domain", %{browser: browser} do
      page =
        browser
        |> new_context()
        |> new_page()

      text =
        page
        |> Page.goto("https://playwright.dev")
        |> Page.text_content(".navbar__title")

      assert text == "Playwright"
    end

    test "against the local test assets server", %{browser: browser} do
      page =
        browser
        |> new_context()
        |> new_page()
        |> Page.goto("http://localhost:3002/dom.html")

      page
      |> Page.query_selector("css=div#outer")
      |> assert()
    end
  end
end
