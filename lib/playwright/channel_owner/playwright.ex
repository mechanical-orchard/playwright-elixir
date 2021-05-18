defmodule Playwright.ChannelOwner.Playwright do
  use Playwright.ChannelOwner

  @spec new(atom | %{:connection => atom | pid | port | {atom, atom}, optional(any) => any}, map) ::
          %Playwright.ChannelOwner{
            connection: any,
            guid: any,
            initializer: any,
            parent:
              atom | %{:connection => atom | pid | port | {atom, atom}, optional(any) => any},
            type: any
          }
  def new(parent, args) do
    channel_owner(parent, args)
  end

  def get(state, key) do
    Logger.info("Getting #{inspect(key)} from state: #{inspect(state.initializer)}")
    state.initializer[key]
  end

  def list(state) do
    Logger.info("Playwright initializer keys: #{inspect(Map.keys(state.initializer))}")
    state
  end

  def chromimum(state) do
    %{"guid" => guid} = state.initializer["chromium"]
    GenServer.call(state.connection, {:wait_for, guid})
  end

  @spec selectors(atom | %{:initializer => nil | maybe_improper_list | map, optional(any) => any}) ::
          any
  def selectors(state) do
    state.initializer["selectors"]
  end
end
