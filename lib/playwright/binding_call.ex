defmodule Playwright.BindingCall do
  @moduledoc false
  use Playwright.SDK.ChannelOwner
  alias Playwright.BindingCall
  alias Playwright.SDK.Channel
  alias Playwright.SDK.Helpers.Serialization

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

      Channel.post({binding_call, :resolve}, %{
        result: Serialization.serialize(func.(source, Serialization.deserialize(binding_call.args)))
      })
    end)
  end
end
