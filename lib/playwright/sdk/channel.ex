defmodule Playwright.SDK.Channel do
  @moduledoc false
  import Playwright.SDK.Helpers.ErrorHandling
  alias Playwright.SDK.Channel.{Catalog, Connection, Event, Message, Response, Session}

  @type resource :: struct()

  # API
  # ---------------------------------------------------------------------------

  def bind(session, {:guid, guid}, event_type, callback) when is_binary(guid) do
    Session.bind(session, {guid, event_type}, callback)
  end

  def close(resource, options \\ %{})

  def close(resource, options) do
    case post({resource, :close}, %{refresh: false}, options) do
      {:error, %Playwright.API.Error{} = error} ->
        {:error, error}

      _ ->
        :ok
    end
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

  # NOTE(20240929):
  #
  # Calls to `post/3` that return the subject resource generally refresh
  # that resource prior to returning. However, some posts will result in removal
  # of the resource from the `Catalog`, in which case the `find/2` will fail and
  # cause a timeout. In those cases, pass `refresh: false` with the options.
  #
  # Examples:
  # - `Page.close/1`
  # - `CDPSession.detach/1`
  @spec post({resource(), atom() | String.t()}, map(), map()) :: any() | {:error, any()}
  def post({resource, action}, params \\ %{}, options \\ %{})
      when is_struct(resource)
      when is_atom(action) or is_binary(action) do
    {refresh?, params} = Map.pop(Map.merge(%{refresh: true}, Map.merge(params, options)), :refresh)
    connection = Session.connection(resource.session)
    message = Message.new(resource.guid, action, params)

    with_timeout(params, fn timeout ->
      case Connection.post(connection, message, timeout) do
        # on success...
        {:ok, %{id: _} = response} ->
          if Enum.count(response) == 1 do
            # ...empty message: send (generally refreshed) resource
            if refresh?, do: find(resource.session, {:guid, resource.guid}), else: resource
          else
            # ...populated message: send that
            response
          end

        # on successful fetch of related resource, send resource
        {:ok, resource} ->
          resource

        # on acceptable (API call) errors, send error tuple
        {:error, %Playwright.API.Error{} = error} ->
          {:error, error}
      end
    end)
  end

  def recv(session, {nil, message}) when is_map(message) do
    Response.recv(session, message)
    # |> IO.inspect(label: "<--- Channel.recv/2 A")
  end

  def recv(session, {from, message}) when is_map(message) do
    Response.recv(session, message)
    # |> IO.inspect(label: "<--- Channel.recv/2 B")
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

  defp reply(%Playwright.API.Error{} = error, from) do
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
