defmodule Playwright.SDK.Channel.Session do
  @moduledoc false
  use GenServer
  import Playwright.SDK.Extra.Atom
  alias Playwright.SDK.Channel

  defstruct [:bindings, :catalog, :connection]

  # module init
  # ---------------------------------------------------------------------------

  def child_spec(transport) do
    %{
      id: {__MODULE__, Channel.SessionID.next()},
      start: {__MODULE__, :start_link, [transport]},
      restart: :transient
    }
  end

  def start_link(transport) do
    GenServer.start_link(__MODULE__, transport)
  end

  # @impl init
  # ---------------------------------------------------------------------------

  @impl GenServer
  def init(transport) do
    pid = self()
    root = %{session: pid}
    {:ok, catalog} = Channel.Catalog.start_link(root)
    {:ok, connection} = Channel.Connection.start_link({pid, transport})

    {:ok,
     %__MODULE__{
       bindings: %{},
       catalog: catalog,
       connection: connection
     }}
  end

  # module API
  # ---------------------------------------------------------------------------

  def bind(session, {guid, event_type}, callback) do
    GenServer.cast(session, {:bind, {guid, event_type}, callback})
  end

  def bindings(session) do
    GenServer.call(session, :bindings)
  end

  def catalog(session) do
    GenServer.call(session, :catalog)
  end

  def connection(session) do
    GenServer.call(session, :connection)
  end

  # @impl callbacks
  # ---------------------------------------------------------------------------

  @impl GenServer
  def handle_call(:bindings, _, %{bindings: bindings} = state) do
    {:reply, bindings, state}
  end

  @impl GenServer
  def handle_call(:catalog, _, %{catalog: catalog} = state) do
    {:reply, catalog, state}
  end

  @impl GenServer
  def handle_call(:connection, _, %{connection: connection} = state) do
    {:reply, connection, state}
  end

  @impl GenServer
  def handle_cast({:bind, {guid, event_type}, callback}, %{bindings: bindings} = state) do
    key = {guid, as_atom(event_type)}
    updated = (bindings[key] || []) ++ [callback]
    bindings = Map.put(bindings, key, updated)
    {:noreply, %{state | bindings: bindings}}
  end

  # private
  # ---------------------------------------------------------------------------

  defp as_atom(value) when is_atom(value) do
    value
  end

  defp as_atom(value) when is_binary(value) do
    snakecased(value)
  end
end
