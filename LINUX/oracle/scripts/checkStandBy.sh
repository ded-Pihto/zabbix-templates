#!/bin/bash
#
# Script for the check a databases in Phisical StandBy mode for applying and apply delay
# Parameters: check|delay SID
# by D.Khenkin 23/04/2022
#
# example: checkStandBy.sh delay orcl 
#   run only for user oracle
# 
# v.2.2

. /home/oracle/.bash_profile

GREP=/bin/grep
FIND=/usr/bin/find
DATE=/bin/date
ECHO=/bin/echo
CAT=/bin/cat

export ORACLE_SID=$2
export tmp_check_nodata=/tmp/stndbydelay-$2.tmp

CURDATE=`$DATE +%D\ %T`

## Define functions

TNAME="V\$DATABASE"
DATABASE_ROLE=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
set head off
set pagesize 0
SELECT DATABASE_ROLE from $TNAME;
EOF`
unset TNAME

case $DATABASE_ROLE in
		"PHYSICAL STANDBY")
			case $1 in
				delay)
					TNAME="V\$ARCHIVED_LOG"
					TIME_DELAY_MINUTES=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
						set head off
						set pagesize 0
						SELECT ROUND((SYSDATE - next_time)*24*60,0) as minutes FROM $TNAME where RECID = (SELECT MAX (RECID) from  $TNAME where applied = 'YES' );
EOF`
					unset TNAME
					TIME_DELAY_MINUTES=$(( $TIME_DELAY_MINUTES + 0 ))

					if [ ${#TIME_DELAY_MINUTES} -gt 0 ] && [ ${#TIME_DELAY_MINUTES} -lt 10 ]; then
						echo $TIME_DELAY_MINUTES" "$(date +%s) > $tmp_check_nodata
					else
						if [ -e $tmp_check_nodata ]; then
							last_TIME_DELAY=`cat $tmp_check_nodata | awk '{print $1}' `
							last_timestamp=`cat $tmp_check_nodata | awk '{print $2}' `
							new_timestamp=$(date +%s)

							TIME_DELAY_MINUTES=$(( $last_TIME_DELAY + ( $new_timestamp - $last_timestamp  )/60 ))
						else
							TIME_DELAY_MINUTES="no data"
						fi
					fi

					echo $TIME_DELAY_MINUTES
					;;
				check)
					TNAME="V\$MANAGED_STANDBY"
					STANDBYE_STATUS=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
						column RECOVERY_ON format a13
						column db_name format a10
						column open_mode format a20
						column database_role format a20
						column db_unique_name format a13
						set head off
						set pagesize 0
						select count(1) from $TNAME where process like 'MRP%';
EOF`
					unset TNAME
					
					if [ ${#STANDBYE_STATUS} -gt 3 ]; then
						LOGSTDBY_STATE=0
					else
						if [ $STANDBYE_STATUS -eq 0 ]; then
							LOGSTDBY_STATE=0
						else
							LOGSTDBY_STATE=1
						fi
					fi
					echo $LOGSTDBY_STATE
			esac
			;;
		*)
			echo "no data"
			;;
esac
