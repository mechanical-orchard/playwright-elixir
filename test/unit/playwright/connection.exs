defmodule Playwright.ConnectionTest do
  use ExUnit.Case
  alias Playwright.Connection

  setup do
    %{
      connection: start_supervised!({Connection, []})
    }
  end

  describe "get/2" do
    test "always finds the 'Root' resource", %{connection: connection} do
      Connection.get(connection, {:guid, "Root"})
      |> assert()
    end
  end
end
