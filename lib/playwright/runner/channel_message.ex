defmodule Playwright.Runner.ChannelMessage do
  @moduledoc """
  Messages sent to Playwright are packaged up internally in `ChannelMessage`
  data structures.

  Before being dispatched to Playwright, a monotonically
  incremented `id` is added. This `id` is used to match related messages
  received from the server. Those received messages ofter represent a form
  of "completeness".
  """
  @enforce_keys [:guid, :method, :params]

  @derive {Jason.Encoder, only: [:guid, :id, :method, :params]}
  defstruct [
    :guid,
    :id,
    :locals,
    :method,
    :params
  ]

  @type t() :: %__MODULE__{
          guid: binary(),
          id: integer(),
          locals: map() | nil,
          method: binary(),
          params: map()
        }
end
