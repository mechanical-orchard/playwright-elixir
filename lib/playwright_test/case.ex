defmodule PlaywrightTest.Case do
  @moduledoc """
  Use `PlaywrightTest.Case` in an ExUnit test module to start a Playwright server
  and put it into the test context.

  ## Example

      defmodule Web.FeatureTest do
        use ExUnit.Case
        use PlaywrightTest.Case, transport: :driver, headless: true

        describe "features" do
          test "goes to a page", %{browser: browser} do
            _page =
              Pw.Browser.new_page(browser)
              |> Pw.Page.goto("https://playwright.dev")
          end
        end
      end

      defmodule Web.BrowserlessTest do
        use ExUnit.Case
        use PlaywrightTest.Case, transport: :websocket,
      end
  """
  defmacro __using__(config \\ %{}) do
    quote do
      alias Playwright.ChannelOwner.Browser
      alias Playwright.ChannelOwner.BrowserContext
      alias Playwright.ChannelOwner.BrowserType
      alias Playwright.ChannelOwner.Page
      alias Playwright.Test.Support.AssetsServer

      setup_all do
        config = unquote(config)

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

          # NOTE:
          # This will become more configurable; it currently assumes
          # Playwright is running in a (customized) Docker container.
          :websocket ->
            endpoint = Keyword.get(config, :playwright_endpoint, "ws://localhost:3000/playwright")
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
