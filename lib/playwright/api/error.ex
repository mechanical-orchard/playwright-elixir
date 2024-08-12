defmodule Playwright.API.Error do
  @moduledoc false
  # `Error` represents an error message received from the Playwright server
  # that is in response to a `Message` previously sent.

  @enforce_keys [:type, :message]
  defstruct [:type, :message]

  @type t() :: %__MODULE__{
          type: String.t(),
          message: String.t()
        }

  def new(%{error: %{name: name, message: message} = _error}, _catalog) do
    %__MODULE__{
      type: name,
      message: String.split(message, "\n") |> List.first()
    }
  end
  def new(%{error: %{message: message} = error}, _catalog) do
    dbg(error)
    %__MODULE__{
      type: "UnknownError",
      message: String.split(message, "\n") |> List.first()
    }
  end
end
