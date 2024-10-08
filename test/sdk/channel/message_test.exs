defmodule Playwright.SDK.Channel.MessageTest do
  use ExUnit.Case, async: true
  alias Playwright.SDK.Channel.Message

  describe "new/3" do
    test "returns a Message struct" do
      assert Message.new("guid", "click") |> is_struct(Message)
    end

    test "returns a Message struct with a monotonically-incrementing ID" do
      one = Message.new("element-handle", "click")
      two = Message.new("element-handle", "click")

      assert one |> is_struct(Message)
      assert two |> is_struct(Message)

      assert two.id > one.id
    end

    test "accepts optional params" do
      is_default = Message.new("guid", "method")
      has_params = Message.new("guid", "method", %{key: "value"})

      assert is_default.params == %{}
      assert has_params.params == %{"key" => "value"}
    end
  end
end
