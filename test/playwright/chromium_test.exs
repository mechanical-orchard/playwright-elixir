defmodule Playwright.ChromiumTest do
  use ExUnit.Case, async: true
  # doctest Playwright.Chromium

  alias Playwright.Chromium
  alias Playwright.Page

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
      {:ok, supervised_pid} = start_supervised(Chromium)

      :ok = Chromium.connect(supervised_pid, ws_endpoint: context[:ws_endpoint])
      assert Process.alive?(supervised_pid)

      {:ok, page} = Chromium.new_page(supervised_pid)
      page |> Page.goto("https://playwright.dev")

      :ok = supervised_pid |> Chromium.stop()
      assert !Process.alive?(supervised_pid)
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
