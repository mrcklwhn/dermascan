# Eigene Klassifikations Architektur
Ein Arzt beurteilt Hautläsionen anhand verschiedener aber konkreter Merkmale wie Farbe, Struktur, Asymmetrie etc.
Da neuronale Modelle oft als "Blackbox" wahrgenommen werden und die Nachvollziehbarkeit der Entscheidungen erschwert ist, soll hier ein Ansatz verfolgt werden, der die Entscheidungsfindung des Arztes nachahmt. Insofern soll die Architektur mehrere spezialisierte "Experten"-Netzwerke enthalten, die jeweils auf bestimmte Merkmale der Läsion trainiert werden. Die Ergebnisse dieser Experten-Netzwerke werden dann kombiniert, um eine finale Klassifikation zu erstellen.

## Ansatz 1: Fusion
Aufbau eines **Dualbranch-CNN**, welches die Enschätzung zweier gemeinsam trainierter CNNs per `Fusions-Layer` kombiniert.
  - Zwei CNNs erzeugen gleich große Feature-Vektoren.
  - Fusion der Vektoren; Klassifikation via Dense NN, SVM, Decision Tree.
  - Ausgabe: Wahrscheinlichkeiten für Melanom/Leberfleck.

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

## Ansatz 2: Soft Voting
Aufbau eines **Dualbranch-CNN**, welches die Enschätzung zweier **getrennt** trainierter CNNs nach Soft Voting kombiniert.
  - Zwei CNNs erzeugen getrennte Feature-Vektoren
  - Jeweils Klassifikation via Dense NN, SVM, Decision Tree
  - Soft-Voting der beiden Wahrscheinlichkeiten für das Endergebnis

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

