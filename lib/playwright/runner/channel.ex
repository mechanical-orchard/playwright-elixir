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

  @spec bind(struct(), atom() | binary(), (... -> any)) :: {:ok, struct()}
  def bind(%{connection: connection} = owner, event, callback) do
    :ok = Connection.bind(connection, {as_atom(event), owner}, callback)
    {:ok, owner}
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

  def on(connection, {event, subject}, handler) do
    Connection.on(connection, {event, subject}, handler)
  end

  # spec: :: {:ok, struct()}
  def post(%{connection: connection} = owner, method, params \\ %{}) do
    Connection.post(connection, Channel.Command.new(owner.guid, method, params))
  end

  # def send(%{connection: connection} = owner, method, params \\ %{})
  #     when is_atom(method) do
  #   Connection.post(connection, Channel.Command.new(owner.guid, method, params))
  # end

  @spec wait_for(struct(), atom() | binary()) :: {:ok, EventInfo.t()}
  def wait_for(owner, event) do
    Connection.wait_for(owner.connection, {as_atom(event), owner}, fn -> IO.puts("NOTE: executing dummy action") end)
  end

  @spec wait_for(struct(), atom() | binary(), (() -> any())) :: {:ok, EventInfo.t()}
  def wait_for(owner, event, action) do
    Connection.wait_for(owner.connection, {as_atom(event), owner}, action)
  end

  # ---------------------------------------------------------------------------

  def all(connection, filter, default \\ []) do
    Connection.get(connection, filter, default)
  end

  def get(connection, {:guid, guid}) do
    Connection.get(connection, {:guid, guid})
  end

  def patch(connection, guid, data) do
    result = Connection.patch(connection, {:guid, guid}, data)
    {:ok, result}
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
