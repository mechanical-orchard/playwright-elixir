defmodule PlaywrightTest.Case do
  defmacro __using__(config \\ %{}) do
    quote do
      alias Playwright.ChannelOwner.Browser
      alias Playwright.ChannelOwner.BrowserContext
      alias Playwright.ChannelOwner.BrowserType
      alias Playwright.ChannelOwner.Page
      alias Playwright.Test.Support.AssetsServer

      setup_all do
        [transport: transport] = Keyword.merge([transport: :driver], unquote(config))

        case transport do
          :driver ->
            {connection, browser} = Playwright.launch()

            [
              connection: connection,
              browser: browser,
              server: %{
                prefix: "http://localhost:3002"
              }
            ]

          # NOTE:
          # This will become more configurable; it currently assumes
          # Playwright is running in a (customized) Docker container.
          :websocket ->
            {connection, browser} = Playwright.connect("ws://localhost:3000/playwright")

            [
              connection: connection,
              browser: browser,
              server: %{
                prefix: "http://host.docker.internal:3002"
              }
            ]
        end
      end
    end
  end
end
