ExUnit.start()
{:ok, _} = Playwright.start()
{:ok, _} = Playwright.Test.Support.AssetsServer.start(nil, nil)
