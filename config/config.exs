import Config

config :playwright, ConnectOptions, ws_endpoint: System.get_env("PLAYWRIGHT_ENDPOINT", "ws://localhost:3000/chromium")

config :playwright, LaunchOptions,
  channel: System.get_env("PLAYWRIGHT_CHANNEL", nil),
  headless: String.to_atom(System.get_env("PLAYWRIGHT_HEADLESS", "true")) != false

config :playwright, PlaywrightTest, transport: String.to_atom(System.get_env("PLAYWRIGHT_TRANSPORT", "driver"))

if config_env() == :test do
  config :logger, level: :info
end

if config_env() == :dev do
  esbuild = fn args ->
    [
      args: args,
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]
  end

  common_args = ~w(--bundle --platform=node)
  playwright_core = ["./js/playwright_elixir"] ++ common_args
  playwright_cli = ["./node_modules/playwright-core/lib/cli/cli.js"] ++ common_args

  config :esbuild,
    version: "0.13.10",
    module:
      esbuild.(
        playwright_core ++
          ~w(--format=esm --sourcemap --outfile=../priv/static/playwright_elixir.esm.js)
      ),
    main:
      esbuild.(
        playwright_core ++
          ~w(--format=cjs --sourcemap --outfile=../priv/static/playwright_elixir.cjs.js)
      ),
    cdn:
      esbuild.(
        playwright_core ++
          ~w(--format=iife --target=es2016 --global-name=playwright_elixir --outfile=../priv/static/playwright_elixir.js)
      ),
    cdn_min:
      esbuild.(
        playwright_core ++
          ~w(--format=iife --target=es2016 --global-name=playwright_elixir --minify --outfile=../priv/static/playwright_elixir.min.js)
      ),
    cli:
      esbuild.(
        playwright_cli ++
          ~w(--format=iife --target=es2016 --outfile=../priv/static/playwright_cli.js)
      )
end
