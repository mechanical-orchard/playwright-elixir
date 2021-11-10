defmodule Playwright.ResponseTest do
  use Playwright.TestCase, async: true

  alias Playwright.Page
  alias Playwright.Response

  describe "Response.ok/1" do
    test "...", %{assets: assets, page: page} do
      response = Page.goto(page, assets.prefix <> "/dom.html")
      assert Response.ok(response)
    end
  end

  # describe "Response.body/1" do
  #   test "...", %{assets: assets, page: page} do
  #     response = Page.goto(page, assets.prefix <> "/dom.html")
  #     assert Response.ok(response)


  #     assert_received(:intercepted)
  #   end
  # end
end


# it('...Response.body', async () => {
#   const page = await browser.newPage();

#   // page.on('response', async (response) => { let body = await response.body(); console.warn("BODY....", body.toString()); });
#   const response = await page.goto("http://localhost:3002/dom.html");
#   console.info("response", response);
#   console.info("    body", (await response.body()).toString());
# });
