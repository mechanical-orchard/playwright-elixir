defmodule Playwright.BindingCall do
  @moduledoc false
  use Playwright.SDK.ChannelOwner
  alias Playwright.BindingCall
  alias Playwright.SDK.{Channel, Helpers}

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

      result = func.(source, Helpers.Serialization.deserialize(binding_call.args))
      Channel.post(session, {:guid, binding_call.guid}, :resolve, %{result: Helpers.Serialization.serialize(result)})
    end)
  end
end
