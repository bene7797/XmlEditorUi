# Template-Konfigurationssystem

## Übersicht

Das Template-System hat zwei Schichten:

### Layer 1: Verwaltung (im Code leicht anpassbar)
- **Haupttemplate** (`Main.xml`) - enthält alle gemeinsamen Daten
- **Beschäftigungsart-Vorlagen** - Vollzeit, Teilzeit, Externenprüfung
- **Ort-Vorlagen** - Leipzig, Kassel, etc.

### Layer 2: Konfiguration für neue Services
Beim Erstellen eines neuen Services:
1. Benutzer wählt Ort + Beschäftigungsart
2. System wendet beide Konfigurationen auf Main.xml an
3. Neuer Service wird mit kombinierten Daten erstellt

## Im Editor: Vorlagen bearbeiten

Der "Vorlagen bearbeiten" Tab hat jetzt 3 Subtabs:

### 1. **Main Template Tab**
- Bearbeitet `Main.xml`
- Zeigt wichtige Felder aus Beschäftigungsart + Ort Templates
- Diese Felder werden auf ALLE neuen Services angewendet

### 2. **Beschäftigungsart Tab**
- Bearbeitet Vorlagen für: Vollzeit, Teilzeit, Externenprüfung
- ComboBox zum Auswählen der Beschäftigungsart
- DataGrid zeigt nur essentiell Felder (definiert in Code)
- Beispiel-Felder:
  - Beschäftigungsart (z.B. "Vollzeit")
  - type-Attribute (z.B. type="1")
  - Kursdauer
  - Start/End Datum

### 3. **Ort Tab**
- Bearbeitet Vorlagen für: Leipzig, Kassel, etc.
- ComboBox zum Auswählen des Ortes
- DataGrid zeigt nur essentiell Felder (definiert in Code)
- Beispiel-Felder:
  - Name
  - Straße
  - PLZ, Stadt
  - Bundesland
  - Telefon, Email
  - URL

## Für Entwickler: Essentiell Felder anpassen

### Beschäftigungsart-Felder

Datei: `Models/CourseTypeTemplateFields.cs`

```csharp
public static class CourseTypeTemplateFields
{
    public static readonly List<(string Label, string Path)> EssentialFields = new()
    {
        ("Beschäftigungsart", "SERVICE_DETAILS/.../INSTRUCTION_TIME"),
        ("Beschäftigungsart (type)", "SERVICE_DETAILS/.../INSTRUCTION_TIME@type"),
        // ... weitere Felder
    };
}
```

**Um Felder hinzuzufügen/entfernen:**
1. Öffne `CourseTypeTemplateFields.cs`
2. Füge Tupel hinzu: `("Label", "xml/path")`
3. Sofort im Editor sichtbar!

### Ort-Felder

Datei: `Models/LocationTemplateFields.cs`

```csharp
public static class LocationTemplateFields
{
    public static readonly List<(string Label, string Path)> EssentialFields = new()
    {
        ("Name", "SERVICE_DETAILS/.../LOCATION/NAME"),
        ("Straße", "SERVICE_DETAILS/.../LOCATION/STREET"),
        // ... weitere Felder
    };
}
```

**Um Felder hinzuzufügen/entfernen:**
1. Öffne `LocationTemplateFields.cs`
2. Füge Tupel hinzu: `("Label", "xml/path")`
3. Sofort im Editor sichtbar!

## Technische Details

### Welche Vorlagen-Dateien gibt es?

```
templates/services/
├── Main.xml              (Haupttemplate - Basis für alle Services)
├── Vollzeit*.xml         (Beschäftigungsart-Vorlage)
├── Teilzeit*.xml         (Beschäftigungsart-Vorlage)
├── Externenprüfung*.xml  (Beschäftigungsart-Vorlage)
├── *Leipzig*.xml         (Ort-Vorlage)
└── *Kassel*.xml          (Ort-Vorlage)
```

### Klassen & deren Aufgaben

- **`CourseTypeTemplateFields`**: Definiert wichtige Beschäftigungsart-Felder
- **`LocationTemplateFields`**: Definiert wichtige Ort-Felder
- **`CourseTypeTemplateManager`**: Lädt/speichert Beschäftigungsart-Vorlagen
- **`LocationTemplateManager`**: Lädt/speichert Ort-Vorlagen
- **`TemplateFieldMapping`**: Definiert welche Felder beim Service-Erstellen angepasst werden
- **`TemplateConfigurationManager`**: Wendet Konfigurationen an

### Ablauf beim Erstellen eines Services (im Hintergrund)

```csharp
// Benutzer wählt: Leipzig + Vollzeit

// 1. Main.xml laden
var configManager = new TemplateConfigurationManager(profileManager);
configManager.LoadMainTemplate("Main.xml");

// 2. Ort-Konfiguration anwenden
// - Diese Felder aus LocationTemplateFields werden angepasst
configManager.ApplyLocationConfiguration(leipzigProfile);

// 3. Beschäftigungsart-Konfiguration anwenden
// - Diese Felder aus CourseTypeTemplateFields werden angepasst
configManager.ApplyCourseTypeConfiguration(vollzeitProfile);

// 4. Service hinzufügen
var configuredTemplate = configManager.GetConfiguredTemplate();
serviceManager.AddServiceFromConfiguredTemplate(configuredTemplate);
```

## Häufige Anpassungen

### Neues wichtiges Feld für Beschäftigungsarten hinzufügen
1. Öffne `CourseTypeTemplateFields.cs`
2. Füge Zeile hinzu:
   ```csharp
   ("Mein Label", "SERVICE_DETAILS/.../MEIN_FELD"),
   ```
3. Der Editor zeigt das Feld sofort im Beschäftigungsart-Tab

### Neues wichtiges Feld für Orte hinzufügen
1. Öffne `LocationTemplateFields.cs`
2. Füge Zeile hinzu:
   ```csharp
   ("Mein Label", "SERVICE_DETAILS/.../LOCATION/MEIN_FELD"),
   ```
3. Der Editor zeigt das Feld sofort im Ort-Tab

### Neuen Ort hinzufügen
1. Im Editor → Tab "Ort" → Neue Vorlage für neuen Ort erstellen/speichern
2. System erkennt neue Orte automatisch in der ComboBox

### Neue Beschäftigungsart hinzufügen
1. Im Editor → Tab "Beschäftigungsart" → Neue Vorlage für neue Beschäftigungsart
2. System erkennt neue Arten automatisch in der ComboBox

## Fehlerbehandlung

**"Template nicht gefunden"**
- Stelle sicher, dass die Vorlagen-Datei existiert
- Dateinamen sollten klar identifizierbar sein:
  - Vollzeit/Teilzeit/Extern für Beschäftigungsarten
  - Leipzig/Kassel für Orte

**Felder werden nicht angepasst**
- Überprüfe den XML-Pfad in CourseTypeTemplateFields/LocationTemplateFields
- Teste: Öffne Template im Editor, bearbeite Feld, speichern, neu laden

