defmodule Playwright.Channel.Error do
  @moduledoc false
  # `Error` represents an error message received from the Playwright server that is
  # in response to a `Message` previously sent.
  alias Playwright.Channel.Error

  @enforce_keys [:message]
  defstruct [:message]

  @type t() :: %__MODULE__{message: String.t()}

  def new(%{error: error}, _catalog) do
    %Error{
      message: String.split(error.message, "\n") |> List.first()
    }
  end
end
