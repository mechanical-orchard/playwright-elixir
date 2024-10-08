defmodule Playwright.SDK.Extra.MapTest do
  use ExUnit.Case, async: true

  alias Playwright.SDK.Extra

  describe "deep_atomize_keys" do
    test "deeply converts keys from strings to atoms" do
      map = %{"item1" => "chapstick", "item2" => %{"item3" => "mask"}}
      assert map |> Extra.Map.deep_atomize_keys() == %{item1: "chapstick", item2: %{item3: "mask"}}
    end

    test "handles keys that are already atoms" do
      map = %{:item1 => %{"item3" => "mask"}, "item2" => 2}
      assert map |> Extra.Map.deep_atomize_keys() == %{item1: %{item3: "mask"}, item2: 2}
    end

    test "handles values that are lists" do
      map = %{"item1" => "chapstick", "item2" => %{"item3" => ["mask", "altoids"]}}
      assert map |> Extra.Map.deep_atomize_keys() == %{item1: "chapstick", item2: %{item3: ["mask", "altoids"]}}
    end
  end

  describe "deep_camelize_keys" do
    test "deeply converts keys from atoms" do
      map = %{key: "value", key_with_converted_case: %{nested_pair: "value"}}

      assert map |> Extra.Map.deep_camelize_keys() == %{
               "key" => "value",
               "keyWithConvertedCase" => %{"nestedPair" => "value"}
             }
    end

    test "deeply converts keys from strings" do
      map = %{"key" => "value", "key_with_converted_case" => %{"nested_pair" => "value"}}

      assert map |> Extra.Map.deep_camelize_keys() == %{
               "key" => "value",
               "keyWithConvertedCase" => %{"nestedPair" => "value"}
             }
    end

    test "retains special-case, already camelized strings" do
      map = %{"camelizedKey" => "value", "CamelizedKey" => %{"nestedAPIKey" => "value"}}

      assert map |> Extra.Map.deep_camelize_keys() == map
    end
  end
end
