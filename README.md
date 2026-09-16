# XML Service Editor (Monorepo)

Ein Repo, zwei unabhängige Apps:

| Ordner | Stack | Start |
|--------|--------|--------|
| Repo-Root (WinForms) | .NET Windows Forms | `dotnet run` bzw. Visual Studio öffnen `XmlEditorUi.sln` |
| [`flutter/`](flutter/) | Flutter Windows | `cd flutter` → `flutter run -d windows` |
| [`native/`](native/) | C# NativeAOT (XSD) | nur für Flutter „Gegen XSD prüfen“ |

Die Projekte teilen sich **keine** Build-Outputs. WinForms bleibt am Root wie bisher; Flutter und Native liegen in eigenen Ordnern und können parallel entwickelt werden.

## WinForms (Original)

```bash
cd XmlEditorUi
dotnet run
```

## Flutter-Port

```bash
cd flutter
flutter pub get
flutter run -d windows
```

XSD-Validator bauen (einmalig / nach Native-Änderungen):

```bash
cd native
dotnet publish -c Release -r win-x64 -o publish
copy publish\xsd_validator.dll ..\flutter\native\
```

Details: [`flutter/README.md`](flutter/README.md)

## Konflikte vermeiden

- **Nicht** Flutter-Quellen unter `Forms/` oder `Services/` mischen
- Build-Artefakte sind per `.gitignore` ausgeschlossen (`bin/`, `obj/`, `flutter/build/`, …)
- Templates/Schema: WinForms nutzt `templates/` + `schema.xsd` am Root; Flutter seedet eigene Kopien nach AppData aus `flutter/assets/`
