# Changelog

All notable changes to this project are documented here. Versions follow a SemVer-style `0.x` scheme.

## [0.1.1] - 2026-10-14

### Changed
- README (EN/DE): new section on why the bundled `.qlgenerator` stopped working (deprecated since macOS 10.15, removed in macOS 15.0 Sequoia), with sources.
- README (EN/DE): known limitations rewritten after analysing 15 files from 1998–2013 (no usable embedded preview; remedy: re-save in current Vectorworks) and measuring extraction time (~30 ms, independent of file size).
- `.gitignore`: `.history/` is versioned; only `.archive/` stays local.

## [0.1.0] - 2026-10-14

Initial release.

### Added
- Quick Look thumbnail extension (`VWXThumbnail.appex`) for Finder icons and gallery view.
- Quick Look preview extension (`VWXPreview.appex`, data-based) for the space-bar preview.
- Host app `VWXQuickLook.app` that carries and registers both extensions.
- `Shared/VWXPreview.swift`: header parser for Vectorworks files and an independent decoder for the raw snappy block format; extracts the embedded JPEG preview.
- `vwxextract` command-line test tool.
- XcodeGen project definition, signing via git-ignored `Config/Local.xcconfig`.
- READMEs (EN/DE), GPL-3.0-or-later license.

### Known limitations
- Files older than about 2013 show no preview.
- Occasional delay before the preview appears, not correlated with file size.
