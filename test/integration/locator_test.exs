defmodule Playwright.LocatorTest do
  use Playwright.TestCase, async: true

  alias Playwright.{ElementHandle, Locator, Page}
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

      locator = Locator.new(frame, "input#exists")
      assert :ok = Locator.check(locator, options)
    end

    test "returns a timeout error when unable to 'check'", %{options: options, page: page} do
      frame = Page.main_frame(page)

      locator = Locator.new(frame, "input#bogus")
      assert {:error, %Error{message: "Timeout 1000ms exceeded."}} = Locator.check(locator, options)
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

      locator = Locator.new(frame, "a#exists")
      assert :ok = Locator.click(locator, options)
    end

    test "returns a timeout error when unable to click", %{options: options, page: page} do
      frame = Page.main_frame(page)

      locator = Locator.new(frame, "a#bogus")
      assert {:error, %Error{message: "Timeout 1000ms exceeded."}} = Locator.click(locator, options)
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

      locator = Locator.new(frame, "a#exists")

      task =
        Task.async(fn ->
          assert :ok = Locator.wait_for(locator, Map.put(options, :state, "attached"))
        end)

      page |> Page.set_content("<a id='exists' target=_blank rel=noopener href='/one-style.html'>yo</a>")

      Task.await(task)
    end
  end

  describe "Locator.evaluate/4" do
    test "called with expression", %{page: page} do
      element = Locator.new(page, "input")
      Page.set_content(page, "<input type='checkbox' checked><div>Not a checkbox</div>")

      {:ok, checked} = Locator.is_checked(element)
      assert checked

      Locator.evaluate(element, "function (input) { return input.checked = false; }")

      {:ok, checked} = Locator.is_checked(element)
      refute checked
    end

    test "called with expression and an `ElementHandle` arg", %{page: page} do
      selector = "input"
      locator = Locator.new(page, selector)

      Page.set_content(page, "<input type='checkbox' checked><div>Not a checkbox</div>")

      {:ok, handle} = Page.wait_for_selector(page, selector)

      {:ok, checked} = Locator.is_checked(locator)
      assert checked

      Locator.evaluate(locator, "function (input) { return input.checked = false; }", handle)

      {:ok, checked} = Locator.is_checked(locator)
      refute checked
    end
  end

  describe "Locator.locator/4" do
    test "returns values with previews", %{assets: assets, page: page} do
      Page.goto(page, assets.dom)

      outer = Page.locator(page, "#outer")
      inner = Locator.locator(outer, "#inner")
      check = Page.locator(page, "#check")
      text = Locator.evaluate_handle(inner, "e => e.firstChild")

      assert Locator.string(outer) == ~s|Locator@#outer|
      assert Locator.string(inner) == ~s|Locator@#outer >> #inner|
      assert Locator.string(check) == ~s|Locator@#check|
      assert ElementHandle.string(text) == ~s|JSHandle@#text=Text,↵more text|
    end
  end
end
