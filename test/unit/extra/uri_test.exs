defmodule Playwright.SDK.Extra.URITest do
  use ExUnit.Case, async: true

  alias Playwright.SDK.Extra

  describe "absolute?" do
    test "returns true if the URI has a scheme and a host" do
      assert Extra.URI.absolute?("http://example.com/foo/bar")
      assert Extra.URI.absolute?("wss://example.org:2345")
    end

    test "returns false if the URI does not have a scheme" do
      refute Extra.URI.absolute?("//example.com:2345/foo/bar")
    end

    test "returns false if the URI does not have a host" do
      refute Extra.URI.absolute?("/foo/bar")
    end
  end
end
