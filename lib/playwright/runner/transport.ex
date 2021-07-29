defmodule Playwright.Runner.Transport do
  @moduledoc false

  defstruct [:mod, :pid]

  def connect(module, config) do
    %__MODULE__{
      mod: module,
      pid: module.start_link!(config)
    }
  end

  def post(transport, data) do
    transport.mod.post(transport.pid, data)
  end
end
