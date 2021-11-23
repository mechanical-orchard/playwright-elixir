defmodule Playwright.Runner.Helpers.Macros do
  @moduledoc false

  defmacro def_locator(name, method) do
    quote do
      @spec unquote(name)(Playwright.Frame.Locator.t(), Playwright.Frame.Locator.options()) ::
          :ok | {:error, Playwright.Runner.Channel.Error.t()}
      def unquote(name)(locator, options \\ %{}) do
        case Playwright.Runner.Channel.post(locator.frame, unquote(method), Map.merge(options, %{selector: locator.selector})) do
          {:ok, %{id: _id}} -> :ok
          {:ok, %{guid: _id}} -> :ok
          {:error, error} -> {:error, error}
        end
      end
    end
  end
end
