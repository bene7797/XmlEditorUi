# Wartungshandbuch

Ziel: eine neue Person findet Klasse, Verantwortlichkeit und die richtige Datei, ohne den ganzen Port nachbauen zu müssen.

Einstieg für den Alltag: [README.md](../README.md). Vorlagen-Felder: [VORLAGEN.md](VORLAGEN.md).

Die **aktive Codebasis** ist `flutter/lib/`. WinForms (`Forms/`, `Services/`, `Models/`) ist Legacy mit ähnlichen Namen.

---

## 1. Datenfluss

```
main()
  → AppDataStore.ensureInitialized()     # Assets nach AppData kopieren
  → EditorController(store)              # Session + Templates + Referenz
  → XmlEditorApp → HomeShell
        ├─ ServiceEditorPage             # Katalog
        └─ TemplateEditorPage            # Vorlagen
```

UI spricht **nur** `EditorController` an. XML-Pfade, Export-Sanitize und SOAP bleiben außerhalb der Widgets.

Pfad-Syntax überall: `ELEMENT/CHILD` und `ELEMENT@type` (case-insensitive), analog zum alten C# `XmlHelper`.

---

## 2. Verzeichnis `flutter/lib/`

```
lib/
├── main.dart
├── app/editor_controller.dart
├── ui/
│   ├── home_shell.dart
│   ├── service_editor/service_editor_page.dart
│   ├── template_editor/template_editor_page.dart
│   ├── widgets/field_grid.dart
│   └── dialogs/
├── domain/
│   ├── catalog/          # Katalog-Session + Modelle
│   ├── fields/           # welche XML-Pfade die UI zeigt
│   ├── templates/        # Main + Ort + Beschäftigungsart mergen
│   ├── dates/
│   ├── titles/
│   └── kursnet/          # Leitfaden-Regeln (nicht XSD)
├── data/
│   ├── assets/           # Seed nach AppData
│   ├── xml/              # Lesen, Pfade
│   ├── templates/        # XML-Dateien der Vorlagen
│   ├── profiles/         # locations.xml / coursetypes.xml
│   ├── reference/        # BA-Wertebereiche
│   └── kursnet/          # SOAP
├── ffi/xsd_validator.dart
└── debug/xml_file_diff.dart
```

---

## 3. Klassen- und Funktionskatalog

Private `_foo`-Methoden sind absichtlich kurz gehalten. Sie gehören zur Klasse darüber.

### 3.1 Start & App-Fassade

#### `main.dart` — `main()`, `XmlEditorApp`

| Symbol | Aufgabe |
|--------|---------|
| `main()` | Binding, `AppDataStore`, `EditorController`, `runApp` |
| `XmlEditorApp` | `MaterialApp`, Theme, `HomeShell` |

#### `app/editor_controller.dart`

Fassade zwischen UI und Domain. Hält die aktuelle Auswahl und Statuszeile.

| Symbol | Aufgabe |
|--------|---------|
| `CourseListEntry` | Listeneintrag: `service`, `title`, `isVeranstaltung` |
| `EditorController` | `ChangeNotifier`, besitzt Session/Templates/Profiles/Referenz |
| `sortedCourses` | Angebote zuerst, darunter ihre Termine (nach Startdatum) |
| `loadXml` / `selectService` | Katalog laden, Zeile wählen |
| `setFieldValue` | Freitext/Datum setzen; bei Kursstart Default-Daten nachziehen |
| `setCodedValue` | BA-Code: `type` + Label, **ohne** Elternknoten mit Kindern zu zerstören |
| `setSystematik` | `FEATURE/FNAME` + passendes `FVALUE` |
| `createService` | Main-Template + Ort + optional Beschäftigungsart |
| `copyWith` | bestehenden SERVICE mit neuem Ort/Typ kopieren |
| `addVeranstaltung` | Termin (`type=false`) zum Angebot |
| `deleteSelected` | in `UPDATE_CATALOG/DELETE` merken |
| `buildValidatedExport` | Export bauen + `KursnetRules.validateDocument` |
| `exportXml` | Datei schreiben |
| `validateKursnetRules` | Prüfung ohne Datei |
| `uploadToKursnet` | SOAP action 1 oder 2 |
| `saveKursnetUser` / `loadSavedKursnetUser` | nur Loginname in `kursnet_login.json` (kein Passwort) |
| `validateAgainstSchema` | FFI gegen `schema.xsd` |
| `newServiceTitles` / `updatedServiceTitles` / `deletedServiceTitles` | Statusleisten |

`setCodedValue` setzt bei Blatt-Elementen Text = Label und `@type` = Id. `DURATION` und Knoten **mit Kind-Elementen** (z.B. `EDUCATION`) bekommen nur `@type`.

---

### 3.2 Domain: Katalog

#### `domain/catalog/models.dart`

| Typ | Aufgabe |
|-----|---------|
| `ServiceState` | `unchanged`, `neu`, `updated` |
| `DeletedServiceInfo` | `productId` + Titel für DELETE-Block |
| `QuickFieldDefinition` | Label + Pfad der Schnellfelder (Daten) |
| `TemplateFieldDefinition` | Label + Pfad in Vorlagen-Grids |
| `LocationProfile` | Name + Map Kurzname → Wert (`ZIP`, `CITY`, …) |
| `CourseTypeProfile` | Name + Werte + `attributes` (`INSTRUCTION_TIME@type`, …) |

#### `domain/catalog/catalog_session.dart` — `CatalogSession`

Port von `XmlServiceManager`. Arbeitet auf einem `XmlDocument`.

| Symbol | Aufgabe |
|--------|---------|
| `loadXml` / `loadXmlString` | Katalog laden, Header merken |
| `getServiceNodes` / `getActiveServices` | `SERVICE` außerhalb von `DELETE` |
| `addServiceFromConfiguredTemplate` | neue `PRODUCT_ID`, `COURSE_ID` sync, State `neu` |
| `copyServiceWithConfiguration` | Kopie + Ort/Typ, neue Id |
| `isAngebot` | `EDUCATION@type` fehlt oder `true` |
| `educationCourseId` | `…/EDUCATION/COURSE_ID` |
| `addVeranstaltungFrom` | Termin: `type=false`, `COURSE_ID` = Angebots-Id, neue `PRODUCT_ID` |
| `removeService` | aus Baum, in `deletedServices` |
| `markFieldAsChanged` / `markAsUpdated` | Färbung + UPDATE-Export |
| `generateNewProductId` | fortlaufend aus bestehenden Ids |
| `buildExportDocument` | `NEW_CATALOG` oder `UPDATE_CATALOG` + Sanitize |
| `writeExportFile` | Encoding/Pretty-Print für KURSNET |

Wichtige interne Gruppen:

- `_applyServiceModeForExport` — `mode` auf SERVICE
- `_sanitizeServiceForExport` — u.a. `KursnetRules.sanitizeService`
- `_syncCourseIdWithProductId` — Angebot: COURSE_ID = PRODUCT_ID
- `_ensureSupplierRequiredContent` — Header-Lücken aus Main.xml füllen

**Export ist bewusst nicht 1:1 die Arbeitsdatei.** Leere FAX/CERT_VALIDITY, Land DE, Kontaktrolle, Datumsformat werden normalisiert.

---

### 3.3 Domain: Felder, Daten, Titel, Vorlagen-Merge

#### `domain/fields/important_fields.dart` — `ImportantFields`

Schnell-Grid: Start/Ende Kurs, Ankündigung, Preis. Pfade hier ändern = UI ändert sich.

#### `domain/fields/template_field_definitions.dart`

| Klasse | Aufgabe |
|--------|---------|
| `LocationTemplateFields.essentialFields` | Ort-Tab |
| `CourseTypeTemplateFields.essentialFields` | Beschäftigungsart-Tab (inkl. `type`) |
| `HeaderTemplateFields.essentialFields` | Header-Tab |

#### `domain/fields/template_field_mapping.dart` — `TemplateFieldMapping`

Kurzname aus `locations.xml` / `coursetypes.xml` → voller XML-Pfad beim **Erzeugen** eines Service.

| Map | Inhalt |
|-----|--------|
| `locationFieldPaths` | `CITY` → `…/LOCATION/CITY` usw. |
| `courseTypeFieldPaths` | `INSTRUCTION_TIME`, `DURATION`, `COURSE_TYPE`, … |
| `courseTypeFieldAttributes` | `…@type`-Pfade |

Neues Profil-Feld: **beide** Stellen pflegen (Definition für Editor + Mapping für Create).

#### `domain/fields/template_field_collector.dart` — `TemplateFieldCollector`

| Methode | Aufgabe |
|---------|---------|
| `collectFromService` | alle Blätter/Attribute (Main-Template-Tab), ohne Header/Keyword und ohne Ort-/Kurs-/Wichtig-Pfade |
| `collectFilledFields` | nur befüllte Blätter (Detail-Grid im Service-Editor) |

Attribute werden als `PFAD@type` gesammelt.

#### `domain/dates/date_field_rules.dart` — `DateFieldRules`

| Methode | Aufgabe |
|---------|---------|
| `isDatePath` / `isCourseDatePath` / `isCourseStartPath` | welcher Editor |
| `tryParse` / `format` | OpenQCat `yyyy-MM-dd[+01:00]` bzw. mit `T` und Uhrzeit |
| `isTeilzeit` | aus `INSTRUCTION_TIME` |
| `applyCourseStartDefaults` | Ankündigungsende = Kursstart-Tag; Ankündigungsstart = heute oder Start−1 Jahr; Kursende nach Vollzeit/Teilzeit |
| `getCourseStartDateOrMax` | Sortierung der Kursliste |

Tests: `flutter/test/golden/date_and_export_test.dart`.

#### `domain/titles/service_title_builder.dart` — `ServiceTitleBuilder.build`

Listentitel: `[NEU|UPDATE] [Angebot\|Termin] [Ort - Zeit] | ID | Start | TITLE`.

#### `domain/templates/main_template_variants.dart` — `MainTemplateVariants`

`Main.xml` vs. `Main - Externenprüfung.xml`.

#### `domain/templates/template_configurator.dart` — `TemplateConfigurator`

| Methode | Aufgabe |
|---------|---------|
| `loadMainTemplate` / `loadMainTemplateDocument` | Basis laden |
| `applyLocationConfiguration` | Profile auf LOCATION-Pfade |
| `applyCourseTypeConfiguration` | Werte + `@type` |
| `applyLocationToService` / `applyCourseTypeToService` | statisch, auch beim Kopieren |
| `getConfiguredTemplate` | fertiges Dokument für `addServiceFromConfiguredTemplate` |

---

### 3.4 Domain: KURSNET-Regeln

#### `domain/kursnet/kursnet_rules.dart` — `KursnetRules`

Zusätzlich zum XSD (Leitfaden / Upload-Client).

| Methode | Aufgabe |
|---------|---------|
| `sanitizeDocument` / `sanitizeHeader` / `sanitizeService` | DE, leere Tel/Fax, Creator, Kontaktrolle 2/3 falls nötig |
| `validateDocument` / `validateHeader` / `validateService` | Pflichtfelder, Telefonmuster, Angebot vs. Termin, Orte gegen Referenz |
| `phonePattern` | `+Ziffern.Ziffern` |

`_ensureSupplierContactRole` schreibt die erste Header-Rolle auf type 3, wenn weder 2 noch 3 gesetzt ist. Das ist Leitfaden, nicht XSD.

---

### 3.5 Data-Schicht

#### `data/assets/app_data_store.dart` — `AppDataStore`

| Symbol | Aufgabe |
|--------|---------|
| `ensureInitialized` | Ordner anlegen, Assets kopieren |
| `schemaPath`, `servicesFolder`, `profilesFolder`, `referenceFolder`, `nativeDllFolder`, `credentialsPath` | Laufzeitpfade |
| `_seedIfNeeded` | Schema immer überschreiben; Templates einmalig; Referenzlisten überschreiben |
| `_repairStaleTemplates` | alte Main.xml mit `deutschland` / `CONTACT_ROLE type="5"` / fehlendem EXTENDED_INFO neu aus Assets |

Bundled Quelle: `flutter/assets/openqcat/`.

#### `data/xml/xml_file_io.dart` — `XmlFileIo`

UTF-8 (mit BOM) oder Latin-1/iso-8859-15. OpenQCat-Exporte sind oft Latin-1.

#### `data/xml/xml_document_loader.dart` — `XmlDocumentLoader`

Dünner Wrapper: laden/speichern mit Pretty-Print.

#### `data/xml/xml_path.dart` — `XmlPath`

| Methode | Aufgabe |
|---------|---------|
| `getNodeByPath` / `getTextByPath` / `setNodeByPath` | `A/B` und `A/B@type` |
| `findChild` / `getChildText` / `setChildText` | ein Kind, case-insensitive |
| `hasElementChildren` | Blatt vs. Container |
| `descendantElements` | DFS |
| `isServiceNode` / `isInsideDelete` | welche SERVICE zählen |
| `importElement` | Deep-Copy |
| `setRepeatingChildElements` | z.B. mehrere `EMAIL` |

`setNodeByPath` auf einem Element **ersetzt alle Kinder durch Text**. Deshalb darf `EDUCATION` nie so gesetzt werden — nur `EDUCATION@type`.

#### `data/templates/service_template_repository.dart`

| Typ / Methode | Aufgabe |
|---------------|---------|
| `TemplateDocumentSession` | geöffnete Vorlagen-Datei, `save()` |
| `getTemplateFiles` | alle `*.xml` im Services-Ordner |
| `findMainTemplatePath` | Standard oder Extern |
| `findTemplateByFileNameContains` | Vollzeit/Teilzeit-Datei |
| `findTemplateByCity` | Ort-Vorlage über `LOCATION/CITY` |
| `loadMainTemplateSession` | Main als Session |
| `getDistinctCourseTypeNames` / `getDistinctLocationNames` | Comboboxen |

#### `data/profiles/profile_repository.dart` — `ProfileRepository`

Liest `locations.xml` (`LOCATION_PROFILE`) und `coursetypes.xml` (`COURSE_TYPE_PROFILE`).

#### `data/reference/openq_reference.dart`

| Typ / Methode | Aufgabe |
|---------------|---------|
| `CodedValue` | `id`, `label`, `display` (`id — label`) |
| `OpenqReference.load` | `wertebereiche/*.dat`, CSVs Orte/Systematik/Zertifizierer |
| `optionsForPath` | welcher Wertebereich zu einem XML-Pfad |
| `tooltipFor` | Erklärung + Liste fürs Info-Icon |
| `displayFor` | Anzeige im Grid |
| `isSystematikPath` | `FEATURE/FNAME` |
| `searchSystematik` | Suche im Picker |
| `isKnownPlace` | PLZ+Ort gegen `Orte.csv` |

`.dat`-Format: `id|label` (Tab als Fallback). Encoding Latin-1.

#### `data/kursnet/kursnet_client.dart` — `KursnetClient`

| Methode | Aufgabe |
|---------|---------|
| `upload` | SOAP `urn:upload`, XML als Base64, action 1 oder 2 |
| `testAccess` | `urn:testAccess` |

Endpoint: `…/ws-kursnet/UploadOpenq`. Passwort nur im Dialog, nicht speichern.

---

### 3.6 FFI & Debug

#### `ffi/xsd_validator.dart` — `XsdValidator`

Lädt `ValidateXml` aus `xsd_validator.dll`. Rückgabe `null` = ok, sonst Fehlertext.

Native: `native/NativeExports.cs` (`ValidateXml`, iso-8859-15-fähig).

#### `debug/xml_file_diff.dart` — `XmlFileDiff`, `XmlDiffResult`

Struktureller Vergleich (Elementname-Geschwister, nicht Position). Nur Debug-UI. Max. 250 Diffs. Ignoriert Whitespace/Kommentare.

---

### 3.7 UI

#### `ui/home_shell.dart` — `HomeShell`

Zwei Tabs: Service / Vorlagen.

#### `ui/widgets/field_grid.dart`

| Typ | Aufgabe |
|-----|---------|
| `FieldRowColor` | pending (rot), changed (grün), normal (blau) |
| `FieldGrid` | Liste, Edit, Datums-Tap |
| `FieldGridRow` | `label`, `path`, `value`, `tooltip`, `displayValue`, `isDate` |

Info-Icon: Hover = Tooltip, Klick = Dialog mit Wertebereich.

#### `ui/service_editor/service_editor_page.dart` — `ServiceEditorPage`

Öffnen, Export, XSD, KURSNET prüfen/upload, Neu, Kopie, Termin, Löschen, Compare (Debug). Links Kursliste, rechts Schnellfelder + Detail-Grid.

| Interne Gruppe | Aufgabe |
|----------------|---------|
| `_quickRows` / `_detailRows` | Grids inkl. Tooltip/Display |
| `_editRow` | Datum / Systematik / Coded / Text |

#### `ui/template_editor/template_editor_page.dart` — `TemplateEditorPage`

Tabs Main / Beschäftigungsart / Ort / Header. Speichern schreibt die Vorlagen-XML in AppData.

| Symbol | Aufgabe |
|--------|---------|
| `_editTemplateField` | gleicher Editor wie im Service (Coded/Systematik/Text) |
| `_applyCodedValue` | analog `EditorController.setCodedValue` |
| `_typedRow` / `_codedRaw` | Anzeige `3 — Leiter…` statt nur `3` |
| `_MainTemplateTab` … `_HeaderTab` | je ein Grid |

#### `ui/dialogs/common_dialogs.dart`

`showTextEditorDialog`, `showDateTimePickerDialog`, `showCodedPickerDialog`, `showSystematikPickerDialog`, `showKursnetUploadDialog`.

#### `ui/dialogs/service_dialogs.dart`

`showCreateServiceDialog`, `showCopyWithConfigurationDialog` (Ort, Main-Variante, Beschäftigungsart).

---

## 4. WinForms (Legacy) ↔ Flutter

| C# | Dart |
|----|------|
| `XmlServiceManager` | `CatalogSession` |
| `XmlHelper` | `XmlPath` |
| `ServiceTemplateRepository` | gleichnamig |
| `TemplateConfigurationManager` | `TemplateConfigurator` |
| `TemplateProfilManager` | `ProfileRepository` |
| `DateFieldHelper` | `DateFieldRules` |
| `ServiceTitleBuilder` | gleichnamig |
| `CourseTypeTemplateFields` etc. | `domain/fields/template_field_definitions.dart` |
| `MainForm` / `ServiceConfigurationForm` | `ServiceEditorPage` + Dialoge |
| `xsd_validator.dll` | unverändert, FFI |

Nicht neue Features in WinForms bauen, außer jemand muss die alte EXE noch liefern.

---

## 5. Typische Wartungsaufgaben

### Neues Schnellfeld (Service-Tab)

1. Pfad in `ImportantFields.list` eintragen.
2. Bei Datum: `DateFieldRules.isDatePath` greift über `START_DATE`/`END_DATE`.
3. Bei Code-Feld: `OpenqReference.optionsForPath` erweitern + `.dat` laden.

### Neues Vorlagen-Feld

Siehe [VORLAGEN.md](VORLAGEN.md). Kurz: Definition **und** `TemplateFieldMapping`, sonst erscheint es im Tab, wird aber beim Create nicht übernommen.

### Neuer `type=`-Wertebereich

1. `.dat` nach `flutter/assets/openqcat/reference/wertebereiche/` und in `AppDataStore` `wertFiles`.
2. In `OpenqReference.load` einlesen.
3. In `optionsForPath` den XML-Pfad zuordnen.
4. Optional Hint in `_fieldHint` fürs Tooltip.

### Export ändert sich unerwartet

Zuerst `CatalogSession.buildExportDocument` und `KursnetRules.sanitize*` prüfen, nicht die UI. Roundtrip ist **kein** Diff auf Byte-Ebene.

### Stale Templates beim User

`AppDataStore._repairStaleTemplates` erkennt alte Main.xml. Nach Template-Fixes in Assets: Seed überschreibt Schema/Referenz immer; Templates nur bei Repair oder fehlender Datei. Zum Erzwingen: AppData-Ordner `templates` löschen.

---

## 6. Tests & Qualität

```powershell
cd flutter
dart analyze lib
flutter test
```

Goldene Annahmen in `date_and_export_test.dart` nicht still ändern — das sind die Datums- und Exportverträge.

---

## 7. Bekannte Fallstricke

- **`setNodeByPath` auf Container** löscht Kinder. Immer `@type` für `EDUCATION`.
- **Header-Kontakt type 5** ist XSD-ok, KURSNET-Header will 2 oder 3.
- **Angebot vs. Termin** nicht an der Listeneinrückung festmachen, sondern an `EDUCATION@type` / `COURSE_ID`.
- **Encoding:** Dateien oft iso-8859-15; `XmlFileIo` und Native-Validator berücksichtigen das.
- **ProgramFiles(x86):** Flutter-Windows-Build braucht die Umgebungsvariable, falls VS-Build-Tools unter `C:\Program Files (x86)` liegen (siehe `.vscode/launch.json`).
- **Compare-Button** nur `kDebugMode`.
