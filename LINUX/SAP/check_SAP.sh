#!/bin/bash
#   Check status of SAP services and application by SAPcontrol utility
#	
#	v.2.1
# 	by D.Khenkin 2024
#
#	usage: check_SAP.sh discovery   			- create JSON for DDL zabbix
#              check_SAP.sh ServiceDescription iCOD             - return status 
#

case ${1} in
discovery)
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
						sNAME=$(printf "%s $i" | awk -F ',' '{print $1}' | tr -d ' ')
						sDESC=$(printf "%s $i" | awk -F ',' '{print $2}' | tr -d ' ')
						echo "    $comma{\"{#INAME}\":\"$iNAME\" ,"
						echo "    \"{#ICOD}\":\"$iCOD\", "
						echo "    \"{#SNAME}\":\"$sNAME\", "
						echo "    \"{#SDESC}\":\"$sDESC\"} "
						comma=","
						#sSTATUS=$(printf "%s $i" | awk -F ',' '{print $4}' | tr -d ' ')
						#echo "$sNAME $sDESC $sSTATUS"
					done
            fi
        done << EOF
$INST
EOF
        echo "]"
        echo "}"
;;
*)
	sDESC=$1
	iCOD=$2

	sDESC=${sDESC//_/\ }
	sDESC=${sDESC//\"}", GREEN"

	if ( /usr/sap/hostctrl/exe/sapcontrol -nr $iCOD -function GetProcessList | grep "$sDESC" 1>/dev/null 2>&1 ); then
        echo 1
	else
        echo 0
	fi
;;
esac
