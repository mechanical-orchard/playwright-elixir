defmodule Playwright.Session do
  alias Playwright.Socket

  defstruct(socket: nil, calls: 0, message: "", stuff: "")

  @spec start(binary | WebSockex.Conn.t()) :: %Playwright.Session{
          calls: 0,
          message: <<>>,
          socket: pid,
          stuff: <<>>
        }
  def start(url) do
    {:ok, pid} = Socket.start_link(url)

    %__MODULE__{
      socket: pid
    }
  end

  def post(session, message) do
    # %Playwright.Session{calls: 2, message: "la", socket: #PID<0.212.0>}
    # IO.inspect(session, label: "session...")

    stuff = Socket.post(session.socket, message)

    session
    |> Map.put(:calls, session.calls + 1)
    |> Map.put(:message, message)
    |> Map.put(:stuff, stuff)
  end

  # use GenServer

  # alias Playwright.Socket

  # defstruct(socket: nil)

  # # API
  # # ---------------------------------------------------------------------------

  # def start_link do
  #   GenServer.start_link(__MODULE__, :ok)
  # end

  # def post(session, value) do
  #   GenServer.call(session, {:post, value})
  # end

  # # @impl (GenServer callbacks)
  # # ---------------------------------------------------------------------------

  # def init(_) do
  #   {:ok, pid} = Socket.start_link("ws://localhost:3000/playwright")

  #   session = %__MODULE__{
  #     socket: pid
  #   }

  #   {:ok, session}
  # end

  # def handle_call({:post, value}, _, session) do
  #   IO.inspect(session)
  #   IO.inspect(value)
  #   # session = Session.apply(session)
  #   {:reply, :ok, session}
  # end
end
