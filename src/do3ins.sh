#!/bin/bash
###################################### 
#
# Doorpi3 Installations Modul
#
#  0.1.x - Doorpi 3 install  
#
#    
######################################

GitTarget="/usr/local/src/doorpicon"
SipPath="/usr/local/src/sip"
MasterScriptPath=$1
VERSION=$2
HWRevision=$(cat /proc/cpuinfo | grep 'Revision' | awk '{print $3}' | sed 's/^1000//')
MinHWRevison="0xb03111" #Raspi4 2GB
MinHWRevison=$(printf "%d" "$MinHWRevison")
HWRevision=$(printf "%d" "0x$HWRevision")

Debug=0
 
#[ Debug == 1 ] || set -x

locationOfScript=$(dirname "$(readlink -e "$0")")
ScripName=${0##*/} 

DoorPi3Install(){

    SipPath="/usr/local/src/sip"
 
    result="DoorPi3 Installation abgebrochen"
    if !( whiptail --yesno " A C H T U N G ! ! \n \n die Auswahl von Doorpi3 ist aktuell absolut experimental !!! \n \n Wollen Sie trotzdem starten ?" 16 78 );then
        echo "wurde abgebrochen" sudo apt-get install -y python3-pip
		return 1
    fi

    result="Install Systemdateien fehlgeschlagen" 
    sudo apt install -y python3-pip &&
    sudo pip install --upgrade pip &&
    true || return 1
    
    result="Git konnte nicht geladen werden"
    cd /tmp
    git clone https://github.com/emphasize/DoorPi || return
    cd DoorPi
    result="Branch nicht vorhanden"
    git checkout bugfix/setuptools || return

    result="Installation fehlgeschlagen" &&
    sudo python3 setup.py install --prefix=/usr/local &&
    true || return 1
 
    result="Doorpi3 Installation fertiggestellt"
    return 0
    
}

PJASUInstall(){
    
    result="Installation Libs fehlgeschlagen"
    sudo apt-get install -y libasound2-dev libssl-dev libv4l-dev libsdl2-dev libsdl2-gfx-dev libsdl2-image-dev \
                            libsdl2-mixer-dev libsdl2-net-dev libsdl2-ttf-dev libx264-dev libavformat-dev libavcodec-dev \
                            libavdevice-dev libavfilter-dev libavresample-dev libavutil-dev libavcodec-extra libopus-dev \
                            libopencore-amrwb-dev libopencore-amrnb-dev libvo-amrwbenc-dev || return

    sudo apt-get install -y swig default-jdk || return

    if [ ! -d $SipPath ]; then      
       mkdir -p $SipPath   
    fi
  
    cd $SipPath
    wget https://github.com/cisco/openh264/archive/v2.2.0.tar.gz &&
    tar -xf v2.2.0.tar.gz &&
    cd $SipPath/openh264-2.2.0 &&
    make &&
    sudo make install &&
    result="Installation openh264 fehlgeschlagen" &&
    true || return 1

    # swap erweitern sonst wird abgebrochen 
    if [[ $HWRevision -lt $MinHWRevison ]] ; then
        result="swap Erweiterung fehlgeschlagen" &&      
        sudo systemctl stop dphys-swapfile &&
        sed -i /etc/dphys-swapfile -e "s/.*CONF_SWAPSIZE=.*/CONF_SWAPSIZE=100/g" &&
        sudo systemctl start dphys-swapfile &&
        true || return 1
    fi

    cd $SipPath
    wget https://github.com/pjsip/pjproject/archive/refs/tags/2.11.1.tar.gz &&
    tar -xf 2.11.1.tar.gz &&
    cd $SipPath/pjproject-2.11.1 &&

    echo "#define PJMEDIA_AUDIO_DEV_HAS_ALSA      1" > pjlib/include/pj/config_site.h &&
    echo "#define PJMEDIA_AUDIO_DEV_HAS_PORTAUDIO 0" >> pjlib/include/pj/config_site.h &&
    echo "#define PJMEDIA_HAS_VIDEO       1" >> pjlib/include/pj/config_site.h &&

    echo "export CFLAGS += -march=armv8-a -mtune=cortex-a53 -mfpu=neon-fp-armv8 -mfloat-abi=hard -mlittle-endian -munaligned-access -ffast-math" > ./user.mak &&
    echo "export LDFLGS +=" >> ./user.mak &&
    result="Vorbereitung  pjsip fehlgeschlagen" &&
    true || return 1

    CFLAGS="-I/usr/local/src/sip/ffmpeg-5.0/" LDFLAGS="-L/tmp/test/" ./configure
    ./configure  --with-ffmpeg=/usr/local/src/sip/ffmpeg-5.0/ &&
    make dep &&
    make &&
    sudo make install &&
    result="Installation pjsip fehlgeschlagen" &&
    true || return 1

    cd $SipPath/pjproject-2.11.1/pjsip-apps/src/swig/ &&
    sed -i $SipPath/pjproject-2.11.1/pjsip-apps/src/swig/python/Makefile -e "s/USE_PYTHON3?=1/USE_PYTHON3=1/" &&
    make &&
    sudo make install &&
    result="Installation pjsip python fehlgeschlagen" &&
    true || return 1
    
    # swap erweitern
    if [[ $HWRevision -lt $MinHWRevison ]] ; then
    	result="swap Erweiterung fehlgeschlagen" &&      
    	sudo systemctl stop dphys-swapfile &&
    	sed -i /etc/dphys-swapfile -e "s/.*CONF_SWAPSIZE=.*/CONF_SWAPSIZE=100/g" &&
    	sudo systemctl start dphys-swapfile &&
    	true || return 1
    fi

    result="PJSUA Installation fertiggestellt"
    return 0

}

while [ 1 ]
do
    CHOICE=$(
        whiptail --title "!!! Doorpi 3 Konfiguration Menu $VERSION" --menu "\n " 20 100 12 \
        "10" "| DoorPi 3 Installation      Neuinstallation Doorpi"   \
        "20" "| PJSUA installation         SIP Client" 3>&2 2>&1 1>&3	
    )


    result=$(whoami)
    case $CHOICE in
        
            "") 
                exit
			;;
	    
            "10")
                DoorPi3Install
			;;

            "20")  
                PJASUInstall		
			;;        
 
            "60")
                InstallSamba			
			;;

            "70")
               read -r result < result
			;;
    esac
done
