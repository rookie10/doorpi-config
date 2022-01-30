# doorpi-config
Automatische Installation von Doorpi

## Installation
erst mal git installieren 
```
sudo apt-get -y install git
```
dann das Installations git clonen 
```
sudo git clone https://github.com/rookie10/doorpi-config.git /tmp/doorpicon
```
instalieren
```
sudo /tmp/doorpicon/doorpi-config.sh
```
DoorPi 3 branch
```
cd /usr/local/src/doorpicon
sudo git checkout Doorpi3_test
```

danach kann das Script mit 
```
sudo doorpi-config
```
aufgerufen werden

<br>

## Installscript
Beim starten des Script wird das Auswahlmenü gestartet

![grafik](https://user-images.githubusercontent.com/3772602/133646277-407f6e2b-6264-499a-9844-5da2eab88631.png)

### Doorpi Installation
Bei start der Installation wird eine komplette Neuinstalltion des Doorpi ausgeführt. Dies ist nur bei einem neuen Image möglich. Wurde bereits eine Installtion ausgeführt wird die Ausführung abgebrochen.
Nach der Installtion ist doorpi bereits mit einem Daemon gestartet. Bei manuellen Start des doorpi mit ```sudo doorpi_cli --trace```  muss der daemon vorher beendet werden

### Backup
Die doorpi configuration wird in einem Zipfile auf dem Userdata Laufwerk abgelegt, wenn vorher eine Samba Installation erfolgt ist 

### Restore 
Hier können die Backup Dateien die erstellt wurden wieder zurückgespielt werden.

### Samba
Bei der Installation von Samba werden die Netzlaufwerke <b>config</b> und <b>userdata</b> angelegt. Zugriff zu den Laufwerken erhält man mit folgenden Login Daten.
```
   User: pi
Passort: doorpi
```

#### Doorpi-config
config Dateien des doorpi

#### Doorpi-userdata 
hier werden die Backup Dateien abgelegt
