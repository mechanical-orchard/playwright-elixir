defmodule Playwright.Runner.EventInfo do
  @moduledoc false
  alias Playwright.Extra

  @enforce_keys [:target, :type, :params]
  defstruct [:target, :type, :params]

  def new(target, type, params \\ %{}) do
    %__MODULE__{
      target: target,
      type: Extra.Atom.from_string(type),
      params: params
    }
  end
end
