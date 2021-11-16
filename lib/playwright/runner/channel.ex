defmodule Playwright.Runner.Channel do
  @moduledoc false
  alias Playwright.Runner.Channel
  alias Playwright.Runner.Connection
  alias Playwright.Runner.EventInfo

  def all(connection, filter, default \\ []) do
    Connection.get(connection, filter, default)
  end

  def get(connection, {:guid, guid}) do
    Connection.get(connection, {:guid, guid})
  end

  def on(connection, {event, subject}, handler) do
    Connection.on(connection, {event, subject}, handler)
  end

  def patch(connection, guid, data) do
    Connection.patch(connection, {:guid, guid}, data)
  end

  def send(subject, method, params \\ %{})

  def send(subject, method, params) do
    command = Channel.Command.new(subject.guid, method, params)
    Connection.post(subject.connection, command)
  end

  @spec wait_for(struct(), binary(), (-> any())) :: EventInfo.t()
  def wait_for(subject, event, action) do
    Connection.wait_for(subject.connection, {event, subject, action})
  end

  @spec wait_for_match(struct(), binary(), (EventInfo.t() -> boolean())) :: EventInfo.t()
  def wait_for_match(subject, event, predicate) do
    Connection.wait_for_match(subject.connection, {event, subject, predicate})
  end
end
