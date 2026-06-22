# Dermascan (Arbeitstitel)

Mobile App zur strukturierten Erfassung von Hautlaesionen und zur KI-gestuetzten Ersteinschaetzung der Dringlichkeit.

## Team

- [John Schubert](mailto:schubertjo97184@th-nuernberg.de)
- [Illia Pichkur](mailto:pichkuril97175@th-nuernberg.de)
- [Maurice Klawuhn](mailto:klawuhnma96400@th-nuernberg.de)

## Betreuung

- [Christian Axenie](mailto:cristian.axenie@th-nuernberg.de)

## Kurzbeschreibung

Dermascan ist ein Forschungs- und Entwicklungsprojekt für eine mobile, plattformübergreifende Anwendung im dermatologischen Umfeld. Die App unterstützt die Dokumentation von Hautläsionen und liefert eine KI-basierte Ersteinschätzung.

Die Bildanalyse (Inferenz) erfolgt standardmäßig lokal auf dem Endgerät mittels ONNX Runtime. Patienten-, Läsions- und Diagnosedaten werden strukturiert über Supabase gespeichert und durch Rollenmodell, serverseitige Validierung und Policies abgesichert.

## Zielsetzung

- Datenschutzkonforme Erfassung von Hautveränderungen
- Strukturierte Dokumentation für Verlaufskontrollen
- KI-gestützte Priorisierung als Entscheidungshilfe
- Vergleich mehrerer ML-Strategien für mobile Nutzung

## Konkrete Ergebnisse

- Mobile Flutter-App (Proof of Concept)
- Lokale Modellinferenz mit ONNX Runtime
- Dokumentierte Trainings- und Evaluierungspipeline in Python
- Dokumentation in Markdown und Jupyter Notebooks

## Technischer Rahmen

- App-Framework: Flutter
- Lokale Inferenz: ONNX Runtime (via Flutter-Wrapper)
- Backend: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- ML-Entwicklung: Python, PyTorch, ONNX-Export

## Trennung von Inferenz und Datenhaltung

- **Lokal auf dem Gerät**:
  - Vorverarbeitung von Bilddaten für die Analyse
  - Ausführung der Klassifikation (On-Device-Inferenz)
  - Berechnung deterministischer ABC-Merkmale
- **Cloud-Backend (Supabase)**:
  - Persistenz von Patienten-, Läsions- und Diagnosedaten
  - Rollen- und Zugriffsverwaltung (Praxis/Arzt)
  - Serverseitige Validierung kritischer Schreibvorgänge über Edge Functions
  - Zugriffsschutz durch Row Level Security (RLS) und Storage-Policies

## Grenzen und Nutzungskontext

- Dermascan ist ein Forschungsprototyp und derzeit **kein zertifiziertes Medizinprodukt**.
- Die bereitgestellten Auswertungen dienen der **klinischen Entscheidungsunterstützung**, nicht der finalen Diagnose.
- Die medizinische Bewertung und Verantwortung verbleibt immer bei qualifiziertem Fachpersonal.

## Datenquellen

- HAM10000 / ISIC-Daten:
  - https://www.kaggle.com/datasets/kmader/skin-cancer-mnist-ham10000
  - https://www.nature.com/articles/s41597-024-03743-w#Sec9

## Dokumentation

Die Projektdokumentation liegt im Verzeichnis `docs/` und wird mit MkDocs bereitgestellt. Notebooks und ML-Skripte befinden sich unter `python/`.

### Lokaler Start

```bash
pip install mkdocs mkdocs-material
mkdocs serve
```

Anschliessend ist die Dokumentation unter `http://127.0.0.1:8000/` erreichbar.

## Ausblick

- Erweiterung der Validierung mit reproduzierbaren Vergleichsläufen
- Weitere Härtung des Sicherheitsmodells für Produktivbetrieb
- Verbesserung der Modellrobustheit für seltene Klassen und schwierige Bildqualitäten
