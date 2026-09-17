Der UploadClient (Version 1.5)


Dieser UploadClient ermöglicht die übertragung des Openq-Katalogs (http- und https-Protokoll) zur Kursnet-Anwendung.
Der UploadClient kommuniziert hierbei mit dem WebService der Anwendung "KURSNET - Bildung einfach anbieten".


Inhaltsverzeichnis 
1. Inhalt des Zip-Archivs:
2. Die Parameter von uploadclient.conf
3. Starten des Clients


1. Inhalt des Zip-Archivs:

Libraries:
Die libraries im Unterverzeichnis lib sind für die Nutzung des Uploadclients notwendig.

lib/de und lib/openq: 
Beinhaltet den UploadClient und die Stubs.

etc/uploadclient.conf: 
Ist die Konfigurationsdatei für den UploadClient.

etc/uploadclient.keystore: 
Dieser Keystore beinhaltet das Zertifikat von TC TrustCenter (http://www.trustcenter.de), bei dem das SSL-Zertificat der Kursnet-Anwendung Zertifiziert wurde.

bin/uploadclient_start.sh und bin/uploadclient_start.bat: 
Sind Beispiele für eine mögliche Benutzung des UploadClients.

openq.wsdl:
Diese Web Service Description Language Datei (WSDL) definiert eine plattform-, programmiersprachen-
und protokollunabhängige XML-Spezifikation zur Beschreibung des Netzwerkdienstes (hier Web Services für den OpenQ-Katalog-Austausch).


2. Die Parameter von uploadclient.conf

<benutzer> und <passwort> 
Sind die Anmeldeinformationen des Ansprechpartners bei "KURSNET - Bildung einfach anbieten".

Folgende Parameter sind wichtig, wenn Ihr Computer sich in einem Netzwerk befindet und der Zugriff auf das www über einen Proxy-Server stattfindet.
In diesem Fall können die Proxy-informationen für http und https hier konfiguriert werden.
<http.proxyHost>, <http.proxyPort>
<https.proxyHost>, <https.proxyPort>

<katalog>
Gibt die Position des zu übertragenden Katalogs an. Hierbei muss der gesamte Pfad mit dem Dateinamen angegeben werden:
Unter Unix:
katalog=/home/user/hban/my_katalog.xml
Unter Windows:
katalog=c:\\kataloge\\hban\\my_katalog.xml

<action>
Diese Option ist für den Upload vorgesehen.
Mögliche Werte sind 1 und 2.
1 = Ihr Katalog wird auf Validität, Plausibilität und vollständigkeit überprüft, um die möglichen Fehler bei weiterer Verarbeitung in Kursnet auszuschließen.
Die Rückmeldung der Überprüfung des Katalogs wird an den Client zurückgeliefert.
2 = Hierbei wird der Katalog gleichen Prüfungskriterien wie bei 1 unterzogen. War die Überprüfung erfolgreich verlaufen, so wird der Katalog für die weitere Verarbeitung bei Kursnet abgespeichert. War die Überprüfung hingegen nicht positiv, erfolgt eine Rückmeldung zum UploadClient (wie bei 1).
 
<aufgabe>
Mit dieser Option kann festgelegt werden, ob der Katalog an die Kursnet-Anwendung übermittelt oder von der Kursnet-Anwendung abgeholt werden soll. Mit dem Wert 'test' wird lediglich eine Verbindung zum Kursnet-Webservice aufgebaut.
Mögliche Werte sind: "test", "upload" oder "download".
Bei "upload" wird der Katalog unter Verwendung der Optionen <katalog> und <action> zur Kursnet-Anwendung übertragen.
Bei "download"  wird der katalog in der Kursnet-Anwendung erstellt und an den UploadClient übertragen. Hierbei muss die Option <speichernunter_zip> definiert sein.
Bei "test" wird versucht den Webservice für Testzwecke zu kontaktieren.

<speichernunter_zip>
Hier kann definiert werden, in welchem Verzeichnis und unter welchem Dateinamen der heruntergeladene Katalog abgespeichert werden soll. Die Übertragung des Katalogs findet hierbei im Zip-Format statt.
Beachten Sie, dass das angegebene Verzeichnis existieren muss.
In dem Zip-Archiv wird der Dateiname nach folgendem Muster erstellt:
openq_{ban_id}_{Monat}_{Tag}-{Stunden}_{Minuten}_{Sekunden}.xml


3. Starten des Clients

a) Das Archiv auspacken (z.B. c:\...\uploadclient
b) uploadclient_start.bat oder uploadclient_start.sh anpassen:
in uploadclient_start.bat  muss die Umgebungsvariable 'DIR' und 
in uploadclient_start.sh  muss die Umgebungsvariable DIRUPLOAD zugewiesen werden 
set DIR=c:\...\uploadclient
DIRUPLOAD=/home1/.../uploadclient
Hierbei muss immer der Pfad angegeben werden, in den das ZIP-Archiv entpackt wurde.

c) Konfigurieren der Anwendung
Siehe dazu 2.