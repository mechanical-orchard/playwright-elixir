import Config

if config_env() == :test do
  config :logger, level: :error
end
