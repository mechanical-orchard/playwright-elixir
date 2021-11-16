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

  @doc """
  Waits for event to fire (i.e., is blocking) and passes its value into the
  predicate function.

  Returns when the predicate returns a truthy value. Will throw an error if the
  context closes before the event is fired. Returns the event data value.

  NOTE:
  - The "throw an error if the context closes..." is not yet implemented.
  - The handling of :predicate is not yet implemented.
  """
  def expect_event(subject, event, action) do
    Channel.wait_for(subject, event, action)
  end

  @doc """
  Alias for `expect_event/3`.
  """
  defdelegate wait_for_event(subject, event, action), to: __MODULE__, as: :expect_event

  @doc """
  Performs `action` and waits for a new Page to be created in the context.

  If predicate is provided, it passes Page value into the predicate function
  and waits for predicate(event) to return a truthy value. Will throw an error
  if the context closes before new Page is created.

  NOTE:
  - The handling of :predicate is not yet implemented.
  """
  def expect_page(subject, action) do
    expect_event(subject, "page", action)
  end

  @doc """
  Register a handler for various event types.
  """
  def on(subject, event, handler) do
    Channel.on(subject.connection, {event, subject}, handler)
    subject
  end
end
