defmodule Playwright.BindingCall do
  @moduledoc false
  use Playwright.ChannelOwner
  import Playwright.Runner.Helpers.Serialization

  @property :args
  @property :frame
  @property :handle
  @property :name

  def call(binding_call, func) do
    source = %{
      context: "TBD",
      frame: "TBD",
      page: "TBD"
    }

    result = func.(source, deserialize(binding_call.args))

    Task.start_link(fn ->
      Channel.post(binding_call, :resolve, %{result: serialize(result)})
    end)
  end
end
