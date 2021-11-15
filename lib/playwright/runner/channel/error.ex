defmodule Playwright.Runner.Channel.Error do
  @moduledoc false
  # `Error` represents an error message received from the Playwright server that is
  # in response to a `Command` previously sent.
  # alias Playwright.Runner.Channel.Error

  @enforce_keys [:message]
  defstruct [:message]

  def new(%{error: error}, _catalog) do
    message = String.split(error.message, "\n") |> List.first()
    raise message
    # %Error{message: String.split(error.message, "\n") |> List.first()}
  end
end

# <--- RECV (Transport.recv) message:
# %{
#   "error" => %{
#     "error" => %{
#       "message" => "info.waitId: expected string, got undefined",
#       "name" => "Error",
#       "stack" =>
#         "Error: info.waitId: expected string, got undefined\n    at tString (/Users/corey/Desktop/work/src/github.com/geometerio/playwright-elixir/assets/node_modules/playwright-core/lib/protocol/validatorPrimitives.js:48:9)\n    at /Users/corey/Desktop/work/src/github.com/geometerio/playwright-elixir/assets/node_modules/playwright-core/lib/protocol/validatorPrimitives.js:99:21\n    at /Users/corey/Desktop/work/src/github.com/geometerio/playwright-elixir/assets/node_modules/playwright-core/lib/protocol/validatorPrimitives.js:99:21\n    at Object.PageWaitForEventInfoParams (/Users/corey/Desktop/work/src/github.com/geometerio/playwright-elixir/assets/node_modules/playwright-core/lib/protocol/validator.js:45:14)\n    at DispatcherConnection._validateParams (/Users/corey/Desktop/work/src/github.com/geometerio/playwright-elixir/assets/node_modules/playwright-core/lib/dispatchers/dispatcher.js:223:26)\n    at DispatcherConnection.dispatch (/Users/corey/Desktop/work/src/github.com/geometerio/playwright-elixir/assets/node_modules/playwright-core/lib/dispatchers/dispatcher.js:266:26)\n    at Transport.transport.onmessage (/Users/corey/Desktop/work/src/github.com/geometerio/playwright-elixir/assets/node_modules/playwright-core/lib/cli/driver.js:65:57)\n    at Immediate._onImmediate (/Users/corey/Desktop/work/src/github.com/geometerio/playwright-elixir/assets/node_modules/playwright-core/lib/protocol/transport.js:89:34)\n    at processImmediate (node:internal/timers:464:21)"
#     }
#   },
#   "id" => 5
# }
