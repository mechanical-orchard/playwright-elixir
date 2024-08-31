# Browsers

## Setting a custom user agent

It's possible to set the user agent to a custom value via `BrowserContext` or `Browser`
### With Browser

```elixir
page = Playwright.Browser.new_page(browser, %{"userAgent" => "My Custom Agent"})
```

### With BrowserContext

```elixir
context = Browser.new_context(browser, %{"userAgent" => "Special Agent"})
```

## Custom Agent and Phoenix / Ecto

Setting a custom agent can be particularly useful when running Playwright in tests with the database involved.

Follow https://hexdocs.pm/phoenix_ecto/Phoenix.Ecto.SQL.Sandbox.html and set the `userAgent` to the result of `Phoenix.Ecto.SQL.Sandbox.metadata_for(YourApp.Repo, pid)`


