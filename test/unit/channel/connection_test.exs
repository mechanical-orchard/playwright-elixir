defmodule Playwright.SDK.Channel.ConnectionTest do
  # use ExUnit.Case, async: true
  # alias Playwright.Catalog
  # alias Playwright.SDK.Channel
  # alias Playwright.Connection
  # alias Playwright.ConnectionTest.TestTransport

  # setup do
  #   %{
  #     connection: start_supervised!({Connection, {TestTransport, %{param: "value"}}})
  #   }
  # end

  # describe "get/2" do
  #   test "always finds the `Root` resource", %{connection: connection} do
  #     Connection.get(connection, {:guid, "Root"})
  #     |> assert()
  #   end
  # end

  # describe "post/2" do
  #   test "removing an item via __dispose__ also removes its 'children'", %{connection: connection} do
  #     %{catalog: catalog} = :sys.get_state(connection)
  #     root = Catalog.get(catalog, "Root")
  #     json = Jason.encode!(%{guid: "browser@1", method: "__dispose__"})

  #     Catalog.put(catalog, %{guid: "browser@1", parent: %{guid: "Root"}, type: "Browser"})
  #     Catalog.put(catalog, %{guid: "context@1", parent: %{guid: "browser@1"}, type: "BrowserContext"})

  #     Catalog.put(catalog, %{
  #       guid: "page@1",
  #       parent: %{guid: "context@1", initializer: %{isClosed: false}},
  #       type: "Page"
  #     })

  #     :sys.replace_state(connection, fn state -> %{state | catalog: catalog} end)

  #     Connection.get(connection, %{guid: "browser@1"})
  #     |> assert()

  #     Connection.get(connection, %{guid: "context@1"})
  #     |> assert()

  #     Connection.get(connection, %{guid: "page@1"})
  #     |> assert()

  #     Connection.recv(connection, {:text, json})

  #     Connection.get(connection, %{guid: "browser@1"})
  #     |> refute()

  #     Connection.get(connection, %{guid: "context@1"})
  #     |> refute()

  #     Connection.get(connection, %{guid: "page@1"})
  #     |> refute()

  #     Connection.get(connection, %{guid: root.guid})
  #     |> assert()
  #   end
  # end

  # describe "recv/2 with a `__create__` payload" do
  #   test "adds the item to the catalog", %{connection: connection} do
  #     json =
  #       Jason.encode!(%{
  #         guid: "",
  #         method: "__create__",
  #         params: %{
  #           guid: "page@1",
  #           initializer: %{isClosed: false},
  #           type: "Page"
  #         }
  #       })

  #     Connection.recv(connection, {:text, json})

  #     assert Connection.get(connection, {:guid, "page@1"}).type == "Page"
  #   end
  # end

  # # @impl
  # # ----------------------------------------------------------------------------

  # describe "@impl: init/1" do
  #   test "starts the `Transport`, with provided configuration", %{connection: connection} do
  #     %{transport: transport} = :sys.get_state(connection)
  #     assert Process.alive?(transport.pid)
  #   end
  # end

  # describe "@impl: handle_call/3 for :get" do
  #   test "when the desired item is in the catalog, sends that", %{
  #     connection: connection
  #   } do
  #     state = :sys.get_state(connection)
  #     from = {self(), :tag}

  #     {response, _} = Connection.handle_call({:get, {:guid, "Root"}}, from, state)
  #     assert response == :noreply
  #     assert_received({:tag, %Playwright.SDK.Channel.Root{}})
  #   end
  # end

  # describe "@impl: handle_call/3 for :post" do
  #   test "sends a message and blocks on a matching return message", %{connection: connection} do
  #     state = %{:sys.get_state(connection) | callbacks: %{}}

  #     from = {self(), :tag}
  #     cmd = Channel.Message.new("page@1", "click", %{selector: "a.link"})
  #     cid = cmd.id

  #     {response, state} = Connection.handle_call({:post, {:cmd, cmd}}, from, state)
  #     assert response == :noreply
  #     assert state.callbacks == %{cid => %Channel.Callback{listener: from, message: cmd}}

  #     posted = TestTransport.dump(state.transport.pid)
  #     assert List.last(posted) == Jason.encode!(cmd)

  #     {_, %{callbacks: callbacks}} = Connection.handle_cast({:recv, {:text, Jason.encode!(%{id: cid})}}, state)

  #     assert callbacks == %{}
  #     assert_received({:tag, {:ok, %{id: ^cid}}})
  #   end
  # end

  # describe "@impl: handle_cast/2 for :recv" do
  #   test "sends a reply to an awaiting query", %{connection: connection} do
  #     state = :sys.get_state(connection)

  #     json =
  #       Jason.encode!(%{
  #         guid: "",
  #         method: "__create__",
  #         params: %{
  #           guid: "Playwright",
  #           type: "Playwright",
  #           initializer: %{}
  #         }
  #       })

  #     from = {self(), :tag}

  #     {_, state} = Connection.handle_call({:get, {:guid, "Playwright"}}, from, state)
  #     Connection.handle_cast({:recv, {:text, json}}, state)

  #     assert_received({:tag, %Playwright{}})
  #   end
  # end

  # # helpers
  # # ----------------------------------------------------------------------------

  # defmodule TestTransport do
  #   use GenServer

  #   def start_link(arg) do
  #     GenServer.start_link(__MODULE__, arg)
  #   end

  #   def start_link!(arg) do
  #     {:ok, pid} = start_link(arg)
  #     pid
  #   end

  #   def dump(pid) do
  #     GenServer.call(pid, :dump)
  #   end

  #   def post(pid, message) do
  #     GenServer.cast(pid, {:post, message})
  #   end

  #   # ---

  #   def init({connection, config}) do
  #     {
  #       :ok,
  #       %{
  #         connection: connection,
  #         config: config,
  #         posted: []
  #       }
  #     }
  #   end

  #   def handle_call(:dump, _from, %{posted: posted} = state) do
  #     {:reply, posted, state}
  #   end

  #   def handle_cast({:post, message}, %{posted: posted} = state) do
  #     {:noreply, %{state | posted: posted ++ [message]}}
  #   end
  # end
end
