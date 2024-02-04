#!/bin/bash
#   Check status of SAP services and application by SAPcontrol utility
#   use sapcontrol & saphostcontrol utilities
#
#	v.3.1
# 	by D.Khenkin 2024
#
#	usage: check_SAP.sh 	- create JSON for DDL zabbix & status
#
#

    SAPCMD="/usr/sap/hostctrl/exe/saphostctrl"
    INST=$(${SAPCMD} -function ListInstances | awk '{print $4" "$6}')

    echo "{"
    echo "\"data\":["
    comma=""
    while read iNAME iCOD
        do
            #printf "$iNAME $iCOD\n"
            PROC=$(/usr/sap/hostctrl/exe/sapcontrol -nr ${iCOD} -function GetProcessList  | grep ', ' | grep -v 'name,' )
	    PROC=${PROC//, /,}
            PROC=${PROC// /_}
            if [ -n ${#PROC[@]} ]; then
                for i in $PROC
                    do
                        pNAME=$(printf "%s $i" | awk -F ',' '{print $1}' | tr -d ' ')
                        pDESC=$(printf "%s $i" | awk -F ',' '{print $2}' | tr -d ' ')
			pSTAT=$(printf "%s $i" | awk -F ',' '{print $3}' | tr -d ' ')

			echo "    $comma{\"{#INAME}\":\"$iNAME\" ,"
                        echo "    \"{#ICOD}\":\"$iCOD\", "
                        echo "    \"{#PNAME}\":\"$pNAME\", "
                        echo "    \"{#PDESC}\":\"$pDESC\", "
			echo "    \"INDEX\":\"${iCOD}${iNAME}${pNAME}\", "
			echo "    \"STATUS\":\"$pSTAT\"} "
                        comma=","
                    done
            fi
        done << EOF
$INST
EOF
    echo "]"
    echo "}"

