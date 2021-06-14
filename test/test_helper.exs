if Application.get_env(:playwright, :run_asset_server),
  do: {:ok, _} = Test.Support.AssetsServer.start(nil, nil)

ExUnit.start()
