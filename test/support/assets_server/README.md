# A Server for Playwright Test Assets

This embedded assets server is run in order to support the testing of `playwright-assets` itself.

## Licenses

The assets within `assets` are acquired from [microsoft/playwright](https://github.com/microsoft/playwright), which uses the Apache License (copied here, per the license terms).

## Contributing

Updates to the assets pulled from Playwright and embedded here should be made as follows:

```shell
git remote add --fetch --master master --no-tags playwright https://github.com/microsoft/playwright.git
git rm -r ${PROJECT}/test/support/assets_server/assets
git read-tree --prefix=${PROJECT}/test/support/assets_server/ -u playwright/master:tests/assets
```

Any assets that are additional to the "canonical" assets from [microsoft/playwright](https://github.com/microsoft/playwright) should be added to `${PROJECT}/test/support/assets_server/extras`.

## Usage

See [the test examples](../assets_server_test.exs)
