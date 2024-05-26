import Config

config :playwright, ConnectOptions, ws_endpoint: System.get_env("PLAYWRIGHT_ENDPOINT", "ws://localhost:3000/chromium")

config :playwright, LaunchOptions,
  channel: System.get_env("PLAYWRIGHT_CHANNEL", nil),
  headless: String.to_atom(System.get_env("PLAYWRIGHT_HEADLESS", "true")) != false,
  driver_path: Path.expand("../priv/static/driver.js", __DIR__)

config :playwright, PlaywrightTest, transport: String.to_atom(System.get_env("PLAYWRIGHT_TRANSPORT", "driver"))

if config_env() == :test do
  config :logger, level: :info

  config :playwright_assets,
    port: 4002
end

if config_env() == :dev do
  config :esbuild,
    version: "0.14.0",
    cli: [
      args: ~w(
          driver=./node_modules/playwright/cli.js
          --bundle
          --platform=node
          --format=cjs
          --target=es2016
          --outdir=../priv/static
          --external:*.png
          --external:*/gridBrowserWorker.js
          --external:*/gridWorker.js
          --external:*/loader
          --external:@playwright/test/*
        ),
      cd: Path.expand("../assets", __DIR__)
    ]

  # NOTE that the following are not actually copied and made available:
  #   - playwright-core/lib/grid/gridBrowserWorker.js
  #   - playwright-core/lib/grid/gridWorker.js
  #   - playwright-core/lib/server/electron/loader.js
end
