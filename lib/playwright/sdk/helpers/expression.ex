defmodule Playwright.SDK.Helpers.Expression do
  @moduledoc false

  # Page.evaluate(page, "function () { return 'lala'; }")
  # Page.evaluate(page, "() => { return 'lala'; }")
  # Page.evaluate(page, "() => 'lala'")
  # Page.evaluate(page, "(thing) => { return thing; }")
  # Page.evaluate(page, "(thing) => thing;")
  # Page.evaluate(page, "thing => thing;")

  def function?("function" <> _) do
    true
  end

  def function?("() =>" <> _) do
    true
  end

  def function?(expression) do
    String.match?(expression, ~r/^[^=]+ =>/)
  end
end
