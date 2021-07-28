defmodule Test.Support.AssetsServer do
  @moduledoc """
  An simple server to provide assets needed for tests. The assets are acquired
  from the main [Playwright project](https://github.com/microsoft/playwright)
  and are imported/updated here as follows:

  ```shell
  source="https://github.com/microsoft/playwright.git"
  target="test/support/assets_server/assets"

  git remote add --fetch --master master --no-tags playwright ${source}
  git read-tree --prefix=${target} -u playwright/master:tests/assets
  ```
  """
  require Logger
  use Application
  alias Test.Support.AssetsServer

  # @impl
  # ----------------------------------------------------------------------------

  @impl Application
  def start(_type, _args) do
    Logger.info("Starting assets server")

    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: AssetsServer.Router,
        options: [
          port: 3002,
          ip: {0, 0, 0, 0}
        ]
      )
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__)
  end
end
