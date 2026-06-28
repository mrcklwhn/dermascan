# Eigene Klassifikationsarchitektur

Als Teil der Modellentwicklung wurde eine eigene `Multibranch CNN Architektur` entworfen und implementiert.
In Anlehnung an den menschlichen Analyseprozess von Hautläsionen, bei dem verschiedene visuelle Merkmale betrachtet werden, verfolgt diese Architektur den Ansatz, mehrere CNNs auf bestimmte Bildaspekte zu spezialisieren. 
Jeder CNN-Branch soll sich dabei auf unterschiedliche Merkmale der Hautläsion konzentrieren, wie z.B. Farbe, Textur oder Form.
Schließlich werden die Ausgaben der einzelnen Branches kombiniert, um eine finale Klassifikation zu erstellen.

Als Kombinationsstrategien ist der Vergleich von Fusions-Layer als auch Ensemble-Voting angedacht. Aufgrund der Komplexität eines Fusions-Ansatzes und der damit verbundenen Herausforderungen bei der Synchronisierung der Branches, wurde zunächst die Implementierung eines Ensemble-Voting Systems priorisiert. Dieses ermöglicht es, die Vorhersagen der einzelnen Branches unabhängig zu treffen und anschließend durch eine gewichtete Abstimmung zu einem finalen Ergebnis zu kommen, was in den ersten Tests bereits vielversprechende Ergebnisse gezeigt hat.


## Datenerweiterung durch Filter

Um die eben beschriebene Spezialisierung der einzelnen Branches zu unterstützen, werden verschiedene Bildfilter auf dem Originaldatensatz angewendet.
Damit soll eine Fokussierung des jeweiligen Branches auf bestimmte Merkmale künstlich herbeigeführt werden. Zum Einsatz kommen dabei klassische Filter wie Gabor, LBP und GLCM, welche aufgrund ihrer Thematisierung in der [Literatur](https://doi.org/10.1016/j.compbiomed.2019.103423) als besonders vielversprechend für die Analyse von Hautläsionen gelten.

Die verwendeten Filter setzen dabei unterschiedliche Schwerpunkte: **Gabor-Filter** reagieren auf lokale Frequenzen und Orientierungen und können dadurch Kanten sowie grobe Formverläufe hervorheben. **Local Binary Patterns (LBP)** kodieren lokale Helligkeitsunterschiede in der Nachbarschaft eines Pixels und machen feine, teils unregelmäßige Texturmuster sichtbar. **GLCM-basierte Merkmale** (z.B. Contrast) beschreiben die räumliche Beziehung von Grauwerten und betonen Texturübergänge innerhalb einer Region.

Für einen Struktur-Branch sind diese Filter interessant, weil sie komplementäre Informationen liefern, die im RGB-Bild nur implizit enthalten sind: Gabor unterstützt eher die Erfassung von Form- und Kantenstruktur, LBP und GLCM eher die Erfassung von Oberflächen- und Texturvariationen.

Für die Filterung wurde zunächst die Scikit-Image (Skimage) Bibliothek eingesetzt, da diese ebenfalls in der Literatur häufig verwendet wird. Die gefilterten Bilder werden als separate Datensätze im `.npy`-Format gespeichert, um sie effizient in den jeweiligen Branches zu verwenden und nicht bei jedem Trainingslauf neu berechnen zu müssen. Dadurch bläht sich die Datenmenge erheblich auf - von anfangs knapp 7 GB müssen nun mehr als 600 GB an gefilterten Bildern gehalten werden. 


## Auditing von Trainingsergebnissen

Die Trainingspipeline speichert alle relevanten Informationen zu einem Trainingslauf, um die Rückverfolgung und Reproduzierbarkeit der Ergebnisse zu gewährleisten. Dazu gehören die Modellgewichte, der Trainingsverlauf, die finalen Metriken und die Konfiguration des Branches.

Weitere Informationen zum Auditing-Prozess und der Rückverfolgung von Modellen finden sich in der [Auditing Dokumentation](auditing.md).

## Siehe auch
- [Auditierung](auditing.md)
- [Trainingspipeline](./pipeline.md)
- [Experimentergebnisse](./experiment_results.md)
