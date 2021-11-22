defmodule Playwright.Runner.Transport do
  @moduledoc false

  defstruct [:mod, :pid]

  def connect(module, arg) do
    %__MODULE__{
      mod: module,
      pid: module.start_link!(arg)
    }
  end

  def post(transport, data) do
    transport.mod.post(transport.pid, data)
  end
end
