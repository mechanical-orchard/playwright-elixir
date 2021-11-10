defmodule Playwright.NetworkTest do
  use Playwright.TestCase, async: true

  alias Playwright.Page
  # alias Playwright.Response

  describe "Page.goto/2" do
    setup :visit_empty

    test "...", %{page: page, url: url} do
      assert Page.url(page) == url
    end
  end

  # describe "Response.body/1" do
  #   test "...", %{assets: assets, page: page} do
  #     response = Page.goto(page, assets.prefix <> "/dom.html")
  #     assert Response.ok(response)


  #     assert_received(:intercepted)
  #   end
  # end

  defp visit_empty(%{assets: assets, page: page}) do
    url = assets.prefix <> "/empty.html"
    Playwright.Page.goto(page, url)
    [url: url]
  end
end


# it('...Response.body', async () => {
#   const page = await browser.newPage();

#   // page.on('response', async (response) => { let body = await response.body(); console.warn("BODY....", body.toString()); });
#   const response = await page.goto("http://localhost:3002/dom.html");
#   console.info("response", response);
#   console.info("    body", (await response.body()).toString());
# });
