# VWX-Quicklook-Plugin

<p align="center">
  <a href="https://github.com/netzbub/VWX-Quicklook-Plugin"><img src="https://img.shields.io/badge/github-repo-blue?logo=github" alt="GitHub repo"></a>
  <img src="https://img.shields.io/github/v/tag/netzbub/VWX-Quicklook-Plugin?label=version&color=blue" alt="version">
  <img src="https://img.shields.io/github/license/netzbub/VWX-Quicklook-Plugin?color=olive&cacheSeconds=3600" alt="license">
  <img src="https://img.shields.io/github/last-commit/netzbub/VWX-Quicklook-Plugin?color=blueviolet" alt="last commit">
  <img src="https://img.shields.io/github/issues/netzbub/VWX-Quicklook-Plugin?color=yellow" alt="open issues">
  <img src="https://img.shields.io/badge/macOS-15%2B-000000?logo=apple&logoColor=white" alt="macOS 15+">
  <img src="https://img.shields.io/badge/Vectorworks-2014%E2%80%932024-0A7BC2" alt="Vectorworks-Dateien 2014–2024">
  <img src="https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white" alt="Swift 5">
  <img src="https://img.shields.io/badge/Claude_Code-built_with-D97757?logo=claude&logoColor=white" alt="built with Claude Code">
</p>

*Finder-Miniaturen und Quick-Look-Vorschau (Leertaste) für Vectorworks®-Dateien unter macOS 15 Sequoia und neuer.*

> **Kurz gesagt.** macOS 15 lädt das mit Vectorworks ausgelieferte `VectorWorksQL.qlgenerator` nicht mehr; dieses Projekt ersetzt es durch eine zeitgemäße Quick-Look-Thumbnail- und -Preview-Erweiterung, die das Vorschaubild anzeigt, das Vectorworks in jede gespeicherte Datei einbettet.

🇬🇧 **English version: [README.md](README.md)**

Unabhängiges privates Projekt, kein Produkt, keine Verbindung zu Vectorworks, Inc. oder der Nemetschek Group.

---

### Inhalt

- [Zweck](#zweck)
- [Funktionsweise](#funktionsweise)
- [Unterstützte Dateien](#unterstützte-dateien)
- [Bauen und installieren](#bauen-und-installieren)
- [Projektstruktur](#projektstruktur)
- [Stand und bekannte Einschränkungen](#stand-und-bekannte-einschränkungen)
- [Entstehung](#entstehung)
- [Versionsgeschichte](#versionsgeschichte)
- [Lizenz](#lizenz)
- [Danksagung](#danksagung)
- [Marken + Logos](#marken--logos)

---

### Zweck

Vectorworks liefert ein Quick-Look-Generator-Plugin (`.qlgenerator`) mit. Apple hat die Unterstützung für diesen Plugin-Typ mit macOS 15 Sequoia entfernt; Vectorworks-Dateien zeigen im Finder seither nur ein allgemeines Symbol und keine Vorschau per Leertaste. Quick-Look-Unterstützung muss heute als App-Erweiterung in einem App-Bundle geliefert werden. Genau das leistet dieses Projekt – und nichts darüber hinaus.

---

### Funktionsweise

Vectorworks legt beim Speichern ein JPEG-Vorschaubild in der Datei ab. Die Erweiterungen rendern keine Zeichnungen, sie finden und entpacken nur dieses eingebettete Bild.

| Komponente | Aufgabe |
| --- | --- |
| `Shared/VWXPreview.swift` | Liest den Dateikopf, findet den Vorschau-Datensatz, entpackt bei Bedarf und liefert das JPEG |
| `Snappy` (gleiche Datei) | Kleiner, eigenständiger Decoder für das [snappy](https://github.com/google/snappy/blob/main/format_description.txt)-Blockformat neuerer Dateien |
| `VWXThumbnail.appex` | Quick-Look-Thumbnail-Erweiterung (Finder-Symbole, Galerie) |
| `VWXPreview.appex` | Quick-Look-Preview-Erweiterung (Leertaste), datenbasiert |
| `VWXQuickLook.app` | Leere Träger-App für beide Erweiterungen; einmal starten registriert sie |
| `vwxextract` | Kommandozeilen-Testwerkzeug: schreibt die eingebettete Vorschau als `.jpg` |

Keine Fremdbibliotheken, kein Netzwerkzugriff, Sandbox mit reinem Lesezugriff.

---

### Unterstützte Dateien

| Typ | Endung | Content Type |
| --- | --- | --- |
| Dokument | `.vwx`, `.mcd` | `net.nemetschek.vectorworks.document` |
| Vorlage | `.sta` | `net.nemetschek.vectorworks.stationery` |
| Projektdatei | `.vwxp` | `net.nemetschek.vectorworks.project` |
| Arbeitsdatei | `.vwxw` | `net.nemetschek.vectorworks.working` |

Getestet mit Dateien aus Vectorworks 2014, 2022 und 2024.

---

### Bauen und installieren

Voraussetzungen: macOS 15+, Xcode 26+, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`), eine kostenlose Apple-ID in Xcode (Personal Team).

1. Team-ID in `Config/Local.xcconfig` eintragen (wird nicht committet):

   ```
   DEVELOPMENT_TEAM = XXXXXXXXXX
   ```

2. Projekt erzeugen und bauen:

   ```
   xcodegen generate
   xcodebuild -project VWXQuickLook.xcodeproj -scheme VWXQuickLook -configuration Release -derivedDataPath build/DerivedData -allowProvisioningUpdates build
   ```

3. App nach `/Applications` kopieren und einmal starten:

   ```
   ditto build/DerivedData/Build/Products/Release/VWXQuickLook.app /Applications/VWXQuickLook.app
   open /Applications/VWXQuickLook.app
   ```

4. Altes Plugin entfernen, falls vorhanden: `~/Library/QuickLook/VectorWorksQL.qlgenerator`.

Erscheint keine Vorschau: Systemeinstellungen → Allgemein → Anmeldeobjekte & Erweiterungen → Quick Look → „VWX QuickLook“ einschalten. Quick-Look-Cache zurücksetzen mit `qlmanage -r && qlmanage -r cache`.

---

### Projektstruktur

```
App/                  Träger-App (SwiftUI, ein Infofenster)
ThumbnailExtension/   QLThumbnailProvider
PreviewExtension/     QLPreviewProvider (datenbasiert)
Shared/               Dateiparser und Snappy-Decoder
Tools/vwxextract/     Kommandozeilen-Testwerkzeug
Config/               Signatur-Einstellungen (Local.xcconfig ist git-ignoriert)
project.yml           XcodeGen-Projektdefinition
```

---

### Stand und bekannte Einschränkungen

- Funktioniert für Dateien etwa ab 2013/2014.
- Ältere Dateien (etwa vor 2013) zeigen noch keine Vorschau – in Untersuchung.
- Die Vorschau erscheint gelegentlich verzögert, unabhängig von der Dateigröße – in Untersuchung.
- Dateien ohne eingebettete Vorschau (z. B. mit abgeschalteter Vorschau gespeichert) behalten das allgemeine Symbol.

---

### Entstehung

Idee und Anforderungen stammen von mir. Das Dateiformat wurde in enger Zusammenarbeit mit **Claude Opus 5.5** in **Claude Code** analysiert, die Erweiterungen dort entworfen, geschrieben und getestet.

---

### Versionsgeschichte

| Version | Änderungen | Datum |
| :--- | :--- | :--- |
| v0.1.0 | Erste Version: Thumbnail- und Preview-Erweiterung, Träger-App, Snappy-Decoder, Testwerkzeug `vwxextract`, READMEs (EN/DE), Changelog, GPL-3.0-Lizenz | 2026.10.14 |

---

### Lizenz

**GNU General Public License v3.0 oder später (GPL-3.0-or-later).** Nutzung, Weitergabe, Forks und Änderungen sind erlaubt, sofern abgeleitete Werke unter derselben Lizenz bleiben und die Quelle genannt wird. Siehe [LICENSE](LICENSE).

---

### Danksagung

- Analyse, Code, Dokumentation und Review in Zusammenarbeit mit `Claude Opus 5.5` (Claude Code).
- Kompressionsformat: Formatbeschreibung von [Google snappy](https://github.com/google/snappy); der Decoder hier ist eine eigenständige Implementierung.
- Projekterzeugung: [XcodeGen](https://github.com/yonaskolb/XcodeGen).

### Marken + Logos

Vectorworks ist eine eingetragene Marke der Vectorworks, Inc., Teil der Nemetschek Group. Alle in diesem Repository genannten Produktnamen, Logos und Marken sind Eigentum ihrer jeweiligen Inhaber. Sie werden nur zur Identifikation und Beschreibung verwendet und bedeuten keine Verbindung zu den Inhabern oder deren Billigung.
