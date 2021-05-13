defmodule Playwright.BrowserType do
  require Logger

  use Supervisor
  alias Playwright.{Connection}

  # API
  # ---------------------------------------------------------------------------

  defstruct(connection: nil)

  def connect(ws_endpoint) do
    {:ok, pid} = start_link([ws_endpoint])

    pid
  end

  # @impl
  # ---------------------------------------------------------------------------

  def init(args) do
    children = [
      {Connection, args}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # private
  # ---------------------------------------------------------------------------

  defp start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end
end

# defmodule Playwright.BrowserType do
#   defmacro __using__() do
#     quote do
#       @behaviour Playwright.BrowserType

#       require Logger
#       use GenServer

#       def start_link(opts \\ []) do
#         Playwright.BrowserType.start_link(__MODULE__, opts)
#       end
#     end
#   end
# end

# use GenServer

# alias Playwright.{Connection, Transport}

# defstruct(connection: nil)

# # API
# # ---------------------------------------------------------------------------

# def start_link([ws_endpoint]) do
#   GenServer.start_link(__MODULE__, ws_endpoint)
# end

# def send(self, message) do
#   GenServer.call(self, {:send, message})
# end

# def show(self) do
#   GenServer.call(self, :show)
# end

# # @impl
# # ---------------------------------------------------------------------------

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
