defmodule Playwright.ChromiumTest do
  use ExUnit.Case, async: true
  # doctest Playwright.Chromium

  alias Playwright.Chromium

  # TODO:
  # - [ ] get a successful connection with a provided `ws_endpoint`
  # - [ ] get a successful connection with a defaul `ws_endpoint`
  # - [ ] handle :econnrefused for when there is no server listening
  # - [ ] handle :econnrefused (?) for when the server endpoint does not exist
  # - [ ] handle the websocket server closing the connection:
  #       `(EXIT from #PID<0.189.0>) shell process exited with reason: {:remote, :closed}`
  # - [ ] IMPORTANT: handle the fact that I'm currently sending back the PID of the WS.start_link to the consumer of Chromium.connect, when that should definitely not be the case (see the `IO.inspects`).
  # NOTE:
  # - in order to accomplish those, a fake server will be needed. for now, I'll add placeholder comments.
  # - when successfully connecting to a websocket endpoint, `Process.alive?/1` is subsequently `true`. This is a good example of why a fake server is needed: connections are leaking (because there's now cleanup).
  # - importantly: while I'm clearly attracted to abstracting away the `start_link` call, that's likely an anti-pattern.
  describe "connect/1" do
    setup do
      %{ws_endpoint: "ws://localhost:3000/playwright"}
    end

    test "does something", context do
      # there's more stuff in "context":
      # IO.inspect(context)
      {:ok, pid} = Chromium.connect(ws_endpoint: context[:ws_endpoint])
      assert Process.alive?(pid)
      # it's a bit brutish, but this does seem to close the WS connection...
      Agent.stop(pid)
      assert !Process.alive?(pid)

      # no server listening:
      #   {:error, %WebSockex.ConnError{original: :econnrefused}}

      # with TLS...
      #   {:ok, pid} = Chromium.connect(ws_endpoint: "wss://localhost:3000/playwright")
      # ...and TLS is not supported:
      #   {:error, %WebSockex.ConnError{original: {:tls_alert, {:unexpected_message, 'TLS client: In state hello at tls_record.erl:539 generated CLIENT ALERT: Fatal - Unexpected Message\n {unsupported_record_type,72}'}}}}
    end
  end

  # describe "new_context" do
  #   test "does something" do
  #   end
  # end

  # describe "new_page" do
  #   test "does something" do
  #   end
  # end
end
