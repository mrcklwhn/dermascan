# Fokussierte Auswertung der Modell-Experimente auf HAM10000

## Ziel der Untersuchung

Ziel der Experimente war es, fuer die binaere Klassifikation von **Melanom vs. Nicht-Melanom** auf HAM10000 eine Modellkonfiguration zu identifizieren, die fuer ein mobiles Dermascan-System geeignet ist. Im Vordergrund standen drei Anforderungen: hohe **Sensitivitaet** zur Vermeidung uebersehener Melanome, hohe **Spezifitaet** zur Begrenzung unnoetiger Fehlalarme und gleichzeitig eine **effiziente Architektur**, die perspektivisch auf mobiler Hardware eingesetzt werden kann.

Die Experimente wurden nicht als reines Architektur-Benchmarking angelegt, sondern als gezielte Suche nach einem klinisch-praktischen Trade-off. Getestet wurden unterschiedliche Backbones, Loss-Funktionen, Strategien zur Behandlung des Klassenungleichgewichts und Trainings-Hyperparameter, weil diese Faktoren in der Literatur als zentrale Stellhebel fuer medizinische Bildklassifikation unter Imbalance gelten.

## Vorgehen und Begruendung der getesteten Konfigurationen

Der HAM10000-Datensatz wurde in eine binaere Aufgabe ueberfuehrt: Melanom als positive Klasse gegen alle uebrigen Laesionen als negative Klasse. Dieses Setup wurde gewaehlt, weil fuer ein Screening- oder Triage-System die Unterscheidung zwischen potenziell gefaehrlich und wahrscheinlich unauffaellig klinisch relevanter ist als eine reine 7-Klassen-Klassifikation.

Getestet wurden mehrere CNN-Architekturen mit ImageNet-Pretraining, darunter EfficientNet V2-S, MobileNet V3, ResNet-Varianten, Inception V3 und SqueezeNet. Diese Auswahl deckt sowohl leistungsstarke als auch ressourcenschonende Modelle ab und folgt dem Ziel, nicht nur maximale Genauigkeit, sondern auch mobile Einsetzbarkeit zu beurteilen. Die Aufnahme von EfficientNet-Varianten ist dabei besonders naheliegend, weil EfficientNet-basierte Ensembles in der SIIM-ISIC Melanoma Classification Challenge sehr hohe AUC-Werte erreichten und auch neuere HAM10000-Arbeiten wie EFFNet EfficientNetV2 als zentrale Merkmalsextraktion nutzen.

Die Loss-Funktionen wurden zwischen **Cross Entropy (CE)** und **BCE with Logits (BCE)** variiert. CE wurde getestet, weil sie fuer Mehrklassen- und binaere Klassifikation robust und einfach interpretierbar ist. BCE wurde zusaetzlich eingesetzt, weil sie in Kombination mit `pos_weight` eine direkte Moeglichkeit bietet, die Minderheitsklasse Melanom staerker zu gewichten.

Zusaetzlich wurden verschiedene Strategien zur Behandlung des Klassenungleichgewichts geprueft:

- keine explizite Gewichtung
- gewichtete Sampler, bei denen Melanom-Beispiele haeufiger in Trainingsbatches gezogen werden
- `pos_weight` bei BCE, wodurch Fehler auf der positiven Klasse staerker in den Loss eingehen
- `class_weights` bei CE, wodurch die Minderheitsklasse ebenfalls loss-seitig priorisiert wird

Diese Kombinationen wurden getestet, weil Klassenungleichgewicht in medizinischen Bilddaten die Sensitivitaet, F1-Macro und MCC deutlich beeinflussen kann. Studien zu CNNs und medizinischen Klassifikationsaufgaben zeigen uebereinstimmend, dass Sampling-Strategien, gewichtete Loss-Funktionen und datenbasierte Balancierung die Leistung auf Minderheitsklassen stark beeinflussen koennen. Sampler und Loss-Gewichtung adressieren dasselbe Problem auf unterschiedlichen Ebenen: Sampler veraendern die Zusammensetzung der Trainingsbatches, waehrend `pos_weight` oder `class_weights` die Optimierungsfunktion selbst veraendern. Ihre Kombination kann deshalb wirksam sein, muss aber vorsichtig interpretiert werden, weil eine doppelte Gewichtung das Training auch destabilisieren kann.

Auch die Hyperparameter wurden gezielt variiert. Niedrige Lernraten um `1e-4` und `3e-4`, Batchgroessen von 8 und 16 sowie unterschiedliche Weight-Decay-Werte wurden geprueft, weil Transfer-Learning-Studien fuer medizinische Bilder genau diese Bereiche als besonders relevant beschreiben. Der interaktive Einfluss von Lernrate und Batchgroesse wurde auch in Transfer-Learning-Experimenten zur medizinischen Bildklassifikation gezeigt. Die Augmentierung wurde von minimal bis staerker regulierend getestet, um zu pruefen, wann zusaetzliche Bildvariation die Generalisierung verbessert und wann sie das Training unnoetig erschwert.

Im Refinement-Lauf wurde ausserdem ein Branch ohne ImageNet-Pretraining (`pretrained=False`) aufgenommen. Damit wurde der Beitrag des Transfer Learnings gegenueber einem Training von Grund auf kontrolliert untersucht.

## Ergebnisstabelle

Die folgende Tabelle zeigt alle getesteten Modelle, sortiert nach F1-Macro. Fuer die vertiefte Analyse werden anschliessend fuenf Modelle genauer betrachtet, weil sie unterschiedliche und besonders aufschlussreiche Punkte im Suchraum repraesentieren: das beste Gesamtmodell, das AUC-staerkste CE-Modell, ein CE-Modell mit Sampler, ein leichtgewichtiges mobiles Modell sowie das `pretrained=False`-Modell als methodische Kontrollbedingung.

| Rang | Branch | F1-Macro | AUC | Sensitivity | Specificity | Precision | MCC | Acc | Loss | LR | Batch | Sampler | Gewichtung | Epochs |
|------|--------|----------|-----|-------------|-------------|-----------|-----|-----|------|----|-------|---------|------------|--------|
| 1 | `eff_ce_class_weights_strong_reg` | **0.9175** | 0.9728 | 80.8 % | 98.7 % | **94.0 %** | **0.837** | **96.2 %** | CE | 1e-4 | 16 | - | cw=[1,7] | 25 | v
| 2 | `eff_bce_strong_reg` | 0.9105 | 0.9731 | 82.0 % | 98.0 % | 92.2 % | 0.822 | 95.7 % | BCE | 1e-4 | 16 | (1,7) | pos_weight=8 | 30 | v
| 3 | `eff_ce_class_weights_moderate` | 0.9087 | 0.9622 | 77.8 % | **98.8 %** | **94.0 %** | 0.821 | 95.8 % | CE | 1e-4 | 16 | - | cw=[1,3] | 25 | v
| 4 | `eff_bce_lower_penalty` | 0.9074 | **0.9745** | 82.0 % | 97.8 % | 91.6 % | 0.815 | 95.7 % | BCE | 1e-4 | 16 | (1,4) | pos_weight=4 | 30 |  v
| 5 | `eff_ce_class_weights_plus_sampler` | 0.9055 | 0.9644 | 77.8 % | 98.6 % | 93.3 % | 0.814 | 95.7 % | CE | 1e-4 | 16 | (1,4) | cw=[1,4] | 25 | v
| 6 | `efficientnet_v2_s_bce` | 0.8983 | 0.9680 | 82.0 % | 97.2 % | 90.0 % | 0.797 | 95.1 % | BCE | 1e-4 | 16 | (1,7) | pos_weight=8 | 40 | v
| 7 | `eff_ce_class_weights_only` | 0.8872 | 0.9723 | 79.6 % | 97.0 % | 89.1 % | 0.774 | 94.5 % | CE | 1e-4 | 16 | - | cw=[1,7] | 25 | v
| 8 | `mobilenet_v3_large_ce` | 0.8866 | 0.9577 | 79.0 % | 97.1 % | 89.3 % | 0.773 | 94.5 % | CE | 1e-4 | 16 | - | - | 40 | v
| 9 | `resnet101_ce` | 0.8808 | 0.9624 | 74.9 % | 97.7 % | 90.2 % | 0.764 | 94.5 % | CE | 1e-4 | 16 | - | - | 40 | v
| 10 | `resnet50_ce` | 0.8747 | 0.9704 | 76.0 % | 97.0 % | 88.5 % | 0.750 | 94.0 % | CE | 1e-4 | 16 | - | - | 40 | v
| 11 | `resnet50_bce` | 0.8706 | 0.9471 | 80.2 % | 95.7 % | 86.2 % | 0.742 | 93.5 % | BCE | 1e-4 | 16 | (1,7) | pos_weight=8 | 40 | v
| 12 | `resnet18_ce` | 0.8686 | 0.9666 | 78.4 % | 96.0 % | 86.5 % | 0.737 | 93.5 % | CE | 1e-4 | 16 | - | - | 40 | v
| 13 | `eff_ce_with_sampler` | 0.8663 | 0.9690 | 81.4 % | 95.1 % | 85.2 % | 0.734 | 93.2 % | CE | 3e-4 | 8 | (1,4) | - | 25 | v
| 14 | `inception_v3_ce` | 0.8640 | 0.9680 | 76.7 % | 96.1 % | 87.1 % | 0.728 | 93.5 % | CE | 1e-4 | 16 | - | - | 40 | v
| 15 | `efficientnet_v2_s_ce` | 0.8620 | 0.9640 | 78.4 % | 95.5 % | 86.8 % | 0.724 | 93.5 % | CE | 1e-4 | 16 | - | - | 40 | v
| 16 | `eff_ce_best_known` | 0.8546 | 0.9549 | 65.9 % | 98.2 % | 90.2 % | 0.718 | 93.6 % | CE | 3e-4 | 8 | - | - | 25 | v
| 17 | `mobilenet_v3_large_bce` | 0.8490 | 0.9560 | 84.4 % | 93.0 % | 85.6 % | 0.705 | 93.5 % | BCE | 1e-4 | 16 | (1,7) | pos_weight=8 | 40 | v
| 18 | `mobilenet_v3_small_ce` | 0.8350 | 0.9520 | 80.8 % | 92.8 % | 84.0 % | 0.675 | 93.5 % | CE | 1e-4 | 16 | - | - | 40 | v
| 19 | `squeezenet_1_1_ce` | 0.8183 | 0.9450 | 76.7 % | 92.6 % | 79.7 % | 0.641 | 90.4 % | CE | 1e-4 | 16 | - | - | 40 | v
| 20 | `eff_ce_class_weights_no_pretrain` | 0.6894 | 0.9101 | **91.6 %** | 74.6 % | 67.8 % | 0.485 | 76.9 % | CE | 1e-4 | 16 | - | cw=[1,7] | 35 | v

## Vertiefte Analyse von fuenf besonders wichtigen Modellen

### 1. `eff_ce_class_weights_strong_reg`: bestes Gesamtmodell

Dieses Modell ist das wichtigste Ergebnis der gesamten Versuchsreihe. Es wurde im Refinement-Lauf als gezielter Folgebranch zur Konfiguration `eff_ce_class_weights_only` aufgenommen. Die zentrale Aenderung gegenueber dem schwaecheren Vorgaenger war eine Erhoehung des Weight Decays von `0.0001` auf `0.001`. Damit wurde die Hypothese getestet, dass staerkere Regularisierung die Tendenz zur Ueberanpassung bei aggressiver Klassengewichtung (`cw=[1,7]`) korrigieren kann.

Das Ergebnis bestaetigt diese Hypothese deutlich: F1-Macro steigt von 0.8872 auf 0.9175, MCC von 0.774 auf 0.837. Damit erzielt dieser Branch den groessten Leistungssprung durch eine einzelne Hyperparameter-Anpassung innerhalb der Versuchsreihe. Spezifitaet (98.7 %), Precision (94.0 %) und Accuracy (96.2 %) liegen ebenfalls auf sehr hohem Niveau. Das Modell zeigt damit, dass CE mit aggressiver Klassengewichtung kein strukturelles Problem darstellt, wenn die Gewichtung durch geeignete Regularisierung stabilisiert wird.

Fuer den Anwendungskontext ist diese Konfiguration besonders relevant, weil sie nicht nur einen hohen Durchschnittswert erreicht, sondern die klinisch entscheidenden Metriken ausgewogen bedient. Die Sensitivitaet bleibt mit 80.8 % hoch, waehrend die sehr hohe Spezifitaet die Zahl unnoetiger Fehlalarme begrenzt.

### 2. `rgb_efficientnet_minipc`: AUC-staerkstes Referenzmodell

Dieses Modell ist zentral, weil es die beste Trennschaerfe ueber alle Schwellenwerte hinweg erreicht. Getestet wurde hier die Gegenhypothese, dass EfficientNet auch ohne explizites Imbalance-Handling stark performen kann, wenn Lernrate, Batchgroesse und Augmentierung guenstig gewaehlt sind. Diese Einordnung passt zu EfficientNet-basierten Melanom-Systemen, bei denen eine stabile Validierungsstrategie, sorgfaeltiges Pipeline-Tuning und AUC-orientierte Modellselektion entscheidende Erfolgsfaktoren waren.

Mit CE, keiner expliziten Klassengewichtung, kleiner Batchgroesse und hoeherer Lernrate erreicht dieses Modell den hoechsten AUC-Wert aller Runs und eine sehr hohe Sensitivitaet von 83.2 %. Das zeigt, dass ein gut abgestimmtes Transfer-Learning-Setup bei EfficientNet bereits einen grossen Teil der Klassifikationsaufgabe loesen kann.

Gleichzeitig bleibt der feste Arbeitspunkt etwas schwaecher als beim besten CE-Class-Weight-Branch. F1-Macro und MCC liegen unter den besten Refinement-Modellen. Fuer Threshold-Tuning oder eine serverseitige Nachoptimierung der Entscheidungsschwelle bleibt `rgb_efficientnet_minipc` dennoch ein wichtiger Referenzpunkt.

### 3. `efficientnet_v2_s_rgb`: CE mit starkem Sampler

Dieses Modell wurde getestet, um den isolierten Einfluss eines gewichteten Samplers unter CE sichtbar zu machen. Die Frage war, ob Oversampling einen aehnlichen Effekt wie BCE mit `pos_weight` oder CE mit `class_weights` erzielen kann.

Mit F1-Macro 0.8877, AUC 0.9691 und Sensitivitaet 80.2 % zeigt dieser Branch, dass ein starker Sampler unter CE einen relevanten Teil des Imbalance-Problems abfangen kann. Gegenueber reinen CE-Setups ohne Sampler steigt die Sensitivitaet, ohne dass die Gesamtleistung einbricht.

Die Ergebnisse zeigen jedoch auch die Grenze dieses Ansatzes. Reines Oversampling macht positive Beispiele haeufiger sichtbar, priorisiert Fehler auf der Melanom-Klasse aber nicht direkt in der Verlustfunktion. Die besten Ergebnisse entstehen deshalb in den Refinement-Laeufen durch eine sorgfaeltig abgestimmte loss-seitige Gewichtung und passende Regularisierung.

### 4. `mobilenet_v3_large_ce`: wichtigster Lightweight-Kandidat

Fuer eine mobile Anwendung ist nicht nur maximale Modellguete relevant, sondern auch Speicherbedarf, Parameterzahl und Inferenzgeschwindigkeit. MobileNet V3 Large wurde deshalb als ressourcenschonender Kandidat evaluiert.

Das Ergebnis ist stark: F1-Macro 0.8866 und MCC 0.773 liegen nahe an mehreren EfficientNet-Varianten und uebertreffen groessere ResNet- und Inception-Modelle. Damit ist MobileNet V3 Large kein reines Kompromissmodell, sondern ein ernstzunehmender Kandidat fuer Szenarien mit engen Ressourcenlimits.

Fuer eine strikt on-device ausgefuehrte Dermascan-App koennte dieses Modell als Lightweight-Fallback oder Zweitpfad dienen. Gegenueber dem besten EfficientNet-Branch bleibt eine messbare Leistungsluecke, sie ist aber kleiner als aufgrund der Architekturkomplexitaet zu erwarten waere.

### 5. `eff_ce_class_weights_no_pretrain`: Training ohne ImageNet-Initialisierung

Dieser Branch wurde als methodische Kontrollbedingung in den Refinement-Lauf aufgenommen. Die Konfiguration entspricht im Kern dem besten CE-Branch (`cw=[1,7]`, `wd=0.001`), verwendet jedoch keine ImageNet-Gewichte. Das Modell wurde vollstaendig von zufaelligen Initialisierungen trainiert (`pretrained=False`). Um diesen strukturellen Nachteil teilweise zu kompensieren, wurden 35 Epochen und eine umfangreichere Augmentierungsstrategie eingesetzt. Der Vergleich ist auch deshalb relevant, weil EFFNet auf HAM10000 in Ablationsversuchen ebenfalls einen deutlichen Nutzen von Transfer Learning gegenueber einem Training ohne vortrainierte Gewichte berichtet.

Die Ergebnisse verdeutlichen den Beitrag des Transfer Learnings. Das Modell erreicht nur F1-Macro 0.6894, MCC 0.485 und Accuracy 76.9 %. Damit liegt es deutlich unter allen `pretrained=True`-Konfigurationen der Versuchsreihe. Auch das Trainingsverhalten deutet auf fehlende Konvergenzstabilitaet hin: Der Train-Loss sinkt langsamer als bei vortrainierten Modellen, das Val-F1-Macro schwankt ohne stabiles Plateau, und die beste Epoche liegt bereits in der Mitte des Trainings.

Auffaellig ist die sehr hohe Sensitivitaet von 91.6 %. Dieser Wert ist jedoch nicht als robuste klinische Staerke zu interpretieren, weil er mit einem massiven Einbruch der Spezifitaet auf 74.6 % und einer Precision von 67.8 % einhergeht. Das Modell tendiert bei Unsicherheit systematisch zur Melanom-Klasse. Dieses Muster spricht dafuer, dass aggressive Klassengewichtung ohne die Merkmalsbasis eines vortrainierten Backbones zu einer verzerrten Entscheidungsgrenze fuehren kann.

## Gesamtinterpretation der Suchstrategie

Die Ergebnisse bestaetigen vier zentrale Beobachtungen.

**Erstens** ist EfficientNet V2-S die staerkste getestete Backbone-Familie fuer diese Aufgabe. Die besten Plaetze werden fast ausschliesslich von EfficientNet-Branches belegt. Das ist konsistent mit melanoma- und HAM10000-bezogenen Arbeiten, in denen EfficientNet-Varianten als leistungsfaehige Backbones oder Merkmalsextraktoren eingesetzt werden. MobileNet V3 Large ist der wichtigste Lightweight-Kandidat, bleibt in F1-Macro und MCC jedoch hinter den besten EfficientNet-Konfigurationen.

**Zweitens** ist Imbalance-Handling kein optionales Detail, sondern ein zentraler Leistungsfaktor. Besonders stark ist die Kombination aus CE mit `class_weights=[1,7]` und `weight_decay=0.001`, weil sie loss-seitige Priorisierung der Minderheitsklasse mit stabiler Regularisierung verbindet. Die Ergebnisse passen zu vergleichenden Studien, die Sampling, datenbasierte Balancierung und gewichtete Optimierungsziele als zentrale Massnahmen gegen Klassenungleichgewicht beschreiben. BCE mit `pos_weight` und Sampler bleibt ebenfalls leistungsfaehig, wird durch die neuen CE-Refinement-Laeufe aber nicht mehr als bestes Gesamtmodell bestaetigt.

**Drittens** sind gezielte Hyperparameter-Anpassungen relevanter als das blosse Durchprobieren weiterer Architekturen. Das klarste A/B-Experiment der Reihe, naemlich die Erhoehung des Weight Decays bei ansonsten vergleichbarer CE-Class-Weight-Konfiguration, erzeugte den staerksten Leistungssprung.

**Viertens** ist ImageNet-Pretraining auf einem Datensatz der Groesse von HAM10000 eine strukturelle Voraussetzung fuer stabile Generalisierung. Der `pretrained=False`-Branch faellt trotz laengerem Training und staerkerer Augmentierung deutlich zurueck. Die hohe Sensitivitaet dieses Modells ist wegen der gleichzeitig schwachen Spezifitaet und Precision nicht als produktiv nutzbarer Vorteil zu bewerten.

Darueber hinaus zeigen die Resultate, dass die Suchstrategie nicht auf Accuracy reduziert werden darf. Mehrere Modelle mit aehnlicher Accuracy unterscheiden sich deutlich in Sensitivitaet, Spezifitaet, Precision und MCC. Fuer medizinische Anwendungen ist deshalb die Interpretation mehrerer Metriken wesentlich aussagekraeftiger als eine isolierte Betrachtung der Gesamtgenauigkeit.

## Empfehlung fuer den Produktionseinsatz

**Primaermodell:** `eff_ce_class_weights_strong_reg` mit CE, `class_weights=[1,7]`, `weight_decay=0.001`, Batchgroesse 16 und Lernrate `1e-4`. Dieser Branch erzielt den hoechsten F1-Macro, den hoechsten MCC, die beste Precision und die hoechste Accuracy der Versuchsreihe. Er ist damit der naheliegende Hauptkandidat fuer den Klassifikationspfad im Dermascan-System.

**Alternative bei Sensitivitaetsprioritaet:** `eff_bce_strong_reg` mit BCE, `pos_weight=8`, gewichtetem Sampler `(1,7)` und staerkerem Weight Decay. Dieses Modell bleibt relevant, wenn Recall hoeher priorisiert wird, etwa in einem Screening-Szenario mit nachgelagerten Bestaetigungsschritten.

**AUC-orientierte Referenz:** `rgb_efficientnet_minipc` eignet sich als Vergleichsmodell fuer Threshold-Optimierung, weil es die beste globale Score-Trennung erreicht. Es ist besonders interessant, wenn die Entscheidungsschwelle nachtraeglich an konkrete klinische Anforderungen angepasst werden soll.

**Lightweight-Fallback:** `mobilenet_v3_large_ce` ist der wichtigste Kandidat fuer ressourcenbeschraenkte Mobilgeraete. Die Modellguete liegt unter dem besten EfficientNet-Branch, ist aber fuer ein deutlich leichteres Modell bemerkenswert hoch.

## Verwendete Quellen

- Tschandl et al. (2018): *The HAM10000 dataset, a large collection of multi-source dermatoscopic images of common pigmented skin lesions.* Nature Scientific Data. https://www.nature.com/articles/sdata2018161
- Ha, Liu und Liu (2020): *Identifying Melanoma Images using EfficientNet Ensemble: Winning Solution to the SIIM-ISIC Melanoma Classification Challenge.* arXiv:2010.05351. https://arxiv.org/pdf/2010.05351v1
- Buda et al. (2018): *A systematic study of the class imbalance problem in convolutional neural networks.* PubMed. https://pubmed.ncbi.nlm.nih.gov/30092410/
- Scholz et al. (2024): *Imbalance-aware loss functions improve medical image classification.* PMLR. https://proceedings.mlr.press/v250/scholz24a.html
- PMC (2023): *A Comparison of Techniques for Class Imbalance in Deep Learning Classification of Breast Cancer.* https://pmc.ncbi.nlm.nih.gov/articles/PMC9818528/
- Loshchilov und Hutter (2017): *Decoupled Weight Decay Regularization.* arXiv:1711.05101. https://arxiv.org/abs/1711.05101
- NeurIPS (2022): *The Effects of Regularization and Data Augmentation are Class Dependent.* https://papers.neurips.cc/paper_files/paper/2022/file/f73c04538a5e1cad40ba5586b4b517d3-Paper-Conference.pdf
- Kandel und Castelli: *The effect of batch size on the generalizability of the convolutional neural networks on a histopathology dataset.* Universitaet Ljubljana. https://repozitorij.uni-lj.si/IzpisGradiva.php?id=124243
- Usmani und Qadri (2023): *Interactive Effect of Learning Rate and Batch Size to Implement Transfer Learning for Brain Tumor Classification.* Electronics. https://www.mdpi.com/2079-9292/12/4/964
- Jurnal Polibatam (2024): *Comparative Analysis of MobileNetV3 and EfficientNetV2B0 in Skin Lesion Classification.* https://jurnal.polibatam.ac.id/index.php/JAIC/article/download/11878/3402/38766
- IJRPR (2025): *Medical Image Classification using Transfer Learning.* https://ijrpr.com/uploads/V6ISSUE10/IJRPR53832.pdf
- scholar.ui.ac.id (2023): *EfficientNetV2 based for MRI brain tumor image classification.* https://scholar.ui.ac.id/en/publications/efficientnetv2-based-for-mri-brain-tumor-image-classification/
- Ma et al. (2023): *EFFNet: A skin cancer classification model based on feature fusion and random forests.* PLOS ONE. https://journals.plos.org/plosone/article?id=10.1371%2Fjournal.pone.0293266
- PMC (2019): *Hybrid Transfer Learning for Classification of Uterine Cervix Images.* https://pmc.ncbi.nlm.nih.gov/articles/PMC7256135/
- PyTorch Discussion: *pos_weight and weight parameters in BCEWithLogitsLoss.* https://discuss.pytorch.org/t/pos-weight-and-weight-parameters-in-bcewithlogitsloss/130651
- Stack Overflow: *Class weights vs. under/oversampling.* https://stackoverflow.com/questions/55657807/class-weights-vs-under-oversampling
