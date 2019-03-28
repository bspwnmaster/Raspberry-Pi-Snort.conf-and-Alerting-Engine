#!/bin/bash

#Snort Alert Engine V.1
#Requirements:
#Linux operating system running Snort and SSMTP configured
#iostat, sed, and awk installed
#cron with shell script ran daily
#in the same directory as oui.txt (MAC Resolver), alertdata.csv (Snort Alerts), and emailformat.txt (SSMTP)

#Future Plans:
#1.Accept user input to configure
#2.More options for data analytics included in email/text alerts
#3.Automatically detect subnet and configure script, snort, and alerts accordingly
#4.RAM and Storage Space data
#5.Add nmap support
#6.Add ASCII art
#7.Match phone service providers to their phone number email format

############Environmental Updates#############

#wget http://standards-oui.ieee.org/oui/oui.txt  #gets updated manufacturer list for oui.txt #only needs to be done once or periodically 
#ping -c 6 -b <bip>  #broadcasts ping on network #lightweight alternative to nmap #customize to home network broadcast ip
#sleep 7 #waits for ping to finish

##############Data Acquisition#################

arpdata="arp -a | cut -d ' ' -f 1,2,4 | sed 's/[()]//g'"  #get hostname + ip + MAC through ARP -f 1,2,4
eval $arpdata > arpdata.txt # (Hostname | IP | MAC)

alertdatabackup="cat alerts.csv | sed 's/,/ /g'"  #takes example Snort csv alert output and separates by spaces
eval $alertdatabackup > alertdatabackup.txt # (Timestamp | Src IP | Src MAC | Dest IP | Msg)

alertdata="cat alerts.csv | sed 's/,/ /g'"  #working file
eval $alertdata > alertdata.txt

##############Data Analytics####################

month="$(date +'%m')"
today="$(date +'%m/%d')"
echo $today
cat alertdata.txt | while read line #need timestamp field in alerts
do
        if [[ $line == $today* ]];
        then
                echo $line >> daily.txt
        fi
        if [[ $line == $month* ]]
        then
                echo $line >> monthlyalerts.txt
        fi
done  

cat monthlyalerts.txt | uniq -u >> monthlyalerts.txt #overwrite duplicate lines for accurate monthly data
cat daily.txt | cut -d' ' -f 2- >> dailyalerts.txt #everything but the timestamp
>daily.txt #clears
cat monthlyalerts.txt | cut -d ' ' -f 2- >> monthlyalerts.txt
cat dailyalerts.txt | sort | uniq -c | sort -n -r | head >> topdailyalerts.txt #top 10 daily alerts w/ count
cat monthlyalerts.txt | sort | uniq -c | sort -n -r | head >> topmonthlyalerts.txt #top 10 monthly alerts w/ count

#dailyalerts.txt now main file to use

###########Manufacturer Resolver###############

cat dailyalerts.txt | while read alerts
do
        alertsmac="$(echo "$alerts" | cut -d ' ' -f 2)" #gets alert mac address
        mac="$(echo "$alerts" | cut -d ' ' -f 2 | sed 's/ //g' | sed 's/-//g' | sed 's/://g' | cut -c1-6)" #gets manufacturer portion of mac address
        macman="$(grep ^"$mac" ./oui.txt)" #looks for mac in oui.txt
        man="$(echo "$macman" | cut -f 3)" #only gets manufacturer name
        if [ "$macman" ]
        then
                man="$(echo "$macman" | cut -f 3 | awk '{print $1;}')" #important only one word
                sed -i "s/$alertsmac/$man/" dailyalerts.txt #replaces mac address with manufacturer
        fi
done

#######ARP Data Find & Replace#########

cat dailyalerts.txt | while read alerts #searches each line called ($alerts) in generated alerts (for alerts in dailyalerts.txt)
do   
    alertsip=$(echo "$alerts" | cut -d ' ' -f 1) #gets only source IP for that line
    cat arpdata.txt | while read arp #searches each line called ($arp) in ARP data (for arp in arpdata.txt) (Hostname | IP | MAC)
    do
        arpip=$(echo "$arp" | cut -d ' ' -f 2) #gets only ARP IP        
        if [ "$alertsip" = "$arpip" ] #if IPs are the same
        then                        
            sed -i "s/$alertsip/$arp/g" dailyalerts.txt #insert on line ARP data (Hostname | Src IP | MAC), replacing alert (Src IP)
        fi
    done   
done

##############Format####################

cat dailyalerts.txt | sort | uniq -c | sort -n -r | head >> topdailyalerts.txt #top 10 daily alerts w/ count
cat monthlyalerts.txt | sort | uniq -c | sort -n -r | head >> topmonthlyalerts.txt #top 10 monthly alerts w/ count
iostat | sed -n '4{p;q}' >> cpu.txt #gets average cpu info
echo “$(date)”  >> emailalert.txt #puts date on first line of email
echo “Top Daily Alerts:” >> emailalert.txt #daily alerts title
cat topdailyalerts.txt >> emailalert.txt
echo “Top Monthly Alerts:” >> emailalert.txt #monthly alerts title
cat topmonthlyalerts.txt >> emailalert.txt
echo “Performance:” >> emailalert.txt #performance alerts title
cat cpu.txt >> emailalert.txt
cat emailalert.txt
##sed "/^$/d" emailalert.txt | sed G #optional way to format lines
##cat emailalert.txt | sed '/ / a\ -----------------------------------------------------------'

######Notification (Email/Text)##########

cat emailformat.txt emailalert.txt >> emailalert.txt #adds customized message to format template
ssmtp -t < emailalert.txt #send message to email or text

###########Clearing Files################

>emailalert.txt
>topdailyalerts.txt
>topmonthlyalerts.txt
