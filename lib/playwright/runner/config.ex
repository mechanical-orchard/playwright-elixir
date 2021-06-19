defmodule Playwright.Runner.Config do
  @moduledoc """
  Configuration for Playwright.

  Overview:

      config :playwright, LaunchOptions, [...]
  """

  alias Playwright.Extra

  defstruct [:args, :channel, :chromium_sandbox, :devtools, :downloads_path, :headless]

  @doc """
  Optional configuration for Playwright browser launch commands.

  This function should not typically be used by consumers of the library.
  Rather, configuration is provided via `config :playwright` statements, which
  are utilized by `Playwright.Runner` at runtime.

  ## Option: `args`

  Additional arguments to pass to the browser instance. The list of Chromium
  flags may be found [online](http://peter.sh/experiments/chromium-command-line-switches/).

  e.g.,

      config :playwright, LaunchOptions,
        args: [
          "--use-fake-ui-for-media-stream",
          "--use-fake-device-for-media-stream"
        ]

  ## Option: `channel`

  Browser distribution channel for Chromium. Supported values are:

    - `chrome`
    - `chrome-beta`
    - `chrome-dev`
    - `chrome-canary`
    - `msedge`
    - `msedge-beta`
    - `msedge-dev`
    - `msedge-canary`

  Read more about using Google Chrome and Microsoft Edge
  [online](https://playwright.dev/docs/browsers#google-chrome--microsoft-edge).

  e.g.,

      config :playwright, LaunchOptions,
        channel: "chrome"

  ## Option: `chromium_sandbox`

  Enable Chromium sandboxing. Defaults to `false`.

  e.g.,

      config :playwright, LaunchOptions,
        chromium_sandbox: true

  ## Option: `devtools`

  With Chromium, specifies whether to auto-open a "Developer Tools" panel for
  each tab. If this option is `true`, the `headless` option will be set to
  `false`.

  Defaults to `false`.

  e.g.,

      config :playwright, LaunchOptions,
        devtools: true

  ## Option: `headless`

  Specifies whether to run the browser in "headless" mode. See:

    - [headless Chromium](https://developers.google.com/web/updates/2017/04/headless-chrome)
    - [headless Firefox](https://developer.mozilla.org/en-US/docs/Mozilla/Firefox/Headless_mode)

  Defaults to `true` unless the `devtools` option is `true`.

  e.g.,

      config :playwright, LaunchOptions,
        headless: false # e.g., see a browser window pop up in "dev".

  ## Option: `downloads_path`

  **WARNING: not yet implemented**

  If specified, accepted downloads are written to this directory. Otherwise, a
  temporary directory is created and is removed when the browser is closed.

  e.g.,

      config :playwright, LaunchOptions,
        downloads_path: "./doc/downloads"

  ## Option: `env`

  **WARNING: not yet implemented**

  Environment variables that will be made visible to the browser. Defaults to
  `System.get_env/0`.

  e.g.,

      config :playwright, LaunchOptions,
        env: ["DEBUG", "true"]

  ## Option: `executable_path`

  A filesystem path to a browser executable to run instead of the bundled
  browser. If `executable_path` is a relative path, then it is resolved relative
  to the current working directory.

  **Chromium-only**

  Playwright can also be used to control the Google Chrome or Microsoft Edge
  browsers, but it works best with the bundled version of Chromium. There is no
  guarantee that it will work with any other version.

  Use `executable_path` option with extreme caution.

  e.g.,

      config :playwright, LaunchOptions,
        executable_path: "/Applications/..."
  """
  @spec launch_options() :: %{
          args: [binary()],
          channel: binary(),
          chromium_sandbox: boolean(),
          devtools: boolean(),
          downloads_path: binary(),
          env: any(),
          executable_path: binary(),
          headless: boolean()
        }
  def launch_options do
    config_for(LaunchOptions) || %{}
  end

  # private
  # ----------------------------------------------------------------------------

  defp config_for(key) do
    configured =
      Application.get_env(:playwright, key, %{})
      |> Enum.into(%{})

    build(configured) |> clean()
  end

  defp build(source) do
    result =
      for key <- Map.keys(%__MODULE__{}) |> Enum.reject(fn key -> key == :__struct__ end),
          into: %{} do
        {key, Map.get(source, key)}
      end

    Map.merge(%__MODULE__{}, result)
  end

  defp clean(source) do
    Map.from_struct(source)
    |> Extra.Map.deep_camelize_keys()
    |> Enum.reject(fn
      {_key, value} when is_nil(value) -> true
      {_key, value} when is_list(value) -> value == []
      _otherwise_ -> false
    end)
    |> Enum.into(%{})
  end
end
