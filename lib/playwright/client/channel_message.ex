defmodule Playwright.Client.ChannelMessage do
  @moduledoc """
  Messages sent to Playwright are packaged up internally in ChannelMessage data
  structures. Before being dispatched to Playwright, a monotonically incremented
  id is added.
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
