#!/bin/bash

# SCAN TO SEE WHO IS ON YOUR NETWORK
# WIRED OR WIRELESS

################### FUNCTIONS #########################

fout() {
	if nmcli d | grep -w "wireless"
	then
		clear
		(sudo arp-scan --interface=wlan0 --localnet) > arpfile
	else
		(sudo arp-scan -l) > arpfile
	fi
	sleep 0.5
}

#PRINT UNKNOWN MAC ADDRESS(S)
intruder() {
	echo ""
	echo -e "\\e[33mNOT ON DATABASE\\e[0m"
	echo -e "\\e[31m---------------------[STRANGER DANGER]--------------------------\\e[0m"
	grep 192.168 < arpfile | awk '{print $2}' | sort -u > arpfilecat
	grep -v -Ff arpfile-macs arpfilecat | tee arpdiff
	echo -e "\\e[31m----------------------------------------------------------------\\e[0m"
	echo ""
}

yesno()
{
while :
do
        echo -e "$* (Y/N)? \c"
        read -r yn

        case $yn in
                y|Y|yes|YES|Yes)
                        return 0;;
                n|N|no|NO|No)
                        return 1;;
                *)
                        echo "Please enter Yes or No.";;
        esac
done
}

######################### MAIN ##############################

#FOR FIRST TIME RUN
clear

if [ ! -f arpfile-macs ]; then
	touch arpfile-macs
fi

fout		#CALL FIRST FUNCTION

SCAN_RESULTS=$(grep 192 < arpfile | awk '{printf ("%5s\t%s\n", $1, $2)}')
echo ""
echo -e "\\e[33m-----------------------[SCAN RESULTS]---------------------------\\e[0m"
echo ""
echo -e "\\e[33m$SCAN_RESULTS\\e[0m"
echo -e "\\e[33m----------------------------------------------------------------\\e[0m"
echo ""

#GET HOST IP,NAME,DEVICE,INTERFACE
HOST=$(uname -n)
HOSTPC=$(ip route list | tail -n1 | awk '{print $3,$9}')

echo "Scanning from host: $HOSTPC $HOST"

intruder	#CALL SECOND FUNCTION
sleep 1

echo ""
echo -e "\\e[33mON DATABASE\\e[0m"
printf "MAC-Address\t\tDevice-Name\n"
echo "----------------------------------------------------------------"

#MATCH KNOWN DEVICES IN DATABASE
while read -r row; do

		for i in $(cat arpfile-macs); do
			if [[ "$row" =~ $i ]]; then

			CUTIT=$(grep "$i" < net-macs | awk '{print $2}')
			printf '%s\t%s\n' "$i" "$CUTIT"

			fi
	        done
done < arpfilecat

echo "----------------------------------------------------------------"
echo ""
echo ""
echo -e "\\e[33mTO DO LIST:\\e[0m"
echo "Check Mac(s) in STRANGER DANGER to see if they are legit."
echo ""

#ADD TO DATABASE
WAC=$(wc -l < arpdiff)

if [ "$WAC" -gt 0 ]
then
        if yesno "$WAC unknown Mac(s) in STRANGER DANGER. Add any to database if trusted..."
        then
                echo "-------------------------------------------------------------------"
        else
		rm arpfilecat
		rm arpdiff
                exit 0
        fi
fi

#USING WHILE READ CAUSES INFINITE LOOP HERE
#IF ANYONE CAN IMPROVE THIS I'D BE GRATEFUL
#SHELLCHECK GRUMBLE HERE

for inc in $(cat arpdiff)
do
        if yesno "Add> $inc <to database"
        then
                echo ""
                echo -e "\\e[33mEnter Device information\\e[0m:"
                echo ""
                echo -e "\tDevice Name: \c"
                read -r DEVNAME
                echo ""
                echo "Added $DEVNAME to database"
                echo -e "\\e[33m----------------------------------------\\e[0m"
		printf '%s\t %s\n' "$inc" "$DEVNAME" >> net-macs
		printf '%s\n' "$inc" >> arpfile-macs
                echo ""
        fi
done

sed -i '/^$/d' arpfile-macs net-macs
rm arpfilecat
exit 0
