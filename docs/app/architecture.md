# App-Architektur

Die technische Architektur der Anwendung wurde mit Fokus auf Wartbarkeit, Testbarkeit und Ressourceneffizienz entworfen. Als primäres Architekturmuster kommt **MVVM (Model-View-ViewModel)** zum Einsatz. Das gesamte Projekt ist strikt nach dem Clean-Architecture-Gedanken aufgebaut und nutzt das **GetX**-Framework für das Zustandsmanagement, die Dependency Injection und das Routing.


## Modulare Struktur und Feature-Aufteilung

Der Quellcode ist auf oberster Ebene konsequent in die Domänen der beiden Benutzerrollen unterteilt, um eine unabsichtliche Daten- oder Logikverarbeitung zu verhindern. Innerhalb dieser Domänen ist die App in eigenständige, in sich geschlossene Feature-Module zerlegt:

```
lib/
├── feature/
│   ├── auth/              # Anmeldung & Registrierung (Praxis & Arzt)
│   ├── doctor/            # Arzt-Domäne
│   │   ├── home/    # Zentrale Übersicht des Arztes
│   │   ├── patients/     # CRUD-Operationen für Patienten
│   │   └── profile/        # Persönliche Einstellungen des Arztes
│   ├── praxis/            # Praxis-Domäne
│   │   ├── home/   # Arztverwaltung (Hinzufügen, Entfernen, Freigeben)
│   │   └── profile/        # Stammdaten der medizinischen Einrichtung
│   └── splash/            # App-Startup und Routing-Distribution

```

## MVVM-Implementierung mit GetX

Jedes dieser Features ist intern strikt nach dem MVVM-Muster in drei Komponenten gegliedert:

* **View (UI):** Reine deklarative Widgets, die ausschließlich für das Layout zuständig sind. Sie enthalten keinerlei Business- oder Navigationslogik.
* **Controller (ViewModel):** Verwaltet den Zustand des jeweiligen Screens und kapselt die Interaktionslogik.
* **Binding:** Regelt die Dependency Injection. Es definiert präzise, welche Controller beim Aufruf eines Features instanziiert und im Speicher bereitgestellt werden müssen.

### Speicher- und Lifecycle-Management

Durch das Routing-System von GetX wird ein hocheffizientes Speichermanagement realisiert. Wenn der Benutzer eine Route (einen Screen) aufruft, sorgt das dazugehörige `Binding` dafür, dass die benötigten Controller bereitgestellt werden. Sobald der Benutzer den Screen wieder verlässt (z. B. durch Zurück-Navigation), schließt GetX diese Controller automatisch (`dispose`) und gibt den beanspruchten RAM-Speicher umgehend frei.

Auf den Einsatz von rechenintensiven `StatefulWidgets` konnte dank des reaktiven Ansatzes vollständig verzichtet werden. Alle dynamischen UI-Elemente sind in `Obx(())`-Widgets gekapselt. Ändert sich eine reaktive Variable (`Rx`) im Controller, registriert GetX dies automatisch und zeichnet ausschließlich das betroffene Widget neu – ohne manuellen Aufruf von `setState`.

## 3.3 Globale Services (Kern-Infrastruktur)

Zusätzlich zu den flüchtigen Feature-Controllern existieren zwei langlebige Instanzen, die als `GetxService` direkt beim App-Start initialisiert werden und über den gesamten Lebenszyklus hinweg aktiv bleiben. Sie dienen als Abstraktionsschicht für die Datenquellen:

### `AuthService` (`auth_service.dart`)

Verantwortlich für die gesamte Authentifizierung und Sitzungsverwaltung (Login, Logout, Registrierung). Er hält das aktuelle Benutzerobjekt (Arzt oder Praxis) global im Speicher bereit, sodass jeder Feature-Controller direkt den Kontext des agierenden Nutzers abfragen kann.

### `DatabaseService` (`db_service.dart`)

Der zentrale Einstiegspunkt für alle Datenoperationen. Die App nutzt **Supabase** als Backend. Um eine lose Kopplung (Loose Coupling) zu garantieren, rufen die Controller niemals direkte Datenbankabfragen auf. Sie kommunizieren ausschließlich mit dem `DatabaseService`. Dieser triggert im Hintergrund optimierte **Supabase Edge Functions** (serverseitige Funktionen). Der Service nimmt die Rohdaten der Edge Functions entgegen, transformiert und parst diese in die stark typisierten Datenmodelle der App (Dart-Objekte) und gibt diese an die Controller zurück. Bei einer eventuellen Migration des Datenbbackend muss somit nur dieser Service angepasst werden.

## 3.4 Der Splash-Screen und dynamisches Routing

Der `SplashScreen` fungiert als intelligenter Gatekeeper beim App-Start. Visuell zeigt er lediglich einen Ladeindikator. Im Hintergrund prüft er über den `AuthService` den aktuellen Sitzungsstatus sowie den Kontotyp des authentifizierten Benutzers. Basierend auf dieser Auswertung wird der Benutzer vollautomatisch auf die korrekte Zielroute geleitet (z. B. direkt zum `DoctorHomeScreen` oder, falls nicht eingeloggt, zur Login-Maske des `Auth`-Features).

## 3.5 Integration des Machine Learning Modells (ONNX Runtime)

Die Ausführung des KI-Klassifikators erfolgt vollständig gerätelokal (On-Device AI), um Latenzen zu minimieren und Datenschutz zu verbessern.

```
+-----------------------------------------------------------------------+
| [DIAGRAMM: Datenfluss - Bildaufnahme -> ONNX-Inferenz -> UI-Anzeige]  |
+-----------------------------------------------------------------------+
```

Hierzu ist das trainierte Machine-Learning-Modell als Datei in den assets der Anwendung hinterlegt. Für die Ausführung wird das onnxruntime-Package genutzt, welches eine native C++ Laufzeitumgebung via Dart-FFI anspricht.

Sobald ein Bild aufgenommen und der Cutout bestätigt wurde, wird die Bildmatrix in ein Float32-Tensor-Format transformiert und an das ONNX-Modell übergeben. Die native Laufzeitumgebung berechnet Klassifizierung ggf. unter Verwendung einer gerätespezifischen Hardwarebeschleunigung.

Die gesamte Berechnung wird in einer Wrapper-Klasse namens `LesionAnalysis` gekapselt. Diese Klasse bündelt die gesamte logische Analyseeinheit, um eine saubere Datenübergabe zu gewährleisten. Das Ergebnis dieses Objekts wird über das reaktive GetX-System unmittelbar in der UI zur Anzeige gebracht, sodass der Dermatologe die Auswertung sofort einsehen kann. Parallel dazu werden die Ergbnisse der Analyse mittels des `DatabaseService` persistent in der Datenbank gespeichert.

## Siehe auch:
- [App-Entwicklung](./README.md)
- [App-Features](./features.md)
- [Datenbank Dokumentation](../db/README.md)
