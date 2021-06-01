defmodule Playwright.ConnectionTest do
  use ExUnit.Case
  alias Playwright.Connection
  alias Playwright.ConnectionTest.TestTransport

  setup do
    %{
      connection: start_supervised!({Connection, [{TestTransport, ["param"]}]}),
      impl_state: %{catalog: %{"existing" => "found item"}, queries: %{}}
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

  describe "@impl: handle_call/3 for :get" do
    test "when the desired item is in the catalog, returns that and does not record the query", %{impl_state: state} do
      {response, result, %{queries: queries}} = Connection.handle_call({:get, {:guid, "existing"}}, :caller, state)

      assert response == :reply
      assert result == "found item"
      assert queries == %{}
    end

    test "when the desired item is NOT in the catalog, records the query and does not reply", %{impl_state: state} do
      {response, %{queries: queries}} = Connection.handle_call({:get, {:guid, "missing"}}, :caller, state)

      assert response == :noreply
      assert queries == %{"missing" => :caller}
    end
  end

  # helpers
  # ----------------------------------------------------------------------------

  defmodule TestTransport do
    def start_link!([connection | args]) do
      %{
        connection: connection,
        args: args
      }
    end
  end
end
