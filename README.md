# Raspberry-Pi-Snort.conf-and-Alerting-Engine
Home router IDS solution with a Raspberry Pi 3. Dynamically resolves device name, manufacturer, and alerts user of Snort analytics through email or text. Currently handles around 15,000 rules.
Tested with a Raspberry Pi 3 B, Snort 2.9.7.0 and Raspbian version 2018-11-13
Snort.conf file is meant to be used as a template. 
The preprocessor values and 'output alert_csv: /home/pi/Alerting_Engine/alerts.csv timestamp,src,ethsrc,dst,msg' are the important aspects of Snort.conf.
The Alerting Engine needs basic modification upon install and serves as a host to add additional features.
For more information regarding the install or setup - send me a message.