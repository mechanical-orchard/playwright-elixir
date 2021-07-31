defmodule Playwright.Runner.Catalog do
  @moduledoc false
  require Logger

  defmodule Server do
    @moduledoc false
    use GenServer

    @enforce_keys [:callers, :storage]
    defstruct [:callers, :storage]

    def start_link(arg) do
      GenServer.start_link(__MODULE__, arg)
    end

    def get(pid, guid) do
      GenServer.call(pid, {:get, guid})
    end

    def get(pid, guid, caller) do
      # GenServer.call(pid, {:get, {guid, caller}})
      case Server.get(pid, guid) do
        nil ->
          Server.await!(pid, {guid, caller})

        item ->
          Server.found!(pid, {item, caller})
      end
    end

    def put(pid, item) do
      GenServer.call(pid, {:put, item})
    end

    def rm(pid, guid) do
      GenServer.call(pid, {:rm, guid})
    end

    def await!(pid, {guid, caller}) do
      GenServer.call(pid, {:await, {guid, caller}})
    end

    def found!(pid, {item, caller}) do
      GenServer.call(pid, {:found, {item, caller}})
    end

    def values(pid) do
      GenServer.call(pid, {:values})
    end

    # ---

    def find(pid, filter, default \\ nil) do
      GenServer.call(pid, {:find, {filter, default}})
    end

    # ---

    def init(root) do
      {:ok, %__MODULE__{callers: %{}, storage: %{"Root" => root}}}
    end

    def handle_call({:get, guid}, _, %{storage: storage} = state) do
      {:reply, storage[guid], state}
    end

    def handle_call({:put, item}, _, %{callers: callers, storage: storage} = state) do
      with updated <- Map.put(storage, item.guid, item) do
        caller = Map.get(callers, item.guid)

        if caller do
          handle_call({:found, {item, caller}}, nil, state)
        end

        {:reply, updated, %{state | storage: updated}}
      end
    end

    def handle_call({:rm, guid}, _, %{storage: storage} = state) do
      with updated <- Map.delete(storage, guid) do
        {:reply, updated, %{state | storage: updated}}
      end
    end

    def handle_call({:await, {guid, caller}}, _, %{callers: callers} = state) do
      with updated <- Map.put(callers, guid, caller) do
        {:reply, updated, %{state | callers: updated}}
      end
    end

    def handle_call({:found, {item, caller}}, _, state) do
      {:reply, GenServer.reply(caller, item), state}
    end

    def handle_call({:values}, _, %{storage: storage} = state) do
      {:reply, Map.values(storage), state}
    end

    # ---

    # def find(pid, filter, default \\ nil) do
    def handle_call({:find, {filter, default}}, _, %{storage: storage} = state) do
      case select(Map.values(storage), filter, []) do
        [] ->
          {:reply, default, state}

        result ->
          {:reply, result, state}
      end
    end

    # ---

    defp select([], _attrs, result) do
      result
    end

    defp select([head | tail], attrs, result) when head.type == "" do
      select(tail, attrs, result)
    end

    defp select([head | tail], %{parent: parent, type: type} = attrs, result)
         when head.parent.guid == parent.guid and head.type == type do
      select(tail, attrs, result ++ [head])
    end

    defp select([head | tail], %{parent: parent} = attrs, result)
         when head.parent.guid == parent.guid do
      select(tail, attrs, result ++ [head])
    end

    defp select([head | tail], %{type: type} = attrs, result)
         when head.type == type do
      select(tail, attrs, result ++ [head])
    end

    defp select([head | tail], %{guid: guid} = attrs, result)
         when head.guid == guid do
      select(tail, attrs, result ++ [head])
    end

    defp select([_head | tail], attrs, result) do
      select(tail, attrs, result)
    end
  end
end
