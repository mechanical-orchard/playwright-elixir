defmodule Playwright.SDK.Transport do
  @moduledoc false
  use GenServer
  import Playwright.Extra.Map
  alias Playwright.SDK.Channel.Connection

  defstruct [:connection, :transport]

  # module init
  # ---------------------------------------------------------------------------

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, timeout: 1000)
  end

  def start_link!(arg) do
    {:ok, pid} = start_link(arg)
    pid
  end

  # @impl init
  # ---------------------------------------------------------------------------

  @impl GenServer
  def init({connection, {module, config}}) do
    state = %__MODULE__{
      connection: connection,
      transport: {module, module.setup(config)}
    }

    {:ok, state}
  end

  # module API
  # ---------------------------------------------------------------------------

  # def post(transport, %Message{} = message) do
  def post(transport, %{} = message) do
    GenServer.cast(transport, {:post, message})
  end

  # @impl callbacks
  # ---------------------------------------------------------------------------

  @impl GenServer
  def handle_cast({:post, message}, %{transport: {module, data}} = state) do
    module.post(serialize(message), data)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(info, %{connection: connection, transport: {module, data}} = state) do
    {messages, updates} = module.parse(info, data)

    messages
    |> Enum.each(fn message ->
      Connection.recv(connection, deserialize(message))
    end)

    {:noreply, %{state | transport: {module, Map.merge(data, updates)}}}
  end

  # Transport.Driver...
  # def handle_info({:DOWN, _ref, :port, port, :normal}, state) do
  #   Logger.warning("[transport@#{inspect(self())}] Handled :DOWN message from port: #{inspect(port)}")
  #   {:noreply, state}
  # end

  # def handle_info(msg, state) do
  #   Logger.info("[transport@#{inspect(self())}] Unhandled message: #{inspect(msg)}")
  #   {:noreply, state}
  # end

  # Transport.Websocket...
  # def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
  #   warn("Process went down: #{inspect(pid)}")
  #   {:stop, reason, state}
  # end

  # private
  # ----------------------------------------------------------------------------

  defp deserialize(json) do
    case Jason.decode(json) do
      {:ok, data} ->
        deep_atomize_keys(data)

      error ->
        raise ArgumentError,
          message: "error: #{inspect(error)}; #{inspect(json: Enum.join(for <<c::utf8 <- json>>, do: <<c::utf8>>))}"
    end
  end

  defp serialize(message) do
    Jason.encode!(message)
  end
end
