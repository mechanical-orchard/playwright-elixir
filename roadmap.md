# Playwright Elixir Upgrade Roadmap: 1.49.1 → 1.59.1

This roadmap tracks the upgrade of playwright-elixir from Playwright 1.49.1 to 1.59.1.

**Branch:** `upgrade-playwright-1.59`
**Protocol diff:** ~3,715 lines changed in `protocol.yml` across 10 minor versions.

---

## Phase 1: Package & Version Bump ✅

- [x] Update `priv/static/package.json`: `playwright` from `1.49.1` to `1.59.1`
- [x] Update `priv/static/package.json`: `engines.node` from `>=16` to `>=18`
- [x] Run `npm install` in `priv/static/`
- [x] Install updated browser binaries (`npx playwright install`)
- [x] Update `mix.exs` version from `1.49.1-alpha.2` to `1.59.1-alpha.1`
- [x] Verify `priv/static/driver.js` symlink still resolves

---

## Phase 2: Breaking Changes ✅

### 2a: Removed Protocol Commands ✅

- [x] **Remove `Page.Accessibility` module** — `accessibilitySnapshot` command removed in 1.57
- [x] **Remove `Selectors` module** — interface removed entirely in 1.57
- [x] **Remove `backgroundPage` event** from BrowserContext docs and type

### 2b: Required Timeouts ✅

- [x] Add default timeout (30_000) to all `Channel.post` calls
  - Server validator ignores extra params, so safe to add globally
  - Special cases: `is_hidden`/`is_visible` timeout stripped by server validator automatically

### 2c: Type System Changes ✅

- [x] Fixed float serialization (was broken, now works)
- [x] Added typed array (`ta`) deserialization support
- [x] Added `{:error, _}` clause to `deserialize/1` (pre-existing bug)

### 2d: Other Breaking Changes ✅

- [x] Video changed from event to initializer property — handled in Page.init/2
- [x] New "Disposable" return type — handled in `post!` and `add_init_script`
- [x] New "Debugger" channel owner type — handled by GenericChannelOwner fallback
- [x] `viewportSizeChanged` new event — handler supports both camelCase and snake_case params
- [ ] `ContextOptions.recordHar` removed — HAR recording now via `harStart`/`harExport` commands (not yet used)
- [ ] `Route.continue` no longer allows overriding Cookie header (document only)
- [ ] Glob patterns in `page.route()` no longer support `?` and `[]` (document only)
- [ ] `BrowserType.launchPersistentContext` now returns `{browser, context}` instead of just `context` (not yet implemented)

---

## Phase 3: Deprecations ✅

- [x] Mark `Page.type/4` as deprecated
- [x] Mark `Frame.type/4` as deprecated
- [x] Mark `Locator.type/3` as deprecated

---

## Phase 4: New APIs ✅ (priority items)

### Priority (small, high value) ✅

- [x] `Page.requests/1` — returns up to 100 last network requests (1.56)
- [x] `Page.aria_snapshot/2` — shorthand for body aria snapshot (1.59)
- [x] `Locator.describe/2` — annotate locator for traces/reports (1.53)
- [x] Cookie `partitionKey` field in `BrowserContext` cookie type (1.53)
- [x] `Page.emulateMedia` `contrast` option — already implemented
- [x] Unskipped `console_messages` and `page_errors` tests
- [x] Fixed CDPSession detach error message for Chrome 147

### Medium (new params on existing commands)

- [x] `Frame.click`/`dblclick`/`dragAndDrop` `steps: int` option (1.54) — documented, already passes through
- [x] `ElementHandle.click` `steps: int` option (1.54) — documented, already passes through
- [ ] `Frame.expect` `selector` now optional (1.57) — deferred, expect not implemented
- [x] Worker console event support — added `on/3`, `url` property, `init/2` with close binding
- [x] `BrowserContext.storageState` `indexedDB` option (1.57)

### Deferred (larger effort)

- [ ] `Screencast` module — new ChannelOwner for video recording with annotations (1.50)
  - Methods: `start`, `stop`, `showActions`, `hideActions`, `showChapter`, `showOverlay`, `showOverlays`, `hideOverlays`
- [ ] IndexedDB support in storage state (new `IndexedDBDatabase` type)
- [ ] `Page.snapshotForAI` (internal, for MCP/AI integrations)

---

## Phase 5: Testing & Validation ✅

- [x] Run full test suite — 519 tests, 0 failures
- [x] Accessibility tests removed
- [x] Browser installation verified (Chrome 147, Firefox 148, WebKit 26.4)
- [x] `consoleMessages`, `pageErrors` tests unskipped and passing
- [ ] Test on Firefox and WebKit engines (currently only Chromium)
- [ ] Add smoke test verifying driver version is 1.59.x

---

## Phase 6: Documentation & Release

- [ ] Update README version references
- [ ] Update `man/guides/feature_parity.md` to reflect final state
- [ ] Write changelog entry covering:
  - Breaking: Accessibility API removed, Selectors interface removed
  - Deprecated: `type()` methods
  - New: `requests/1`, `aria_snapshot/2`, `describe/2`, cookie `partitionKey`
- [ ] Update `man/basics/release-notes.md`

---

## Protocol Change Summary

| Version | Key Changes |
|---------|------------|
| 1.50 | `type()` deprecated, Screencast API added |
| 1.51 | Glob patterns changed, Route.continue cookie override removed |
| 1.53 | `Locator.describe()`, cookie `partitionKey` |
| 1.54 | `click`/`dragTo` `steps` option |
| 1.55 | Chromium extension manifest v2 dropped |
| 1.56 | `Page.requests()`, `emulateMedia` contrast |
| 1.57 | **Accessibility API removed**, Selectors removed, Node 16 dropped, Chrome for Testing, all timeouts required |
| 1.58 | `tracing.group()` |
| 1.59 | `routeWebSocket`, `Page.ariaSnapshot()`, Worker console events |

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| `accessibilitySnapshot` removed | **High** | Remove module, skip tests |
| `Selectors` interface removed | **High** | Migrate to BrowserContext methods |
| Timeouts now required | **High** | Audit all Channel.post calls, add defaults |
| New ChannelOwner types (e.g. Screencast) cause crash | **Medium** | Add fallback in `ChannelOwner.module/1` |
| Serialization changes (typed arrays) | **Medium** | Add `ta` handler in Serialization.ex |
| Glob pattern behavior change | **Low** | Document only — Elixir-side matcher already ignores `?`/`[]` |
| `number` → `int`/`float` split | **Low** | JSON doesn't distinguish; cosmetic |
