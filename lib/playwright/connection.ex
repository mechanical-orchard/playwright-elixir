defmodule Playwright.Connection do
  require Logger

  use GenServer
  alias Playwright.Transport

  # API
  # ---------------------------------------------------------------------------

  defstruct(objects: %{}, transport: nil)

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  # @impl
  # ---------------------------------------------------------------------------

  def init([ws_endpoint]) do
    state = connect(ws_endpoint)

    # Logger.info("Init - connection, #{inspect(self())}, with state #{inspect(state)}")
    #    [info]  Init - connection: %Playwright.Connection{objects: %{}, transport: #PID<0.214.0>}

    # TODO: remove this from here, and call as Connection.wait_for_object
    {browser, state} = retrieve("Browser", state)
    Logger.info("Init - retrieved browser: #{inspect(browser)} and state: #{inspect(state)}")

    {:ok, state}
  end

  # def handle_call({:wait_for_object, guid}, _, state) do
  #   # state = Map.merge(state, %{waiting_for: guid})
  #   # collect()

  #   {object, state} = retrieve(guid, state)
  #   Logger.info("Retrieved object #{inspect(object)} and have state #{inspect(state)}")

  #   {:reply, object, state}
  # end

  # private
  # ---------------------------------------------------------------------------

  defp connect(ws_endpoint) do
    Logger.info("Connecting to #{inspect(ws_endpoint)}")
    {:ok, pid} = Transport.start_link(ws_endpoint)

    %__MODULE__{
      transport: pid
    }
  end

  defp retrieve(guid, state = %__MODULE__{}) do
    Logger.info("Attempting to retrieve #{inspect(guid)} from #{inspect(state)}")

    # TODO:
    # - Stop using nested `case`
    # - Get rid of this polling, and be more Elixir-like (e.g., `receive`)
    case Map.get(state.objects, guid) do
      nil ->
        result = Transport.poll(state.transport)
        # Logger.info("Poll result: #{inspect(result)}")

        case result do
          nil ->
            :timer.sleep(1000)
            retrieve(guid, state)

          msg ->
            {guid, object} =
              msg
              |> Jason.decode!()
              |> dispatch(state)

            state = Map.put(state, :objects, Map.put(state.objects, guid, object))
            # retrieve(guid, state)
            {object, state}
        end

      object ->
        Logger.info("Retrieved object: #{inspect(object)}")
        {object, state}
    end
  end

  defp dispatch(message = %{"method" => "__create__"}, state) do
    create_remote_object(message["guid"], message["params"], state)
  end

  defp dispatch(message, _) do
    raise "Not implemented: #{inspect(message)}"
  end

  defp create_remote_object(parent_guid, params, state) do
    parent = Map.get(state.objects, parent_guid)
    # Logger.info("Parent: #{inspect(parent)}")

    # TODO: create ChannelOwner `@behaviour`, which all of these `use`.
    guid = params["guid"]
    type = params["type"]
    initializer = params["initializer"]

    # TODO: finish matching implementation
    case type do
      "Browser" ->
        # Logger.info("Creating Browser with guid: #{inspect(guid)}")

        {
          "Browser",
          Playwright.ChannelOwner.Browser.init(
            self(),
            parent,
            type,
            guid,
            initializer
          )
        }

      _ ->
        Logger.error("Don't know how to create #{inspect(type)}")
        nil
    end
  end

  # TODO: finish matching implementation
  # defp replace_guids_with_channels(initializer) do
  #   Logger.info("Decoding #{inspect(initializer)}")
  #   Jason.decode!(initializer)
  # end
end
