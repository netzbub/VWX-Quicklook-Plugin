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
- [Hintergrund: Warum das mitgelieferte Plugin nicht mehr funktioniert](#hintergrund-warum-das-mitgelieferte-plugin-nicht-mehr-funktioniert)
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

### Hintergrund: Warum das mitgelieferte Plugin nicht mehr funktioniert

- **Alte Technik.** Bis macOS 10.14 wurde Quick Look über Generator-Plugins (`.qlgenerator`) im QuickLook-Framework erweitert. Mit macOS 10.15 Catalina (2019) führte Apple App-Erweiterungen ein (QuickLook Thumbnailing, Preview-Erweiterungen, vorgestellt auf der WWDC 2019) und erklärte die Generatoren für veraltet ([Howard Oakley, Eclectic Light](https://eclecticlight.co/2024/10/31/how-sequoia-has-changed-quicklook-and-its-thumbnails/)).
- **Abschaltung mit macOS 15.0 Sequoia (2024).** Seit Sequoia werden Generator-Plugins von Drittanbietern gar nicht mehr geladen; eigene Quick-Look-Unterstützung muss als App-Erweiterung kommen ([Michael Tsai](https://mjtsai.com/blog/2024/11/05/sequoia-no-longer-supports-quicklook-generator-plug-ins/)). Xcode warnte beim Bauen von Generatoren nicht, viele Hersteller haben die Abkündigung daher übersehen.
- **Das Vectorworks-Plugin.** `VectorWorksQL.qlgenerator` in Vectorworks 2022 und 2024 ist noch ein solcher Generator (Versionskennung „2015“, gebaut gegen das macOS-11/12-SDK, Universal Binary). Es wird installiert und ist signiert, aber Sequoia ignoriert es kommentarlos – Vectorworks-Dateien zeigen nur ein allgemeines Symbol.
- **Was das alte Plugin eigentlich tat.** Es renderte nichts, sondern las das JPEG-Vorschaubild, das Vectorworks beim Speichern einbettet, und zeichnete es. Neuere Dateien komprimieren ihren Inhalt blockweise mit Google snappy, die Vorschau muss also erst entpackt werden. Genau das baut dieses Projekt als eigenständige Implementierung zur Herstellung der Interoperabilität nach.
- **Werkzeuge, die nicht mehr helfen.** `qlmanage -m` zeigt nur Generatoren, keine App-Erweiterungen. Registrierte Erweiterungen zeigen `pluginkit -m -p com.apple.quicklook.thumbnail` und Systemeinstellungen → Allgemein → Anmeldeobjekte & Erweiterungen → Quick Look.

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

- Funktioniert für Dateien, die Vectorworks mit Vorschau gespeichert hat – zuverlässig für Dateien ab Vectorworks 2014.
- **Ältere Dateien enthalten meist keine verwendbare Vorschau**, es gibt also nichts anzuzeigen. Untersuchung von 15 Beispieldateien aus 1998–2013: Ins 2014er-Format konvertierte Dateien behalten oft einen veralteten Vorschau-Verweis ohne tatsächliches Vorschaubild; Formate vor 2008 (MiniCAD/VectorWorks 8–10) enthalten höchstens Ressourcen-Miniaturen mit 64×64 px. Eine davon anzuzeigen würde einen falschen Planinhalt vortäuschen, daher bleibt bewusst das allgemeine Symbol. **Abhilfe:** Datei in einem aktuellen Vectorworks öffnen und einmal speichern – dabei wird eine neue Vorschau geschrieben.
- Die Vorschau erscheint gelegentlich mit kurzer Verzögerung. Die Extraktion selbst dauert unabhängig von der Dateigröße etwa 30 ms (gemessen an 25 Dateien bis 30 MB); die Verzögerung entsteht sehr wahrscheinlich beim Start des Erweiterungsprozesses durch macOS (nicht verifiziert).

---

### Entstehung

Idee und Anforderungen stammen von mir. Das Dateiformat wurde in enger Zusammenarbeit mit **Claude Opus 5.5** in **Claude Code** analysiert, die Erweiterungen dort entworfen, geschrieben und getestet.

---

### Versionsgeschichte

| Version | Änderungen | Datum |
| :--- | :--- | :--- |
| v0.1.0 | Erste Version: Thumbnail- und Preview-Erweiterung, Träger-App, Snappy-Decoder, Testwerkzeug `vwxextract`, READMEs (EN/DE), Changelog, GPL-3.0-Lizenz | 2026.10.14 |
| v0.1.1 | README (EN/DE): Hintergrund zum Ende der `.qlgenerator`-Unterstützung in macOS 15, Analyse von Dateien vor 2014, Zeitmessung; `.history` wird versioniert, nur `.archive` ist git-ignoriert | 2026.10.14 |

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
