defmodule Playwright.ChannelOwner do
  @base [connection: nil, parent: nil, type: nil, guid: nil, initializer: nil]

  defmacro __using__(fields \\ []) do
    fields = @base ++ fields

    quote do
      alias Playwright.Channel
      alias Playwright.ChannelOwner.BrowserContext
      alias Playwright.Connection

      defstruct unquote(fields)

      def channel_owner(
            parent,
            %{"guid" => guid, "type" => type, "initializer" => initializer} = args
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
