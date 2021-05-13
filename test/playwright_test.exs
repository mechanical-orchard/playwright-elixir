defmodule PlaywrightTest do
  use ExUnit.Case
  doctest Playwright

  test "greets the world" do
    assert Playwright.hello() == :world
  end

  describe "Usage" do
    test "looks something like..." do
      endpoint = "ws://localhost:3000/playwright"

      playwright = Playwright.start()
      chromium = Playwright.chromium(playwright)
      browser = Playwright.Browser.connect(chromium, endpoint)
      page = Playwright.Page.create(browser)

      Playwright.Page.goto(page, "https://playwright.dev")
      Playwright.Browser.close(browser)
    end
  end
end

# An example in Java to reproduce in Elixir:
#
# public class Example {
#   public static void main(String[] args) {
#     try (Playwright playwright = Playwright.create()) {
#       BrowserType chromium = playwright.chromium();
#       Browser browser = chromium.launch();
#       Page page = browser.newPage();
#       page.navigate("https://example.com");
#       // other actions...
#       browser.close();
#     }
#   }
# }
