# Dermascan Dokumentation

## Team

- [John Schubert](mailto:schubertjo97184@th-nuernberg.de)
- [Illia Pichkur](mailto:pichkuril97175@th-nuernberg.de)
- [Maurice Klawuhn](mailto:klawuhnma96400@th-nuernberg.de)

## Betreuung

- [Christian Axenie](mailto:cristian.axenie@th-nuernberg.de)

## Projektüberblick

Dermascan ist ein praxisnahes Forschungsprojekt zur Entwicklung einer mobilen App für die dermatologische Verlaufsdokumentation. Die Anwendung wurde in enger Abstimmung mit einer Dermatologin konzipiert und fokussiert die strukturierte Erfassung von Hautläsionen, die Nachverfolgung über Zeit und eine KI-gestützte Ersteinschätzung.

## Architektur auf einen Blick

### Lokal auf dem Endgerät

- Aufnahme und Vorverarbeitung von Bilddaten
- On-Device-Inferenz des Klassifikators (ONNX Runtime)
- Berechnung deterministischer ABC-Merkmale

### Cloud-Backend (Supabase)

- Speicherung von Patienten-, Läsions- und Diagnosedaten
- Authentifizierung und rollenbasierte Autorisierung
- Serverseitige Prüfung kritischer Schreiboperationen über Edge Functions
- Zugriffssteuerung über RLS- und Storage-Policies

Damit ist klar getrennt: Die KI-Auswertung läuft lokal, während persistente Verwaltungs- und Dokumentationsdaten kontrolliert im Backend gehalten werden.

## Grenzen und Nutzungskontext

- Dermascan ist ein Forschungsprototyp und **kein Medizinprodukt**.
- Die Ergebnisse sind als **Entscheidungsunterstützung** gedacht und ersetzen keine fachärztliche Diagnose.
- Die klinische Verantwortung verbleibt bei medizinischem Fachpersonal.

## Struktur der Dokumentation

1. [App](./app/README.md)
2. [Datenbank](./db/README.md)
3. [Machine Learning](./ml/README.md)
4. [ABC-Algorithmen](./abc_algorithms/README.md)
5. [Glossar](./glossar.md)

## Fazit

Dermascan verbindet klinische Anforderungen mit einer End-to-End-Umsetzung aus App, Datenhaltung, ML-Pipeline und deterministischen Merkmalsalgorithmen. Die Kombination aus On-Device-Inferenz und abgesicherter Cloud-Dokumentation ermöglicht einen praxisnahen Workflow für strukturierte Untersuchungen und mit minimalem Anschaffungsaufwand.
