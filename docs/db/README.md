# Datenbank
Für die Entwicklung wird eine Supabase Instanz der Gratis-Stufe verwendet, welche genügend Spielraum bietet, um die Eckpunkte der Entwicklung abzudecken und auch mit einigen Testdaten einen funktionsfähigen Demoprototypen zu gestalten.

Supabase basiert auf der Postgres Platform, also einer relationalen Datenbank.
Da unser Projekt Daten in klassischer Form verarbeitet, kann ein festes Datenbankschema erstellt werden, dass sich im Entwicklungsverlauf nicht ändert.

## Datenbankschema

Das folgende Bild zeigt das Datenbankschema wie es in Supabase angelegt wurde.

![](../images/supabase-schema.png)

Im Folgenden sollen nur ausgewählte Felder der Grafik näher erläutert werden.

| Tabelle | Feldname | Erklärung |
|---------|----------|-----------|
| diagnosis | notes | Freitextfeld für Notizen zur Lesion durch den Doktor |
| diagnosis | classificationresult | Klassifikationsergebnis des verwendeten CNNs als Wahrscheinlichkeit für Melanom bzw. Leberfleck |
| diagnosis | ascore, bscore, cscore | Berechneter Score des jeweiligen deterministischen Algorithmus zu den Kategorien Asymmetry, Border und Color |
| lesion | location | Position am Körper zur Darstellung auf 2D Karte |
| patient | note | Allgemeines Notizfeld zum Patienten, sodass der Doktor ggf. Vorerkrankungen festhalten kann |

Die ebenfalls in der Grafik dargestellte Beziehung des `auth.users.id`-Feld zu der `doctor` und `practice`-Tabelle definiert, dass ein Nutzer der App sich entweder als Doktor oder als Praxis anmelden kann. Eine Anmeldung als Patient ist vorerst nicht vorgesehen.