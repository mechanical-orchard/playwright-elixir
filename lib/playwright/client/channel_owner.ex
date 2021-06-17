defmodule Playwright.Client.ChannelOwner do
  @moduledoc false
  @base [connection: nil, parent: nil, type: nil, guid: nil, initializer: nil]

  defmacro __using__(extra \\ []) do
    fields = @base ++ extra

    quote do
      @derive {Inspect, only: [:guid, :initializer] ++ Keyword.keys(unquote(extra))}

      alias Playwright.Client.Channel
      alias Playwright.Client.Connection

      defstruct unquote(fields)

      @type t() :: %__MODULE__{}

      @doc false
      def channel_owner(
            parent,
            %{guid: guid, type: type, initializer: initializer} = args
          ) do
        %__MODULE__{
          connection: parent.connection,
          parent: parent,
          type: type,
          guid: guid,
          initializer: initializer
        }
      end
    end
  end
end
