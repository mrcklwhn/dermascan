# Dermascan Dokumentation

**Team**: 
- [John Schubert](mailto:schubertjo97184@th-nuernberg.de)
- [Illia Pichkur](mailto:pichkuril97175@th-nuernberg.de)
- [Maurice Klawuhn](mailto:klawuhnma96400@th-nuernberg.de)

**Betreuer**:
- [Christian Axenie](mailto:cristian.axenie@th-nuernberg.de)

## Kurzbeschreibung
Dermascan umfasst die Forschung und Entwicklung einer mobilen App, mit der Bilder von Hautläsionen aufgenommen werden sollen und mithilfe eines ML Models direkt auf dem Endgerät des Anwenders klassifiziert wird. Dabei soll insbesondere die Datensicherheit und der Datenschutz der sensiblen Patientendaten gewährleistet werden, indem die Verarbeitung ausschließlich auf dem Endgerät erfolgt und alle Ergebnisse verschlüsselt gespeichert werden.

## Allgemeine Projektinformationen
- Zielgruppe: ausschließlich Ärzte
- App Framework: Flutter 
- Datenhaltung: Supabase
- Primärplattform: Android
- Sicherheit: Bilder und Patientendaten werden verschlüsselt gespeichert; Zugriff nur für Ärzte innerhalb derselben Praxis


## Entwicklung und Forschung

### App

Die App-Entwicklung erfolgt mit dem Framework Flutter, um eine plattformübergreifende Entwicklung zu ermöglichen.
In der [App Dokumentation](./app/README.md) finden sich detaillierte Informationen zur Zusammenarbeit mit einem realen Stakeholder, der App-Architektur und den implementierten Features.


### ML Backend

Verschiedene neuronale Modelle wurden evaluiert, um einen Kompromiss zwischen Genauigkeit und Effizienz zu finden.
Dabei wird neben dem Finetuning von vortrainierten Modellen auch eine eigene Modellarchitektur entwickelt, die speziell auf die Anforderungen der Hautläsionserkennung zugeschnitten ist.

Nähere Informationen zur Modellentwicklung finden sich in der [ML Dokumentation](./ml/README.md).


### Datenbank

Zur Datenhaltung wird die Cloud-Plattform Supabase eingesetzt, die auf PostgreSQL basiert. Sie ermöglicht ein stabiles und konsistentes Datenbankschema, das den organisatorischen Ablauf einer Arztpraxis sowie den dermatologischen Diagnoseprozess nativ abbildet. Die Entscheidung für einen externen Dienstleister ist auch damit zu begründen, dass wir selbst keine dauerhaft verfügbare Datenbank aufsetzen und einen ortsunabhängigen Zugriff ermöglichen müssen, wodurch der Fokus auf der Entwicklung bleibt.

Details zum Datenbankdesign und Sicherheitsmaßnahmen finden sich in der [Datenbank Dokumentation](./db/README.md).
