import Config

endpoint = System.get_env("PLAYWRIGHT_ENDPOINT", "ws://localhost:3000/playwright")
transport = String.to_atom(System.get_env("PLAYWRIGHT_TRANSPORT", "driver"))

config :playwright,
  endpoint: endpoint,
  transport: transport

config :playwright, LaunchOptions,
  channel: System.get_env("PLAYWRIGHT_CHANNEL", nil),
  headless: String.to_atom(System.get_env("PLAYWRIGHT_HEADLESS", "true")) != false

if config_env() == :test do
  config :logger, level: :info
end
