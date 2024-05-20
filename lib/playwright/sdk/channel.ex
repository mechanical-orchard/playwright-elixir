defmodule Playwright.SDK.Channel do
  @moduledoc false
  import Playwright.SDK.Helpers.ErrorHandling
  alias Playwright.SDK.Channel.{Catalog, Connection, Error, Event, Message, Response, Session}

  # API
  # ---------------------------------------------------------------------------

  def bind(session, {:guid, guid}, event_type, callback) when is_binary(guid) do
    Session.bind(session, {guid, event_type}, callback)
  end

  def find(session, {:guid, guid}, options \\ %{}) when is_binary(guid) do
    Session.catalog(session) |> Catalog.get(guid, options)
  end

  def list(session, {:guid, guid}, type) do
    Catalog.list(Session.catalog(session), %{
      parent: guid,
      type: type
    })
  end

  def patch(session, {:guid, guid}, data) when is_binary(guid) do
    catalog = Session.catalog(session)
    owner = Catalog.get(catalog, guid)
    Catalog.put(catalog, Map.merge(owner, data))
  end

  def post(session, {:guid, guid}, message, params \\ %{}) when is_binary(guid) when is_pid(session) do
    connection = Session.connection(session)
    message = Message.new(guid, message, params)

    with_timeout(params, fn timeout ->
      case Connection.post(connection, message, timeout) do
        {:ok, %{id: _}} -> :ok
        {:ok, resource} -> resource
        {:error, error} -> {:error, error}
      end
    end)
  end

  def recv(session, {nil, message}) when is_map(message) do
    Response.recv(session, message)
  end

  def recv(session, {from, message}) when is_map(message) do
    Response.recv(session, message)
    |> reply(from)
  end

  # or, "expect"?
  def wait(session, owner, event_type, options \\ %{}, trigger \\ nil)

  def wait(session, {:guid, guid}, event_type, options, trigger) when is_map(options) do
    connection = Session.connection(session)

    with_timeout(options, fn timeout ->
      {:ok, event} = Connection.wait(connection, {:guid, guid}, event_type, timeout, trigger)
      evaluate(event, options)
    end)
  end

  def wait(session, {:guid, guid}, event, trigger, _) when is_function(trigger) do
    wait(session, {:guid, guid}, event, %{}, trigger)
  end

  # private
  # ---------------------------------------------------------------------------

  defp evaluate(%Event{} = event, options) do
    predicate = Map.get(options, :predicate)

    if predicate do
      with_timeout(options, fn timeout ->
        task =
          Task.async(fn ->
            evaluate(predicate, event.target, event)
          end)

        Task.await(task, timeout)
      end)
    else
      event
    end
  end

  defp evaluate(predicate, resource, event) do
    case predicate.(resource, event) do
      false ->
        :timer.sleep(5)
        evaluate(predicate, resource, event)

      _ ->
        event
    end
  end

  defp load_preview(handle, timeout \\ DateTime.utc_now() |> DateTime.add(5, :second))

  defp load_preview(items, timeout) when is_list(items) do
    result =
      Enum.map(items, fn item ->
        load_preview(item, timeout)
      end)

    result
  end

  defp load_preview(%Playwright.ElementHandle{session: session} = handle, timeout) do
    if DateTime.compare(DateTime.utc_now(), timeout) == :gt do
      {:error, :timeout}
    else
      case handle.preview do
        "JSHandle@node" ->
          :timer.sleep(5)
          find(session, {:guid, handle.guid}) |> load_preview(timeout)

        _hydrated ->
          handle
      end
    end
  end

  defp load_preview(item, _timeout) do
    item
  end

  defp reply(%Error{} = error, from) do
    Task.start_link(fn ->
      GenServer.reply(from, {:error, error})
    end)
  end

  defp reply(%Response{} = response, from) do
    Task.start_link(fn ->
      GenServer.reply(from, {:ok, load_preview(response.parsed)})
    end)
  end

  defp reply(%Event{} = event, from) do
    Task.start_link(fn ->
      GenServer.reply(from, {:ok, event})
    end)
  end
end
