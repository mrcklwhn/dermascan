# App-Features

Der Funktionsumfang der Anwendung ist exakt auf den klinischen Untersuchungspfad abgestimmt. Er begleitet den Arzt vom Erstkontakt über die visuelle und KI-gestützte Analyse bis hin zur Archivierung.

## Arzt- und Praxisverwaltung

Um einen Patienten zu dokumentieren, muss der Arzt zunächst ein eigenes Benutzerkonto anlegen. Dieses Konto ist zu Beginn mit keiner Praxis verknüpft, sodass der Arzt einer bestehenden Praxis beitreten muss. Die Praxiszuordnung ist für die Verwaltung von Patientendaten entscheidend, da sie den Zugriff auf die Daten anderer Ärzte derselben Praxis regelt.

![](../images/doctor_login.gif)

Gleichermaßen muss ein Praxisadministrator ein eigenes Konto anlegen, um die Praxis zu registrieren. Der Administrator kann dann weitere Ärzte einladen, die der Praxis zugeordnet werden sollen. Damit ist sichergestellt, dass nur autorisierte Ärzte Zugriff auf die Patientendaten der Praxis erhalten.

![](../images/practice_login.gif)

### Arztverwaltung und Mehrbenutzerfähigkeit

Jeder Arzt ist genau einer Praxis zugeordnet und besitzt ein eigenes Benutzerkonto mit eindeutiger E-Mail-Adresse. Ärzte derselben Praxis können die Patientendaten anderer zugeordneter Kollegen einsehen, sodass die Behandlung im Team konsistent dokumentiert und fortgeführt werden kann.

**Das Praxiskonto verwaltet den Zugriff über ein Einladungsmodul**: Einladungen an neue Ärzte können in einem eigenen Fenster eingesehen und bei Bedarf jederzeit zurückgenommen werden, etwa bei versehentlichem Versand. Sobald ein Arzt eine Einladung akzeptiert, erhält er Zugriff auf die Patientendaten der Praxis; dieser Zugriff kann durch die Praxisadministration jederzeit wieder entzogen werden, indem der Arzt aus der Praxis entfernt wird.

![](../images/doctor_management.gif)

## Patientenverwaltung und Anamnese

Das Anlegen eines neuen Patienten bildet den Startpunkt der Dokumentation. Die zu erfassenden Parameter wurden gemeinsam mit der Fachärztin definiert. Sie umfassen neben den demografischen Stammdaten gezielt jene Risikofaktoren, die für eine fundierte Hautkrebsdiagnostik und -prävention maßgeblich sind:

* **Stammdaten:** Vorname, Nachname, Geburtsdatum, biologisches Geschlecht.
* **Sonnen- und Lebensstilfaktoren:** Nutzung von Sonnenschutzmitteln, Historie von Sonnenbränden, Nutzung von Solarien.
* **Medizinische Vorgeschichte:** Eigene Melanom-Vorgeschichte, familiäres Vorkommen von Hautkrebserkrankungen, vorausgegangene dermatologische Operationen.
* **Herkunft:** Geburtsland sowie aktuelles Wohnsitzland (zur Einschätzung der kumulativen UV-Exposition).

Alle Daten können bei Folgeuntersuchungen aktualisiert werden. In der zentralen Patientenübersicht werden diese Risikofaktoren kompakt zusammengefasst, um dem Arzt sofort den Kontext des Patienten zu vermitteln.

![](../images/patient_screen.gif)

> **Hinweis:** Um einen Patienten aus der Praxis zu löschen, muss der Arzt das Patientenprofil öffnen und die Option "Delete" auswählen. **Es dürfen keine Läsionen mehr mit dem Patienten verknüpft sein**, da sonst die Datenintegrität nicht gewährleistet ist.

## Das digitale Patientenprofil & Interaktive 3D-Körperkarte

Das Patientenprofil ist die zentrale Arbeitsumgebung für den Mediziner. Um eine intuitive Dokumentation zu ermöglichen, wurde eine interaktive 3D-Körperdarstellung integriert. Im Gegensatz zu klassischen Systemen, die mit starren, vordefinierten Text-Kategorien (z. B. „Rücken“) arbeiten, erlaubt dieses Modell die präzise Platzierung von Hautläsionen im dreidimensionalen Raum.

### Funktionen der 3D-Körperkarte:

* **Freie Interaktion:** Das dreidimensionale Modell lässt sich stufenlos drehen und zoomen, um jede anatomische Region exakt zu erreichen.
* **Kameraperspektiven:** Ein Quick-Reset erlaubt das sofortige Zurücksetzen auf die Standardansicht.
* **Präzise Läsionsplatzierung:** Durch Tippen auf das Modell können beliebig viele Läsionen exakt an der realen anatomischen Position markiert werden.

![](../images/3dmap.gif)

### Schnellübersicht und Navigation

Zusätzlich zur visuellen Karte bietet das Profil eine effiziente Informationsarchitektur für den Praxisalltag:

* **Diagnose-Timeline:** Ein Direktzugriff auf die letzten fünf dokumentierten Diagnosen. Ein Tippen auf einen Eintrag fokussiert sofort die dazugehörige Läsion auf dem 3D-Modell.
* **Kontext-Info:** Schnelleinsicht der Patienten-Risikofaktoren über ein Info-Symbol, ohne den aktuellen Untersuchungsbildschirm verlassen zu müssen.

![](../images/timeline.gif)

## Läsionsverwaltung und Befundung

Wird ein neuer Punkt auf der 3D-Karte gesetzt, öffnet sich der Workflow zur Läsionsverwaltung. Nach Vergabe eines eindeutigen Namens wird ein neuer Untersuchungszeitpunkt (eine Diagnose) initiiert.

### Bildaufnahme und Cutout-Generierung

Der Arzt kann das klinische Bild entweder direkt über die Kamera des Mobilgeräts aufnehmen oder aus der Galerie importieren. Um Störfaktoren (wie gesunde Hautareale oder Haare) zu minimieren und das neuronale Netzwerk auf den relevanten Bereich zu fokussieren, wird im nächsten Schritt ein optimierter Bildausschnitt – der sogenannte Läsions-Cutout – durch den Dermatologen ausgewählt.


### Medizinische Statusverfolgung

Jede Läsion besitzt einen dynamischen Status, der den klinischen Verlauf widerspiegelt:

* **Verdächtig** (unter Beobachtung)
* **Entfernt** (operativ exzidiert)
* **Histologisch bestätigt** (nach Laborbefund als Melanom klassifiziert)

Da eine Läsion über Jahre hinweg unbegrenzt viele Diagnosen und Bildaufnahmen enthalten kann, wird die morphologische Veränderung lückenlos nachvollziehbar.

![](../images/workflow.gif)

>**Hinweis:** Um eine Läsion zu löschen, muss der Arzt das Läsionsprofil öffnen und die Option "Delete" auswählen. Es müssen erst **alle Diagnosen der Läsion gelöscht** werden, bevor die Läsion selbst gelöscht werden kann.

## KI-gestützte Analyse und Diagnosedokumentation

Für jede neu erfasste Diagnose wird das Bildmaterial lokal analysiert. Das System kombiniert dabei die klassische dermatologische Bewertungsmetrik mit modernen Deep-Learning-Verfahren:

1. **[Klassisches ABC-Scoring](../abc_algorithms/README.md)** Automatische Berechnung und visuelle Aufbereitung der Kriterien *Asymmetrie* (A), *Begrenzung* (B) und *Color/Farbe* (C).
2. **[Neuronale Klassifikation](../ml/README.md)** Berechnung der statistischen Wahrscheinlichkeiten für das Vorliegen eines *Melanoms* im Vergleich zu einem gutartigen *melanozytären Nävus* (Leberfleck).

Ergänzend dokumentiert der Arzt das Untersuchungsdatum, den behandelnden Kollegen sowie freie klinische Anmerkungen. Die Ergebnisse werden für den Arzt übersichtlich aufbereitet und dienen als objektive, reproduzierbare Zweitmeinung (*Decision Support System*).

![](../images/diagnosis.gif)


## Automatisierte PDF-Berichterstellung

Für die Archivierung in der primären Praxis-EDV oder für die Weitergabe an den Patienten wurde ein Export-Modul implementiert. Der Arzt kann über eine Checkbox-Auswahl dediziert steuern, welche Läsionen und welche spezifischen Untersuchungszeitpunkte in den Bericht einfließen sollen. Das generierte PDF-Dokument enthält strukturiert alle Stammdaten, Anamnesefaktoren, die bildlichen Dokumentationen, die berechneten KI-Metriken sowie die ärztlichen Kommentare.

![](../images/export.gif)

## Kurzdokumentation

In der App ist eine Kurzdokumentation integriert, die die zentralen App-Funktionen erläutert. Sie ist jederzeit über das eigene Arztprofil zugänglich und bietet eine schnelle Orientierungshilfe für neue Nutzer.

![](../images/in_app_documentation.gif)


## Siehe auch
- [App-Architektur](./architecture.md)
- [Datenbank Dokumentation](../db/README.md)
- [App-Entwicklung](./README.md)