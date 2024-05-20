defmodule Playwright.BindingCall do
  @moduledoc false
  use Playwright.SDK.ChannelOwner
  import Playwright.SDK.Helpers.Serialization
  alias Playwright.BindingCall

  @property :args
  @property :frame
  @property :handle
  @property :name

  def call(%BindingCall{session: session} = binding_call, func) do
    Task.start_link(fn ->
      frame = Channel.find(session, {:guid, binding_call.frame.guid})

      source = %{
        context: "TBD",
        frame: frame,
        page: "TBD"
      }

      result = func.(source, deserialize(binding_call.args))

      Channel.post(session, {:guid, binding_call.guid}, :resolve, %{result: serialize(result)})
    end)
  end
end
