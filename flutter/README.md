# Flutter XML Service Editor

Flutter/Windows-Port des WinForms-Editors im Repo-Root. Original und Flutter sind unabhängig startbar.

## Start

```bash
cd flutter
flutter pub get
flutter run -d windows
```

Beim ersten Start werden `schema.xsd` und `templates/**` nach
`%LocalAppData%/…/XmlEditorFlutter/` kopiert (beschreibbar für den Vorlagen-Editor).

## XSD-Validator (FFI)

```bash
cd ../native
dotnet publish -c Release -r win-x64 -o publish
copy publish\xsd_validator.dll ..\flutter\native\xsd_validator.dll
```

Ohne DLL funktioniert der Editor weiterhin; nur „Gegen XSD prüfen“ meldet dann einen Fehler.

## Struktur

- `lib/domain/` — Katalog-/XML-Regeln (1:1-Port)
- `lib/data/` — Datei-IO, Profiles, Asset-Seed
- `lib/ui/` — Flutter-Oberfläche
- `lib/ffi/` — Binding zu `xsd_validator.dll`
