# Fokussierte Auswertung der Modell-Experimente auf HAM10000

## Ziel der Untersuchung

Ziel der Experimente war es, für die binäre Klassifikation von **Melanom vs. Nicht-Melanom** auf HAM10000 eine Modellkonfiguration zu identifizieren, die für ein mobiles Dermascan-System geeignet ist. Im Vordergrund standen dabei drei Anforderungen: hohe **Sensitivität** zur Vermeidung übersehener Melanome, hohe **Spezifität** zur Begrenzung unnötiger Fehlalarme und gleichzeitig eine **effiziente Architektur**, die sich perspektivisch für mobile Hardware eignet.

Die Experimente wurden deshalb nicht als reine Architektur-Benchmarking-Übung angelegt, sondern als gezielte Suche nach einem guten **klinisch-praktischen Trade-off**. Getestet wurden unterschiedliche Backbones, Loss-Funktionen, Strategien zur Behandlung des Klassenungleichgewichts und Trainings-Hyperparameter, weil genau diese Faktoren in der Literatur als zentrale Stellhebel für medizinische Bildklassifikation unter Imbalance gelten.

## Vorgehen und Begründung der getesteten Konfigurationen

Getestet wurden mehrere CNN-Architekturen mit ImageNet-Pretraining, darunter EfficientNet V2-S, MobileNet V3, ResNet-Varianten, Inception V3 und SqueezeNet. Diese Auswahl deckt sowohl leistungsstarke als auch ressourcenschonende Modelle ab und folgt dem Ziel, nicht nur maximale Genauigkeit, sondern auch mobile Einsetzbarkeit zu beurteilen.

Die Loss-Funktionen wurden zwischen **Cross Entropy (CE)** und **BCE with Logits (BCE)** variiert. CE wurde getestet, weil sie für Mehrklassen- und binäre Klassifikation robust und einfach interpretierbar ist. BCE wurde zusätzlich getestet, weil sie in Kombination mit `pos_weight` eine direkte Möglichkeit bietet, die Minderheitsklasse Melanom stärker zu gewichten.

Zusätzlich wurden verschiedene Strategien zur Behandlung des Klassenungleichgewichts geprüft: keine Gewichtung, gewichtete Sampler sowie erhöhte `pos_weight`-Werte. Diese Kombinationen wurden getestet, weil in der Literatur zu medizinischen Bilddaten wiederholt gezeigt wird, dass Imbalance-Handling einen größeren Einfluss auf Sensitivität und F1-Macro haben kann als kleine Architekturänderungen.

Auch die Hyperparameter wurden gezielt variiert. Niedrige Lernraten um 1e-4 und 3e-4, Batchgrößen von 8 und 16 sowie unterschiedliche Weight-Decay-Werte wurden geprüft, weil Transfer-Learning-Studien für medizinische Bilder genau diese Bereiche als besonders relevant identifizieren. Die Augmentierung wurde von minimal bis stärker regulierend getestet, um zu prüfen, wann zusätzliche Bildvariation die Generalisierung verbessert und wann sie das Training eher unnötig erschwert.

## Ergebnisstabelle

Die folgende Tabelle zeigt die wichtigsten Modelle, sortiert nach F1-Macro. Für die vertiefte Analyse werden anschließend vier Modelle genauer betrachtet, weil sie unterschiedliche und besonders aufschlussreiche Punkte im Suchraum repräsentieren: das beste Gesamtmodell, das AUC-stärkste CE-Modell, ein CE-Modell mit Sampler und ein leichtgewichtiges mobiles Modell.

| Rang | Branch | F1-Macro | AUC | Sensitivity | Specificity | Precision | MCC | Acc | Loss | LR | Batch | Sampler | pos_w | Epochs |
|------|--------|----------|-----|------------|-------------|-----------|-----|-----|------|----|-------|---------|-------|--------|
| 1 | `eff_bce_strong_reg` | **0.9105** | 0.9731 | 82.0% | **98.0%** | **92.2%** | **0.822** | **95.7%** | BCE | 1e-4 | 16 | (1,7) | 8.0 | 30 |
| 2 | `efficientnet_v2_s_bce` | 0.8983 | 0.9680 | 82.0% | 97.2% | 90.0% | 0.797 | 95.1% | BCE | 1e-4 | 16 | (1,7) | 8.0 | 40 |
| 3 | `rgb_efficientnet_minipc` | 0.8982 | **0.9789** | **83.2%** | 97.0% | 89.5% | 0.796 | 95.1% | CE | 3e-4 | 8 | — | 1.0 | 35 |
| 4 | `efficientnet_v2_s_rgb` | 0.8877 | 0.9691 | 80.2% | 96.9% | 89.0% | 0.775 | 94.5% | CE | 3e-4 | 16 | (1,7) | 1.0 | 35 |
| 5 | `mobilenet_v3_large_ce` | 0.8866 | 0.9577 | 79.0% | 97.1% | 89.3% | 0.773 | 94.5% | CE | 1e-4 | 16 | — | 1.0 | 40 |
| 6 | `resnet101_ce` | 0.8808 | 0.9624 | 74.9% | 97.7% | 90.2% | 0.764 | 94.5% | CE | 1e-4 | 16 | — | 1.0 | 40 |
| 7 | `rgb_efficientnet_1node_bce` | 0.8768 | 0.9711 | 73.9% | 97.7% | 89.9% | 0.756 | 94.5% | BCE | 3e-4 | 8 | — | 1.0 | 35 |
| 8 | `resnet50_ce` | 0.8747 | 0.9704 | 76.0% | 97.0% | 88.5% | 0.750 | 94.0% | CE | 1e-4 | 16 | — | 1.0 | 40 |
| 9 | `resnet50_bce` | 0.8706 | 0.9471 | 80.2% | 95.7% | 86.2% | 0.742 | 93.5% | BCE | 1e-4 | 16 | (1,7) | 8.0 | 40 |
| 10 | `resnet18_ce` | 0.8686 | 0.9666 | 78.4% | 96.0% | 86.5% | 0.737 | 93.5% | CE | 1e-4 | 16 | — | 1.0 | 40 |
| 11 | `eff_ce_with_sampler` | 0.8663 | 0.9690 | 81.4% | 95.1% | 85.2% | 0.734 | 93.2% | CE | 3e-4 | 8 | (1,4) | 1.0 | 25 |
| 12 | `inception_v3_ce` | 0.8640 | 0.9680 | 76.7% | 96.1% | 87.1% | 0.728 | 93.5% | CE | 1e-4 | 16 | — | 1.0 | 40 |
| 13 | `efficientnet_v2_s_ce` | 0.8620 | 0.9640 | 78.4% | 95.5% | 86.8% | 0.724 | 93.5% | CE | 1e-4 | 16 | — | 1.0 | 40 |
| 14 | `eff_ce_best_known` | 0.8546 | 0.9549 | 65.9% | 98.2% | 90.2% | 0.718 | 93.6% | CE | 3e-4 | 8 | — | 1.0 | 25 |
| 15 | `mobilenet_v3_large_bce` | 0.8490 | 0.9560 | **84.4%** | 93.0% | 85.6% | 0.705 | 93.5% | BCE | 1e-4 | 16 | (1,7) | 8.0 | 40 |
| 16 | `mobilenet_v3_small_ce` | 0.8350 | 0.9520 | 80.8% | 92.8% | 84.0% | 0.675 | 93.5% | CE | 1e-4 | 16 | — | 1.0 | 40 |
| 17 | `squeezenet_1_1_ce` | 0.8183 | 0.9450 | 76.7% | 92.6% | 79.7% | 0.641 | 90.4% | CE | 1e-4 | 16 | — | 1.0 | 40 |

## Vertiefte Analyse von vier besonders wichtigen Modellen

### 1. `eff_bce_strong_reg`: bestes Gesamtmodell

Dieses Modell ist das wichtigste Ergebnis der gesamten Versuchsreihe. Es kombiniert EfficientNet V2-S mit BCE, hohem `pos_weight`, gewichtetem Sampler und stärkerem Weight Decay. Damit wurde genau die Hypothese getestet, dass starke Imbalance-Behandlung in Verbindung mit Regularisierung die klinisch relevanten Kennzahlen verbessert.

Das Ergebnis bestätigt diese Hypothese deutlich: F1-Macro, MCC, Spezifität und Präzision sind hier am höchsten. Besonders wichtig ist, dass Sensitivität mit 82.0% trotzdem hoch bleibt. Das Modell erreicht also nicht nur einen guten Durchschnittswert, sondern einen für die Praxis sehr wertvollen Kompromiss: viele Melanome werden gefunden, ohne dass zu viele harmlose Läsionen fälschlich als verdächtig markiert werden.

Die Interpretation ist, dass EfficientNet V2-S mit BCE die Minderheitsklasse besonders gut modellieren kann, wenn Sampler und `pos_weight` gemeinsam wirken. Das erhöhte Weight Decay von 0.005 scheint außerdem die Tendenz zu übermäßig scharfen, instabilen Entscheidungen zu dämpfen, was zum starken MCC und zur hohen Präzision passt.

### 2. `rgb_efficientnet_minipc`: AUC-stärkstes Referenzmodell

Dieses Modell ist deshalb zentral, weil es die beste Trennschärfe über alle Schwellenwerte hinweg erreicht. Getestet wurde hier die Gegenhypothese: Vielleicht braucht EfficientNet gar kein explizites Imbalance-Handling, wenn Lernrate, Batchgröße und Augmentierung sehr günstig gewählt sind.

Das Ergebnis ist bemerkenswert: Mit CE, keiner expliziten Klassengewichtung, kleiner Batchgröße und höherer Lernrate erreicht dieses Modell den höchsten AUC-Wert aller Runs und sogar die höchste Sensitivität unter den Top-3-Modellen. Das zeigt, dass ein sehr sauberes Transfer-Learning-Setup bei EfficientNet bereits einen großen Teil der Klassifikationsaufgabe lösen kann.

Interpretativ bedeutet das: Das Modell sortiert positive und negative Fälle global hervorragend, ist also sehr stark in der Score-Rangordnung. Dennoch ist sein fester Arbeitspunkt etwas schwächer als bei `eff_bce_strong_reg`, weshalb F1-Macro und MCC minimal darunter liegen.

### 3. `efficientnet_v2_s_rgb`: CE mit starkem Sampler

Dieses Modell wurde getestet, um die Frage zu klären, ob CE durch Oversampling einen ähnlichen Effekt wie BCE mit `pos_weight` erreichen kann. Es ist methodisch wichtig, weil es den isolierten Einfluss des Samplers unter ansonsten effizienter EfficientNet-Konfiguration sichtbar macht.

Mit F1-Macro 0.8877, AUC 0.9691 und Sensitivität 80.2% zeigt dieses Modell, dass ein starker Sampler unter CE tatsächlich einen relevanten Teil des Imbalance-Problems abfangen kann. Gegenüber reinen CE-Setups ohne Sampler steigt die Sensitivität deutlich, ohne dass die Gesamtrelevanz des Modells zusammenbricht.

Die Interpretation ist jedoch auch klar: CE plus Sampler reicht nicht ganz an BCE plus Sampler plus `pos_weight` heran. Das deutet darauf hin, dass reines Oversampling zwar mehr positive Beispiele sichtbar macht, aber die Verlustfunktion selbst die Fehler auf der Melanom-Klasse nicht stark genug priorisiert. Genau darin liegt der Vorteil des besten BCE-Modells.

### 4. `mobilenet_v3_large_ce`: wichtigster Lightweight-Kandidat

Dieses Modell wurde vor allem mit Blick auf die Zielplattform untersucht. Für eine echte mobile Anwendung ist nicht nur maximale Performance relevant, sondern auch Parameterzahl, Speicherbedarf und Inferenzgeschwindigkeit. MobileNet V3 Large gilt in der Literatur als starker Kompromiss zwischen Genauigkeit und Effizienz für ressourcenbeschränkte Geräte.

Das Ergebnis ist überraschend stark: F1-Macro 0.8866 und MCC 0.773 liegen sehr nahe an einigen EfficientNet-Varianten. Besonders bemerkenswert ist, dass MobileNet V3 Large CE mehrere größere ResNet- und Inception-Modelle schlägt.

Die Interpretation lautet: Für eine strikt on-device ausgeführte Dermascan-App könnte MobileNet V3 Large ein sehr interessanter Fallback oder Zweitpfad sein. Das Modell ist zwar dem besten EfficientNet-Branch unterlegen, aber die Leistungslücke ist kleiner als erwartet. Damit entsteht eine wichtige Produktperspektive: maximales Screening-Niveau mit EfficientNet V2-S versus höhere Effizienz mit MobileNet V3 Large.

## Gesamtinterpretation der Suchstrategie

Die Gesamtheit der Ergebnisse zeigt, dass drei Hypothesen weitgehend bestätigt wurden. Erstens ist **EfficientNet V2-S** die stärkste getestete Backbone-Familie für diese Aufgabe. Zweitens ist **Imbalance-Handling** kein optionales Detail, sondern ein zentraler Leistungsfaktor; insbesondere BCE mit `pos_weight` und Sampler hebt die Balance zwischen Sensitivität und Spezifität sichtbar an. Drittens sind **kleinere, aber gezielt abgestimmte Hyperparameter-Änderungen** – etwa LR, Batchgröße und Weight Decay – relevanter als das bloße Durchprobieren vieler weiterer Architekturen.

Darüber hinaus zeigen die Resultate, dass die Suchstrategie nicht nur auf „höchste Accuracy“ reduziert werden darf. Mehrere Modelle mit ähnlicher Accuracy unterscheiden sich stark in Sensitivität, Spezifität und MCC. Für medizinische Anwendungen ist deshalb die Interpretation auf Kennzahlenebene wesentlich wichtiger als eine isolierte Betrachtung der Accuracy.

## Schlussfolgerung

Die Experimente zeigen insgesamt, dass der Suchraum sinnvoll und zielgerichtet aufgebaut wurde. Getestet wurde nicht wahllos, sondern entlang der für medizinische Bildklassifikation wichtigsten Achsen: Modellkapazität, Transfer-Learning-Verhalten, Loss-Wahl und Imbalance-Handling. Das beste Ergebnis wurde mit `eff_bce_strong_reg` erzielt, was nahelegt, dass für HAM10000 in dieser binären Aufgabenform nicht die exotischste Architektur, sondern die **richtige Kombination aus starkem Backbone und angemessener Klassenbehandlung** entscheidend ist.

Für die weitere Arbeit bedeutet das: `eff_bce_strong_reg` ist der naheliegende Hauptkandidat für die produktive Weiterentwicklung, `rgb_efficientnet_minipc` ist ein wichtiger Referenzpunkt für Threshold-Optimierung und AUC-orientierte Analysen, `efficientnet_v2_s_rgb` belegt den isolierten Wert von Oversampling unter CE, und `mobilenet_v3_large_ce` ist der wichtigste Kandidat für ein leichteres mobiles Deployment.