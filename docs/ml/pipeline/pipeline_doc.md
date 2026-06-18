# Trainingspipeline

Die Trainingspipeline wurde entwickelt, um die verschiedenen Modellansätze des Projekts systematisch trainieren, bewerten und miteinander vergleichen zu können. Im Verlauf der Modellentwicklung entstand schnell die Schwierigkeit, dass nicht nur ein einzelnes Modell betrachtet wurde, sondern viele Varianten: unterschiedliche CNN-Architekturen, verschiedene Eingabedaten, klassische Bildfilter, Transfer Learning, Maßnahmen gegen das Klassenungleichgewicht und unterschiedliche Bewertungsmetriken. Ohne eine gemeinsame Pipeline wären diese Experimente nur schwer vergleichbar gewesen, weil jeder Trainingslauf eigene Zwischenschritte, Ausgaben und Einstellungen gehabt hätte.

Die Pipeline erfüllt deshalb vor allem die Rolle eines einheitlichen Experimentrahmens. Sie nimmt eine Trainingsidee entgegen, bereitet die Daten passend vor, trainiert das Modell, bewertet das Ergebnis und speichert alle Informationen, die später für den Vergleich und die Rückverfolgung benötigt werden. Damit bildet sie die Verbindung zwischen der konzeptionellen Modellentwicklung, den im Auditing beschriebenen Anforderungen an Reproduzierbarkeit und den späteren Trainingsergebnissen.

## Einordnung in die Modellarchitektur

Die Pipeline orientiert sich an der Architektur, die auch in der Präsentation für die Modellentwicklung gezeigt wurde. Ausgangspunkt ist der HAM10000-Datensatz, der für das Projekt auf die binäre Klassifikation zwischen Melanom und Nicht-Melanom reduziert wurde. Aus diesen Daten entstehen zunächst feste Trainings-, Validierungs- und Testbereiche. Diese Trennung ist wichtig, weil das Modell nicht auf denselben Bildern bewertet werden darf, auf denen es zuvor gelernt hat.

Anschließend können mehrere Trainingspfade parallel gedacht und nacheinander ausgeführt werden. Ein solcher Pfad entspricht einem Branch der Multibranch-Idee. Ein Branch kann zum Beispiel mit den originalen RGB-Bildern arbeiten, während ein anderer Branch gefilterte Bilddaten wie Gabor-, LBP- oder GLCM-Repräsentationen nutzt. Dadurch lässt sich untersuchen, ob bestimmte visuelle Informationen für die Klassifikation hilfreicher sind als andere. RGB-Bilder enthalten die vollständige Farbinformation, während die Filter eher Textur-, Kanten- oder Strukturmerkmale hervorheben. Diese Aufteilung ist an den Gedanken angelehnt, dass Hautläsionen nicht nur über Farbe, sondern auch über Form und Oberflächenstruktur beurteilt werden.

Innerhalb eines Trainingspfads werden die Daten vereinheitlicht, augmentiert und an ein CNN übergeben. Die Augmentierung erzeugt leicht veränderte Versionen der Trainingsbilder, zum Beispiel durch Spiegelung, Zuschnitt oder Rotation. Dadurch sieht das Modell während des Trainings mehr Variation und soll robuster gegenüber unterschiedlichen Aufnahmesituationen werden. Die Validierungs- und Testdaten werden dagegen nicht zufällig verändert, damit die Bewertung stabil und nachvollziehbar bleibt.

Nach dem Training bewertet die Pipeline das Modell auf Validierungs- und Testdaten. Dabei wird nicht nur eine einfache Genauigkeit betrachtet, weil der Datensatz stark unausgeglichen ist. Melanome sind deutlich seltener als gutartige Nävi. Ein Modell könnte deshalb eine scheinbar hohe Accuracy erreichen, obwohl es Melanome zu häufig übersieht. Die Pipeline betrachtet daher Metriken wie Sensitivität, Spezifität, F1-Werte und AUC. Besonders relevant ist die Sensitivität, weil falsch negative Melanom-Vorhersagen im medizinischen Kontext kritisch sind.

## Zusammenhang mit Transfer Learning

Transfer Learning war ein zentraler Grund für den Aufbau der Pipeline. Statt CNNs vollständig von Grund auf zu trainieren, werden vortrainierte Architekturen verwendet, die bereits auf großen Bilddatensätzen gelernt haben, allgemeine visuelle Merkmale zu erkennen. Solche Modelle können beispielsweise Kanten, einfache Formen, Texturen und später komplexere Bildstrukturen erfassen. Diese Fähigkeit wird für die Hautläsionsklassifikation wiederverwendet und an die konkrete Aufgabe angepasst.

Für das Projekt ist dieser Ansatz besonders sinnvoll, weil der verfügbare medizinische Datensatz vergleichsweise klein und unausgeglichen ist. Ein vollständig neu trainiertes Modell müsste alle relevanten Bildmerkmale allein aus diesen Daten lernen. Ein vortrainiertes Modell bringt dagegen bereits eine visuelle Grundrepräsentation mit. In der Pipeline kann deshalb getestet werden, ob es besser ist, große Teile des Modells eingefroren zu lassen und nur die letzte Entscheidungsschicht anzupassen, oder ob mehr Schichten weitertrainiert werden sollten.

Die Pipeline erlaubt außerdem den Vergleich verschiedener Modellfamilien. ResNet diente als naheliegender Einstieg, weil diese Architektur weit verbreitet und gut verstanden ist. Effizientere Modelle wie EfficientNet oder MobileNet sind ebenfalls relevant, weil das finale System perspektivisch auf mobilen Endgeräten laufen soll. Die Pipeline macht diese Varianten vergleichbar, indem sie für jeden Lauf dieselbe Grundstruktur aus Datenaufbereitung, Training, Bewertung und Ergebnisablage verwendet.

Bei gefilterten Bilddaten wird Transfer Learning etwas anspruchsvoller. Vortrainierte Modelle erwarten normalerweise RGB-Bilder mit drei Farbkanälen. Filterdaten können jedoch eine andere Kanalzahl und andere Wertebereiche haben. Die Pipeline wurde deshalb so aufgebaut, dass auch solche Eingaben trainiert und bewertet werden können. Fachlich bedeutet das: Die gleiche Modellfamilie kann sowohl auf normalen Bildern als auch auf speziell hervorgehobenen Strukturinformationen untersucht werden.

## Umgang mit unausgeglichenen Daten

Der HAM10000-Datensatz enthält deutlich mehr gutartige Nävi als Melanome. Dieses Ungleichgewicht beeinflusst das Training stark, weil ein Modell sonst dazu neigen kann, die häufigere Klasse zu bevorzugen. Die Pipeline unterstützt deshalb mehrere Maßnahmen, um die seltenere Melanom-Klasse stärker zu berücksichtigen.

Zum einen können Fehlklassifikationen der Minderheitsklasse im Training stärker gewichtet werden. Zum anderen können Melanom-Beispiele beim Zusammenstellen der Trainingsbatches häufiger berücksichtigt werden. Beide Ansätze verfolgen dasselbe Ziel: Das Modell soll nicht nur die Mehrheitsklasse gut erkennen, sondern auch ausreichend empfindlich für Melanome bleiben.

Auch die Wahl des Entscheidungsschwellwerts ist dabei wichtig. Ein CNN gibt zunächst eine Wahrscheinlichkeit aus. Erst ein Threshold entscheidet, ab wann diese Wahrscheinlichkeit als Melanom gewertet wird. Ein fester Standardwert ist nicht zwangsläufig für den medizinischen Kontext geeignet. Deshalb sucht die Pipeline auf dem Validierungsset nach einem sinnvollen Threshold, der eine Mindest-Spezifität einhält und gleichzeitig die Sensitivität möglichst hoch hält. So wird die Entscheidung stärker an den Anforderungen der Aufgabe ausgerichtet.

## Auditing und Ergebnisablage

Ein wesentlicher Zweck der Pipeline ist die Auditierbarkeit der Trainingsläufe. Im Auditing-Kapitel wird beschrieben, warum ein trainiertes Modell später nachvollziehbar sein muss: Es soll erkennbar bleiben, mit welchen Daten, welcher Architektur, welchen Hyperparametern und welchem Trainingsverlauf es entstanden ist. Die Pipeline erzeugt genau diese Nachweise automatisch als Ergebnis eines Trainingslaufs.

Zu einem Pipeline-Ergebnis gehören daher nicht nur die trainierten Modellgewichte. Gespeichert werden auch die verwendete Konfiguration, der Trainingsverlauf, die finalen Bewertungsmetriken und verschiedene Diagramme zur Modellbeurteilung. Dazu zählen zum Beispiel Verlaufsgrafiken für das Training, Konfusionsmatrizen sowie Kurven zur Einordnung der Klassifikationsleistung. Diese Artefakte sind keine losgelösten technischen Nebenprodukte, sondern die praktische Umsetzung des Auditing-Konzepts: Sie machen sichtbar, wie ein Modell entstanden ist und wie es sich auf unabhängigen Daten verhalten hat.

Zusätzlich werden die Experimente über MLflow nachvollziehbar gemacht. MLflow dient hier als Experimentprotokoll, in dem Trainingsläufe mit ihren Parametern, Metriken und Artefakten gesammelt werden. Dadurch können mehrere Modelle nicht nur anhand einzelner Ergebnisdateien, sondern auch in einer gemeinsamen Übersicht verglichen werden. Gerade bei vielen Branches und wiederholten Trainingsläufen ist das wichtig, weil sonst schnell unklar wird, welches Modell zu welchem Experiment gehört.

Die Auditierungsdaten sind außerdem relevant für den späteren Einsatz in der App. Wenn ein Modell exportiert und mobil verwendet wird, muss weiterhin nachvollziehbar bleiben, aus welchem Trainingslauf es stammt. Die Pipeline stellt diese Verbindung her, indem sie jeden Lauf eindeutig dokumentiert. So kann ein in der App verwendetes Modell später wieder mit seinen Trainingsdaten, seinen Metriken und seiner Konfiguration in Beziehung gesetzt werden.

## Bedeutung für die Projektentwicklung

Die Pipeline ist damit weniger als einzelnes Programm zu verstehen, sondern als methodischer Rahmen für die Modellentwicklung. Sie ermöglicht, Hypothesen kontrolliert zu prüfen: etwa ob Gabor-gefilterte Bilder zusätzliche Informationen liefern, ob Transfer Learning gegenüber einfachen CNNs Vorteile bringt oder ob bestimmte Modellarchitekturen besser für eine spätere mobile Nutzung geeignet sind.

Gleichzeitig schafft sie eine gemeinsame Grundlage für die weiteren Kapitel. Die Multibranch-Architektur beschreibt, warum mehrere spezialisierte Sichtweisen auf eine Läsion sinnvoll sein können. Die Auditing-Dokumentation beschreibt, welche Informationen für Rückverfolgbarkeit und Reproduzierbarkeit benötigt werden. Die Trainingsergebnisse zeigen schließlich, welche Resultate mit den untersuchten Ansätzen erreicht wurden. Die Pipeline verbindet diese Teile, indem sie die Experimente einheitlich ausführt und ihre Ergebnisse vergleichbar dokumentiert.

Für eine kurze praktische Anleitung zum Starten der Pipeline ist die separate [Quickstart-Seite](pipeline_getting_started.md) vorgesehen. Diese allgemeine Dokumentation erklärt dagegen vor allem, warum die Pipeline existiert, wie sie fachlich in die Modellentwicklung eingebettet ist und welche Rolle ihre Ausgaben für Bewertung und Auditing spielen.
