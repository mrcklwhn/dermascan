# Projektname (Arbeitstitel)
Mobile App zur Erfassung von Hautanomalien und Erst‑Einschätzung der Dringlichkeit.

**Team**: 
- [John Schubert](schubertjo97184@th-nuernberg.de)
- [Illia Pichkur](pichkuril97175@th-nuernberg.de)
- [Maurice Klawuhn](klawuhnma96400@th-nuernberg.de)

**Betreuer**:
- [Christian Axenie](cristian.axenie@th-nuernberg.de)

## Kurzbeschreibung
>Diese App ermöglicht das Fotografieren und Erfassen von Hautanomalien und liefert eine erste, nicht-klinische Einschätzung, ob eine weitergehende dringliche Untersuchung empfohlen wird. Ziel ist ein Prototyp / Proof-of-Concept für eine mobile, plattformübergreifende Lösung.

## Ziel
- datenschutzkonforme Erfassung von Hautveränderungen
- Erste Priorisierung (dringlich / nicht dringlich) zur Unterstützung von Ärzten
- Forschung: Vergleich mehrerer ML‑Ansätze auf mobilen Geräten

### Konkrete Ergebnisse
- Mobile App (Proof of Concept) mit lokal laufendem ML Modell
- Repo: Demo‑App, Modelle, README(s)
- Präsentationsfolien
- Optional: Abschlussbericht



## Projektdaten

### Hauptfunktionen
- Aufnahme und Verwaltung von Fotos / Befunden
- Lokale Vorverarbeitung (Bilder, Metadaten anonymisieren)
- On‑device Inferenz mit leichtgewichtigen Modellen (z. B. TensorFlow Lite)
- Anzeige einer erklärbaren Einschätzung (z. B. Feature‑Wichtigkeit, Confidence)

### Technische Eckdaten
- Framework: Flutter (plattformagnostisch, mobile Fokus)
- On‑device ML: TensorFlow Lite oder vergleichbare Embedded‑Bibliothek
- ML‑Modelle: mehrere Ansätze evaluieren (Decision Trees / Random Forests, SVM, CNNs für Bildfeatures)
- Erklärungsmethoden: SHAP / Feature‑Importances für Modelldehnung


## Datenquellen
- Öffentliche Datensätze (z. B. Kaggle)
    - https://www.kaggle.com/datasets/kmader/skin-cancer-mnist-ham10000
    - https://www.nature.com/articles/s41597-024-03743-w#Sec9
- Echte Klinikdaten durch Kontakt zum Klinikum Nürnberg oder aus Rumänien 

## ML‑Ansatz (grob)
- Datensammlung → Preprocessing → Feature‑Extraktion (Bild + Metadaten)
- Modellvergleich: klassifikatorische Priorisierung (Dringlich / Nicht)
- Bewertung: Accuracy, Precision/Recall, F1, AUC
- Erklärbarkeit: SHAP oder Tree‑based feature importances

## Nächste Schritte (ToDo)
- Anforderungsanalyse mit Ärzt:innen / Dermatolog:innen
- Datensammlung und rechtliche Prüfung
- Prototyp UI + Kamera‑Workflow
- ML‑Baseline trainieren und on‑device testen

## Dokumentation

Alle Informationen zu Analyse, Daten, Modellentwicklung und -export sind in Form von Markdown-Dateien und Jupyter Notebooks organisiert.
Die Markdown-Dateien im `docs/` Verzeichnis sind der Kern der Projektdokumentation, während die Jupyter Notebooks im `python/` Verzeichnis die detaillierten Schritte der Datenanalyse, Modellierung und Exportierung enthalten.
Für eine interaktiven Aufruf der Dokumentation reicht es die folgenden Befehle im Terminal auszuführen:

```bash
# Install mkdocs
pip install mkdocs

# Serve the documentation locally
mkdocs serve
```

Unter `http://127.0.0.1:8000/` kann die Dokumentation dann im Browser aufgerufen werden. Alle Markdown-Dateien und Notebooks sind dort übersichtlich strukturiert und können direkt eingesehen werden.
