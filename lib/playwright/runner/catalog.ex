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

    # ---

    def init(root) do
      {:ok, %__MODULE__{callers: %{}, storage: %{"Root" => root}}}
    end

    def handle_call({:get, guid}, _, %{storage: storage} = state) do
      {:reply, storage[guid], state}
    end

    def handle_call({:put, item}, _, %{storage: storage} = state) do
      with updated <- Map.put(storage, item.guid, item) do
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
  end

  # API
  # ----------------------------------------------------------------------------

  @enforce_keys [:dictionary]
  defstruct [:dictionary, :awaiting, :server]

  alias Playwright.Runner.Catalog.Server

  def new(root) do
    {:ok, server} = Server.start_link(root)

    %__MODULE__{
      dictionary: %{
        "Root" => root
      },
      awaiting: %{},
      server: server
    }
  end

  # ----------------------------------------------------------------------------

  def get(catalog, key, caller) do
    case Server.get(catalog.server, key) do
      nil ->
        found?(catalog, key, caller)

      val ->
        found!(catalog, val, caller)
    end
  end

  # NOTE: should probably raise if not found.
  def get!(catalog, guid) do
    Server.get(catalog.server, guid)
  end

  # NOTE: should merge with existing
  def put(catalog, item) do
    caller = Map.get(catalog.awaiting, item.guid)

    if caller do
      found!(catalog, item, caller)
    end

    %__MODULE__{catalog | dictionary: Server.put(catalog.server, item)}
  end

  def delete(catalog, guid) do
    %__MODULE__{catalog | dictionary: Server.rm(catalog.server, guid)}
  end

  # ----------------------------------------------------------------------------

  # def fetch(catalog, guid) do
  #   Map.fetch(catalog.dictionary, guid)
  # end

  def find(catalog, filter, default \\ nil) do
    case select(values(catalog), filter, []) do
      [] ->
        default

      result ->
        result
    end
  end

  # private
  # ---------------------------------------------------------------------------

  defp found?(catalog, guid, caller) do
    %__MODULE__{catalog | awaiting: Server.await!(catalog.server, {guid, caller})}
  end

  defp found!(catalog, item, caller) do
    Server.found!(catalog.server, {item, caller})
    catalog
  end

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

  defp values(catalog) do
    Map.values(catalog.dictionary)
  end
end
