
## Breaking

- No longer return successful API/capability calls with `{:ok, resource}`. This approach was feeling more and more cumbersome to the user of the package, and provided no real value.

## Changes

- Refactor `Page` -> `Frame | BrowserContext` delegation.
