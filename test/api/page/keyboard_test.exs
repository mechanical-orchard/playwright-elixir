defmodule Playwright.Page.KeyboardTest do
  use Playwright.TestCase, async: true

  alias Playwright.Page
  alias Playwright.Page.Keyboard

  describe "down" do
    test "returns the `:page`", %{page: page} do
      assert %Page{} = Keyboard.down(page, "A")
    end

    test "sends proper code", %{page: page, assets: assets} do
      Page.goto(page, assets.prefix <> "/input/keyboard.html")

      Keyboard.down(page, "Control")

      assert Page.evaluate(page, "() => getResult()") ==
               "Keydown: Control ControlLeft 17 [Control]"
    end
  end

  describe "insert_text" do
    test "returns the `:page`", %{page: page} do
      assert %Page{} = Keyboard.insert_text(page, "text")
    end

    test "should send characters inserted", %{page: page} do
      Page.evaluate(page, """
        const textarea = document.createElement('textarea');
        document.body.appendChild(textarea);
        textarea.focus();
      """)

      text = "Hello world. I am the text that was typed!"

      Keyboard.insert_text(page, text)

      assert Page.evaluate(page, ~s[document.querySelector("textarea").value]) == text
    end
  end

  describe "press" do
    test "returns the `:page`", %{page: page} do
      assert %Page{} = Keyboard.press(page, "A")
    end

    test "test should press plus", %{page: page, assets: assets} do
      Page.goto(page, assets.prefix <> "/input/keyboard.html")

      Keyboard.press(page, "+")

      assert Page.evaluate(page, "() => getResult()") ==
               [
                 # 192 is ` keyCode
                 "Keydown: + Equal 187 []",
                 # 126 is ~ charCode
                 "Keypress: + Equal 43 43 []",
                 "Keyup: + Equal 187 []"
               ]
               |> Enum.join("\n")
    end
  end

  describe "type" do
    test "returns the `:page`", %{page: page} do
      assert %Page{} = Keyboard.type(page, "text")
    end

    test "keyboard type into a textbox", %{page: page} do
      Page.evaluate(page, """
        const textarea = document.createElement('textarea');
        document.body.appendChild(textarea);
        textarea.focus();
      """)

      text = "Hello world. I am the text that was typed!"

      Keyboard.type(page, text)

      assert Page.evaluate(page, ~s[document.querySelector("textarea").value]) == text
    end
  end

  describe "up" do
    test "returns the `:page`", %{page: page} do
      assert %Page{} = Keyboard.up(page, "A")
    end

    test "sends proper code", %{page: page, assets: assets} do
      Page.goto(page, assets.prefix <> "/input/keyboard.html")

      Keyboard.up(page, ";")

      assert Page.evaluate(page, "() => getResult()") ==
               "Keyup: ; Semicolon 186 []"
    end
  end
end
