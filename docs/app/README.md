# App-Entwicklung

## Zielsetzung und Kontext

Die vorliegende Dokumentation beschreibt die Konzeption und Implementierung einer mobilen Flutter-Anwendung zur dermatologischen Hautläsionsverwaltung. Das Projekt entstand in enger Zusammenarbeit mit einer Dermatologin. Ziel war es, die realen Anforderungen, klinischen Arbeitsabläufe und Dokumentationspflichten einer dermatologischen Praxis präzise zu erfassen und in eine benutzerzentrierte Softwarelösung zu überführen.

Die Anwendung unterstützt Dermatologen gezielt bei der langfristigen Dokumentation, der strukturierten Verlaufskontrolle sowie der Diagnose von Hautläsionen. Ein Kernaspekt ist die nahtlose Integration eines Machine-Learning-basierten [Klassifikators](../ml/README.md) zur automatisierten Hautkrebsanalyse. Durch die lokale Ausführung des Modells entfällt die Notwendigkeit für teure Zusatzhardware. Die App führt Patientenverwaltung, Bilddokumentation, KI-gestützte Analyse und automatisierte Berichterstellung (PDF) in einem System zusammen.

## Konten- und Rollenmodell

Um den organisatorischen Strukturen im medizinischen Alltag gerecht zu werden, trennt die Anwendung strikt zwischen zwei Benutzerrollen:

* **Praxis-Account:** Repräsentiert die übergeordnete medizinische Einrichtung (z. B. eine Gemeinschaftspraxis oder Klinik). Diese Rolle übernimmt die administrative Verwaltung und autorisiert die zugehörigen Ärztinnen und Ärzte.
* **Arzt-Account:** Wird von den behandelnden Dermatologen genutzt. Dieser Account berechtigt zur Patientenverwaltung, zur Durchführung von Untersuchungen, zur Erstellung von Diagnosen und zur Einsicht in die Historie.

### Registrierungs- und Verifikationsprozess

Sowohl Praxis- als auch Arzt-Accounts können direkt in der Anwendung registriert werden. Zum Schutz sensibler Patientendaten ist der Registrierungsprozess zweistufig aufgebaut: Nach der Erstellung befindet sich ein neuer Arzt-Account zunächst in einem Wartestatus und besitzt keinerlei Datenzugriff. Erst wenn ein Praxis-Account die Beitrittsanfrage des Arztes explizit bestätigt, wird dieser der Praxis zugeordnet und freigeschaltet.

### Datenzugriff und Datenschutz

Das Berechtigungskonzept folgt strengen Mustern zur Wahrung der ärztlichen Schweigepflicht und des Datenschutzes:

* Alle verifizierten Ärzte einer Praxis teilen sich den Zugriff auf die Patientendaten *dieser spezifischen* Praxis, um Urlaubs- oder Schichtvertretungen zu ermöglichen.
* Ärzte verschiedener Praxen sind vollständig voneinander isoliert; ein organisationsübergreifender Datenzugriff ist technisch ausgeschlossen.
* Ärzte können eine Praxis jederzeit eigenständig verlassen, während der Praxis-Account die Berechtigung besitzt, Ärzte hinzuzufügen oder zu entfernen.

## Siehe auch
- [App-Features](./features.md)
- [App-Architektur](./architecture.md)
- [Datenbank Dokumentation](../db/README.md)
- [ML Dokumentation](../ml/README.md)
- [ABC-Algorithmus Dokumentation](../abc_algorithms/README.md)