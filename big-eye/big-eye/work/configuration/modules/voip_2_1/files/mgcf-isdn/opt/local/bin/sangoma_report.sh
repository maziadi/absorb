#!/bin/sh

FILE=/tmp/sangoma_report

rm -rf $FILE
touch $FILE
echo "   **** Wanrouter version ****" >> $FILE
wanrouter version >> $FILE
echo "==================================================================================================================================================="
echo "   **** ifconfig  ****" >> $FILE
ifconfig >> $FILE
echo "==================================================================================================================================================="
echo "   **** interrupts  ****" >> $FILE
cat /proc/interrupts >> $FILE
echo "==================================================================================================================================================="
echo "   **** Wanpipemon ****" >> $FILE
wanpipemon -i w1g1 -c Ta >> $FILE
wanpipemon -i w2g1 -c Ta >> $FILE
wanpipemon -i w3g1 -c Ta >> $FILE
wanpipemon -i w4g1 -c Ta >> $FILE
wanpipemon -i w5g1 -c Ta >> $FILE
wanpipemon -i w6g1 -c Ta >> $FILE
wanpipemon -i w7g1 -c Ta >> $FILE
wanpipemon -i w8g1 -c Ta >> $FILE
echo "==================================================================================================================================================="
echo "   **** wanrouter hwprobe verbose ****"
wanrouter hwprobe verbose >> $FILE
echo "==================================================================================================================================================="
echo "   **** wanrouter status ****" >> $FILE
wanrouter status >> $FILE
echo "==================================================================================================================================================="
echo "   **** /etc/wanpipe/wanpipeX.conf ****" >> $FILE
cat /etc/wanpipe/wanpipe1.conf >> $FILE
cat /etc/wanpipe/wanpipe2.conf >> $FILE
cat /etc/wanpipe/wanpipe3.conf >> $FILE
cat /etc/wanpipe/wanpipe4.conf >> $FILE
cat /etc/wanpipe/wanpipe5.conf >> $FILE
cat /etc/wanpipe/wanpipe6.conf >> $FILE
cat /etc/wanpipe/wanpipe7.conf >> $FILE
cat /etc/wanpipe/wanpipe8.conf >> $FILE
echo "==================================================================================================================================================="
echo "   **** /var/log/messages is redirected to /var/log/syslog ****" >> $FILE
cat /etc/wanpipe/wanpipe1.conf >> $FILE
