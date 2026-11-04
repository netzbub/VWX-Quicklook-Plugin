# VWX-Quicklook-Plugin

<p align="center">
  <a href="https://github.com/netzbub/VWX-Quicklook-Plugin"><img src="https://img.shields.io/badge/github-repo-blue?logo=github" alt="GitHub repo"></a>
  <img src="https://img.shields.io/github/v/tag/netzbub/VWX-Quicklook-Plugin?label=version&color=blue" alt="version">
  <img src="https://img.shields.io/github/license/netzbub/VWX-Quicklook-Plugin?color=olive&cacheSeconds=3600" alt="license">
  <img src="https://img.shields.io/github/last-commit/netzbub/VWX-Quicklook-Plugin?color=blueviolet" alt="last commit">
  <img src="https://img.shields.io/github/issues/netzbub/VWX-Quicklook-Plugin?color=yellow" alt="open issues">
  <img src="https://img.shields.io/badge/macOS-15%2B-000000?logo=apple&logoColor=white" alt="macOS 15+">
  <img src="https://img.shields.io/badge/Vectorworks-2014%E2%80%932024-0A7BC2" alt="Vectorworks files 2014–2024">
  <img src="https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white" alt="Swift 5">
  <img src="https://img.shields.io/badge/Claude_Code-built_with-D97757?logo=claude&logoColor=white" alt="built with Claude Code">
</p>

*Finder thumbnails and Quick Look previews (space bar) for Vectorworks® files on macOS 15 Sequoia and later.*

> **Scope in one sentence.** macOS 15 no longer loads the legacy `VectorWorksQL.qlgenerator` that ships with Vectorworks; this project replaces it with a modern Quick Look thumbnail extension and preview extension that display the preview image Vectorworks embeds in every saved file.

🇩🇪 **German version: [README.de.md](README.de.md)**

This is an independent personal project, not a product, and not affiliated with Vectorworks, Inc. or Nemetschek Group.

---

### Table of contents

- [Purpose](#purpose)
- [Background: why the bundled plug-in stopped working](#background-why-the-bundled-plug-in-stopped-working)
- [How it works](#how-it-works)
- [Supported files](#supported-files)
- [Download](#download)
- [Build and install](#build-and-install)
- [Project structure](#project-structure)
- [Status and known limitations](#status-and-known-limitations)
- [Genesis](#genesis)
- [Version History](#version-history)
- [License](#license)
- [Acknowledgments](#acknowledgments)
- [Trademarks + Logos](#trademarks--logos)

---

### Purpose

Vectorworks ships a Quick Look generator plug-in (`.qlgenerator`). Apple removed support for this plug-in type in macOS 15 Sequoia, so Vectorworks files show only a generic icon in the Finder and no preview on the space bar. Modern Quick Look support must be delivered as app extensions inside an app bundle. This project provides exactly that — and nothing else.

---

### Background: why the bundled plug-in stopped working

- **Old technology.** Until macOS 10.14, Quick Look was extended by generator plug-ins (`.qlgenerator`) in the QuickLook framework. With macOS 10.15 Catalina (2019) Apple introduced app extensions (QuickLook Thumbnailing, preview extensions, presented at WWDC 2019) and deprecated the generators ([Howard Oakley, Eclectic Light](https://eclecticlight.co/2024/10/31/how-sequoia-has-changed-quicklook-and-its-thumbnails/)).
- **Removal in macOS 15.0 Sequoia (2024).** Since Sequoia, third-party generator plug-ins are no longer loaded at all; all custom Quick Look support has to be delivered as app extensions ([Michael Tsai](https://mjtsai.com/blog/2024/11/05/sequoia-no-longer-supports-quicklook-generator-plug-ins/)). Xcode issued no warning when building generators, so many vendors missed the deprecation.
- **The Vectorworks plug-in.** `VectorWorksQL.qlgenerator` in Vectorworks 2022 and 2024 is still such a generator (version string "2015", built against the macOS 11/12 SDK, universal binary). It installs and is code-signed, but Sequoia silently ignores it — Vectorworks files show only a generic icon.
- **What the old plug-in actually did.** It rendered nothing; it read the JPEG preview that Vectorworks embeds when saving and drew it. Newer files compress their body in chunks with Google snappy, so the preview has to be decompressed first. This project reimplements exactly that, as an independent implementation for interoperability.
- **Tools that no longer help.** `qlmanage -m` only lists generators and does not see app extensions; registered extensions are shown by `pluginkit -m -p com.apple.quicklook.thumbnail` and under System Settings → General → Login Items & Extensions → Quick Look.

---

### How it works

Vectorworks stores a JPEG preview inside each document when it is saved. The extensions do not render drawings; they only locate and decode that embedded image.

| Component | Role |
| --- | --- |
| `Shared/VWXPreview.swift` | Reads the file header, locates the preview record, decompresses the body if necessary, returns the JPEG |
| `Snappy` (same file) | Small self-contained decoder for the raw [snappy](https://github.com/google/snappy/blob/main/format_description.txt) block format used by newer files |
| `VWXThumbnail.appex` | Quick Look thumbnail extension (Finder icons, gallery view) |
| `VWXPreview.appex` | Quick Look preview extension (space bar), data-based |
| `VWXQuickLook.app` | Empty host app that carries both extensions; launching it once registers them |
| `vwxextract` | Command-line test tool: writes the embedded preview of given files as `.jpg` |

No third-party libraries, no network access, sandboxed read-only file access.

---

### Supported files

| Type | Extension | Content type |
| --- | --- | --- |
| Document | `.vwx`, `.mcd` | `net.nemetschek.vectorworks.document` |
| Template | `.sta` | `net.nemetschek.vectorworks.stationery` |
| Project file | `.vwxp` | `net.nemetschek.vectorworks.project` |
| Working file | `.vwxw` | `net.nemetschek.vectorworks.working` |

Tested with files saved by Vectorworks 2014, 2022 and 2024.

---

### Download

Ready-made app, no Xcode needed: download `VWXQuickLook-<version>.zip` from [Releases](https://github.com/netzbub/VWX-Quicklook-Plugin/releases/latest).

1. Unzip and drag `VWXQuickLook.app` into `/Applications`.
2. Launch the app once. macOS blocks it on first launch because it is not notarized by Apple (that would require a paid Apple Developer account). Then: System Settings → Privacy & Security → scroll down → click "Open Anyway" next to "VWXQuickLook" and confirm ([Apple Support](https://support.apple.com/en-us/102445)).
   Alternatively remove the quarantine flag in Terminal, then launch:

   ```
   xattr -dr com.apple.quarantine /Applications/VWXQuickLook.app
   ```

3. Remove the old generator if present: `~/Library/QuickLook/VectorWorksQL.qlgenerator`.

The app is ad-hoc signed and not notarized. If you do not trust the ready-made app, build it yourself from source (next section).

---

### Build and install

Requirements: macOS 15+, Xcode 26+, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`), a free Apple ID signed in to Xcode (Personal Team).

1. Put your team ID into `Config/Local.xcconfig` (not committed):

   ```
   DEVELOPMENT_TEAM = XXXXXXXXXX
   ```

2. Generate the project and build:

   ```
   xcodegen generate
   xcodebuild -project VWXQuickLook.xcodeproj -scheme VWXQuickLook -configuration Release -derivedDataPath build/DerivedData -allowProvisioningUpdates build
   ```

3. Copy the app to `/Applications` and launch it once:

   ```
   ditto build/DerivedData/Build/Products/Release/VWXQuickLook.app /Applications/VWXQuickLook.app
   open /Applications/VWXQuickLook.app
   ```

4. Remove the old generator if present: `~/Library/QuickLook/VectorWorksQL.qlgenerator`.

If previews do not appear: System Settings → General → Login Items & Extensions → Quick Look → enable "VWX QuickLook". Reset the Quick Look cache with `qlmanage -r && qlmanage -r cache`.

---

### Project structure

```
App/                  host app (SwiftUI, one info window)
ThumbnailExtension/   QLThumbnailProvider
PreviewExtension/     QLPreviewProvider (data-based)
Shared/               file parser and snappy decoder
Tools/vwxextract/     command-line test tool
Config/               signing configuration (Local.xcconfig is git-ignored)
project.yml           XcodeGen project definition
```

---

### Status and known limitations

- Works for files that Vectorworks saved with a preview — reliably for files created with Vectorworks 2014 and later.
- **Older files usually contain no usable preview**, so there is nothing to show. Analysis of 15 sample files from 1998–2013: files converted to the 2014 format often keep a stale preview pointer without an actual preview image; pre-2008 formats (MiniCAD/VectorWorks 8–10) store at most 64×64 px resource thumbnails. Showing one of those would misrepresent the drawing, so the extension deliberately falls back to the generic icon. **Remedy:** open the file in a current Vectorworks and save it once — this writes a new preview.
- The preview sometimes appears with a short delay. Extraction itself takes about 30 ms regardless of file size (measured on 25 files up to 30 MB); the delay most likely comes from macOS starting the extension process (not verified).

---

### Genesis

The idea and the requirements are mine. The file format was analysed, and the extensions were designed, written and tested in close teamwork with **Claude Opus 5.5** in **Claude Code**.

---

### Version History

| Version | Changes | Date |
| :--- | :--- | :--- |
| v0.1.0 | Initial release: thumbnail and preview extension, host app, snappy decoder, `vwxextract` test tool, READMEs (EN/DE), changelog, GPL-3.0 license | 2026.10.14 |
| v0.1.1 | README (EN/DE): background on the end of `.qlgenerator` support in macOS 15, analysis of pre-2014 files, timing measurement; `.history` versioned, only `.archive` git-ignored | 2026.10.14 |
| v0.1.2 | Ready-made app as zip under Releases, README section "Download" with Gatekeeper note; app version now taken from `MARKETING_VERSION`, copyright string in `App/Info.plist` fixed (GPL instead of MIT) | 2026.11.04 |

---

### License

**GNU General Public License v3.0 or later (GPL-3.0-or-later).** You may use, redistribute, fork and modify this project, provided derivative work stays under the same license and the original source is credited. See [LICENSE](LICENSE).

---

### Acknowledgments

- Analysis, code, documentation and review in teamwork with `Claude Opus 5.5` (Claude Code).
- Compression format: [Google snappy](https://github.com/google/snappy) format description; the decoder here is an independent implementation.
- Project generation: [XcodeGen](https://github.com/yonaskolb/XcodeGen).

### Trademarks + Logos

Vectorworks is a registered trademark of Vectorworks, Inc., part of the Nemetschek Group. All product names, logos and brands mentioned in this repository are the property of their respective owners. They are used here for identification and descriptive purposes only and do not imply any affiliation with or endorsement by their owners.
