defmodule Playwright.Runner.Helpers.Macros do
  @moduledoc false

  # NOTE: need to DRY these once patterns emerge.

  defmacro def_locator(name, method) do
    quote do
      @spec unquote(name)(Playwright.Locator.t(), Playwright.Locator.options()) ::
              :ok | {:error, Playwright.Runner.Channel.Error.t()}
      def unquote(name)(locator, options \\ %{}) do
        case Playwright.Runner.Channel.post(
               locator.frame,
               unquote(method),
               Map.merge(options, %{selector: locator.selector})
             ) do
          {:ok, %{id: _id}} -> :ok
          {:ok, %{guid: _id}} -> :ok
          {:error, error} -> {:error, error}
        end
      end
    end
  end

  defmacro def_locator(name, method, arguments) do
    quote do
      @spec unquote(name)(Playwright.Locator.t(), unquote(arguments)) ::
              :ok | {:error, Playwright.Runner.Channel.Error.t()}
      def unquote(name)(locator, options \\ %{}) do
        case Playwright.Runner.Channel.post(
               locator.frame,
               unquote(method),
               Map.merge(options, %{selector: locator.selector})
             ) do
          {:ok, %{id: _id}} -> :ok
          {:ok, %{guid: _id}} -> :ok
          {:error, error} -> {:error, error}
        end
      end
    end
  end
end
