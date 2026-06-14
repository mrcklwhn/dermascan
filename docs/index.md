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

Die implementierten Features und die Architektur des Projekts wurde in enger Zusammenarbeit mit einem realen Stakeholder, einer Dermatologin, entwickelt. 
Dabei wurden folgende Kernpunkte iterativ erarbeitet:

- Zielgruppe: ausschließlich Ärzte
- App Framework: Flutter 
- Datenhaltung: Supabase
- Primärplattform: Android
- Sicherheit: Bilder und Patientendaten werden verschlüsselt gespeichert; Zugriff nur für Ärzte innerhalb derselben Praxis


## Entwicklung und Forschung

### App

Die App-Entwicklung erfolgt mit dem Framework Flutter, um eine plattformübergreifende Entwicklung zu ermöglichen.
In der [App Dokumentation](./app/README.md) finden sich detaillierte Informationen zur App-Architektur und den implementierten Funktionen.


### Datenbank

Zur Datenhaltung für die App wird die Cloud-Plattform Supabase eingesetzt. Sie ermöglicht ein stabiles und konsistentes Datenbankschema, das den organisatorischen Ablauf einer Arztpraxis sowie den dermatologischen Diagnoseprozess nativ abbildet. 

Details zum Datenbankdesign und Sicherheitsmaßnahmen finden sich in der [Datenbank Dokumentation](./db/README.md).


### Klassifikator und deterministische Algorithmen

Die Entwicklung eines neuronalen Klassifikators für die Hautläsionserkennung gliedert sich in die Erkundung verschiedener neuronalen Modelle und die Implementierung von deterministischen Bildverarbeitungsalgorithmen, die auf der klinischen ABCDE-Regel basieren.

Für die Klassifikation der Hautläsionen wird ein Convolutional Neural Network (CNN) entwickelt, das auf einem umfangreichen Datensatz von Hautläsionen trainiert wird.
Nähere Informationen zur Modellforschung finden sich in der [ML Dokumentation](./ml/README.md).

Im Gespräch mit der Dermatologin wurde deutlich, dass neben der reinen Klassifikation auch die Berechnung von klinisch relevanten Bildmerkmalen (Asymmetrie, Begrenzung, Farbe) von großer Bedeutung ist. Daher werden zusätzlich deterministische Algorithmen implementiert, um diese Merkmale zu extrahieren und in die Diagnose einzubeziehen. Details zu diesen Algorithmen sind in der [zugehörigen Dokumentation](./abc_algorithms/README.md) beschrieben.

## Fazit

_hier könnte ihre Werbung stehen_