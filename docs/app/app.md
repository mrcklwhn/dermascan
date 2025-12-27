# Flutter App

## Funktionen der App
- Patientenverwaltung (anlegen, bearbeiten)
- Bilder aufnehmen/hochladen; Position der Läsion auf einer 2D-Körperdarstellung markieren
- Diagnose und Anmerkungen zu Bildern erfassen
- Pro Bild:
  - Wahrscheinlichkeit (%) für Melanom vs. Melanocytic Nevi (Leberfleck)
  - ABCDE-Details mit prozentualen Bewertungen (z. B. Asymmetrie, Rand, Farbe, Durchmesser, Entwicklung)

## Konten und Rollen
- Rollen: Praxis-Account, Arzt-Account.
- Praxis-Account wird manuell durch einen Admin erstellt und repräsentiert eine Praxis.
- Praxis-Account kann Ärzte zur Praxis hinzufügen.
- Datenzugriff:
  - Alle Ärzte einer Praxis können die Patientendaten der Praxis einsehen.
  - Ärzte aus unterschiedlichen Praxen haben keinen Zugriff aufeinander.