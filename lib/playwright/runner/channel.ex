defmodule Playwright.Runner.Channel do
  @moduledoc false
  alias Playwright.Runner.Channel
  alias Playwright.Runner.Connection

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

  def send(subject, method, params \\ %{}) do
    command = Channel.Command.new(subject.guid, method, params)
    Connection.post(subject.connection, command)
  end

  def send_noreply(subject, method, params \\ %{}) do
    command = Channel.Command.new(subject.guid, method, params)
    Connection.post(subject.connection, :noreply, command)
  end
end
