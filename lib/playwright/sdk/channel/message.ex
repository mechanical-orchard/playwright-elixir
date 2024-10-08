defmodule Playwright.SDK.Channel.Message do
  @moduledoc false
  # `Message` represents communication to and from the Playwright server.
  # The `id` is used to match responses and reply to the caller.

  import Playwright.SDK.Extra.Map
  alias Playwright.SDK.Channel

  @enforce_keys [:guid, :id, :method, :params]

  @derive [Jason.Encoder]
  defstruct [
    :guid,
    :id,
    :method,
    :params,
    :metadata
  ]

  @type t() :: %__MODULE__{
          guid: binary(),
          id: integer(),
          method: binary(),
          params: map()
        }

  # Creates a new `Message` struct. A monotonically-incremented `id` is added.
  # This `id` is used to match `Response` messages to the `Message`. `params`
  # are optional here and are passed to the Playwright server. They may actually
  # be required for the server-side `method` to make sense.
  def new(guid, method, params \\ %{}) do
    %Channel.Message{
      guid: guid,
      id: System.unique_integer([:monotonic, :positive]),
      method: camelize(method),
      params: deep_camelize_keys(params),
      metadata: %{}
    }
  end

  # private
  # ----------------------------------------------------------------------------

  defp camelize(key) when is_binary(key) do
    key
  end

  defp camelize(key) when is_atom(key) do
    Atom.to_string(key) |> Recase.to_camel()
  end
end
