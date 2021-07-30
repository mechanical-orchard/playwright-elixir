defmodule Playwright.Runner.Channel.Command do
  @moduledoc """
  `Command` represents an imperative sent to the Playwright server.
  """
  alias Playwright.Runner.Channel.Command

  @enforce_keys [:guid, :id, :method, :params]

  @derive [Jason.Encoder]
  defstruct [
    :guid,
    :id,
    :method,
    :params
  ]

  @type t() :: %__MODULE__{
          guid: binary(),
          id: integer(),
          method: binary(),
          params: map()
        }

  @doc """
  Creates a new `Command` struct. A monotonically-incremented `id` is added.
  This `id` is used to match `Response` messages to the `Command`.
  """
  def new(guid, method, params \\ %{}) do
    %Command{
      guid: guid,
      id: System.unique_integer([:monotonic, :positive]),
      method: method,
      params: params
    }
  end
end
