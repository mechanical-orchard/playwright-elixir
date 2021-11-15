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

  require Logger
  def send(subject, method, params \\ %{})

  def send(subject, method, params) do
    # Logger.error("Channel.send --- A")
    command = Channel.Command.new(subject.guid, method, params)
    Connection.post(subject.connection, command)
  end

  def send(subject, method, params, :noreply) do
    # Logger.error("Channel.send --- B")
    command = Channel.Command.new(subject.guid, method, params)
    Logger.error("Channel.send w/ message: #{inspect(command)}")
    Connection.post(subject.connection, command)
  end

  def wait_for(subject, event, fun) do
    # fun.(subject)
    Connection.wait_for(subject.connection, {event, subject, fun})
  end
end
