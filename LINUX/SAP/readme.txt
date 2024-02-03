Template use LLD technology for discovery all SAP's processes and create item and triggers for 
monitoring of availability them.

For use this template for SAP's processes monitoring needs:
1. Run zabbix-agentd ( or zabbix-agent2 ) as user "root". Read documentation for this agent's settings.
2. Copy check_SAP.sh to $zabbix_config/scripts folder where $zabbix_config is folder with zabbix config files.
3. Copy userparameter_SAP.conf to $zabbix_config/zabbix_agent.d ( for zabbix-agentd )
   or $zabbix_config/zabbix_agent2.d ( for zabbix-agent2 ).
4. Run chmod +x $zabbix_config/scripts/check_SAP.sh
5. Restart zabbix agent
6. Import template check_SAP.yaml and apply to SAP hosts

All screpts tested on many installations and may be haven't bugs. But I can't warranty that all bugs was found.
You can use all this templates and scripts at your peril.

Thank you for using these templates and feedback if you find any bugs or room for improvement.
teddy.khenkin@gmail.com
