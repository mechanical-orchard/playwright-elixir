defmodule Playwright.BindingCall do
  @moduledoc false
  use Playwright.ChannelOwner
  import Playwright.Runner.Helpers.Serialization

  @property :args
  @property :frame
  @property :handle
  @property :name

  def call(binding_call, func) do
    Task.start_link(fn ->
      frame = Channel.get(binding_call.connection, {:guid, binding_call.frame.guid})

      source = %{
        context: "TBD",
        frame: frame,
        page: "TBD"
      }

      result = func.(source, deserialize(binding_call.args))

      Channel.post(binding_call, :resolve, %{result: serialize(result)})
    end)
  end
end
