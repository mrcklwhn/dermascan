# Flutter App

## Zielsetzung
In Zusammenarbeit mit einer Dermatologin wurden die Anforderungen und Funktionen der App definiert.
Die App soll Dermatologen bei der Dokumentation und Diagnose von Hautläsion unterstützen und die Integration eines ML-basierten Klassifikators ermöglichen ohne zusätzliche Hardware und Infrastruktur zu benötigen.

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
- Praxis-Account und Arzt Account können direkt von Nutzer in der App erstellt werden
- Arzt-Accounts sind nach erstellen noch keiner Praxis zugeordnet; befinden sich im "Wartestatus" bis sie von einem Praxis-Account der jeweiligen Praxis akzeptiert werden
- Datenzugriff:
  - Alle Ärzte einer Praxis können die Patientendaten der Praxis einsehen
  - Ärzte aus unterschiedlichen Praxen haben keinen Zugriff auf die Praxisdaten einer anderen Praxis
