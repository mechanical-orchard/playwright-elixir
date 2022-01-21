for index <- 1..10 do
  defmodule Module.concat([Example, Test, "Speaker#{inspect(index)}"]) do
    @name "Speaker#{inspect(index)}"
    use ExUnit.Case, async: true
    use PlaywrightTest.Case
    alias Playwright.{Browser, Page, Response}

    test "joins and becomes a speaker", %{page: page} do
      page |> Page.goto("https://pogo.horse/typescript")
      page |> Page.fill("[name=room-id]", "stampede-demo")
      page |> Page.fill("[name=display-name]", @name)
      page |> Page.click("#join")

      page |> Page.click("#toggle-presenting")
      :timer.sleep(5_000)
      page |> Page.screenshot(%{path: "#{@name}.png"})
      :timer.sleep(5_000)
    end
  end
end

# for index <- 1..7 do
#   defmodule Module.concat([Example, Test, "Listener#{inspect(index)}"]) do
#     @name "Listener#{inspect(index)}"
#     use ExUnit.Case, async: true
#     use PlaywrightTest.Case
#     alias Playwright.{Browser, Page, Response}

#     test "joins and becomes a listener", %{page: page} do
#       page |> Page.goto("https://pogo.horse/typescript")
#       page |> Page.fill("[name=room-id]", "stampede-demo")
#       page |> Page.fill("[name=display-name]", @name)
#       page |> Page.click("#join")

#       :timer.sleep(15_000)
#       page |> Page.screenshot(%{path: "#{@name}.png"})
#       :timer.sleep(15_000)
#     end
#   end
# end
