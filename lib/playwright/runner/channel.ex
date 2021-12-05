defmodule Playwright.Runner.Channel do
  @moduledoc false
  alias Playwright.Extra
  alias Playwright.Runner.{Channel, Connection, EventInfo}
  require Logger

  # def bind...      (instead of on)
  # def find/item... (???)
  # def post...      (call)
  # def send...      (cast)
  # def wait...

  @spec bind(struct(), atom() | binary(), (... -> any)) :: struct()
  def bind(%{connection: connection} = owner, event, callback) do
    :ok = Connection.bind(connection, {as_atom(event), owner}, callback)
    owner
  end

  @spec find(struct()) :: {:ok, struct()}
  def find(%{connection: _} = owner) do
    {:ok, item(owner)}
  end

  @spec find(struct(), struct()) :: {:ok, struct()}
  def find(%{connection: _} = proxy, %{guid: _} = owner) do
    {:ok, item(proxy, owner)}
  end

  # @spec on(struct(), atom(), function()) :: struct()
  def on(%{} = owner, event, callback)
      when is_atom(event)
      when is_function(callback) do
    Connection.on(owner.connection, {event, owner}, callback)
  end

  def on(connection, {event, owner}, handler) do
    Connection.on(connection, {event, owner}, handler)
  end

  def post(%{connection: connection} = owner, method, params \\ %{}) do
    case Connection.post(connection, Channel.Command.new(owner.guid, method, params)) do
      {:ok, %{id: _}} -> :ok
      {:ok, resource} -> resource
      {:error, error} -> {:error, error}
    end
  end

  # def send(%{connection: connection} = owner, method, params \\ %{})
  #     when is_atom(method) do
  #   Connection.post(connection, Channel.Command.new(owner.guid, method, params))
  # end

  @spec wait_for(struct(), atom() | binary()) :: EventInfo.t()
  def wait_for(owner, event) do
    {:ok, result} =
      Connection.wait_for(owner.connection, {as_atom(event), owner}, fn ->
        Logger.warn("Executing dummy action (does this happen?)")
      end)

    result
  end

  @spec wait_for(struct(), atom() | binary(), (() -> any())) :: EventInfo.t()
  def wait_for(owner, event, action) do
    {:ok, result} = Connection.wait_for(owner.connection, {as_atom(event), owner}, action)
    result
  end

  # NOTE: intend to merge/redesign these various wait things
  def await(owner, {:selector, selector}, options \\ %{}) do
    post(owner, :wait_for_selector, Map.merge(options, %{selector: selector}))
  end

  # ---------------------------------------------------------------------------

  @spec all(pid(), map()) :: [struct()]
  def all(connection, filter) do
    Connection.all(connection, filter)
  end

  def get(connection, {:guid, guid}) do
    Connection.get(connection, {:guid, guid})
  end

  def patch(connection, guid, data) do
    Connection.patch(connection, {:guid, guid}, data)
  end

  # private
  # ---------------------------------------------------------------------------

  defp as_atom(value) when is_atom(value) do
    value
  end

  defp as_atom(value) when is_binary(value) do
    Extra.Atom.snakecased(value)
  end

  defp item(%{connection: _connection} = owner) do
    item(owner, owner)
  end

  defp item(%{connection: connection} = _owner, %{guid: guid}) do
    get(connection, {:guid, guid})
  end
end
