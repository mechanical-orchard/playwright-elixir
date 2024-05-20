defmodule Playwright.TestCase do
  @moduledoc """
  `TestCase` is a helper module intended for use by the tests *of* Playwright.

  When using Playwright to write tests for some other project, consider using `PlaywrightTest.Case`.
  """
  use ExUnit.CaseTemplate

  using(options) do
    quote do
      use PlaywrightTest.Case, unquote(options)

      # https://stackoverflow.com/a/41543671
      defmacro assert_next_receive(pattern, timeout \\ 100) do
        quote do
          receive do
            message ->
              assert unquote(pattern) = message
          after
            unquote(timeout) ->
              raise "Timeout waiting for 'next receive'"
          end
        end
      end

      defp assert_empty_mailbox do
        count = Keyword.get(Process.info(self()), :message_queue_len)
        assert count == 0
      end

      defp attach_frame(%Playwright.Page{} = page, frame_id, url) do
        Playwright.Page.evaluate_handle(
          page,
          """
          async () => {
            const frame = document.createElement('iframe');
                  frame.src = "#{url}";
                  frame.id = "#{frame_id}";
            document.body.appendChild(frame);
            await new Promise(x => frame.onload = x);
            return frame;
          }
          """
        )
        |> Playwright.JSHandle.as_element()
        |> Playwright.ElementHandle.content_frame()
      end

      require Logger

      def log_element_handle_error do
        Logger.warning("""
        The use of ElementHandle is discouraged in favor of Locator.
        Timeouts indicate an issue within Playwright.
        """)
      end
    end
  end

  setup %{transport: transport} do
    prefix =
      case transport do
        :driver -> "http://localhost:4002"
        :websocket -> "http://localhost:4002"
      end

    assets = prefix <> "/assets"
    extras = prefix <> "/extras"

    [
      assets: %{
        prefix: assets,
        extras: extras,
        blank: "about:blank",
        dom: assets <> "/dom.html",
        empty: assets <> "/empty.html"
      }
    ]
  end
end
