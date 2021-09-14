#!/bin/bash
# 
# Doorpi Installations Modul
#
#  v0.1   13.9.21
#  
#  v0.1 - Installation Doorpi  
################################
result=""
BackupPath="/mnt/backup/"
TransferPath="/mnt/conf/"
GitTarget="/usr/local/src/doorpicon"
TempDoorpi="/tmp/DoorPi"
DoorpiSetup="/usr/local/lib/python2.7/dist-packages/DoorPi*"
newpassword="doorpi"

Debug=0
 
[ Debug == 1 ] || set -x

locationOfScript=$(dirname "$(readlink -e "$0")")
ScripName=${0##*/} 

# Root Rechte überprüfen
if [ "$EUID" -ne 0 ]; then
    YesAntwort=$( whiptail --title "Programm Abbruch" --msgbox "Programm muss mit ROOT Rechten ausgeführt werden" 8 78  3>&1 1>&2 2>&3 )
    exit 1
fi


if [ ! -d $GitTarget ]; then

    sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y dist-upgrade
    sudo apt-get -y install git nano mc
    sudo git clone https://github.com/rookie10/doorpi-config.git /usr/local/src/doorpicon
    sudo ln -s  /usr/local/src/doorpicon/doorpi-config.sh /usr/local/bin/doorpi-config
    rm -r /tmp/doorpicon
    exit 0
fi

DoorPiInstall(){
    
    if [ -d $DoorpiSetup ]; then      
        result="Doorpi schon installiert, Installation wird abgebrochen"
        return
    fi    

    if [ -d $TempDoorpi ]; then
        echo "Verzeichnis < $TempDoorpi > schon vorhanden und wird gelöscht"
        rm -r $TempDoorpi
    fi

    git clone https://github.com/motom001/DoorPi.git -b master $TempDoorpi
    curl https://bootstrap.pypa.io/pip/3.5/get-pip.py -o get-pip.py

    sudo apt-get -y install python-watchdog

    sudo python get-pip.py

    sudo python -m pip install --upgrade pip
    sudo python -m pip install --upgrade setuptools

    sed -i $TempDoorpi/setup.py -e "s/from pip.req import parse_requirements/def parse_requirements(filename):/"
    sed -i $TempDoorpi/setup.py -e "s/install_reqs = parse_requirements(os.path.join(base_path, 'requirements.txt'), session=uuid.uuid1())/    \"\"\" load requirements from a pip requirements file \"\"\"/"
    sed -i $TempDoorpi/setup.py -e "s/reqs = \[str(req.req) for req in install_reqs\]/    lineiter = (line.strip() for line in open(filename))/"
    sed -i $TempDoorpi/setup.py -e "/lineiter = /a \ \ \ \ return [line for line in lineiter if line and not line.startswith(\"#\")]"
    sed -i $TempDoorpi/setup.py -e "/line for line /a install_reqs = parse_requirements(os.path.join(base_path, 'requirements.txt'))"
    sed -i $TempDoorpi/setup.py -e "/install_reqs = /a reqs = install_reqs"

    sudo python $TempDoorpi/setup.py install
    sudo pip install python-daemon==2.2.4
    sudo pip install linphone4raspberry

    sudo git clone https://github.com/motom001/DoorPiWeb.git /usr/local/etc/DoorPiWeb

    sudo systemctl enable doorpi.service
    sudo systemctl start doorpi.service

    result="Doorpi Installation erfolgreich abgeschlossen"

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
        chown :www-data -R $BackupPath
        chmod g+rw -R $BackupPath
    fi

    if [ ! -d $TransferPath ]; then
        mkdir -p $TransferPath
        chown :www-data -R $TransferPath
        chmod g+rw -R $TransferPath
    fi
    
 
    #Samba 
    sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install -y samba samba-common smbclient
    cp -r $locationOfScript"/conf/smb.conf" /etc/samba/

    sudo service smbd restart
    sudo service nmbd restart

    (echo $newpassword; echo $newpassword) | smbpasswd -a pi -s

    result="Samba wurde installiert"
}   

while [ 1 ]
do
    CHOICE=$(
        whiptail --title "Willkomen im Doorpi Konfiguration Menu" --menu "\n " 16 78 7 \
        "10" "| Doorpi Installation    Neuinstallation Doorpi"   \
        "20" "| Daemon Start           Start des Daemon"  \
        "25" "| Daemon Stop            Beenden des Daemon"  \
        "30" "| Backup                 Doorpi Konfig backup" \
        "40" "| Restore                Wiederherstellung der Doorpi Konfig"  \
        "50" "| Samba                  Installation Samba" 3>&2 2>&1 1>&3	
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
                InstallSamba			
                read -r result < result
                ;;

            "60")
               read -r result < result
            ;;
    esac
    whiptail --msgbox "$result" 16 78
done

exit
