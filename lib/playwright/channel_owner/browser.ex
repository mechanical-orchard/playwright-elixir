defmodule Playwright.ChannelOwner.Browser do
  require Logger

  defstruct(parent: nil, type: nil, guid: nil, initializer: nil)

  def init(connection, parent, type, guid, initializer) do
    Logger.info("Init browser for connection: #{inspect(connection)}")

    %__MODULE__{
      parent: parent,
      type: type,
      guid: guid,
      initializer: initializer
    }
  end
end

# defmodule Playwright.Client.Browser do
#   require Logger

#   use Supervisor
#   alias Playwright.{Connection}

#   # API
#   # ---------------------------------------------------------------------------

#   defstruct(connection: nil)

#   def connect(ws_endpoint) do
#     {:ok, pid} = start_link([ws_endpoint])

#     pid
#   end

#   # @impl
#   # ---------------------------------------------------------------------------

#   def init(args) do
#     children = [
#       {Connection, args}
#     ]

#     Supervisor.init(children, strategy: :one_for_one)
#   end

#   # private
#   # ---------------------------------------------------------------------------

#   defp start_link(args) do
#     Supervisor.start_link(__MODULE__, args)
#   end
# end

# def init(ws_endpoint) do
#   {:ok, connection} = Connection.start_link([ws_endpoint])

#   {:ok,
#    %__MODULE__{
#      connection: connection
#    }}
# end

# def handle_call(:show, _, state) do
#   [{_, transport, _, _}] = Supervisor.which_children(state.connection)
#   result = Transport.show(transport)

#   {:reply, result, state}
# end

# def handle_call({:send, message}, _, state) do
#   [{_, transport, _, _}] = Supervisor.which_children(state.connection)
#   result = Transport.send(transport, message)

#   {:reply, result, state}
# end
