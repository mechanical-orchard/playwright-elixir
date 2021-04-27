defmodule PlaywrightTest do
  use ExUnit.Case
  doctest Playwright

  test "greets the world" do
    assert Playwright.hello() == :world
  end
end
