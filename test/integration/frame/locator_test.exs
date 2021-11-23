defmodule Playwright.Frame.LocatorTest do
  use Playwright.TestCase, async: true

  alias Playwright.{Frame, Page}
  alias Playwright.Runner.Channel.Error

  describe "Locator.check/2" do
    setup(%{assets: assets, page: page}) do
      options = %{timeout: 1_000}

      page |> Page.goto(assets.prefix <> "/empty.html")
      page |> Page.set_content("<input id='exists' type='checkbox'/>")

      [options: options]
    end

    test "returns :ok on a successful 'check'", %{options: options, page: page} do
      frame = Page.main_frame(page)

      locator = Frame.Locator.new(frame, "input#exists")
      assert :ok = Frame.Locator.check(locator, options)
    end

    test "returns a timeout error when unable to 'check'", %{options: options, page: page} do
      frame = Page.main_frame(page)

      locator = Frame.Locator.new(frame, "input#bogus")
      assert {:error, %Error{message: "Timeout 1000ms exceeded."}} = Frame.Locator.check(locator, options)
    end
  end

  describe "Locator.click/2" do
    setup(%{assets: assets, page: page}) do
      options = %{timeout: 1_000}

      page |> Page.goto(assets.prefix <> "/empty.html")
      page |> Page.set_content("<a id='exists' target=_blank rel=noopener href='/one-style.html'>yo</a>")

      [options: options]
    end

    test "returns :ok on a successful click", %{options: options, page: page} do
      frame = Page.main_frame(page)

      locator = Frame.Locator.new(frame, "a#exists")
      assert :ok = Frame.Locator.click(locator, options)
    end

    test "returns a timeout error when unable to click", %{options: options, page: page} do
      frame = Page.main_frame(page)

      locator = Frame.Locator.new(frame, "a#bogus")
      assert {:error, %Error{message: "Timeout 1000ms exceeded."}} = Frame.Locator.click(locator, options)
    end
  end

  describe "Locator.wait_for/2" do
    setup(%{assets: assets, page: page}) do
      options = %{timeout: 1_000}

      page |> Page.goto(assets.prefix <> "/empty.html")

      [options: options]
    end

    test "waiting for 'attached'", %{options: options, page: page} do
      frame = Page.main_frame(page)

      locator = Frame.Locator.new(frame, "a#exists")

      task = Task.async(fn ->
        assert :ok = Frame.Locator.wait_for(locator, Map.put(options, :state, "attached"))
      end)

      page |> Page.set_content("<a id='exists' target=_blank rel=noopener href='/one-style.html'>yo</a>")

      Task.await(task)
    end
  end
end
