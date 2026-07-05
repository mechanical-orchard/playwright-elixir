defmodule Playwright.LocatorHandlers do
  @moduledoc false
  # ETS-based storage for locator handlers.
  # Used by Page.add_locator_handler/4 and Page.remove_locator_handler/2.

  alias Playwright.SDK.Channel

  @table :playwright_locator_handlers

  @doc false
  def ensure_table do
    case :ets.whereis(@table) do
      :undefined ->
        :ets.new(@table, [:set, :public, :named_table])

      _ ->
        :ok
    end
  end

  @doc false
  def store(page_guid, uid, handler_data) do
    ensure_table()
    :ets.insert(@table, {{page_guid, uid}, handler_data})
  end

  @doc false
  def lookup(page_guid, uid) do
    ensure_table()

    case :ets.lookup(@table, {page_guid, uid}) do
      [{{^page_guid, ^uid}, data}] -> data
      [] -> nil
    end
  end

  @doc false
  def find_by_selector(page_guid, selector) do
    ensure_table()

    # Get all entries for this page and filter by selector
    :ets.foldl(
      fn
        {{^page_guid, uid}, %{selector: ^selector} = data}, acc ->
          [{uid, data} | acc]

        _, acc ->
          acc
      end,
      [],
      @table
    )
  end

  @doc false
  def delete(page_guid, uid) do
    ensure_table()
    :ets.delete(@table, {page_guid, uid})
  end

  @doc false
  def update_times(page_guid, uid, new_times) do
    case lookup(page_guid, uid) do
      nil -> :ok
      data -> store(page_guid, uid, %{data | times: new_times})
    end
  end

  @doc false
  def trigger(page_guid, uid, session) do
    # Spawn async to avoid blocking the GenServer that's processing events
    Task.start(fn ->
      case lookup(page_guid, uid) do
        nil ->
          notify_server(session, page_guid, uid, true)

        %{handler: handler, locator: locator, times: times} ->
          execute_handler(handler, locator)
          remove = maybe_update_handler(page_guid, uid, times)
          notify_server(session, page_guid, uid, remove)
      end
    end)
  end

  defp execute_handler(handler, locator) do
    handler.(locator)
  rescue
    _ -> :ok
  catch
    _, _ -> :ok
  end

  defp maybe_update_handler(page_guid, uid, times) do
    case times do
      nil ->
        false

      1 ->
        delete(page_guid, uid)
        true

      n when is_integer(n) ->
        update_times(page_guid, uid, n - 1)
        false
    end
  end

  defp notify_server(session, page_guid, uid, remove) do
    Channel.post(session, {:guid, page_guid}, :resolve_locator_handler_no_reply, %{
      uid: uid,
      remove: remove
    })
  end

  @doc false
  def cleanup_page(page_guid) do
    ensure_table()

    # Delete all handlers for this page
    :ets.foldl(
      fn
        {{^page_guid, _uid}, _data}, acc ->
          acc

        key, acc ->
          [key | acc]
      end,
      [],
      @table
    )
    |> Enum.each(fn {pg, uid} when pg == page_guid -> delete(page_guid, uid) end)
  end
end
