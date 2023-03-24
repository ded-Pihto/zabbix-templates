For use this template for Oracle DB monitoring needs:
1. Run zabbix-agentd ( or zabbix-agent2 ) as user "root". Read documentation for this agent's settings.
2. You can use agent with no root account for start, but you need to configure sudoers.d setting for start monitoring scripts as 
   user "grid" and user "oracle" ( see *.conf files ).
   And change "echo -e "\n"|runuser grid" to "sudo -u grid" amd "echo -e "\n"|runuser oracle" to "sudo -u oracle" in *.conf files.
3. Set permision to 755 on directory /etc/zabbix and /etc/zabbix/scripts. You can move scripts to non standard directory such as 
   "/oracle/scripts" or other if you don't want change permision for /etc/zabbix. Correct *.conf in this case and set 
   permision 755 for this directory
   Permision for /etc/zabbix/zabbix_agentd.d ( /etc/zabbix/zabbix_agent2.d ) don't need to change.
4. Change "grid" to "oracle" in scripts when you have installation without user "grid" for +ASM technology.

All screpts tested on many installations and may be haven't bugs. But I can't warranty that all bugs was found.
You can use all this templates and scripts at your peril.

Thank you for using these templates and feedback if you find any bugs or room for improvement.
teddy.khenkin@gmail.com
