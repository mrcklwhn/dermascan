# Fokussierte Auswertung der Modell-Experimente auf HAM10000

## Ziel der Untersuchung

Ziel der Experimente war es, für die binäre Klassifikation von **Melanom vs. Nicht-Melanom** auf HAM10000 eine Modellkonfiguration zu identifizieren, die für ein mobiles Dermascan-System geeignet ist. Im Vordergrund standen drei Anforderungen:

- eine hohe **Sensitivität**, damit möglichst wenige Melanome übersehen werden,
- eine hohe **Spezifität**, damit unnötige Fehlalarme begrenzt bleiben, und
- eine **effiziente Architektur**, die perspektivisch auf mobiler Hardware eingesetzt werden kann.

Die Versuchsreihe war deshalb nicht als reines Architektur-Benchmarking angelegt. Sie war vielmehr eine schrittweise Suche nach einem klinisch brauchbaren Kompromiss zwischen Erkennungsleistung, Fehlalarmrate und technischer Umsetzbarkeit. Getestet wurden unterschiedliche Backbones, Loss-Funktionen, Strategien gegen Klassenungleichgewicht und Trainings-Hyperparameter, weil genau diese Faktoren in der Literatur und in den eigenen Vorversuchen als zentrale Stellhebel für medizinische Bildklassifikation sichtbar wurden.

## Vorgehen und Begründung der getesteten Konfigurationen

Der HAM10000-Datensatz wurde in eine binäre Aufgabe überführt: Melanom als positive Klasse gegen alle übrigen Läsionen als negative Klasse. Getestet wurden mehrere CNN-Architekturen mit ImageNet-Pretraining, darunter EfficientNet V2-S, MobileNet V3, ResNet-Varianten, Inception V3 und SqueezeNet. Diese Auswahl deckt sowohl leistungsstarke als auch ressourcenschonende Modelle ab und folgt dem Ziel, nicht nur maximale Genauigkeit, sondern auch mobile Einsetzbarkeit zu beurteilen. Die Aufnahme von EfficientNet-Varianten war dabei besonders naheliegend, weil EfficientNet-basierte Ensembles in der SIIM-ISIC Melanoma Classification Challenge sehr hohe AUC-Werte erreichten und auch neuere HAM10000-Arbeiten wie EFFNet EfficientNetV2 als zentrale Merkmalsextraktion nutzen.

Die Loss-Funktionen wurden zwischen **Cross Entropy (CE)** und **BCE with Logits (BCE)** variiert. CE wurde getestet, weil sie für Mehrklassen- und binäre Klassifikation robust und einfach interpretierbar ist. BCE wurde zusätzlich eingesetzt, weil sie in Kombination mit `pos_weight` eine direkte Möglichkeit bietet, die Minderheitsklasse Melanom stärker zu gewichten.

Zusätzlich wurden verschiedene Strategien zur Behandlung des Klassenungleichgewichts geprüft:

- keine explizite Gewichtung,
- `WeightedRandomSampler`, bei denen Melanom-Beispiele häufiger in Trainingsbatches gezogen werden,
- `pos_weight` bei BCE, wodurch Fehler auf der positiven Klasse stärker in den Loss eingehen,
- `class_weights` bei CE, wodurch die Minderheitsklasse ebenfalls loss-seitig priorisiert wird.

Diese Kombinationen wurden getestet, weil Klassenungleichgewicht in medizinischen Bilddaten Sensitivität, F1-Macro und MCC deutlich beeinflussen kann. Studien zu CNNs und medizinischen Klassifikationsaufgaben zeigen übereinstimmend, dass Sampling-Strategien, gewichtete Loss-Funktionen und datenbasierte Balancierung die Leistung auf Minderheitsklassen stark verändern können. Sampler und Loss-Gewichtung adressieren dasselbe Problem auf unterschiedlichen Ebenen: Sampler verändern die Zusammensetzung der Trainingsbatches, während `pos_weight` oder `class_weights` die Optimierungsfunktion selbst verändern. Ihre Kombination kann deshalb wirksam sein, muss aber vorsichtig interpretiert werden, weil eine doppelte Gewichtung das Training auch destabilisieren kann.

Auch die Hyperparameter wurden gezielt variiert. Niedrige Lernraten um `1e-4` und `3e-4`, Batchgrößen von 8 und 16 sowie unterschiedliche Weight-Decay-Werte wurden geprüft, weil Transfer-Learning-Studien für medizinische Bilder genau diese Bereiche als besonders relevant beschreiben. Der interaktive Einfluss von Lernrate und Batchgröße wurde auch in Transfer-Learning-Experimenten zur medizinischen Bildklassifikation gezeigt. Die Augmentierung wurde von minimal bis stärker regulierend getestet, um zu prüfen, wann zusätzliche Bildvariation die Generalisierung verbessert und wann sie das Training unnötig erschwert.

Im Refinement-Lauf wurde außerdem ein Branch ohne ImageNet-Pretraining (`pretrained=False`) aufgenommen. Damit wurde der Beitrag des Transfer Learnings gegenüber einem Training von Grund auf kontrolliert untersucht.

Die Modelle und Artefakte der dokumentierten Trainingsergebnisse sind in der [FAUBox](https://faubox.rrze.uni-erlangen.de/getlink/fiBdx9pHi9z1Qo3cPAcJmh/Dermascan) abgelegt, insbesondere im Verzeichnis `training results`.

## Erläuterung der Metriken und Trainingsparameter

Die folgenden Tabellen verwenden mehrere Metriken, weil Accuracy allein bei einem unausgeglichenen medizinischen Datensatz ein unvollständiges Bild liefert. Ein Modell kann eine hohe Accuracy erreichen, wenn es die Mehrheitsklasse zuverlässig erkennt, dabei aber zu viele Melanome übersieht. Für die Bewertung sind deshalb insbesondere Sensitivität, Spezifität, AUC, F1-Macro und MCC relevant.

- **Sensitivität** beschreibt den Anteil korrekt erkannter Melanome. Sie ist für den ärztlichen Einsatz besonders wichtig, weil übersehene Melanome das kritischste Fehlermuster darstellen.
- **Spezifität** beschreibt den Anteil korrekt erkannter Nicht-Melanome. Sie zeigt, wie stark ein Modell unnötige Fehlalarme begrenzt.
- **Precision** gibt an, wie viele als Melanom vorhergesagte Fälle tatsächlich Melanome sind. Eine niedrige Precision bedeutet, dass viele positive Hinweise falsch sind.
- **Accuracy** misst den Gesamtanteil korrekter Vorhersagen. Bei Klassenungleichgewicht muss sie zusammen mit den anderen Metriken interpretiert werden.
- **F1 Binary** fasst Precision und Sensitivität für die positive Klasse zusammen. **F1-Macro** mittelt die F1-Werte beider Klassen und ist deshalb aussagekräftiger, wenn beide Klassen trotz Ungleichgewicht ernst genommen werden sollen.
- **AUC** bewertet die Trennfähigkeit des Modells über verschiedene Schwellenwerte hinweg. Ein hoher AUC-Wert bedeutet, dass positive und negative Fälle grundsätzlich gut separierbar sind.
- **MCC** steht für Matthews Correlation Coefficient. Er berücksichtigt True Positives, True Negatives, False Positives und False Negatives gemeinsam und ist bei unausgeglichenen Klassen besonders robust.
- **TN, FP, FN und TP** bezeichnen die absoluten Einträge der Konfusionsmatrix: korrekt erkannte Nicht-Melanome, fälschlich als Melanom markierte Nicht-Melanome, übersehene Melanome und korrekt erkannte Melanome.

Die Trainingsparameter beschreiben, wie die jeweiligen Modelle optimiert wurden. **Loss** bezeichnet die Verlustfunktion, also das Optimierungsziel des Trainings. **LR** ist die Lernrate und bestimmt die Schrittweite der Gewichtsaktualisierung. **Batch** gibt an, wie viele Bilder pro Trainingsschritt verarbeitet werden. **Sampler** beschreibt, ob Trainingsbeispiele gewichtet gezogen wurden, um Melanom-Fälle häufiger in den Batches sichtbar zu machen. **Gewichtung** fasst loss-seitige Maßnahmen wie `class_weights` oder `pos_weight` zusammen. **Epochen** geben an, wie oft das Modell den Trainingsdatensatz vollständig durchlaufen hat. Der **optimale Threshold** ist der Entscheidungsschwellenwert, bei dem aus Modellwahrscheinlichkeiten die finale Klassenzuordnung gebildet wurde.

## Ursprünglicher Basistest: Multibranch- und Filteransatz

Vor der fokussierten Modellserie wurde ein früher Basistest durchgeführt, um die grundsätzliche Sinnhaftigkeit einer Multibranch-Architektur mit unterschiedlich gefilterten Eingaben zu prüfen. Dafür wurden vier ResNet-Modelle trainiert, jeweils auf einem anderen Bildformat: Original-RGB, LBP, Gabor und GLCM. Alle Modelle nutzten dieselben Hyperparameter: `30` Epochen, Batchgröße `16`, AdamW mit Lernrate `1e-4` und Weight Decay `1e-4` sowie einen Reduce-on-Plateau-Scheduler mit Patience `3`.

Anschließend wurden zehn Ensemble-Konfigurationen evaluiert, die sich in der Auswahl der Branches und in der Kombinationsstrategie unterschieden. Die Einzelmodelle sind ebenfalls aufgeführt, um den Mehrwert der kombinierten Varianten sichtbar zu machen. Da dieser frühe Test auf einer anderen Entwicklungsstufe entstand, ist er nicht direkt mit der späteren fokussierten Versuchsreihe vergleichbar. Er ist aber wichtig, weil er die Richtung der weiteren Arbeit begründete: RGB-Informationen blieben zentral, Gabor-Filter lieferten zusätzliche Hinweise, und die insgesamt niedrige Sensitivität machte deutlich, dass stärkere Maßnahmen gegen Klassenungleichgewicht notwendig waren.

| Modell | Sensitivität | AUC | Spezifität | Accuracy | F1 Binary | F1-Macro | TN | FP | FN | TP |
|--------|--------------|-----|------------|----------|-----------|----------|----|----|----|----|
| `ensemble_gabor_rgb_soft` | 59.28 % | 0.9300 | 96.62 % | 91.30 % | 0.6600 | 0.8051 | 972 | 34 | 68 | 99 |
| `gabor_filtered_standalone` | 57.49 % | 0.9240 | 95.43 % | 90.03 % | 0.6214 | 0.7820 | 960 | 46 | 71 | 96 |
| `rgb_standalone` | 44.91 % | 0.9065 | 96.32 % | 89.00 % | 0.5376 | 0.7376 | 969 | 37 | 92 | 75 |
| `ensemble_all_soft` | 38.32 % | 0.9231 | 97.61 % | 89.17 % | 0.5020 | 0.7206 | 982 | 24 | 103 | 64 |
| `ensemble_lbp_rgb_soft` | 35.93 % | 0.8958 | 97.22 % | 88.49 % | 0.4706 | 0.7030 | 978 | 28 | 107 | 60 |
| `ensemble_all_hard` | 36.53 % | 0.8293 | 97.51 % | 88.83 % | 0.4822 | 0.7098 | 981 | 25 | 106 | 61 |
| `ensemble_glcm_rgb_soft` | 32.34 % | 0.9096 | 97.22 % | 87.98 % | 0.4337 | 0.6832 | 978 | 28 | 113 | 54 |
| `lbp_filtered_standalone` | 29.34 % | 0.8259 | 95.92 % | 86.45 % | 0.3813 | 0.6526 | 965 | 41 | 118 | 49 |
| `glcm_filtered_standalone` | 25.15 % | 0.8585 | 97.61 % | 87.30 % | 0.3605 | 0.6450 | 982 | 24 | 125 | 42 |

Der beste frühe Ansatz war `ensemble_gabor_rgb_soft` mit einer AUC von 0.9300 und einem F1-Macro von 0.8051. Gleichzeitig lag die Sensitivität nur bei 59.28 %. Für ein medizinisches Screening-Szenario war das zu niedrig, weil zu viele Melanome übersehen worden wären. Dieser Befund führte direkt zur späteren Fokussierung auf stärkere Backbones, Transfer Learning und explizites Imbalance-Handling.

## Ergebnisstabelle der fokussierten Modellserie

Die folgende Tabelle zeigt die späteren Modellläufe, sortiert nach F1-Macro. Für die vertiefte Analyse werden anschließend fünf Punkte genauer betrachtet: das beste Modell nach F1-Macro, das für den Produktiveinsatz ausgewählte sensitivitätsstarke Modell, der wichtigste Lightweight-Kandidat, die Kontrollbedingung ohne ImageNet-Pretraining sowie eine zusammenfassende Betrachtung der übrigen Architekturen.

| Rang | Branch | F1-Macro | AUC | Sensitivität | Spezifität | Precision | MCC | Acc | opt. Threshold | Loss | LR | Batch | Sampler | Gewichtung | Epochen |
|------|--------|----------|-----|--------------|------------|-----------|-----|-----|----------------|------|----|-------|---------|------------|---------|
| 1 | `eff_ce_class_weights_strong_reg_rgb` | **0.9175** | 0.9728 | 80.8 % | 98.7 % | **94.0 %** | **0.837** | **96.2 %** | 0.1 | CE | 1e-4 | 16 | - | cw=[1,7] | 25 |
| 2 | `eff_bce_strong_reg_rgb` | 0.9105 | 0.9731 | 82.0 % | 98.0 % | 92.2 % | 0.822 | 95.7 % | 0.1 | BCE | 1e-4 | 16 | (1,7) | pos_weight=8 | 30 |
| 3 | `eff_ce_class_weights_moderate_rgb` | 0.9087 | 0.9622 | 77.8 % | **98.8 %** | **94.0 %** | 0.821 | 95.8 % | 0.1 | CE | 1e-4 | 16 | - | cw=[1,3] | 25 |
| 4 | `eff_bce_lower_penalty_rgb` | 0.9074 | 0.9745 | 82.0 % | 97.8 % | 91.6 % | 0.815 | 95.7 % | 0.1 | BCE | 1e-4 | 16 | (1,4) | pos_weight=4 | 30 |
| 5 | `eff_ce_class_weights_plus_sampler_rgb` | 0.9055 | 0.9644 | 77.8 % | 98.6 % | 93.3 % | 0.814 | 95.7 % | 0.1 | CE | 1e-4 | 16 | (1,4) | cw=[1,4] | 25 |
| 6 | `efficientnet_v2_s_bce_rgb` | 0.8983 | 0.9680 | 82.0 % | 97.2 % | 90.0 % | 0.797 | 95.1 % | 0.1 | BCE | 1e-4 | 16 | (1,7) | pos_weight=8 | 40 |
| 7 | `efficientnet_v2_s_rgb` | 0.8885 | **0.9766** | 74.9 % | 98.2 % | 91.67 % | 0.780 | 94.88 % | 0.1 | CE | 3e-4 | 16 | (1,7) | - | 35 |
| 8 | `eff_ce_class_weights_only_rgb` | 0.8872 | 0.9723 | 79.6 % | 97.0 % | 89.1 % | 0.774 | 94.5 % | 0.1 | CE | 1e-4 | 16 | - | cw=[1,7] | 25 |
| 9 | `mobilenet_v3_large_ce_rgb` | 0.8866 | 0.9577 | 79.0 % | 97.1 % | 89.3 % | 0.773 | 94.5 % | 0.1 | CE | 1e-4 | 16 | - | - | 40 |
| 10 | `resnet101_ce_rgb` | 0.8808 | 0.9624 | 74.9 % | 97.7 % | 90.2 % | 0.764 | 94.5 % | 0.1 | CE | 1e-4 | 16 | - | - | 40 |
| 11 | `resnet50_ce_rgb` | 0.8747 | 0.9704 | 76.0 % | 97.0 % | 88.5 % | 0.750 | 94.0 % | 0.1 | CE | 1e-4 | 16 | - | - | 40 |
| 12 | `resnet50_bce_rgb` | 0.8706 | 0.9471 | 80.2 % | 95.7 % | 86.2 % | 0.742 | 93.5 % | 0.1 | BCE | 1e-4 | 16 | (1,7) | pos_weight=8 | 40 |
| 13 | `resnet18_ce_rgb` | 0.8686 | 0.9666 | 78.4 % | 96.0 % | 86.5 % | 0.737 | 93.5 % | 0.1 | CE | 1e-4 | 16 | - | - | 40 |
| 14 | `eff_ce_with_sampler_rgb` | 0.8663 | 0.9690 | 81.4 % | 95.1 % | 85.2 % | 0.734 | 93.2 % | 0.1 | CE | 3e-4 | 8 | (1,4) | - | 25 |
| 15 | `inception_v3_ce_rgb` | 0.8640 | 0.9680 | 76.7 % | 96.1 % | 87.1 % | 0.728 | 93.5 % | 0.1 | CE | 1e-4 | 16 | - | - | 40 |
| 16 | `efficientnet_v2_s_ce_rgb` | 0.8620 | 0.9640 | 78.4 % | 95.5 % | 86.8 % | 0.724 | 93.5 % | 0.1 | CE | 1e-4 | 16 | - | - | 40 |
| 17 | `eff_ce_best_known_rgb` | 0.8546 | 0.9549 | 65.9 % | 98.2 % | 90.2 % | 0.718 | 93.6 % | 0.1 | CE | 3e-4 | 8 | - | - | 25 |
| 18 | `mobilenet_v3_large_bce_rgb` | 0.8490 | 0.9560 | 84.4 % | 93.0 % | 85.6 % | 0.705 | 93.5 % | 0.1 | BCE | 1e-4 | 16 | (1,7) | pos_weight=8 | 40 |
| 19 | `mobilenet_v3_small_ce_rgb` | 0.8350 | 0.9520 | 80.8 % | 92.8 % | 84.0 % | 0.675 | 93.5 % | 0.1 | CE | 1e-4 | 16 | - | - | 40 |
| 20 | `squeezenet_1_1_ce_rgb` | 0.8183 | 0.9450 | 76.7 % | 92.6 % | 79.7 % | 0.641 | 90.4 % | 0.1 | CE | 1e-4 | 16 | - | - | 40 |
| 21 | `eff_ce_class_weights_no_pretrain_rgb` | 0.6894 | 0.9101 | **91.6 %** | 74.6 % | 67.8 % | 0.485 | 76.9 % | 0.1 | CE | 1e-4 | 16 | - | cw=[1,7] | 35 |

## Vertiefte Analyse von fünf besonders wichtigen Modellen

### 1. `eff_ce_class_weights_strong_reg`: bestes Gesamtmodell nach F1-Macro

Dieses Modell ist der stärkste Lauf der Versuchsreihe, wenn F1-Macro, MCC, Precision, Accuracy und Spezifität gemeinsam betrachtet werden. Es wurde im Refinement-Lauf als gezielter Folgebranch zur Konfiguration `eff_ce_class_weights_only` aufgenommen. Die zentrale Änderung gegenüber dem schwächeren Vorgänger war eine Erhöhung des Weight Decays von `0.0001` auf `0.001`. Damit wurde geprüft, ob stärkere Regularisierung die Tendenz zur Überanpassung bei aggressiver Klassengewichtung (`cw=[1,7]`) abfangen kann.

Das Ergebnis bestätigt diese Annahme deutlich: F1-Macro steigt von 0.8872 auf 0.9175, MCC von 0.774 auf 0.837. Auch Spezifität (98.7 %), Precision (94.0 %) und Accuracy (96.2 %) liegen auf sehr hohem Niveau. Der Branch zeigt damit, dass CE mit deutlicher Klassengewichtung kein grundsätzlich instabiles Setup sein muss, solange die Gewichtung durch passende Regularisierung begleitet wird.

Für den Anwendungskontext ist diese Konfiguration besonders aufschlussreich, weil sie die beste durchschnittliche Klassifikationsqualität liefert. Ihre Sensitivität von 80.8 % ist hoch, aber nicht maximal. Genau an dieser Stelle wird sichtbar, dass die Modellwahl nicht allein über den besten Durchschnittswert entschieden werden kann, sondern über die klinisch priorisierte Fehlerart.

### 2. `eff_bce_strong_reg`: sensitivitätsstarker Produktivkandidat

`eff_bce_strong_reg` ist nur knapp hinter dem besten CE-Modell platziert, liefert aber ein für den ärztlichen Einsatz besonders relevantes Profil. Mit F1-Macro 0.9105, AUC 0.9731 und MCC 0.822 bleibt die Gesamtleistung sehr hoch. Gleichzeitig erreicht das Modell eine Sensitivität von 82.0 % bei einer weiterhin starken Spezifität von 98.0 %.

Die Konfiguration kombiniert BCE mit `pos_weight=8`, einen gewichteten Sampler `(1,7)`, eine Lernrate von `1e-4`, Batchgröße `16` und stärkere Regularisierung. Diese Kombination priorisiert Fehler auf der Melanom-Klasse deutlicher als die meisten CE-Setups. Für ein System, das Ärztinnen und Ärzte in der Früherkennung unterstützen soll, ist dieser Schwerpunkt plausibel: Ein übersehenes Melanom ist in der Regel kritischer als ein zusätzlicher Hinweis, der anschließend medizinisch überprüft wird.

Wichtig ist aber auch hier die Balance. Das Modell erkauft die höhere Sensitivität nicht durch einen massiven Einbruch der Spezifität, sondern bleibt mit 98.0 % sehr kontrolliert. Genau deshalb ist dieser Branch ein überzeugender Produktivkandidat, obwohl `eff_ce_class_weights_strong_reg` nach F1-Macro noch etwas stärker abschneidet.

### 3. `mobilenet_v3_large_ce`: wichtigster Lightweight-Kandidat

Für eine mobile Anwendung ist nicht nur maximale Modellgüte relevant, sondern auch Speicherbedarf, Parameterzahl und Inferenzgeschwindigkeit. MobileNet V3 Large wurde deshalb als ressourcenschonender Kandidat evaluiert.

Das Ergebnis ist bemerkenswert stabil: F1-Macro 0.8866 und MCC 0.773 liegen nahe an mehreren EfficientNet-Varianten und übertreffen größere ResNet- und Inception-Modelle. Damit ist MobileNet V3 Large kein reines Kompromissmodell, sondern ein ernstzunehmender Kandidat für Szenarien mit engen Ressourcenlimits.

Für eine strikt on-device ausgeführte Dermascan-App könnte dieses Modell als Lightweight-Fallback oder Zweitpfad dienen. Gegenüber den besten EfficientNet-Branches bleibt eine messbare Leistungslücke, sie ist aber kleiner als aufgrund der Architekturkomplexität zu erwarten wäre. Besonders relevant ist, dass MobileNet V3 Large mit CE bereits ohne zusätzliche Gewichtung eine solide Sensitivität von 79.0 % erreicht.

### 4. `eff_ce_class_weights_no_pretrain`: Training ohne ImageNet-Initialisierung

Dieser Branch wurde als methodische Kontrollbedingung in den Refinement-Lauf aufgenommen. Die Konfiguration entspricht im Kern dem starken CE-Setup mit `cw=[1,7]` und `weight_decay=0.001`, verwendet jedoch keine ImageNet-Gewichte. Das Modell wurde vollständig von zufälligen Initialisierungen trainiert (`pretrained=False`). Um diesen strukturellen Nachteil teilweise zu kompensieren, wurden 35 Epochen und eine umfangreichere Augmentierungsstrategie eingesetzt. Der Vergleich ist auch deshalb relevant, weil EFFNet auf HAM10000 in Ablationsversuchen ebenfalls einen deutlichen Nutzen von Transfer Learning gegenüber einem Training ohne vortrainierte Gewichte berichtet.

Die Ergebnisse zeigen den Beitrag des Transfer Learnings sehr klar. Das Modell erreicht nur F1-Macro 0.6894, MCC 0.485 und Accuracy 76.9 %. Damit liegt es deutlich unter allen `pretrained=True`-Konfigurationen der Versuchsreihe. Auch das Trainingsverhalten deutet auf fehlende Konvergenzstabilität hin: Der Train-Loss sinkt langsamer als bei vortrainierten Modellen, das Val-F1-Macro schwankt ohne stabiles Plateau, und die beste Epoche liegt bereits in der Mitte des Trainings.

Auffällig ist die sehr hohe Sensitivität von 91.6 %. Dieser Wert ist jedoch nicht als robuste klinische Stärke zu interpretieren, weil er mit einem massiven Einbruch der Spezifität auf 74.6 % und einer Precision von 67.8 % einhergeht. Das Modell tendiert bei Unsicherheit systematisch zur Melanom-Klasse. Dieses Muster spricht dafür, dass aggressive Klassengewichtung ohne die Merkmalsbasis eines vortrainierten Backbones zu einer verzerrten Entscheidungsgrenze führen kann.

### 5. Zusammenfassung der übrigen Architekturen

Die übrigen Architekturen ergänzen das Bild der Suchstrategie. ResNet101, ResNet50 und ResNet18 erreichen solide Werte, bleiben aber hinter den besten EfficientNet-Branches zurück. Besonders ResNet50 CE zeigt mit AUC 0.9704, dass die Rangordnung nicht aus fehlender Trennfähigkeit allein entsteht; entscheidend ist vielmehr, wie gut ein Modell bei einem konkreten Schwellenwert Sensitivität, Spezifität und Precision ausbalanciert.

Inception V3 und SqueezeNet erfüllen jeweils andere Rollen. Inception V3 bleibt leistungsfähig, bringt aber keinen Vorteil gegenüber den kompakteren oder stärkeren Alternativen. SqueezeNet ist ressourcenschonend, fällt in F1-Macro, Precision und MCC jedoch klar zurück. Für einen medizinischen Klassifikationspfad ist dieser Leistungsverlust zu groß, auch wenn die Architektur prinzipiell attraktiv für kleine Geräte wäre.

Die MobileNet-Varianten zeigen, dass Leichtgewichtigkeit nicht automatisch schwache Klassifikationsleistung bedeutet. MobileNet V3 Large mit CE ist klar stärker als MobileNet V3 Small und auch stabiler als MobileNet V3 Large mit BCE, bei dem die Sensitivität zwar steigt, die Spezifität aber deutlich sinkt. Insgesamt bestätigen die übrigen Architekturen deshalb zwei Punkte: EfficientNet V2-S bleibt die stärkste Backbone-Familie, während MobileNet V3 Large der sinnvollste Kandidat für ein ressourcenbeschränktes Alternativmodell ist.

## Gesamtinterpretation der Suchstrategie

Die Entwicklung von den frühen Multibranch-Tests zur fokussierten Modellserie zeigt eine klare Lernkurve. Der ursprüngliche Gabor-RGB-Ansatz konnte bereits eine gute AUC erzielen, litt aber unter zu niedriger Sensitivität. Damit war früh erkennbar, dass reine Ensemblebildung oder zusätzliche gefilterte Eingaben nicht ausreichen, wenn die Minderheitsklasse Melanom zuverlässig erkannt werden soll.

In der späteren Modellserie wurde dieses Problem systematischer adressiert. EfficientNet V2-S erwies sich als stärkste Backbone-Familie, vor allem in Kombination mit Transfer Learning und explizitem Imbalance-Handling. Die besten Plätze werden fast ausschließlich von EfficientNet-Branches belegt. Das passt zu melanoma- und HAM10000-bezogenen Arbeiten, in denen EfficientNet-Varianten als leistungsfähige Backbones oder Merkmalsextraktoren eingesetzt werden.

Der wichtigste methodische Befund liegt jedoch nicht nur in der Architekturwahl. Die Ergebnisse zeigen, dass Imbalance-Handling und Regularisierung stärker über die praktische Nutzbarkeit entscheiden als das bloße Durchprobieren weiterer Backbones. CE mit `class_weights=[1,7]` und `weight_decay=0.001` liefert den besten F1-Macro und den höchsten MCC. BCE mit `pos_weight=8`, gewichtetem Sampler und starker Regularisierung erreicht dagegen ein besonders attraktives Sensitivitätsprofil bei weiterhin hoher Spezifität. Beide Befunde sind für die Anwendung wichtig, führen aber zu unterschiedlichen Prioritäten.

Auch die Kontrollbedingung ohne ImageNet-Pretraining ist eindeutig: Auf einem Datensatz der Größe von HAM10000 ist Transfer Learning eine strukturelle Voraussetzung für stabile Generalisierung. Der `pretrained=False`-Branch fällt trotz längerem Training und stärkerer Augmentierung deutlich zurück. Seine hohe Sensitivität ist wegen der schwachen Spezifität und Precision nicht produktiv nutzbar.

Für die Interpretation der Versuchsreihe ist deshalb entscheidend, nicht nur Accuracy oder F1-Macro zu betrachten. Mehrere Modelle mit ähnlicher Accuracy unterscheiden sich deutlich in Sensitivität, Spezifität, Precision und MCC. Gerade im medizinischen Kontext ist die Modellwahl eine fachliche Abwägung: Soll der durchschnittliche Klassifikationskompromiss maximiert werden, spricht viel für `eff_ce_class_weights_strong_reg`. Soll die Vermeidung übersehener Melanome stärker priorisiert werden, ist `eff_bce_strong_reg` die passendere Wahl.

## Produktiveinsatz

Für den Produktiveinsatz hat sich das Team für `eff_bce_strong_reg` entschieden. Ausschlaggebend ist die hohe Sensitivität von 82.0 % bei gleichzeitig sehr guter Spezifität von 98.0 %. In einem ärztlich begleiteten Dermascan-System ist diese Gewichtung sinnvoll: Das Modell soll keine Diagnose ersetzen, sondern verdächtige Fälle möglichst zuverlässig markieren und damit eine medizinische Beurteilung unterstützen. In diesem Nutzungskontext ist ein nicht erkannter Melanomfall schwerwiegender als ein zusätzlicher Hinweis, der anschließend fachlich überprüft werden kann.

Die gewählte Konfiguration nutzt BCE, `pos_weight=8`, einen gewichteten Sampler `(1,7)`, Batchgröße `16`, Lernrate `1e-4` und stärkere Regularisierung. Sie verbindet damit loss-seitige Priorisierung der positiven Klasse mit einer Trainingsbatch-Zusammensetzung, die Melanom-Beispiele häufiger sichtbar macht. Gleichzeitig bleibt die Gesamtleistung mit F1-Macro 0.9105, AUC 0.9731 und MCC 0.822 sehr hoch.

`eff_ce_class_weights_strong_reg` bleibt als stärkstes Vergleichsmodell wichtig, weil es den höchsten F1-Macro, den höchsten MCC, die beste Precision und die höchste Accuracy erreicht. Für den konkreten Einsatz wurde jedoch bewusst nicht allein nach dem höchsten Durchschnittswert entschieden, sondern nach dem klinisch relevanteren Fehlerprofil.

Als ressourcenschonende Alternative bleibt `mobilenet_v3_large_ce` relevant. Es kann als Lightweight-Fallback oder als Kandidat für besonders eingeschränkte Geräte betrachtet werden. Vor einem produktiven Rollout sollten jedoch beide ausgewählten Pfade zusätzlich auf externen Validierungsdaten, kalibrierten Schwellenwerten und realistischen mobilen Inferenzbedingungen geprüft werden.

## Verwendete Quellen

- Tschandl et al. (2018): *The HAM10000 dataset, a large collection of multi-source dermatoscopic images of common pigmented skin lesions.* Nature Scientific Data. https://www.nature.com/articles/sdata2018161
- Ha, Liu und Liu (2020): *Identifying Melanoma Images using EfficientNet Ensemble: Winning Solution to the SIIM-ISIC Melanoma Classification Challenge.* arXiv:2010.05351. https://arxiv.org/pdf/2010.05351v1
- Buda et al. (2018): *A systematic study of the class imbalance problem in convolutional neural networks.* PubMed. https://pubmed.ncbi.nlm.nih.gov/30092410/
- Scholz et al. (2024): *Imbalance-aware loss functions improve medical image classification.* PMLR. https://proceedings.mlr.press/v250/scholz24a.html
- PMC (2023): *A Comparison of Techniques for Class Imbalance in Deep Learning Classification of Breast Cancer.* https://pmc.ncbi.nlm.nih.gov/articles/PMC9818528/
- Loshchilov und Hutter (2017): *Decoupled Weight Decay Regularization.* arXiv:1711.05101. https://arxiv.org/abs/1711.05101
- NeurIPS (2022): *The Effects of Regularization and Data Augmentation are Class Dependent.* https://papers.neurips.cc/paper_files/paper/2022/file/f73c04538a5e1cad40ba5586b4b517d3-Paper-Conference.pdf
- Kandel und Castelli: *The effect of batch size on the generalizability of the convolutional neural networks on a histopathology dataset.* Universität Ljubljana. https://repozitorij.uni-lj.si/IzpisGradiva.php?id=124243
- Usmani und Qadri (2023): *Interactive Effect of Learning Rate and Batch Size to Implement Transfer Learning for Brain Tumor Classification.* Electronics. https://www.mdpi.com/2079-9292/12/4/964
- Jurnal Polibatam (2024): *Comparative Analysis of MobileNetV3 and EfficientNetV2B0 in Skin Lesion Classification.* https://jurnal.polibatam.ac.id/index.php/JAIC/article/download/11878/3402/38766
- IJRPR (2025): *Medical Image Classification using Transfer Learning.* https://ijrpr.com/uploads/V6ISSUE10/IJRPR53832.pdf
- scholar.ui.ac.id (2023): *EfficientNetV2 based for MRI brain tumor image classification.* https://scholar.ui.ac.id/en/publications/efficientnetv2-based-for-mri-brain-tumor-image-classification/
- Ma et al. (2023): *EFFNet: A skin cancer classification model based on feature fusion and random forests.* PLOS ONE. https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0293266
- PMC (2019): *Hybrid Transfer Learning for Classification of Uterine Cervix Images.* https://pmc.ncbi.nlm.nih.gov/articles/PMC7256135/
- PyTorch Discussion: *pos_weight and weight parameters in BCEWithLogitsLoss.* https://discuss.pytorch.org/t/pos-weight-and-weight-parameters-in-bcewithlogitsloss/130651
- Stack Overflow: *Class weights vs. under/oversampling.* https://stackoverflow.com/questions/55657807/class-weights-vs-under-oversampling
