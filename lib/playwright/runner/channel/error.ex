defmodule Playwright.Runner.Channel.Error do
  @moduledoc false
  # `Error` represents an error message received from the Playwright server that is
  # in response to a `Command` previously sent.
  alias Playwright.Runner.Channel.Error

  @enforce_keys [:message]
  defstruct [:message]

  def new(%{error: error}, _catalog) do
    # message = String.split(error.message, "\n") |> List.first()
    # raise message
    %Error{message: String.split(error.message, "\n") |> List.first()}
  end
end
