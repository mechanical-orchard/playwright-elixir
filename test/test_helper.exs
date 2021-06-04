ExUnit.start()
{:ok, _} = Playwright.start()
{:ok, _} = Test.Support.AssetsServer.start(nil, nil)
