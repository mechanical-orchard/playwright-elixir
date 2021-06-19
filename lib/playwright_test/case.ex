defmodule PlaywrightTest.Case do
  @moduledoc """
  Use `PlaywrightTest.Case` in an ExUnit test module to start a Playwright
  server and put it into the test context.

  ## Examples

      defmodule Web.DriverTransportTest do
        use ExUnit.Case
        use PlaywrightTest.Case,
          transport: :driver

        describe "features" do
          test "goes to a page", %{browser: browser} do
            page =
              browser
              |> Playwright.Browser.new_page()

            text =
              page
              |> Playwright.Page.goto("https://playwright.dev")
              |> Playwright.Page.text_content(".navbar__title")

            assert text == "Playwright"

            Playwright.Page.close(page)
          end
        end
      end

      defmodule Web.WebSocketTransportTest do
        use ExUnit.Case
        use PlaywrightTest.Case,
          endpoint: ws://localhost:3000,
          transport: :websocket
      end
  """
  defmacro __using__(config \\ %{}) do
    quote do
      setup_all do
        env = Application.get_all_env(:playwright)
        config = Keyword.merge(env, unquote(config))

        {:ok, _} = Application.ensure_all_started(:playwright)

        if Keyword.has_key?(config, :headless) do
          Application.put_env(:playwright, :headless, Keyword.get(config, :headless))
        end

        case Keyword.get(config, :transport, :driver) do
          :driver ->
            {connection, browser} = Playwright.BrowserType.launch()

            [
              connection: connection,
              browser: browser,
              transport: :driver
            ]

          :websocket ->
            endpoint = Keyword.get(config, :endpoint)
            {connection, browser} = Playwright.BrowserType.connect(endpoint)

            [
              connection: connection,
              browser: browser,
              transport: :websocket
            ]
        end
      end
    end
  end
end
