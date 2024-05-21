defmodule Playwright.SDK.Transport.Driver do
  @moduledoc false
  # A transport for negotiating messages with the embedded Playwright `driver`
  # CLI.

  alias Playwright.SDK.Transport.DriverMessage

  defstruct([
    :port,
    :remaining,
    :buffer
  ])

  # module API
  # ----------------------------------------------------------------------------

  def setup(config) do
    cli = Map.get(config, :playwright_cli_path, default_cli())
    cmd = "run-driver"
    port = Port.open({:spawn, "#{cli} #{cmd}"}, [:binary])

    %__MODULE__{
      port: port,
      remaining: 0,
      buffer: ""
    }
  end

  def post(message, %{port: port}) do
    length = byte_size(message)
    padding = <<length::utf32-little>>
    Port.command(port, padding <> message)
  end

  def parse({_port, {:data, data}}, %{buffer: buffer, remaining: remaining}) do
    %{
      frames: frames,
      buffer: buffer,
      remaining: remaining
    } = DriverMessage.parse(data, remaining, buffer, [])

    {frames, %{buffer: buffer, remaining: remaining}}
  end

  # private
  # ----------------------------------------------------------------------------

  defp default_cli do
    Path.join(:code.priv_dir(:playwright), "static/driver.js")
  end
end
