defmodule Playwright.SDK.Error do
  @moduledoc false
  # `Error` represents an error message received from the Playwright server
  # that is in response to a `Message` previously sent.

  @enforce_keys [:type, :message]
  defstruct [:type, :message]

  @type t() :: %__MODULE__{
          type: String.t(),
          message: String.t()
        }

  # TODO: determine why we get here...
  # DONE: see comment at error_handling.ex:9.
  def new(type, message) do
    %__MODULE__{
      type: type,
      message: message
    }
  end
end
