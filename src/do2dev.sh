#!/bin/bash
###################################### 
#
# Doorpi Modul Develop
#
# 0.1.0 - Installation Doorpi
#    
######################################

result=""
gitPath="https://github.com/motom001/DoorPi.git"
LocalGitPath="/usr/local/src/doorpi"
TempGitPath="/tmp/DoorPi"

MasterScriptPath=$1
VERSION=$2
HWRevision=$(cat /proc/cpuinfo | grep 'Revision' | awk '{print $3}' | sed 's/^1000//')
MinHWRevison="0xb03111" #Raspi4 2GB
MinHWRevison=$(printf "%d" "$MinHWRevison")
HWRevision=$(printf "%d" "0x$HWRevision")
TempInstall=false

Debug=0
 
[ Debug == 1 ] || set -x


function ErrorOut() {
whiptail --title "DoorPi Installation abgebrochen " --msgbox $1  8 78
}


# sort release Versions
CollRelasVers() {

    fnames=""
    test=""

    for file in $(git ls-remote --tags  --symref --sort=-v:refname $gitPath); 
      do
      refscheck=${file%%/*}
      if [ $refscheck == "refs" ]; then
        fnames+=${file##*/}, 
      fi		
    done

    for i in $(echo $fnames | sed "s/,/ /g")
    do 
      if [ $fnames[0] == $i ]; then 
         test+=$i,"",ON,
      else
         test+=$i,"",OFF,
      fi   
    done 

    # Dateien in Array schreiben 
    IFS=',' read -r -a array <<< "$test"

    TAGCHOICE=$(
       whiptail --title "! ! ! DoorPi Entwicklungsversion ! ! !  " --radiolist  "\n Bitte Auswählen welche DoorPi Version verwenden werden soll" 16 78 5 \
                         "${array[@]}" 3>&2 2>&1 1>&3
    ) 
} 

InstVer () {

    InstallVersion=$1
    cd /tmp
    if [ -f $InstallVersion.tar.gz ]; then
        rm -r /tmp/$InstallVersion.tar.gz || return 1
    fi

    wget https://github.com/motom001/DoorPi/archive/refs/tags/$InstallVersion.tar.gz || return 1

    tar -xf $InstallVersion.tar.gz -C /tmp  || return 1

    if [ TempInstall ] ; then
        if [ -d $TempGitPath ]; then
            rm -r $TempGitPath || return 1
        fi   
        cp -r /tmp/DoorPi-${InstallVersion##*v}  $TempGitPath || return 1
        CurrentPath=$TempGitPath
    else 
        if [ -d $LocalGitPath ]; then
            rm -r $LocalGitPath || return 1
        fi
        cp -r /tmp/DoorPi-${InstallVersion##*v}  $LocalGitPath || return 1
        CurrentPath=$LocalGitPath
    fi
    
    cd $CurrentPath
    sudo apt install -y python3-pip || return 1
    sudo pip install -r requirements.txt || return 1

textfeld=$(cat <<-END
    Doopi wurde erfolgreich installiert. DoorPi kann jetzt über die Konsole
    gestartet werden. 
    
    Zum starten bitte folgendes eingeben

    python $CurrentPath/main.py --trace -c [Pfad zur Config]
    
    eingeben
END
)

    whiptail --title "DoorPi Installation abgeschlossen " --msgbox "$textfeld"  15 100
}


while [ 1 ]
do
    CHOICE=$(
        whiptail --title "!!! Doorpi unstable Versions !!!!  $VERSION" --menu "\n " 20 100 12 \
        "10" "| Install                   Last unstable Versions "   \
        "20" "| Quick install             RAM Installation " 3>&2 2>&1 1>&3	
    )


    result=$(whoami)
    case $CHOICE in
        
            "") 
                exit
			;;
	    
            "10")

                TempInstall=1 
                CollRelasVers || ErrorOut "Auswahl der Installationsdatei fehlgeschlagen"	
                if [ $TAGCHOICE ] ; then
                    InstVer $TAGCHOICE || ErrorOut "Installation fehlgeschlagen"
                fi
			;;

            "20")  
                
                TempInstall=0
                CollRelasVers || ErrorOut "Auswahl der Installationsdatei fehlgeschlagen"	
                if [ $TAGCHOICE ] ; then
                    InstVer $TAGCHOICE || ErrorOut "Installation fehlgeschlagen"
                fi		
			;;        
 
            "60")
                exit			
			;;

            "70")
               read -r result < result
			;;
    esac
done
