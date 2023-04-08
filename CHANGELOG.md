
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Changed

- **BREAKING:** **(WIP/UNSTABLE)** - Substantial API/usage changes are underway. e.g.:
  - We intend to restore the use of tagged-tuple results (`{:ok, _}` and `{:error, _}`) throughout the code base, internally as well as for the "API".
  - Bulk Package renaming.

---

## [v0.1.17-preview-2] - 2021-12-06

### Changed

- **BREAKING:** No longer return successful API/capability calls with `{:ok, resource}`. This approach was feeling more and more cumbersome to the user of the package, and provided no real value.

---

## footnotes

...
