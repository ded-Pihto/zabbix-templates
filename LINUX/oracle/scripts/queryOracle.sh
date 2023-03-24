#!/bin/bash
#.
# Find name of exist instances
# If database in PRIMARY mode return tablespaces in active instances
# parameters: search list of SID separate by /. Return all running instance if empty
# by D.Khenkin 23/04/2022
#
# example queryOracle.sh a1/a2/a3
#   run only for user oracle
#
# v.3.1

. /home/oracle/.bash_profile

if ! [[ $USER == oracle ]]; then
	echo "Run only for user oracle"
	echo ""
	exit 1
fi

if [[ $1_ == _ ]]; then
	list_SID=`ps -ef | grep pmon | grep -v grep | grep -v sed | grep -v +ASM | grep -v +APX | awk '{print $8}' | sed "s/ora_pmon_//g"`
	IFS=" "; list_SID=($list_SID); unset IFS;
else
	IFS="/"; list_SID=($1); unset IFS;
fi

PRIMARY_DB_LIST=""
STNDBY_DB_LIST=""

TNAME="V\$DATABASE"
for SIDname in $list_SID; do
	ORACLE_SID=$SIDname
	DATABASE_ROLE=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
	set head off
	set pagesize 0
	SELECT DATABASE_ROLE from $TNAME;
EOF`
	case $DATABASE_ROLE in
	    "PRIMARY")
		PRIMARY_DB_LIST=${PRIMARY_DB_LIST}" "${SIDname}
		;;
	    "PHYSICAL STANDBY")
		STNDBY_DB_LIST=${STNDBY_DB_LIST}" "${SIDname}
		;;
	    *)
		;;
	esac
done
unset TNAME

echo '{'
echo '"data":['
FLG=0
for SIDname in $PRIMARY_DB_LIST; do
    ORACLE_SID=$SIDname

    TB_SPACE=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
    set head off feedback off; 
    select  tablespace_name from  dba_tablespaces ts order by 1
    /
EOF`

    if ! [[ "$TB_SPACE" == *"tablespace_name"* ]]; then
	for c_TB_SPACE in $TB_SPACE; do
	    case $c_TB_SPACE in
		"UNDOTBS1") ;;
		"SYSAUX") ;;
		"SYSTEM") ;;
		"USERS") ;;
		"TEMP") ;;
		"TEMP1") ;;
		"TEMP2") ;;
		*)
		    if [ $FLG = 0 ];then
			FLG=1
		    else
			echo -e -n ',\n'
		    fi
		    echo -e -n  '     { "{#SID_TBSNAME}" : "'
		    echo -e -n  $ORACLE_SID,$c_TB_SPACE'" }'
		    ;;
	    esac
	done
    fi
done

for SIDname in $PRIMARY_DB_LIST; do
    ORACLE_SID=$SIDname

    if [ $FLG = 0 ];then
	FLG=1
    else
	echo -e -n ',\n'
    fi
    echo -e -n  '     { "{#SID_PRIMARY_NAME}" : "'
    echo -e -n  $ORACLE_SID'" }'
done

for SIDname in $STNDBY_DB_LIST; do
    ORACLE_SID=$SIDname

    if [ $FLG = 0 ];then
	FLG=1
    else
	echo -e -n ',\n'
    fi
    echo -e -n  '     { "{#SID_STDBY_NAME}" : "'
    echo -e -n  $ORACLE_SID'" }'
done
echo -e '\n  ]'
echo -e '}'
