defmodule Playwright.Runner.Helpers.URLMatcherTest do
  use ExUnit.Case, async: true
  alias Playwright.Runner.Helpers.URLMatcher

  describe "new/1" do
    test "returns a URLMatcher struct, with a compiled :regex" do
      assert %URLMatcher{regex: ~r/.*\/path/} = URLMatcher.new(".*/path")
    end

    test "given a path-glob style match" do
      assert %URLMatcher{regex: ~r/.*\/path/} = URLMatcher.new("**/path")
    end
  end
end
