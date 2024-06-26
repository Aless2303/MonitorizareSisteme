# MonitorizareSisteme
Utilitar pentru monitorizarea la distanță a mai multor sisteme Linux


## 17.06.2024

-Am ales tema pentru proiect si am citit despre ce implica aceasta tema.

-Utilitarul va colecta date despre resursele de sistem, utilizatori, servicii active și dispozitive hardware, și va oferi posibilitatea de a efectua acțiuni la distanță cum ar fi oprirea/pornirea serviciilor, copierea fișierelor și instalarea aplicațiilor.


## 18.06.2024

-Am studiat despre ce tehnologii as avea nevoie pentru a dezvolta acest utilizat. In principal cred ca va fi nevoie de ssh pentru a conecta mai multe sisteme linux si pentru a le putea administra de la distanta, psutils pentru a putea vedea resursele de sistem de pe fiecare dispozitiv conectat, etc.


## 19.06.2024

-Am studiat despre OpenVPN si wireguard.

-Am incercat sa conectez doua VM-uri care nu erau in aceeasi retea de internet folosind VPN sau wireguard


## 20.06.2024

-Am mai incercat sa configurez un VPN pentru a conecta doua VM-uri din retele diferite.

-Am conectat mai multe masini virtuale din aceeasi retea pentru a putea incepe scriptul de monitorizare remote

-Am observat ca daca folosesc VM-uri nu poti avea acces la temperatura CPU-ului si am incercat sa vad daca se poate rezolva cumva asta.


## 21.06.2024

-Am creat un script care imi ia toti utilizatorii in afara de cel curent din output-ul comenzii "who" iar pentru fiecare utilizator din output-ul respectiv si extrage resursele (RAM,CPU). Inregistreaza valorile intr-un fisier text din folderul fiecarui utilizator conectat, unde va pune Data si ora la care s-a facut monitorizarea + procentele de la RAM Si CPU. 

-Daca procentele sunt prea crescute, mai mult de 80%, rezultate se vor inregistra in fisierul text alerts.txt si va trimite si un mesaj de notificare folosind comanda "notify-send" la utilizatorul la care s-au gasit procentele prea mari. Acest script se va executa la infinit in background, monitorizand constant utilizatorii conectati.


## 25.06.2024

-Am mai actualizat scriptul care monitorizeaza constant sistemele Linux conectate la server. Acum acest script monitorizeaza si serviciile active si dispozitivele hardware. Daca un dispozitiv hardware este conectat sau deconectat de la unul dintre aceste sisteme conectate, se va loga in fisier aceasta modificare. Daca un serviciu se modifica sau apare unul se termina unul, modificarile se vor loga in fisier. 

-Am creat si un meniu pentru actiuni remote asupra sistemelor Linux conectate. In acest meniu vei putea sa pornesti/opresti un serviciu sau un proces, sa instalezi aplicatii sau servicii sau sa copiezi fisiere de pe server pe unul dintre sistemele conectate, sau de pe un sistem conectat la altul. Astazi am realizat oprirea si pornirea de servicii/procese si instalarea de aplicatii si servicii, mai trebuie copierea de fisiere.


## 26.06.2024

-Am mai rezolvat din problemele meniului si am realizat copierea de fisiere/directoare de pe un sistem linux conectat pe altul sau de pe server pe un anumit sistem linux conectat. 











