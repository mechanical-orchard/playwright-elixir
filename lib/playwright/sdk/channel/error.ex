defmodule Playwright.SDK.Channel.Error do
  @moduledoc false
  # `Error` represents an error message received from the Playwright server that is
  # in response to a `Message` previously sent.
  alias Playwright.SDK.Channel

  @enforce_keys [:message]
  defstruct [:message]

  @type t() :: %__MODULE__{message: String.t()}

  def new(%{error: error}, _catalog) do
    %Channel.Error{
      message: String.split(error.message, "\n") |> List.first()
    }
  end
end
