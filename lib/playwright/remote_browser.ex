defmodule Playwright.RemoteBrowser do
  @moduledoc """
  The `initializer` property will include a key `browser`, which may be used to
  look up the browser guid.

  ## Payload

      {
        "guid":"",
        "method":"__create__",
        "params":{
          "type":"RemoteBrowser",
          "initializer":{
            "browser":{"guid":"browser@guid"}
            ...
          }
        }
      }

  ## Note

  - In versions of playwright server before `1.11.0`, the guid of this message
    is `remoteBrowser`.
  - When connecting to versions of playwright server older than `1.11.0`, the
    `Playwright.Playwright` does not exist. Clients should instead block on this
    message to know that the browser is available.
  """
  use Playwright.Runner.ChannelOwner

  def new(parent, args) do
    channel_owner(parent, args)
  end
end
