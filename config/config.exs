import Config

endpoint = System.get_env("PLAYWRIGHT_ENDPOINT", "ws://localhost:3000/playwright")
headless = String.to_atom(System.get_env("PLAYWRIGHT_HEADLESS", "true")) != false
transport = String.to_atom(System.get_env("PLAYWRIGHT_TRANSPORT", "driver"))
run_asset_server = String.to_atom(System.get_env("PLAYWRIGHT_RUN_ASSET_SERVER", to_string(transport == :driver)))

config :playwright,
  endpoint: endpoint,
  headless: headless,
  transport: transport,
  run_asset_server: run_asset_server

if config_env() == :test do
  config :logger, level: :info
end
