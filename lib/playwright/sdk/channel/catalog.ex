defmodule Playwright.SDK.Channel.Catalog do
  @moduledoc """
  Provides storage and management of ChannelOwner instances.

  `Catalog` implements `GenServer` to maintain state, while domain logic is
  expected to be handled within caller modules such as `Playwright.SDK.Channel`.
  """
  use GenServer
  import Playwright.SDK.Helpers.ErrorHandling
  alias Playwright.SDK.Channel

  defstruct [:awaiting, :storage]

  # module init
  # ---------------------------------------------------------------------------

  @doc """
  Starts a `Playwright.SDK.Channel.Catalog` linked to the current process with the
  given "root" resource.

  ## Return Values

  If the `Catalog` is successfully created and initialized, the function
  returns `{:ok, pid}`, where `pid` is the PID of the running `Catalog` server.

  ## Arguments

  | key/name | type   |         | description |
  | -------- | ------ | ------- | ----------- |
  | `root`   | param  | `map()` | The root resource for items in the `Catalog`. Provides the `Session` for its descendants |
  """
  @spec start_link(map()) :: {:ok, pid()}
  def start_link(root) do
    GenServer.start_link(__MODULE__, root)
  end

  # @impl init
  # ---------------------------------------------------------------------------

  @impl GenServer
  def init(root) do
    {:ok,
     %__MODULE__{
       awaiting: %{},
       storage: %{"Root" => root}
     }}
  end

  # module API
  # ---------------------------------------------------------------------------

  def all(catalog) do
    GenServer.call(catalog, :all)
  end

  @doc """
  Retrieves a resource from the `Catalog` by its `param: guid`.

  If the resource is already present in the `Catalog` that resource is returned
  directly. The desired resource might not yet be in the `Catalog`, in which
  case the request will be considered as "awaiting". An awaiting request will
  later receive a response, when the `Catalog` entry is made, or will time out.

  ## Returns

  - `resource`
  - `{:error, error}`

  ## Arguments

  | key/name   | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `catalog`  | param  | `pid()`    | PID for the Catalog server |
  | `guid`     | param  | `binary()` | GUID to look up |
  | `:timeout` | option | `float()`  | Maximum time to wait, in milliseconds. Defaults to `30_000` (30 seconds). |
  """
  @spec get(pid(), binary(), map()) :: struct() | {:error, Channel.Error.t()}
  def get(catalog, guid, options \\ %{}) do
    with_timeout(options, fn timeout ->
      GenServer.call(catalog, {:get, {:guid, guid}}, timeout)
    end)
  end

  @doc """
  Returns a `List` of resources matching the provided "filter".

  ## Returns

  - [`resource`]
  - []

  ## Arguments

  | key/name  | type   |         | description |
  | --------- | ------ | ------- | ----------- |
  | `catalog` | param  | `pid()` | PID for the Catalog server |
  | `filter`  | param  | `map()` | Attributes for filtering |
  """
  @spec list(pid(), map()) :: [struct()]
  def list(catalog, filter) do
    GenServer.call(catalog, {:list, filter})
  end

  @doc """
  Adds a resource to the `Catalog`, keyed on `:guid`.

  ## Returns

  - `resource` (the same as provided)

  ## Arguments

  | key/name   | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `catalog`  | param  | `pid()`    | PID for the Catalog server |
  | `resource` | param  | `struct()` | The resource to store |
  """
  @spec put(pid(), struct()) :: struct()
  def put(catalog, %{guid: guid} = resource) do
    GenServer.call(catalog, {:put, {:guid, guid}, resource})
  end

  @doc """
  Removes a resource from the `Catalog`, along with its legacy.

  ## Returns

  - `:ok`

  ## Arguments

  | key/name   | type   |            | description |
  | ---------- | ------ | ---------- | ----------- |
  | `catalog`  | param  | `pid()`    | PID for the Catalog server |
  | `guid`     | param  | `binary()` | GUID for the "parent" |
  """
  @spec rm_r(pid(), binary()) :: :ok
  def rm_r(catalog, guid) do
    children = list(catalog, %{parent: get(catalog, guid)})
    children |> Enum.each(fn child -> rm_r(catalog, child.guid) end)

    rm(catalog, guid)
  end

  # @impl callbacks
  # ---------------------------------------------------------------------------

  @impl GenServer
  def handle_call(:all, _, %{storage: storage} = state) do
    {:reply, storage, state}
  end

  @impl GenServer
  def handle_call({:get, {:guid, guid}}, from, %{awaiting: awaiting, storage: storage} = state) do
    item = storage[guid]

    if item do
      {:reply, item, state}
    else
      {:noreply, %{state | awaiting: Map.put(awaiting, guid, from)}}
    end
  end

  @impl GenServer
  def handle_call({:list, filter}, _, %{storage: storage} = state) do
    case filter(Map.values(storage), filter, []) do
      [] ->
        {:reply, [], state}

      result ->
        {:reply, result, state}
    end
  end

  @impl GenServer
  def handle_call({:put, {:guid, guid}, item}, _, %{awaiting: awaiting, storage: storage} = state) do
    {caller, awaiting} = Map.pop(awaiting, guid)
    storage = Map.put(storage, guid, item)

    if caller do
      GenServer.reply(caller, item)
    end

    {:reply, item, %{state | awaiting: awaiting, storage: storage}}
  end

  @impl GenServer
  def handle_call({:rm, guid}, _, %{storage: storage} = state) do
    updated = Map.delete(storage, guid)
    {:reply, :ok, %{state | storage: updated}}
  end

  # private
  # ---------------------------------------------------------------------------

  defp filter([], _attrs, result) do
    result
  end

  defp filter([head | tail], attrs, result) when head.type == "" do
    filter(tail, attrs, result)
  end

  defp filter([head | tail], %{parent: parent, type: type} = attrs, result)
       when head.parent.guid == parent.guid and head.type == type do
    filter(tail, attrs, result ++ [head])
  end

  defp filter([head | tail], %{parent: parent, type: type} = attrs, result)
       when head.parent.guid != parent.guid or head.type != type do
    filter(tail, attrs, result)
  end

  defp filter([head | tail], %{parent: parent} = attrs, result)
       when head.parent.guid == parent.guid do
    filter(tail, attrs, result ++ [head])
  end

  defp filter([head | tail], %{type: type} = attrs, result)
       when head.type == type do
    filter(tail, attrs, result ++ [head])
  end

  defp filter([head | tail], %{guid: guid} = attrs, result)
       when head.guid == guid do
    filter(tail, attrs, result ++ [head])
  end

  defp filter([_head | tail], attrs, result) do
    filter(tail, attrs, result)
  end

  defp rm(catalog, guid) do
    GenServer.call(catalog, {:rm, guid})
  end
end
