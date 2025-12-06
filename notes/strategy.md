## Experimente mit Strukturfiltern (Gabor Wavelet, Local Binary Pattern, GLCM Contrast)

Gabor
- sieht nur nach einfachem Graufilter aus
- eventuell minimale Hervorhebung von Kontrast um Kanten, d.h. die generelle Form von Objekten wird umrandet
- brauch weiteres experimentieren mit anderen Parametern

Local binary
- scheint Kanten insbesondere bei symmetrischen Formen ausfinding zu machen
- bei asymetrischen Lesionen oder solche, die mehr generelle Fläche umspannen sieht Ergebnisbild einfach nur nach White Noise aus
- scheint Textur auch an stellen hervorzuheben, die ein Mensch beim Betrachten des Originalbilds eher weniger beachtet (nur hilfreich, wenn diese tatsächlich relevante Merkmale sind)

GLCM
- sehr anfällig für Haare und Stiftstriche auf der Haut
- hebt Details in Texturen hervor, die sich erheblich von anderen Texturen in derselben Region unterscheiden
- generell nicht geeignet um Kanten zu erkennen

Gesamtergebnisse:
- vielleicht müssen mehrere Filter übereinander gelegt werden um Struktur und Form hervorzuheben
- Nachjustieren von den Parametern interessant
- weitere Filter recherchieren



## Generelle Architektur (high-level):
**Approach 1: Fusion (Feature-Level)**

```mermaid
graph TD
    Input[Input Image 224x224 RGB] --> Preproc[Preprocessing<br/>hair removal, normalization]
    Preproc --> B1[Branch 1: Color path<br/>ResNet50]
    Preproc --> B2[Branch 2: Texture path<br/>ResNet50]
    B1 --> FV1[Feature Vector<br/>e.g., 512-dim]
    B2 --> FV2[Feature Vector<br/>e.g., 512-dim]
    FV1 --> Concat[Concatenate Vectors<br/>1024-dim]
    FV2 --> Concat
    Concat --> Fusion[Fusion Layer<br/>Dense -> 256-dim, optional]
    Fusion --> Head[Classification Head<br/>Dense -> 1 sigmoid output]
```

**Approach 2: Ensemble + Soft Voting**

```mermaid
graph TD
    Input[Input Image 224x224 RGB] --> Preproc[Preprocessing<br/>hair removal, normalization]
    Preproc --> B1[Branch 1: Color path<br/>ResNet50]
    Preproc --> B2[Branch 2: Texture path<br/>ResNet50]
    B1 --> FV1[Feature Vector<br/>512-dim]
    B2 --> FV2[Feature Vector<br/>512-dim]
    FV1 --> P1[Dense/SVM<br/>Probability P1]
    FV2 --> P2[Dense/SVM<br/>Probability P2]
    P1 --> Voting[Soft Voting<br/>weighted average]
    P2 --> Voting
    Voting --> Output[Final Binary Output]
```