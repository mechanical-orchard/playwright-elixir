defmodule Playwright.Connection do
  use GenServer
  alias Playwright.ChannelOwner.Root

  @mod __MODULE__

  # API
  # ----------------------------------------------------------------------------

  # Transport.Driver | Transport.WebSocket
  @type transport_module :: module()
  @type transport_config :: {transport_module, [term()]}

  defstruct(catalog: %{}, queries: %{}, transport: %{})

  @spec start_link([transport_config]) :: GenServer.on_start()
  def start_link(config, opts \\ []) do
    name = Keyword.get(opts, :name, @mod)
    GenServer.start_link(__MODULE__, config, name: name)
  end

  def get(name \\ @mod, args)

  def get(name, {:guid, _guid} = args) do
    GenServer.call(name, {:get, args})
  end

  # @impl
  # ----------------------------------------------------------------------------

  @impl GenServer
  def init([{transport_module, config}]) do
    {:ok,
     %@mod{
       catalog: %{
         "Root" => Root.new(self())
       },
       transport: %{
         mod: transport_module,
         pid: transport_module.start_link!([self()] ++ config)
       }
     }}
  end

  @impl GenServer
  def handle_call({:get, {:guid, guid}}, from, %{catalog: catalog, queries: queries} = state) do
    case catalog[guid] do
      nil ->
        {:noreply, %{state | queries: Map.put(queries, guid, from)}}

      item ->
        {:reply, item, state}
    end
  end

  # private
  # ----------------------------------------------------------------------------
end
