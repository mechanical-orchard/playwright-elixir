defmodule Playwright.Runner.ConfigTest do
  use ExUnit.Case
  alias Playwright.Runner.Config

  require Logger

  setup do
    env = Application.get_all_env(:playright)

    on_exit(:ok, fn ->
      Application.put_all_env(playwright: env)
    end)
  end

  describe "launch_options/0" do
    setup do
      Application.delete_env(:playwright, LaunchOptions)
    end

    test "reads from `:playwright, LaunchOptions` configuration" do
      Application.put_env(:playwright, LaunchOptions, headless: false)
      config = Config.launch_options()
      assert config == %{headless: false}
    end

    test "excludes `nil` entries" do
      Application.put_env(:playwright, LaunchOptions, channel: nil)
      config = Config.launch_options()
      assert config == %{}
    end

    test "excludes empty entries" do
      Application.put_env(:playwright, LaunchOptions, args: [])
      config = Config.launch_options()
      assert config == %{}
    end

    test "excludes unrecognized attributes" do
      Application.put_env(:playwright, LaunchOptions, bogus: "value")
      config = Config.launch_options()
      assert config == %{}
    end

    test "optionally transforms snake-case keys to camelcase" do
      Application.put_env(:playwright, LaunchOptions, downloads_path: "./tmp")

      config = Config.launch_options()
      assert config == %{downloads_path: "./tmp"}

      config = Config.launch_options(true)
      assert config == %{"downloadsPath" => "./tmp"}
    end
  end

  describe "playwright_test/0" do
    setup do
      Application.delete_env(:playwright, PlaywrightTest)
    end

    test "respects default 'transport'" do
      config = Config.playwright_test()
      assert config == %{transport: :driver}
    end
  end
end
