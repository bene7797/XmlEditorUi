# Vorlagen-System

Zwei Schichten: **Dateien** (was im XML steht) und **Konfiguration** (was beim Anlegen eines Service zusammengeführt wird).

Die Flutter-App arbeitet auf Kopien unter AppData (`XmlEditorFlutter/templates/`), nicht direkt auf `flutter/assets/openqcat/templates/`. Asset-Änderungen wirken nach Repair/Neuseed (siehe [WARTUNG.md](WARTUNG.md) §5).

WinForms-Pendant (veraltet): [TEMPLATE_SYSTEM.md](../TEMPLATE_SYSTEM.md).

---

## Layer 1 — Vorlagen-Dateien

```
templates/services/
├── Main.xml                         # Umschulung, inkl. HEADER
├── Main - Externenprüfung.xml
├── Kassel - Vollzeit - Extended.xml
├── Kassel - Teilzeit - Extended.xml
├── Leipzig Vollzeit - Extended.xml
├── Leipzig - Teilzeit.xml
└── Externenprüfung Kassel.xml
```

`templates/profiles/`:

- `locations.xml` — `LOCATION_PROFILE` (Ort-Kurzfelder)
- `coursetypes.xml` — `COURSE_TYPE_PROFILE` (Vollzeit/Teilzeit + `@type`)

Im Editor-Tab **Vorlagen bearbeiten**:

| Tab | Quelle | Welche Felder |
|-----|--------|----------------|
| Main Template | `Main.xml` oder Extern-Main | alle Blätter außer Ort-/Kurs-/Wichtig-Pfaden (`TemplateFieldCollector`) |
| Beschäftigungsart | Dateiname enthält Vollzeit/Teilzeit | `CourseTypeTemplateFields` |
| Ort | `LOCATION/CITY` | `LocationTemplateFields` |
| Header | Header aus Main | `HeaderTemplateFields` |

Coded-Felder (`CONTACT_ROLE`, `INSTRUCTION_TIME`, `DURATION@type`, `EDUCATION@type`, …) nutzen Auswahllisten und Tooltips aus `OpenqReference`.

---

## Layer 2 — Neuer Service

1. Nutzer wählt Ort, Main-Variante, ggf. Beschäftigungsart.
2. `TemplateConfigurator` lädt Main, wendet Location- und CourseType-Maps an.
3. `CatalogSession.addServiceFromConfiguredTemplate` vergibt `PRODUCT_ID`, setzt `COURSE_ID` beim Angebot, markiert `[NEU]`.

```
EditorController.createService
  → TemplateConfigurator.loadMainTemplate
  → applyLocationConfiguration
  → applyCourseTypeConfiguration
  → CatalogSession.addServiceFromConfiguredTemplate
```

**Kopie** (`copyWith`) nimmt den bestehenden SERVICE und überschreibt nur Ort/Typ-Mappings.

**Termin zum Angebot** (`addVeranstaltung`) kopiert das Angebot, setzt `EDUCATION@type=false` und `COURSE_ID` auf die Angebots-`PRODUCT_ID`.

---

## Felder im Code anpassen

### Beschäftigungsart-Grid

Datei: `flutter/lib/domain/fields/template_field_definitions.dart`  
Klasse: `CourseTypeTemplateFields`

```dart
TemplateFieldDefinition(
  'Beschäftigungsart (type)',
  'SERVICE_DETAILS/SERVICE_MODULE/EDUCATION/EXTENDED_INFO/INSTRUCTION_TIME@type',
),
```

Damit der Wert auch **beim Erzeugen** landet: denselben Kurznamen in `TemplateFieldMapping.courseTypeFieldPaths` bzw. `courseTypeFieldAttributes` eintragen und in `coursetypes.xml` pflegen.

### Ort-Grid

`LocationTemplateFields` + `TemplateFieldMapping.locationFieldPaths` + `locations.xml`.

`COUNTRY` wird beim Apply auf `DE` gesetzt, falls fehlend. `ZIPBOX` fällt auf `ZIP` zurück.

### Header-Grid

`HeaderTemplateFields`. Header wandert über `CatalogSession.headerTemplate` in jeden Export.

### Wichtige Service-Felder (linke Schnellliste)

`flutter/lib/domain/fields/important_fields.dart` — unabhängig von Vorlagen, aber dieselben XML-Pfade.

---

## Neue Datei (neuer Ort / neue Art)

1. XML analog zu Kassel/Leipzig bzw. Vollzeit/Teilzeit in `assets/openqcat/templates/services/` legen.
2. In `AppDataStore` `serviceAssets` aufnehmen, sonst fehlt sie nach frischem Seed.
3. Ort: `CITY` eindeutig. Art: Dateiname enthält `vollzeit` oder `teilzeit`.
4. Profile in `locations.xml` / `coursetypes.xml` ergänzen, sonst fehlt die Combobox beim **Erstellen**.

---

## `type`-Attribute

OpenQCat speichert oft Text **und** Code:

```xml
<CONTACT_ROLE type="3">Leiter des Betriebs</CONTACT_ROLE>
<INSTRUCTION_TIME type="1">Vollzeit</INSTRUCTION_TIME>
<EDUCATION type="true">…Kinder…</EDUCATION>
```

| Feld | Bedeutung (Auszug) |
|------|-------------------|
| `CONTACT_ROLE` Header | 2 Gesamtansprechpartner, 3 Leiter des Betriebs |
| `INSTRUCTION_TIME` | 1 Vollzeit, 2 Teilzeit |
| `DURATION@type` | Dauerklasse 0–9 |
| `EDUCATION@type` | `true` Angebot, `false` Veranstaltung |
| `COURSE_TYPE` | Angebotstyp aus `angebotstyp.dat` |

Listen: `flutter/assets/openqcat/reference/wertebereiche/`. Logik: `OpenqReference.optionsForPath`.

`EDUCATION` hat Kind-Elemente — nur `@type` schreiben, nie den Elementtext.

---

## Fehlerbilder

**„Haupttemplate nicht gefunden“**  
`Main.xml` fehlt in AppData `templates/services/`. AppData-Ordner prüfen oder Templates löschen und App neu starten.

**Feld im Tab sichtbar, neuer Service hat den Wert nicht**  
Mapping in `TemplateFieldMapping` fehlt oder Profile-XML hat den Kurznamen nicht.

**Tooltip fehlt**  
Pfad in `optionsForPath` nicht erkannt, oder Referenzdatei nicht geseedet (`wertebereiche`).

**Ort erscheint nicht in der Combobox**  
`CITY` leer/`ort ?`, oder nur Main-Template ohne echten Standort.
