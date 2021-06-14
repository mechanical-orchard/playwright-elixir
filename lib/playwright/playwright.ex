defmodule Playwright.Playwright do
  @moduledoc """
  When launching a browser or connecting to a running Playwright server, a
  `Playwright` message from the server indicates that the browser is ready
  for action.

  When connecting to a playwright websocket server, the `initializer`
  property will include a key `preLaunchedBrowser`, which can be used to
  look up the browser guid.

  ## Payload

      {
        "guid":"",
        "method":"__create__",
        "params":{
          "type":"Playwright",
          "initializer":{
            "preLaunchedBrowser":{"guid":"browser@guid"}
            ...
          }
        }
      }

  ## Notes

  * When Playwright is started, the client blocks to wait for this message
    to have been received. In playwright server is older than `1.11.0`, the
    server sends the ` Playwright.RemoteBrowser` message instead.
  """
  @moduledoc since: "Playwright 1.11.0"
  use Playwright.Client.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end
end
