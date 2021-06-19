unless String.to_atom(System.get_env("PLAYWRIGHT_RUN_ASSET_SERVER", "true")) == false,
  do: {:ok, _} = Test.Support.AssetsServer.start(nil, nil)

ExUnit.start()
