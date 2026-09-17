# Flutter XML Service Editor

Aktueller OpenQCat-/KURSNET-Editor (Windows). Überblick und Schnellstart: [README im Repo-Root](../README.md).

## Start

```powershell
cd flutter
flutter pub get
flutter run -d windows
```

Erststart kopiert Schema, Vorlagen und Wertebereiche nach Application Support, Ordner `XmlEditorFlutter`.

Vorlagen dort editieren — nicht die Assets, außer die Änderung soll für alle Neuinstallationen gelten (`assets/openqcat/templates/`).

## XSD-Validator

```powershell
cd ../native
dotnet publish -c Release -r win-x64 -o publish
copy publish\xsd_validator.dll ..\flutter\native\xsd_validator.dll
```

Ohne DLL: Editor ok, Button „Gegen XSD prüfen“ meldet den fehlenden Pfad.

Falls der Windows-Build `ProgramFiles(x86)` vermisst: Variable setzen oder `.vscode/launch.json` nutzen.

## Assets

Unter `assets/openqcat/`:

| Pfad | Inhalt |
|------|--------|
| `schema.xsd` | OpenQCat 1.1 |
| `templates/services/` | Main + Ort/Beschäftigungsart |
| `templates/profiles/` | `locations.xml`, `coursetypes.xml` |
| `reference/*.csv` | Orte, Systematik, Zertifizierer |
| `reference/wertebereiche/*.dat` | BA-Codes (`id\|label`) |

Einträge in `pubspec.yaml` und `AppDataStore` synchron halten.

## Code

Siehe [docs/WARTUNG.md](../docs/WARTUNG.md). Kurz:

- `lib/app/` — `EditorController`
- `lib/domain/` — Katalog, Regeln, Mappings
- `lib/data/` — IO, SOAP, Referenz
- `lib/ui/` — nur Darstellung
- `lib/ffi/` — XSD-DLL

```powershell
dart analyze lib
flutter test
```
