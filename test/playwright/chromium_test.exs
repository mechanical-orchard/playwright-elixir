defmodule Playwright.ChromiumTest do
  use ExUnit.Case
  alias Playwright.Chromium

  # doctest Playwright

  test "connects over a ws endpoint" do
    # assert Playwright.hello() == :world
    browser = Chromium.launch(%Playwright.LaunchOptions{})
    assert browser.is_connected? == false
  end
end
