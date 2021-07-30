defmodule Playwright.Runner.Catalog do
  @moduledoc false

  use GenServer
  require Logger

  # API
  # ----------------------------------------------------------------------------

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def add(pid, resource) do
    Logger.warn("Catalog.add/2 pid: #{inspect(pid)}")
    IO.inspect([pid, resource])
    GenServer.cast(pid, {:add, resource})
  end

  def get(pid, guid) do
    Logger.warn("Catalog.get pid: #{inspect(pid)}")
    GenServer.call(pid, {:get, guid})
  end

  # def put(pid, key, entry) do
  #   Logger.warn("Catalog.put/3")
  #   IO.inspect([pid, key, entry])
  #   # subscriber = Map.get(catalog.awaiting, key)

  #   # if subscriber do
  #   #   found!(catalog, entry, subscriber)
  #   # end

  #   # %__MODULE__{catalog | dictionary: Map.put(catalog.dictionary, key, entry)}
  # end

  # @impl
  # ----------------------------------------------------------------------------

  @enforce_keys [:dictionary]
  defstruct [:dictionary, :awaiting]

  def init(root) do
    {
      :ok,
      %__MODULE__{
        dictionary: %{
          "Root" => root
        },
        awaiting: %{}
      }
    }
  end

  def handle_call({:get, guid}, caller, state) do
    {:noreply, await(state, guid, caller)}
  end

  # `.add` should fail if it exists, `.put` should update (get, merge, write)
  def handle_cast({:add, item}, %{awaiting: awaiting, dictionary: dictionary} = state) do
    caller = Map.get(awaiting, item.guid)

    if caller do
      found!(state, item, caller)
    end

    {:noreply, %{state | dictionary: Map.put(dictionary, item.guid, item)}}
  end
    #   subscriber = Map.get(catalog.awaiting, key)

  #   if subscriber do
  #     found!(catalog, entry, subscriber)
  #   end

  #   %__MODULE__{catalog | dictionary: Map.put(catalog.dictionary, key, entry)}


  # ---

  # def delete(catalog, key) do
  #   %__MODULE__{catalog | dictionary: Map.delete(catalog.dictionary, key)}
  # end

  # def fetch(catalog, key) do
  #   Map.fetch(catalog.dictionary, key)
  # end

  # def find(catalog, filter, default \\ nil) do
  #   case select(values(catalog), filter, []) do
  #     [] ->
  #       default
  #     result ->
  #       result
  #   end
  # end

  # def get(catalog, key) do
  #   Map.get(catalog.dictionary, key)
  # end

  # # when is struct...
  # def put(catalog, entry) do
  #   put(catalog, entry.guid, entry)
  # end

  # def put(catalog, key, entry) do
  #   subscriber = Map.get(catalog.awaiting, key)

  #   if subscriber do
  #     found!(catalog, entry, subscriber)
  #   end

  #   %__MODULE__{catalog | dictionary: Map.put(catalog.dictionary, key, entry)}
  # end

  # def values(catalog) do
  #   Map.values(catalog.dictionary)
  # end

  # private
  # ---------------------------------------------------------------------------

  defp await(state, guid, caller) do
    Logger.info("Catalog.await guid: #{inspect(guid)} in store: #{inspect(state.dictionary)}")

    case Map.get(state.dictionary, guid) do
      nil -> await!(state, guid, caller)
      val -> found!(state, val, caller)
    end
  end

  defp await!(state, key, caller) do
    %__MODULE__{state | awaiting: Map.put(state.awaiting, key, caller)}
  end

  defp found!(state, entry, caller) do
    GenServer.reply(caller, entry)
    state
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
end
