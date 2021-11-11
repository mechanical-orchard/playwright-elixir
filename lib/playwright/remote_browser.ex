defmodule Playwright.RemoteBrowser do
  @moduledoc false
  # The `initializer` property will include a key `browser`, which may be used to
  # look up the browser guid.

  # ## Payload

  #     {
  #       "guid":"",
  #       "method":"__create__",
  #       "params":{
  #         "type":"RemoteBrowser",
  #         "initializer":{
  #           "browser":{"guid":"browser@guid"}
  #           ...
  #         }
  #       }
  #     }
  use Playwright.Runner.ChannelOwner
end
