defmodule Playwright.BrowserContext do
  @moduledoc """
  `Playwright.BrowserContext` provides a way to operate multiple independent
  browser sessions.

  If a page opens another page, e.g. with a `window.open` call, the popup will
  belong to the parent page's browser context.

  Playwright allows creation of "incognito" browser contexts with the
  `Playwright.Browser.new_context/1` function.
  """
  use Playwright.Runner.ChannelOwner, fields: [:browser, :owner_page]
  alias Playwright.Runner.Channel

  @doc false
  def new(parent, args) do
    channel_owner(parent, args)
  end

  @doc """
  Create a new `Playwright.Page` in the browser context. If the context is
  "owned" by a `Playwright.Page` (i.e., was created as a side effect of
  `Browser.new_page`), raise an error because there should be a 1-to-1 mapping
  in that case.
  """
  def new_page(subject) do
    case subject.owner_page do
      nil ->
        Channel.send(subject, "newPage")

      %Playwright.Page{} ->
        raise(RuntimeError, message: "Please use Playwright.Browser.new_context/1")
    end
  end

  @doc """
  Close the browser context. All the pages that belong to the browser context
  will be closed.
  """
  def close(subject) do
    subject |> Channel.send("close")
    subject
  end

  # .channel__on (things that might want to move to Channel)
  # ----------------------------------------------------------------------------

  @doc false
  def channel__on(subject, "close") do
    subject
  end

  @doc false
  def channel__on(subject, "request") do
    subject
  end
end
