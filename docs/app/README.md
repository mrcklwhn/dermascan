# Flutter App

Die alltägliche Arbeit von Dermatologen soll durch die entwickelte App erleichtert werden.
Die App ermöglicht es Ärzten, Patientendaten und Bilder von Hautläsionen zu verwalten und mithilfe eines integrierten ML-Modells eine erste Einschätzung der Läsionen zu erhalten.
Insofern dient die App als unterstützendes Werkzeug im klinischen Alltag.

## Projektstruktur

```
flutter/                      # Flutter-App (iOS/Android)
    ├── lib/
    ├── android/
    └── ios/
```

## Funktionen der App
- Patientenverwaltung (anlegen, bearbeiten)
- Bilder aufnehmen/hochladen; Position der Läsion auf einer 2D-Körperdarstellung markieren
- Diagnose und Anmerkungen zu Bildern erfassen
- Pro Bild:
  - Wahrscheinlichkeit (%) für Melanom vs. Melanocytic Nevi (Leberfleck)
  - ABCDE-Details mit prozentualen Bewertungen (z. B. Asymmetrie, Rand, Farbe, Durchmesser, Entwicklung)

## Konten und Rollen
- Rollen: Praxis-Account, Arzt-Account.
- Nutzer können Praxis-Account und Arzt-Accounts selbstständig erstellen.
- Praxis-Account kann Ärzte zur Praxis hinzufügen.
- Datenzugriff:
  - Alle Ärzte einer Praxis können die Patientendaten der Praxis einsehen.
  - Ärzte aus unterschiedlichen Praxen haben keinen Zugriff aufeinander.