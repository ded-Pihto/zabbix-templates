#!/bin/bash

#read -p "IP ? " -e IPNAME

#read -p "MIB ? " -e MIBNAME

#snmpwalk -v2c -c SIMADMIN 10.152.14.80 $MIBNAME

#snmpwalk -v2c -c SIMADMIN proxysg.pbu.icb .1.3.6.1.2.1
##snmpwalk -c SIMADMIN -v2c proxysg.pbu.icb BLUECOAT-SG-HEALTHMONITOR-MIB::bluecoatSGHealthMonMIB

##snmpwalk -c SIMADMIN -v2c proxysg.pbu.icb BLUECOAT-SG-HEALTHCHECK-MIB::deviceHealthCheckMIB

##snmpwalk -c SIMADMIN -v2c proxysg.pbu.icb BLUECOAT-SG-PROXY-MIB::sgProxyHttpByteRateHit.0
#snmpwalk -c SIMADMIN -v2c 10.152.14.80 SNMPv2-SMI::enterprises.3417.2.11.2.3

#snmpwalk -c SIMADMIN -v2c proxysg.pbu.icb BLUECOAT-SG-HEALTHMONITOR-MIB::deviceHealthMonStatus

##snmpwalk -c SIMADMIN -v2c proxysg.pbu.icb BLUECOAT-SG-HEALTHMONITOR-MIB::bluecoatSGHealthMonMIB
#snmpwalk -c SIMADMIN -v2c proxysg.pbu.icb BLUECOAT-SG-HEALTHCHECK-MIB::deviceHealthCheckMIB

#snmpwalk -c SIMADMIN -v2c proxysg.pbu.icb BLUECOAT-SG-HEALTHCHECK-MIB::deviceHealthCheckName

snmpwalk -c P1raeu5 -v2c 10.152.48.1


