# Dermascan Documentation

**Team**: 
- [John Schubert](mailto:schubertjo97184@th-nuernberg.de)
- [Illia Pichkur](mailto:pichkuril97175@th-nuernberg.de)
- [Maurice Klawuhn](mailto:klawuhnma96400@th-nuernberg.de)

**Betreuer**:
- [Christian Axenie](mailto:cristian.axenie@th-nuernberg.de)

## Kurzbeschreibung
Dermascan umfasst die Forschung und Entwicklung einer mobilen App, mit der Bilder von Hautläsionen aufgenommen werden sollen und mithilfe eines ML Models direkt auf dem Endgerät des Anwenders klassifiziert wird.

## Allgemeine Projektinformationen
- Zielgruppe: ausschließlich Ärzte
- App Framework: Flutter 
- Datenhaltung: Supabase
- Primärplattform: iOS
- Sicherheit: Bilder und Patientendaten werden verschlüsselt gespeichert; Zugriff nur für Ärzte innerhalb derselben Praxis


## Entwicklung und Forschung

### App

Die App-Entwicklung erfolgt mit dem Framework Flutter, um eine plattformübergreifende Entwicklung zu ermöglichen.
Durch die Nutzung von Supabase als Backend-Dienst wird eine einfache Handhabung der Datenhaltung und Authentifizierung gewährleistet, während durch die Inferenz des ML-Modells direkt auf dem Endgerät keine weitere Serverinfrastruktur fordert.

Nähere Informationen zur App-Entwicklung finden sich im [App Dokumentationsordner](./app/README.md).

### ML Modell

Verschiedene ML Modelle werden evaluiert, um einen Kompromiss zwischen Genauigkeit und Effizienz zu finden.
Dabei wird neben dem Finetuning von vortrainierten Modellen auch eine eigene Modellarchitektur entwickelt, die speziell auf die Anforderungen der Hautläsionserkennung zugeschnitten ist.

Nähere Informationen zur Modellentwicklung finden sich im [ML Dokumentationsordner](./ml/README.md).