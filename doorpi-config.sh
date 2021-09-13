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
TransferPath="/mnt/Transfer/"
GitTarget="/usr/local/src/DoorpiConfig"
TempDoorpi="/tmp/DoorPi"
DoorpiSetup="/usr/local/lib/python2.7/dist-packages/DoorPi*"

Debug=0
 
[ Debug == 1 ] || set -x

locationOfScript=$(dirname "$(readlink -e "$0")")
ScripName=${0##*/} 

# Root Rechte überprüfen
if [ "$EUID" -ne 0 ]; then
    YesAntwort=$( whiptail --title "Programm Abbruch" --msgbox "Programm muss mit ROOT Rechten ausgeführt werden" 8 78  3>&1 1>&2 2>&3 )
    exit 1
fi

DoorPiInstall(){
    
    if [ -d $DoorpiSetup ]; then
        whiptail --msgbox "Doorpi schon installiert, Installation wird abgebrochen" 16 78       
        return
    fi    

    sudo apt-get -y update && sudo apt-get -y upgrade && sudo apt-get -y dist-upgrade
    sudo apt-get -y install git nano mc python-watchdog

    if [ -d $TempDoorpi ]; then
        echo "Verzeichnis < $TempDoorpi > schon vorhanden und wird gelöscht"
        rm -r $TempDoorpi
    fi

    git clone https://github.com/motom001/DoorPi.git -b master $TempDoorpi
    curl https://bootstrap.pypa.io/pip/3.5/get-pip.py -o get-pip.py

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
                Dooraupdate		
                read -r result < result
	        ;;
				
            "25")  
                DbSave	
                read -r result < result
	            ;;	

            "30")  
                DooraBackup
                read -r result < result
                ;;

            "40") 
                DooraRestore
                read -r result < result
                ;;

            "50")
                Restart			
                read -r result < result
                ;;

            "60")
               read -r result < result
            ;;
    esac
    whiptail --msgbox "$result" 16 78
done

exit
