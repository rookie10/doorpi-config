#!/bin/bash
###################################### 
#
# Doorpi Installations Modul
#
# 13.9.21  v0.2.1 - Installation Doorpi
#    
######################################

result=""
BackupPath="/mnt/user"
TransferPath="/mnt/conf/"
GitTarget="/usr/local/src/doorpicon"
TempDoorpi="/tmp/DoorPi"
TempConfig="/tmp/doorpicon"
DoorpiSetup="/usr/local/lib/python2.7/dist-packages/DoorPi*"
newpassword="doorpi"
doorpiconf="/usr/local/etc/DoorPi"
gitclonehttps="https://github.com/rookie10/doorpi-config.git /usr/local/src/doorpicon"
python2V=false
version=v0.2.1


Debug=0
 
#[ Debug == 1 ] || set -x

locationOfScript=$(dirname "$(readlink -e "$0")")
ScripName=${0##*/} 


# Root Rechte überprüfen
if [ "$EUID" -ne 0 ]; then
    YesAntwort=$( whiptail --title "Programm Abbruch" --msgbox "Programm muss mit ROOT Rechten ausgeführt werden" 8 78  3>&1 1>&2 2>&3 )
    exit 1
fi


if [ ! -d $GitTarget ]; then

    sudo apt-get -y install git nano mc
    sudo git clone $gitclonehttps
    sudo ln -s  $GitTarget/doorpi-config.sh /usr/local/bin/doorpi-config
    rm -r /tmp/doorpicon
    exit 0
fi

DoorPi3Install(){
 
	result="DoorPi3 Installation abgebrochen"

    Doorpi3CHOICE=$(
    whiptail --title "Doorpi3 >>> expermintel <<<< " --yesno "A C H T U N G die Auswahl vov Doorpi3 ist aktuell \n " ·\
                     "noch im absoluten experimental Status \n \n" \
                     "Verwendung auf eigene gefahr \n \n" \
                     "Bitte daten regelmäßig sichern" 16 78 3>&2 2>&1 1>&3
                    )
    
}

DoorPiInstall()n

    if [ -d $DoorpiSetup ]; then      
        result="Doorpi schon installiert, Installation wird abgebrochen" 
	return 
    fi

    sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y dist-upgrade || return result="Raspberry OS update fehlgeschlagen"
	
	python2V=""
    if [ ! "$( python -c 'import sys; print(".".join(map(str, sys.version_info[:1])))')" == "2" ];then
        echo "###### python2 muss nachinstalliert werden"
        python2V="true"
    fi 		
	

    if [ $python2V ]; then 
        sudo apt-get -y install python-is-python2 &&
        sudo apt-get -y install python-dev &&
        result="Installation Python 2.7.18 fehlgeschlagen" &&
        true || return 
    fi
		
    curl https://bootstrap.pypa.io/pip/3.5/get-pip.py -o get-pip.py &&
    sudo python get-pip.py &&
    result="Installation get-pip fehlgeschlagen" &&
    
    true || return 
	
	
    if [ $python2V ]; then
        result="Watchdog installation fehlgeschlagen"
        sudo pip install watchdog || return 
    else
        result="Watchdog installation fehlgeschlagen"
        sudo apt-get -y install python-watchdog || return 
    fi
	
    if [ -d $TempDoorpi ]; then
        echo "Verzeichnis < $TempDoorpi > schon vorhanden und wird gelöscht"
        rm -r $TempDoorpi
    fi

    result="Download Doorpi fehlgeschlagen"
    git clone https://github.com/motom001/DoorPi.git -b master $TempDoorpi || return 

    cd /tmp/DoorPi &&
    sudo python -m pip install --upgrade pip &&
    sudo python -m pip install --upgrade setuptools &&
    result="Installation pip upgrade fehlgeschlagen" &&
	
    true || return 

    sed -i $TempDoorpi/setup.py -e "s/from pip.req import parse_requirements/def parse_requirements(filename):/" &&
    sed -i $TempDoorpi/setup.py -e "s/install_reqs = parse_requirements(os.path.join(base_path, 'requirements.txt'), session=uuid.uuid1())/    \"\"\" load requirements from a pip requirements file \"\"\"/" &&
    sed -i $TempDoorpi/setup.py -e "s/reqs = \[str(req.req) for req in install_reqs\]/    lineiter = (line.strip() for line in open(filename))/" &&
    sed -i $TempDoorpi/setup.py -e "/lineiter = /a \ \ \ \ return [line for line in lineiter if line and not line.startswith(\"#\")]" &&
    sed -i $TempDoorpi/setup.py -e "/line for line /a install_reqs = parse_requirements(os.path.join(base_path, 'requirements.txt'))" &&
    sed -i $TempDoorpi/setup.py -e "/install_reqs = /a reqs = install_reqs"
    result="Setup.py Änderung fehlgeschlagen"
	
    true || return 

    result="Doorpi installation fehlgeschlagen"
    sudo python $TempDoorpi/setup.py install || return 
    result="Python Daemnon installation fehlgeschlagen"
    sudo pip install python-daemon==2.2.4 || return 
    result="linphone4raspberry installation fehlgeschlagen"
    sudo pip install linphone4raspberry || return 

    result="DoorPiWeb clone fehlgeschlagen" 
    sudo git clone https://github.com/motom001/DoorPiWeb.git /usr/local/etc/DoorPiWeb || return 
	
    sudo systemctl enable doorpi.service &&
    sudo systemctl start doorpi.service &&
    result="Deamon Aktivierung fehlgeschlagen"
	
    true || return 

    result="Doorpi Installation erfolgreich abgeschlossen"

}

Doorpigitpull (){

    cd $GitTarget
    result="Gitpull ist abgebrochen"
    git pull || return
    result="Git pull war erfolgreich"
}	

StartDaemon (){
    
    sudo systemctl start doorpi.service
    result="Doorpi daemon gestartet"
}

StopDaemon (){
    
    sudo systemctl stop doorpi.service
    result="Doorpi daemon gestopt"
}

InstallSamba (){

    if [ ! -d $BackupPath ]; then
        mkdir -p $BackupPath
        chown :pi -R $BackupPath
        chmod g+rw -R $BackupPath
    fi

    ln -s /usr/local/etc/DoorPi/  /mnt/conf
 
    #Samba 
    sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install -y samba samba-common smbclient
    cp -r $locationOfScript"/conf/smb.conf" /etc/samba/

    sudo service smbd restart
    sudo service nmbd restart

    (echo $newpassword; echo $newpassword) | smbpasswd -a pi -s

    result="Samba wurde installiert"
}   

DoorpiBackup (){

    if [ ! -d $BackupPath ]; then
        result="Das Backup ist fehlgeschlagen, /mnt/backup Verzeichnis nicht vorhanden"
        return
    fi

    doorpiconf1="$doorpiconf/conf"
    doorpiconf2="$doorpiconf/log"
    doorpiconf3="$doorpiconf/media"    
    today=`date +%Y-%m-%d_%H%M%S_`$HOSTNAME"_doorpiconf.tar.gz"

    tar cfvz $BackupPath/$today $doorpiconf1 $doorpiconf2 $doorpiconf3
    
    if [ $? == 0 ]; then
        result="Das Backup <  $today  > wurde erstellt"
        return

    else
        result="Das Backup ist fehlgeschlagen"
        return
    fi
}

DoorpiRestore (){
    
    if [ ! -d $BackupPath ]; then
        result="Das Restore ist fehlgeschlagen, /mnt/backup Verzeichnis nicht vorhanden"
        return
    fi
    
    fnames=""   
    bakupadv="$BackupPath/*.tar.gz"
    # Verzeichnis auf dateien durchsuchen
    for file in $bakupadv; do
      fnames+=${file##*/},"",      
    done
    echo $fnames
    # Dateien in Array schreiben 
    IFS=',' read -r -a array <<< "$fnames"
    echo ${array[@]}
    restoreCHOICE=$(
    whiptail --title "Wähle Doorpi Konfiguration zur Wiederherstellung" --menu "\n Bitte Wiederherstellungs Datei auswählen" 16 78 5 \
                      "${array[@]}" 3>&2 2>&1 1>&3
	)
    
    if [ $restoreCHOICE != "" ] ; then
        restorefile=$BackupPath/$restoreCHOICE
        
        StopDaemon
        tar -xvf $restorefile
        StartDaemon

        result="Wiederherstellung erfolgreich abgeschlossen !"
    
    else
        result="Wiederherstellung wurde abgebrochen !"
   
    fi
}



while [ 1 ]
do
    CHOICE=$(
        whiptail --title "Willkomen im Doorpi Konfiguration Menu $version" --menu "\n " 16 78 7 \
        "10" "| DoorPi Installation    Neuinstallation Doorpi"   \
		"15" "| DoorPi3 Installation   Achtung !!! experimental"   \
        "20" "| Daemon Start           Start des Daemon"  \
        "25" "| Daemon Stop            Beenden des Daemon"  \
        "30" "| Backup                 Doorpi Konfig backup" \
        "40" "| Restore                Wiederherstellung der Doorpi Konfig"  \
		"50" "| Config. Update         Git pull wird ausgeführt"  \
        "60" "| Samba                  Installation Samba" 3>&2 2>&1 1>&3	
    )


    result=$(whoami)
    case $CHOICE in
        
            "") 
                exit
                ;;
	    
            "10")
                DoorPiInstall
				read -r result < result
	        ;;

			"15")
                DoorPi3Install
				read -r result < result
	        ;;
				
            "20")  
                StartDaemon		
                read -r result < result
	        ;;
				
            "25")  
                StopDaemon	
                read -r result < result
	        ;;	

            "30")  
                DoorpiBackup
                read -r result < result
                ;;

            "40") 
                DoorpiRestore
                read -r result < result
                ;;

            "50") 
                Doorpigitpull
                read -r result < result
                ;;
             
            "60")
                InstallSamba			
                read -r result < result
                ;;

            "70")
               read -r result < result
            ;;
    esac
    whiptail --msgbox "$result" 16 78
done

exit
