defmodule Playwright.Runner.Channel.Callback do
  @moduledoc false
  alias Playwright.Runner.Channel
  alias Playwright.Runner.Channel.{Callback, Error, Response}
  alias Playwright.ElementHandle

  defstruct [:listener, :message]

  def new(listener, message) do
    %__MODULE__{
      listener: listener,
      message: message
    }
  end

  def resolve(%Callback{listener: listener}, %Error{} = error) do
    GenServer.reply(listener, {:error, error})
  end

  require Logger

  def resolve(%Callback{listener: listener}, %Response{parsed: %ElementHandle{} = handle}) do
    Task.start_link(fn ->
      GenServer.reply(listener, await_preview(handle))
    end)
  end

  def resolve(%Callback{listener: listener}, %Response{parsed: parsed})
      when is_list(parsed) do
    Task.start_link(fn ->
      GenServer.reply(listener, await_preview(parsed))
    end)
  end

  def resolve(%Callback{listener: listener}, %Response{parsed: parsed}) do
    GenServer.reply(listener, {:ok, parsed})
  end

  # private
  # ---------------------------------------------------------------------------

  defp await_preview(handle, timeout \\ DateTime.utc_now() |> DateTime.add(5, :second))

  defp await_preview(items, timeout) when is_list(items) do
    result =
      Enum.map(items, fn item ->
        {:ok, item} = await_preview(item, timeout)
        item
      end)

    {:ok, result}
  end

  defp await_preview(%ElementHandle{} = handle, timeout) do
    if DateTime.compare(DateTime.utc_now(), timeout) == :gt do
      {:error, :timeout}
    else
      case handle.preview do
        "JSHandle@node" ->
          :timer.sleep(5)
          {:ok, handle} = Channel.find(handle)
          await_preview(handle, timeout)

        _hydrated ->
          {:ok, handle}
      end
    end
  end

  defp await_preview(item, _timeout) do
    {:ok, item}
  end
end
