defmodule Playwright.SDK.CLI do
  @moduledoc """
  A wrapper to the Playwright Javascript CLI
  """

  require Logger

  def install do
    Logger.info("Installing playwright browsers and dependencies")
    cli_path = config_cli() || default_cli()

    case detect_os() do
      :arch_linux ->
        Logger.info("Detected Arch Linux, installing dependencies via pacman")
        install_arch_dependencies()
        {result, exit_status} = System.cmd(cli_path, ["install", "chromium", "firefox"])
        Logger.info(result)
        if exit_status != 0, do: raise("Failed to install playwright browsers")

      :ubuntu ->
        Logger.info("Detected Ubuntu/Debian, using --with-deps")
        {result, exit_status} = System.cmd(cli_path, ["install", "--with-deps", "chromium", "firefox"])
        Logger.info(result)
        if exit_status != 0, do: raise("Failed to install playwright browsers")

      :unknown ->
        Logger.warning("Unknown OS, attempting install without system dependencies")
        {result, exit_status} = System.cmd(cli_path, ["install", "chromium", "firefox"])
        Logger.info(result)
        if exit_status != 0, do: raise("Failed to install playwright browsers")
    end
  end

  # private
  # ----------------------------------------------------------------------------

  defp detect_os do
    cond do
      File.exists?("/etc/arch-release") -> :arch_linux
      File.exists?("/etc/debian_version") or File.exists?("/etc/lsb-release") -> :ubuntu
      true -> :unknown
    end
  end

  defp install_arch_dependencies do
    # Playwright browser dependencies for Arch Linux
    packages = [
      "nss",
      "nspr",
      "atk",
      "at-spi2-atk",
      "cups",
      "dbus",
      "libxkbcommon",
      "libxcomposite",
      "libxdamage",
      "libxrandr",
      "mesa",
      "pango",
      "cairo",
      "alsa-lib",
      "libxshmfence"
    ]

    Logger.info("Installing system dependencies: #{Enum.join(packages, ", ")}")

    # Check if running as root or with sudo
    {result, exit_status} =
      if System.get_env("EUID") == "0" or System.get_env("SUDO_USER") do
        System.cmd("pacman", ["-S", "--needed", "--noconfirm" | packages], stderr_to_stdout: true)
      else
        Logger.warning("Not running as root, attempting with sudo")
        System.cmd("sudo", ["pacman", "-S", "--needed", "--noconfirm" | packages], stderr_to_stdout: true)
      end

    Logger.info(result)

    if exit_status != 0 do
      Logger.error("Failed to install system dependencies")
      Logger.warning("You may need to install these packages manually: sudo pacman -S #{Enum.join(packages, " ")}")
    end
  end

  defp config_cli do
    Application.get_env(:playwright, LaunchOptions)[:driver_path]
  end

  defp default_cli do
    Path.join(:code.priv_dir(:playwright), "static/driver.js")
  end
end
