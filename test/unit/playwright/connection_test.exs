defmodule Playwright.ConnectionTest do
  use ExUnit.Case
  alias Playwright.Connection
  alias Playwright.ConnectionTest.TestTransport

  setup do
    %{
      connection: start_supervised!({Connection, [{TestTransport, ["param"]}]})
    }
  end

  describe "get/2" do
    test "always finds the `Root` resource", %{connection: connection} do
      Connection.get(connection, {:guid, "Root"})
      |> assert()
    end
  end

  # @impl
  # ----------------------------------------------------------------------------

  describe "@impl: init/1" do
    test "starts the `Transport`, with provided configuration", %{connection: connection} do
      %{transport: transport} = :sys.get_state(connection)

      assert transport == %{
               mod: TestTransport,
               pid: %{
                 args: ["param"],
                 connection: connection
               }
             }
    end
  end

  defmodule TestTransport do
    def start_link!([connection | args]) do
      %{
        connection: connection,
        args: args
      }
    end
  end
end
