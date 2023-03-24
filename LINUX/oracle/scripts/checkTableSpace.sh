#!/bin/bash
#
# Script for the check spaces ( free, used, total ) in tablespaces of databases
# Parameters:
#		$1 type of request ( used|free|total )
# 		$2 SID or name of tablespace for check in format "SID,Name_of_tablespace"
#		$3 Name_of_tablespace when use SID in second parameter
#
# by D.Khenkin 23/04/2022
#
# example: checkTableSpace.sh free orcl,system or checkTableSpace.sh free orcl system 
#   run only for user oracle
#
# v.3.1
#
. /home/oracle/.bash_profile

if [ $3'_' == '_' ]; then
    IFS=","; TMPparam=($2); unset IFS;
    ORACLE_SID=${TMPparam[0]}
    TBS_NAME=\'${TMPparam[1]}\'
else
    ORACLE_SID=$2
    TBS_NAME=\'$3\'
fi
export ORACLE_SID

## Define functions

TNAME="V\$DATABASE"
DATABASE_ROLE=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
set head off
set pagesize 0
SELECT DATABASE_ROLE from $TNAME;
EOF`
unset TNAME

case $DATABASE_ROLE in
		"PRIMARY")
			case $1 in
				used)
_SPACE=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
    set head off
    set pagesize 0
    SET NUMF 9999999999999999999;
    select ROUND(nvl(Sum(Bytes), 0)/1024/1024) as used from dba_segments where TABLESPACE_NAME=$TBS_NAME group by TABLESPACE_NAME;
EOF`
				;;
				free)
_SPACE=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
    set head off
    set pagesize 0
    SET NUMF 9999999999999999999;
    select round ((sum(bytes)/1024/1024), 0) as free from sys.dba_free_space where tablespace_name=$TBS_NAME group by TABLESPACE_NAME;
EOF`
				;;
				total)
_SPACE=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
    set head off
    set pagesize 0
    SET NUMF 9999999999999999999;
    select round ((sum(bytes)/1024/1024), 0) as total from  sys.dba_data_files where tablespace_name=$TBS_NAME group by TABLESPACE_NAME;
EOF`
				;;
				*)
				;;
			esac

			if ! [ `echo $_SPACE | awk '{print $2}'`'_' == '_' ]; then
				echo '-'
				exit
			fi

			if [[ $_SPACE'_' == '_' ]]; then
				echo '-'
				exit
			fi

			echo `echo $_SPACE | awk '{print $1}'`
			;;
		*)
			echo "no data"
			;;
esac

