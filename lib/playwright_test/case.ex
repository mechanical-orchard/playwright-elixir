defmodule PlaywrightTest.Case do
  @moduledoc """
  Use `PlaywrightTest.Case` in an ExUnit test module to start a Playwright
  server and put it into the test context.

  ## Examples

      defmodule Web.DriverTransportTest do
        use ExUnit.Case
        use PlaywrightTest.Case,
          headless: false,
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
          transport: :websocket
      end
  """
  defmacro __using__(options \\ %{}) do
    quote do
      alias Playwright.Runner.Config

      setup_all do
        inline_options = unquote(options) |> Enum.into(%{})
        launch_options = Map.merge(Config.launch_options(), inline_options)
        runner_options = Map.merge(Config.playwright_test(), inline_options)

        Application.put_env(:playwright, LaunchOptions, launch_options)

        {:ok, _} = Application.ensure_all_started(:playwright)

        case runner_options.transport do
          :driver ->
            {connection, browser} = Playwright.BrowserType.launch()

            [
              connection: connection,
              browser: browser,
              transport: :driver
            ]

          :websocket ->
            options = Config.connect_options()
            {connection, browser} = Playwright.BrowserType.connect(options.ws_endpoint)

            [
              connection: connection,
              browser: browser,
              transport: :websocket
            ]
        end
      end

      setup %{browser: browser} do
        page = Playwright.Browser.new_page(browser)

        on_exit(:ok, fn ->
          Playwright.Page.close(page)
        end)

        [page: page]
      end
    end
  end
end
