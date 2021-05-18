defmodule Playwright.ChannelOwner do
  require Logger

  defmacro __using__(_) do
    quote do
      require Logger
      import Playwright.ChannelOwner
    end
  end

  # API
  # ---------------------------------------------------------------------------

  defstruct(connection: nil, parent: nil, type: nil, guid: nil, initializer: nil)

  @spec channel_owner(
          atom | %{:connection => atom | pid | port | {atom, atom}, optional(any) => any},
          map
        ) ::
          %Playwright.ChannelOwner{
            connection: any,
            guid: any,
            initializer: any,
            parent:
              atom | %{:connection => atom | pid | port | {atom, atom}, optional(any) => any},
            type: any
          }
  def channel_owner(
        parent,
        %{"guid" => guid, "type" => type, "initializer" => initializer} = _args
      ) do
    Logger.info("here is a new #{inspect(type)}; it's parent is: #{inspect(parent)}")

    state = %__MODULE__{
      connection: parent.connection,
      parent: parent,
      type: type,
      guid: guid,
      initializer: initializer
    }

    send(parent.connection, {:register, {guid, state}})
    state
  end
end
