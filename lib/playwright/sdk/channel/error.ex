defmodule Playwright.SDK.Channel.Error do
  @moduledoc false
  # `Error` represents an error message received from the Playwright server
  # that is in response to a `Message` previously sent.
  alias Playwright.SDK.Channel

  @enforce_keys [:type, :message]
  defstruct [:type, :message]

  @type t() :: %__MODULE__{
          type: String.t(),
          message: String.t()
        }

  def new(%{error: %{name: name, message: message} = _error}, _catalog) do
    %Channel.Error{
      type: name,
      message: String.split(message, "\n") |> List.first()
    }
  end

  # TODO: determine why we get here...
  # DONE: see comment at error_handling.ex:9.
  def new(%{error: %{message: message} = _error}, _catalog) do
    %Channel.Error{
      type: "NotImplementedError",
      message: String.split(message, "\n") |> List.first()
    }
  end
end
