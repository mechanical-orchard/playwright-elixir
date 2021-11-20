defmodule Playwright.Runner.EventInfo do
  @moduledoc false
  alias Playwright.Extra

  @type t() :: %__MODULE__{
          target: struct(),
          type: atom(),
          params: map()
        }

  @enforce_keys [:target, :type, :params]
  defstruct [:target, :type, :params]

  def new(target, type, params \\ %{}) do
    %__MODULE__{
      target: target,
      type: as_atom(type),
      params: params
    }
  end

  # private
  # ---------------------------------------------------------------------------

  defp as_atom(value) when is_atom(value) do
    value
  end

  defp as_atom(value) when is_binary(value) do
    Extra.Atom.snakecased(value)
  end
end
