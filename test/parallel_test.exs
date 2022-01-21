for index <- 0..4 do
  # IO.puts("index: #{inspect(index)}")
  defmodule Module.concat([Example, Test, to_string(index)]) do
    use ExUnit.Case, async: true
    use PlaywrightTest.Case
    alias Playwright.{Browser, Page, Response}

    describe "Playwright.launch/0" do
      test "launches and returns an instance of the default Browser" do
        page =
          Playwright.launch()
          |> Browser.new_page()

        :timer.sleep(2000)

        response =
          page
          |> Page.goto("http://example.com")

        :timer.sleep(2000)
        assert Response.ok(response)
      end
    end
  end
end
