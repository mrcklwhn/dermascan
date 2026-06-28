# Funcționalitățile Aplicației

Gama de funcționalități a aplicației este adaptată exact la parcursul examinării clinice. Aceasta însoțește medicul de la primul contact, trecând prin analiza vizuală și asistată de IA, până la arhivare.

## Administrarea Medicilor și a Cabinetului

Pentru a documenta un pacient, medicul trebuie mai întâi să își creeze propriul cont de utilizator. Acest cont nu este inițial asociat cu niciun cabinet, astfel încât medicul trebuie să se alăture unui cabinet existent. Alocarea la un cabinet este crucială pentru gestionarea datelor pacienților, deoarece reglementează accesul la date de către alți medici din același cabinet.

![](doctor_login.gif)

În mod similar, un administrator de cabinet trebuie să își creeze propriul cont pentru a înregistra cabinetul. Administratorul poate apoi invita alți medici care să fie alocați cabinetului. Acest lucru asigură că doar medicii autorizați au acces la datele pacienților cabinetului.

![](practice_login.gif)

### Administrarea Medicilor și Capabilitatea Multi-Utilizator

Fiecare medic este alocat exact unui cabinet și deține un cont propriu de utilizator cu o adresă de e-mail unică. Medicii din același cabinet pot vizualiza datele pacienților celorlalți colegi asociați, astfel încât tratamentul în echipă să poată fi documentat și continuat în mod consecvent.

**Contul cabinetului gestionează accesul printr-un modul de invitații**: Invitațiile pentru medicii noi pot fi vizualizate într-o fereastră separată și pot fi retrase în orice moment dacă este necesar, de exemplu în cazul expedierii accidentale. Odată ce un medic acceptă o invitație, el primește acces la datele pacienților cabinetului; acest acces poate fi revocat în orice moment de către administrația cabinetului prin eliminarea medicului din cabinet.

![](doctor_management.gif)

## Administrarea Pacienților și Anamneza

Crearea unui pacient nou reprezintă punctul de plecare al documentării. Parametrii care urmează să fie înregistrați au fost definiți în colaborare cu medicul specialist. Pe lângă datele demografice de bază, aceștia includ în mod specific acei factori de risc care sunt esențiali pentru o diagnosticare și prevenție fundamentată a cancerului de piele:

* **Date de bază:** Prenume, nume, data nașterii, sex biologic.
* **Factori legați de soare și stil de viață:** Utilizarea cremelor de protecție solară, istoricul arsurilor solare, utilizarea solarelor.
* **Istoric medical:** Antecedente personale de melanom, antecedente familiale de cancer de piele, intervenții chirurgicale dermatologice anterioare.
* **Origine:** Țara de naștere și țara actuală de reședință (pentru a estima expunerea cumulativă la UV).

Toate datele pot fi actualizate în timpul examinărilor de urmărire. În prezentarea generală centrală a pacientului, acești factori de risc sunt rezumați compact pentru a oferi imediat medicului contextul pacientului.

![](patient_screen.gif)

> **Notă:** Pentru a șterge un pacient din cabinet, medicul trebuie să deschidă profilul pacientului și să selecteze opțiunea "Delete" (Ștergere). **Nu trebuie să mai existe leziuni asociate pacientului**, deoarece altfel integritatea datelor nu poate fi garantată.

## Profilul Digital al Pacientului & Harta Interactivă 3D a Corpului

Profilul pacientului este mediul central de lucru pentru medic. Pentru a permite o documentare intuitivă, a fost integrată o reprezentare interactivă 3D a corpului. Spre deosebire de sistemele clasice care funcționează cu categorii de text rigide, predefinite (de ex., „spate”), acest model permite plasarea precisă a leziunilor cutanate în spațiul tridimensional.

### Funcțiile hărții 3D a corpului:

* **Interacțiune liberă:** Modelul tridimensional poate fi rotit și mărit continuu pentru a ajunge cu precizie la orice regiune anatomică.
* **Perspectivele camerei:** O resetare rapidă permite revenirea imediată la vizualizarea standard.
* **Plasarea precisă a leziunilor:** Prin atingerea modelului, orice număr de leziuni pot fi marcate exact în poziția anatomică reală.

![](3dmap.gif)

### Prezentare Generală Rapidă și Navigare

Pe lângă harta vizuală, profilul oferă o arhitectură informațională eficientă pentru practica de zi cu zi:

* **Cronologia diagnosticelor:** Acces direct la ultimele cinci diagnostice documentate. Atingerea unei intrări focalizează imediat leziunea corespunzătoare pe modelul 3D.
* **Informații de context:** Vizualizare rapidă a factorilor de risc ai pacientului printr-un simbol de informații, fără a fi necesară părăsirea ecranului curent de examinare.

![](timeline.gif)

## Gestionarea Leziunilor și Diagnosticarea

Atunci când un nou punct este plasat pe harta 3D, se deschide fluxul de lucru pentru gestionarea leziunilor. După atribuirea unui nume unic, este inițiat un nou moment de examinare (un diagnostic).

### Captarea Imaginii și Generarea Decupajului (Cutout)

Medicul poate face fotografia clinică fie direct prin intermediul camerei dispozitivului mobil, fie o poate importa din galerie. Pentru a minimiza factorii perturbatori (cum ar fi zonele de piele sănătoasă sau părul) și pentru a focaliza rețeaua neuronală pe zona relevantă, în etapa următoare dermatologul selectează o secțiune optimizată a imaginii – așa-numitul decupaj al leziunii (Cutout).

### Urmărirea Statutului Medical

Fiecare leziune are un statut dinamic care reflectă evoluția clinică:

* **Suspectă** (sub observație)
* **Eliminată** (excizată chirurgical)
* **Confirmată histologic** (clasificată ca melanom în urma rezultatelor de laborator)

Deoarece o leziune poate conține un număr nelimitat de diagnostice și înregistrări de imagini de-a lungul anilor, modificările morfologice pot fi urmărite fără întreruperi.

![](workflow.gif)

>**Notă:** Pentru a șterge o leziune, medicul trebuie să deschidă profilul leziunii și să selecteze opțiunea "Delete" (Ștergere). **Mai întâi trebuie șterse toate diagnosticele leziunii** înainte ca leziunea în sine să poată fi ștearsă.

## Analiza Asistată de IA și Documentarea Diagnosticului

Pentru fiecare diagnostic nou înregistrat, materialul imagistic este analizat local. Sistemul combină metodele clasice de evaluare dermatologică cu metodele moderne de învățare profundă (Deep Learning):

1. **Scorul clasic ABC:** Calculul automat și prezentarea vizuală a criteriilor *Asimetrie* (A), *Margini* (B - Begrenzung) și *Culoare* (C - Color).
2. **Clasificare neuronală:** Calcularea probabilităților statistice pentru prezența unui *melanom* în comparație cu un *nev melanocitar* benign (aluniță).

În plus, medicul documentează data examinării, colegul curant, precum și note clinice libere. Rezultatele sunt procesate clar pentru medic și servesc drept o a doua opinie obiectivă și reproductibilă (*Decision Support System*).

![](diagnosis.gif)

## Generarea Automată de Rapoarte PDF

Pentru arhivarea în sistemul IT principal al cabinetului sau pentru transmiterea către pacient, a fost implementat un modul de export. Medicul poate controla dedicat, prin intermediul unor casete de selectare, care leziuni și care momente specifice de examinare ar trebui incluse în raport. Documentul PDF generat conține într-o manieră structurată toate datele de bază, factorii de anamneză, documentația vizuală, metricele calculate de IA, precum și comentariile medicului.

![](export.gif)