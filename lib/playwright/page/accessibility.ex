defmodule Playwright.Page.Accessibility do
  @moduledoc """
  `Playwright.Page.Accessibility` provides functions for inspecting Chromium's accessibility tree.

  The accessibility tree is used by assistive technology such as [screen readers][1] or [switches][2].

  Accessibility is a very platform-specific thing. On different platforms, there are different screen readers that
  might have wildly different output.

  Rendering engines of Chromium, Firefox and WebKit have a concept of "accessibility tree", which is then translated
  into different platform-specific APIs. Accessibility namespace gives access to this Accessibility Tree.

  Most of the accessibility tree gets filtered out when converting from internal browser AX Tree to Platform-specific
  AX-Tree or by assistive technologies themselves. By default, Playwright tries to approximate this filtering,
  exposing only the "interesting" nodes of the tree.

  [1]: https://en.wikipedia.org/wiki/Screen_reader
  [2]: https://en.wikipedia.org/wiki/Switch_access
  """

  alias Playwright.Runner.Channel

  @type page :: %Playwright.Page{}
  @type opts :: map

  @doc """
  Captures the current state of the accessibility tree.

  The returned object represents the root accessible node of the page.

  ## Options

  - `:interestingOnly` - Prune uninteresting nodes from the tree (default: true)
  - `:root` - The root DOM element for the snapshot (default: page)

  ## Examples

  Dumping an entire accessibility tree:

      iex> page = PlaywrightTest.Page.setup()
      ...> page
      ...>   |> Playwright.Page.set_content("<p>Hello!</p>")
      ...>   |> Playwright.Page.Accessibility.snapshot()
      %{children: [%{name: "Hello!", role: "text"}], name: "", role: "WebArea"}

  Retrieving the name of a focused node:

      iex> page = PlaywrightTest.Page.setup()
      ...> body = "<input placeholder='pick me' autofocus /><input placeholder='not me' />"
      ...> page
      ...>   |> Playwright.Page.set_content(body)
      ...>   |> Playwright.Page.Accessibility.snapshot()
      ...>   |> (&(Enum.find(&1.children, fn e -> e.focused end))).()
      ...>   |> Map.get(:name)
      "pick me"
  """
  @spec snapshot(page, opts) :: map
  def snapshot(page, opts \\ %{}) do
    page
    |> Channel.send("accessibilitySnapshot", opts)
    # |> IO.inspect()
    |> ax_node_from_protocol()
  end

  # private
  # ---------------------------------------------------------------------------

  defp ax_node_from_protocol(%{role: role} = input)
       when role in ["text"] do
    ax_node_from_protocol(input, fn e -> e.role != "text" end)
  end

  defp ax_node_from_protocol(input) do
    ax_node_from_protocol(input, fn _ -> true end)
  end

  defp ax_node_from_protocol(input, filter) do
    Enum.reduce(input, %{}, fn {k, v}, acc ->
      cond do
        is_list(v) ->
          normal =
            v
            |> Enum.map(&ax_node_from_protocol/1)
            |> Enum.filter(filter)

          Map.put(acc, k, normal)

        k == :checked ->
          normal =
            case v do
              "checked" -> true
              "unchecked" -> false
              other -> other
            end

          Map.put(acc, k, normal)

        k == :valueString ->
          Map.put(acc, :value, v)

        true ->
          Map.put(acc, k, v)
      end
    end)
  end
end
