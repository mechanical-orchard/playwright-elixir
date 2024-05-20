defmodule Playwright.SDK.ConfigTest do
  use ExUnit.Case, async: true
  alias Playwright.SDK.Config

  require Logger

  # NOTE: We short-circuit the calls here and jump to `config_for` in order to
  # avoid setting state on the *actual* env keys. Otherwise, it's challenging to
  # eliminate test pollution.
  describe "launch_options/0" do
    test "reads from `:playwright, LaunchOptions` configuration", context do
      config = helper(context, headless: false)
      assert config == %{headless: false}
    end

    test "excludes `nil` entries", context do
      config = helper(context, channel: nil)
      assert config == %{}
    end

    test "excludes empty entries", context do
      config = helper(context, args: [])
      assert config == %{}
    end

    test "excludes unrecognized attributes", context do
      config = helper(context, bogus: "value")
      assert config == %{}
    end

    defp helper(context, settings) do
      key = context.test
      Application.put_env(:playwright, key, settings)
      Config.config_for(key, %Config.Types.LaunchOptions{})
    end
  end

  describe "playwright_test/0" do
    test "respects default 'transport'", context do
      config = Config.config_for(context.test, %Config.Types.PlaywrightTest{})
      assert config == %{transport: :driver}
    end
  end
end
