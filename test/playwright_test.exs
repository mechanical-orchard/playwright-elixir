defmodule PlaywrightTest do
  use ExUnit.Case
  doctest Playwright

  test "greets the world" do
    assert Playwright.hello() == :world
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

# pw = Playwright.create()
# br = Playwright.chromium(pw) |> Plawright.Browser.connect(endpoint)
# pg = Playwright.Page.create(br)
# ...
# Playwright.Page.goto(pg, "https://playwright.dev")
# Playwright.Browser.close(br)
