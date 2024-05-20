defmodule Playwright.SDK.Extra.URI do
  @moduledoc false
  def absolute?(uri) do
    uri = URI.parse(uri)
    present?(uri.host) && present?(uri.scheme)
  end

  defp present?(nil), do: false
  defp present?(""), do: false
  defp present?(_), do: true
end
