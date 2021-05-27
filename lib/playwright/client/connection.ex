defmodule Playwright.Client.Connection do
  require Logger

  use GenServer
  alias Playwright.ChannelOwner.Root

  # API
  # ---------------------------------------------------------------------------

  defstruct(
    root: nil,
    transport: %{},
    guid_map: %{},
    message_index: 0,
    messages: %{},
    queries: %{}
  )

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def get(connection, guid) do
    GenServer.call(connection, {:get, guid})
  end

  def has(connection, guid) do
    GenServer.call(connection, {:has, guid})
  end

  def post(connection, message) do
    i = GenServer.call(connection, :increment)

    try do
      case GenServer.call(connection, {:post, message, i}) |> parse_response do
        {:error, error} ->
          throw({:error, error})

        {:guid, guid} ->
          get(connection, guid)

        {:value, value} ->
          value
      end
    catch
      :exit, value ->
        Logger.error("Connection.post timed out with #{inspect(value)}")
        :error
    end
  end

  # @impl
  # ---------------------------------------------------------------------------

  def init([transport_module, args]) do
    pid = self()

    # Logger.info(
    #   "Initializing Connection with #{inspect(transport_module)}, args: #{inspect(args)}"
    # )

    # WARN:
    # This is potentially racy: the transport connection must be made
    # *after* `root` is created.
    connection = %__MODULE__{
      root: Root.new(pid),
      transport: %{
        mod: transport_module,
        pid: transport_module.start_link!(args ++ [pid])
      }
    }

    {:ok, connection}
  end

  def handle_call(
        {:get, guid},
        from,
        %{
          guid_map: guid_map,
          queries: queries
        } = state
      ) do
    case guid_map[guid] do
      nil ->
        queries = Map.put(queries, guid, from)
        {:noreply, Map.put(state, :queries, queries)}

      result ->
        {:reply, result, state}
    end
  end

  def handle_call({:has, guid}, _, %{guid_map: guid_map} = state) do
    {:reply, guid_map[guid] != nil, state}
  end

  def handle_call(
        {:post, message, index},
        from,
        %{transport: transport, queries: queries} = state
      ) do
    payload = Jason.encode!(Map.put(message, :id, index))
    queries = Map.put(queries, index, from)

    case transport.mod.send_message(transport.pid, payload) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error(inspect(reason))
    end

    {:noreply, Map.put(state, :queries, queries)}
  end

  def handle_call(:increment, _, state) do
    state = Map.put(state, :message_index, state.message_index + 1)
    {:reply, state.message_index, state}
  end

  def handle_call(:show, _, state) do
    {:reply, Map.keys(state.guid_map), state}
  end

  def handle_info({:process_frame, {:data, data}}, state) do
    {:noreply, process_json(data, state)}
  end

  def handle_info({:process_frame, {:text, json}}, state) do
    {:ok, data} = Jason.decode(json)
    {:noreply, process_json(data, state)}
  end

  def handle_info({:register, {guid, item}}, state) do
    {:noreply, %__MODULE__{state | guid_map: Map.put(state.guid_map, guid, item)}}
  end

  # private
  # ---------------------------------------------------------------------------

  defp channel_owner(%{"type" => type}) do
    String.to_existing_atom("Elixir.Playwright.ChannelOwner.#{type}")
  end

  # TODO:
  # - Probably add "type" to the result tuple as well.
  defp parse_response(%{"result" => result}) do
    case Map.to_list(result) do
      [{"elements", value}] ->
        {:value, value}

      [{"value", value}] ->
        {:value, value}

      [{_key, %{"guid" => guid}}] ->
        {:guid, guid}

      [] ->
        nil
    end
  end

  defp parse_response(%{"error" => error, "id" => _id}) do
    [{"error", details}] = Map.to_list(error)
    {:error, details}
  end

  defp parse_response(%{"id" => id}) do
    Logger.error("Unhandled response for id: #{inspect(id)}")
    :ok
  end

  defp parse_response(other) do
    Logger.debug("Unhandled response: #{inspect(other)}")
    :ok
  end

  # TODO:
  # - Add "deep atomization" so we're not using string kyeys.
  defp process_json(%{"id" => id} = data, %{queries: queries} = state) do
    {from, queries} = Map.pop(queries, id)
    GenServer.reply(from, data)

    Map.put(state, :queries, queries)
  end

  defp process_json(
         %{
           "guid" => parent_guid,
           "method" => "__create__",
           "params" => params
         },
         %{queries: queries} = state
       ) do
    instance = apply(channel_owner(params), :new, [state.guid_map[parent_guid], params])

    # Logger.debug("processing JSON to create: #{inspect(parent_guid)}; #{inspect(params["guid"])}")

    case Map.pop(queries, _guid = params["guid"], nil) do
      {nil, _queries} ->
        state

      {from, queries} ->
        GenServer.reply(from, instance)
        Map.put(state, :queries, queries)
    end
  end

  # TODO:
  # - Dispose of dependents
  defp process_json(%{"method" => "__dispose__"} = data, %{guid_map: guid_map} = state) do
    {_disposed, guid_map} = Map.pop(guid_map, data["guid"])
    Map.put(state, :guid_map, guid_map)
  end

  defp process_json(_data, state) do
    # Logger.debug("processing JSON of some other kind: #{inspect(data)}")
    state
  end
end
