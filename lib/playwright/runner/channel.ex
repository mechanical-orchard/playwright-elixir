defmodule Playwright.Runner.Channel do
  @moduledoc false
  alias Playwright.Runner.Channel
  alias Playwright.Runner.Connection

  def send(subject, method, params \\ %{}) do
    command = Channel.Command.new(subject.guid, method, params)
    Connection.post(subject.connection, command)
  end
end
