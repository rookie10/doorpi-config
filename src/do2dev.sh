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

MasterScriptPath=$1
VERSION=$2
HWRevision=$(cat /proc/cpuinfo | grep 'Revision' | awk '{print $3}' | sed 's/^1000//')
MinHWRevison="0xb03111" #Raspi4 2GB
MinHWRevison=$(printf "%d" "$MinHWRevison")
HWRevision=$(printf "%d" "0x$HWRevision")

Debug=0
 
[ Debug == 1 ] || set -x

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

    branchCHOICE=$(
       whiptail --title "! ! ! DoorPi Entwicklungsversion ! ! !  " --radiolist  "\n Bitte Auswählen welche DoorPi Version verwenden werden soll" 16 78 5 \
                         "${array[@]}" 3>&2 2>&1 1>&3
    ) 
    
    if [ $branchCHOICE != "" ] ; then    
       return $branchCHOICE
    else
       return 0
    fi

} 

InstFixVer () {

    InstallVersion=$1

    cd /tmp
    wget https://github.com/motom001/DoorPi/archive/refs/tags/$InstallVersion.tar.gz
    tar -xf v$InstallVersion.tar.gz $LocalGitPath
    sudo apt install -y python3-pip

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
                Version=$(CollRelasVers)
                if [ $Version ] ;
                    InstFixVer $Version
                fi
			;;

            "20")  
                exit		
			;;        
 
            "60")
                exit			
			;;

            "70")
               read -r result < result
			;;
    esac
done
