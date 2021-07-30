defmodule Playwright.Runner.Katalog do
  use GenServer
  require Logger

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  def get(pid, params) do
    GenServer.call(pid, {:get, params})
  end

  def put(pid, params) do
    GenServer.cast(pid, {:put, params})
  end

  # ---

  defstruct [:calls, :store, :_legacy_]

  def init([root]) do
    {
      :ok,
      %__MODULE__{
        calls: %{},
        store: %{"Root" => root},
        # _legacy_: legacy
      }
    }
  end

  def handle_call({:get, {guid}}, caller, %{calls: calls} = state) do
    Logger.warn("handle_call:get w/ guid: #{inspect(guid)}")
    {:noreply, %{state | calls: Map.put(calls, guid, caller)}}
  end

  def handle_cast({:put, {guid, player}}, %{store: store} = state) do
    Logger.warn("handle_call:put w/ guid: #{inspect(guid)}")
    {:noreply, %{state | store: Map.put(store, guid, player)}}
  end
end
