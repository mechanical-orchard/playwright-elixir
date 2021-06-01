defmodule Playwright.Connection do
  use GenServer
  alias Playwright.ChannelOwner.Root
  alias Playwright.Client.Transport

  @mod __MODULE__

  # API
  # ----------------------------------------------------------------------------

  def start_link(config, opts \\ []) do
    name = Keyword.get(opts, :name, @mod)
    GenServer.start_link(__MODULE__, config, name: name)
  end

  def get(name \\ @mod, {:guid, _guid} = args) do
    GenServer.call(name, {:get, args})
  end

  # @impl
  # ----------------------------------------------------------------------------

  @type transport_module :: Transport.Driver | Transport.WebSocket
  @type transport_config :: {transport_module, [term()]}

  defstruct(catalog: %{})

  @impl GenServer
  @spec start_link([transport_config]) :: GenServer.on_start()
  def init(_config) do
    {:ok,
     %@mod{
       catalog: %{
         "Root" => Root.new(self())
       }
     }}
  end

  @impl GenServer
  # @spec start_link([transport_config]) :: GenServer.on_start()
  def handle_call({:get, {:guid, guid}}, _from, %{catalog: catalog} = state) do
    {:reply, catalog[guid], state}
  end

  # private
  # ----------------------------------------------------------------------------
end
