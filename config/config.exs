import Config

config :playwright, ConnectOptions, ws_endpoint: System.get_env("PLAYWRIGHT_ENDPOINT", "ws://localhost:3000/chromium")

config :playwright, LaunchOptions,
  channel: System.get_env("PLAYWRIGHT_CHANNEL", nil),
  headless: String.to_atom(System.get_env("PLAYWRIGHT_HEADLESS", "true")) != false,
  playwright_cli_path: Path.expand("../priv/static/driver.js", __DIR__)

config :playwright, PlaywrightTest, transport: String.to_atom(System.get_env("PLAYWRIGHT_TRANSPORT", "driver"))

if config_env() == :test do
  config :logger, level: :info

  config :playwright_assets,
    port: 4002
end
