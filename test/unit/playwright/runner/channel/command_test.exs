defmodule Playwright.Runner.Channel.CommandTest do
  use ExUnit.Case, async: true
  alias Playwright.Runner.Channel.Command

  describe "new/3" do
    test "returns a Command struct" do
      assert Command.new("guid", "click") |> is_struct(Command)
    end

    test "returns a Command struct with a monotonically-incrementing ID" do
      one = Command.new("element-handle", "click")
      two = Command.new("element-handle", "click")

      assert one |> is_struct(Command)
      assert two |> is_struct(Command)

      assert two.id > one.id
    end

    test "accepts optional params" do
      is_default = Command.new("guid", "method")
      has_params = Command.new("guid", "method", %{key: "value"})

      assert is_default.params == %{}
      assert has_params.params == %{"key" => "value"}
    end
  end
end
