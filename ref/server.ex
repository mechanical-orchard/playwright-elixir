defmodule Playwright.Server do
  use GenServer

  alias Playwright.Session

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  def post(pid, message) do
    # IO.inspect(pid, label: "API pid:")
    # IO.inspect(message, label: "API msg:")
    GenServer.call(pid, {:post, message})
  end

  def handle_call({:post, message}, _, session) do
    # IO.inspect(session, label: "IMP session:")
    # IO.inspect(message, label: "IMP message:")

    session = Session.post(session, message)
    # IO.inspect(session, label: "IM2 session:")
    {:reply, nil, session}
  end

  # ---

  @spec init(any) :: {:ok, %Playwright.Session{calls: 0, message: <<>>, socket: pid}}
  def init(_) do
    {:ok, Session.start("ws://localhost:3000/playwright")}
  end

  # defstruct(session: nil)

  # def start_link(_) do
  #   result = GenServer.start_link(__MODULE__, nil)
  #   IO.inspect(result, label: "result:")
  #   result
  # end

  # # ---

  # def post(session, value) do
  #   IO.inspect(session, label: "post:")
  #   GenServer.call(session, {:post, value})
  # end

  # # ---

  # # @impl GenServer
  # def init(_) do
  #   {:ok, pid} = Session.start_link()

  #   server = %__MODULE__{
  #     session: pid
  #   }

  #   {:ok, server}
  # end

  # # {:reply, reply, new_state}
  # def handle_call({:post, value}, _, session) do
  #   session = Session.post(session, value)
  #   {:reply, nil, session}
  # end
end
