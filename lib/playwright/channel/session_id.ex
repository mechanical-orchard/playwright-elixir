defmodule Playwright.Channel.SessionID do
  @moduledoc false

  use Agent

  def start_link(_arg) do
    Agent.start_link(fn -> 0 end, name: __MODULE__)
  end

  def next do
    Agent.get_and_update(__MODULE__, fn state -> {state + 1, state + 1} end)
  end
end
