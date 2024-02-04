#!/bin/env bash
#
# Script get information about instances
#	 get information of tablespaces ( free, used, total ) in tablespaces of PRIMARY databases
#	 get information of status ( applying, apply gap ) for PHYSICAL STANDBY database
# Parameters:
# 		none - get instances list
#		GET_TABLESPACES_STATISTIC
#		GET_RECOVERY_INFO
#		GET_INSTANCES_INFO
#		GET_DESTINATION_INFO
#
# by D.Khenkin 31.10.2023
#
# v.7.2
#

if ! [ $USER == "oracle" ]; then
  echo Use this script only from user \"oracle\" for Oracle Database
  exit 1
fi

## declare function
function DELAIED_GET() {
cmdSTRING=$1
TMPFILE=/tmp/$cmdSTRING.tmp
    if [ -f $TMPFILE ]; then
	TMPJSON=`cat $TMPFILE`
	if [ ${TMPJSON:0-1} == ']' ]; then
#	    echo $TMPJSON
	    cat $TMPFILE
	    rm  $TMPFILE
    	    /bin/bash $0 $cmdSTRING\_INT >$TMPFILE 2>/dev/null & >/dev/null 2>/dev/null
	else
#	    cat $TMPFILE
	    if !( ps ax | grep -v grep | grep $TMPFILE ); then
		/bin/bash $0 $cmdSTRING\_INT >$TMPFILE 2>/dev/null & >/dev/null 2>/dev/null
	    fi
	fi
    else
	echo []
	/bin/bash $0 $cmdSTRING\_INT >$TMPFILE 2>/dev/null & >/dev/null 2>/dev/null
    fi
}

function GET_TABLESPACES_STATISTIC_INT {
#. $(dirname $0)/get_tablespaces_statistics.sh
# get tablespace statistics for all instances
      echo '['
      FLG=0
      for SIDname in $list_SID_online; do
        export ORACLE_SID=$SIDname

        TNAME="V\$DATABASE"
        DATABASE_ROLE=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
set head off
set pagesize 0
SELECT DATABASE_ROLE from $TNAME;
EOF`

	case $DATABASE_ROLE in
		"PRIMARY")
			space_result=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
    set head off;
    set feedback off;
    set pagesize 0
    SET NUMF 9999999999999999999;

SELECT json_object(
        'name'    value Tablespace,
        'used'    value Used,
        'free'    value Free,
        'total'   value Total,
        'maxsize' value MaxSize,
        'utilize' value Utilize
	) DATABASE_SPACES
    FROM
 (
select b.tablespace_name as Tablespace , tbs_size - a.free_space AS Used, a.free_space Free, tbs_size Total, b.tbs_max MaxSize, round((tbs_size - a.free_space)/tbs_size * 100,2) AS Utilize
from  (select tablespace_name, sum(bytes) as free_space from dba_free_space group by tablespace_name) a,
      (select tablespace_name, sum(bytes) as tbs_size, sum(Maxbytes) as tbs_max   from dba_data_files group by tablespace_name) b
where a.tablespace_name(+)=b.tablespace_name
     UNION
     SELECT
	tfs.TABLESPACE_NAME 			     Tablespace,
	tfs.ALLOCATED_SPACE                          Used,
	tfs.FREE_SPACE                               Free,
	(tfs.ALLOCATED_SPACE + tfs.FREE_SPACE)       Total,
	(tfs.ALLOCATED_SPACE + tfs.FREE_SPACE)       MaxSize,
	ROUND(100*tfs.ALLOCATED_SPACE/(tfs.ALLOCATED_SPACE + tfs.FREE_SPACE),2) Utilize
	from dba_temp_free_space tfs
);

EOF`
			space_result=`echo ${space_result}`
			space_result=${space_result// /}
			Findstr='\}\{'
			Newstr='},{'

			if [ $FLG = 0 ];then
			    FLG=1
			else
			    echo -e -n ',\n'
			fi

			echo '{'
			echo '"SID" : "'$ORACLE_SID'", "info" : [{'
			echo '"role" : "Primary",'
#			echo '"openmode":"'$OPEN_MODE'",'
#			echo '"status":"'$DATABASE_STATUS'",'
			echo '"tablespace":'
			echo '['${space_result//$Findstr/$Newstr}']'
			echo '}]'
			echo '}'
		;;
                "PHYSICAL STANDBY")
            		tmp_check_nodata=/tmp/stndbydelay-$2.tmp
                        TNAME="V\$ARCHIVED_LOG"
                        TIME_DELAY_MINUTES=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
set head off
set pagesize 0
SELECT ROUND((SYSDATE - next_time)*24*60,0) as minutes FROM $TNAME where RECID = (SELECT MAX (RECID) from  $TNAME where applied = 'YES' );
EOF`
                        unset TNAME
                        TIME_DELAY_MINUTES=${TIME_DELAY_MINUTES//no rows selected/}
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

			if [ $FLG = 0 ];then
			    FLG=1
			else
			    echo -e -n ',\n'
			fi

			echo '{'
			echo '"SID" : "'$ORACLE_SID'", "info" : [{'
			echo '"role" : "Physical Standby",'
			echo '"delay":"'$TIME_DELAY_MINUTES'",'
                        echo '"apply":"'$LOGSTDBY_STATE'"'
                        echo '}]'
			echo '}'

                ;;
		*)
			echo ''
		;;
	esac
      done
      echo ']'
# end function GET_TABLESPACES_STATISTIC
}

function GET_RECOVERY_INFO_INT {
#. $(dirname $0)/get_recovery_info.sh
# get tablespace statistics for all instances
      echo '['
      FLG=0
      for SIDname in $list_SID_online; do
        export ORACLE_SID=$SIDname

        TNAME="v\$recovery_file_dest"
        RECOVERY_STAT=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF

set head off;
set feedback off;
set pagesize 0;
set NUMF 9999999999999999999;
col name     format a32;

SELECT json_object(
        'FRA_dest'	value name,
        'FRA_used'    	value space_used,
        'FRA_limit'   	value space_limit
	) RECOVERY_SPACES
    FROM
 (
select
    name,
    space_limit,
    space_used
from
    $TNAME
);

EOF`

	unset TNAME

	RECOVERY_STAT=`echo ${RECOVERY_STAT}`
	RECOVERY_STAT=${RECOVERY_STAT// /}
	Findstr='\}\{'
	Newstr='},{'

	if [ $FLG = 0 ];then
	    FLG=1
	else
	    echo -e -n ',\n'
	fi
	echo '{'
	echo '"SID" : "'$ORACLE_SID'", "info" : [{'
	echo '"FRA":'
	echo '['${RECOVERY_STAT//$Findstr/$Newstr}']'
	echo '}]'
	echo '}'

      done
      echo ']'
# end function GET_RECOVERY_INFO
}

function GET_DESTINATION_INFO_INT {
#. $(dirname $0)/get_destination_info.sh
# get tablespace statistics for all instances
      echo '['
      FLG=0
      for SIDname in $list_SID_online; do
        export ORACLE_SID=$SIDname

        TNAME="V\$ARCHIVE_DEST"
        ARC_DEST=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF

set head off;
set feedback off;
set pagesize 0;
set NUMF 9999999999999999999;
col name     format a32;

SELECT json_object(
        'SID':'$SIDname',
        'dest_name'     value DEST_NAME,
        'status'        value STATUS,
        'target'        value TARGET,
        'destination'   value DESTINATION,
        'transmit_mode' value TRANSMIT_MODE,
        'valid_role'    value VALID_ROLE,
        'compression'   value COMPRESSION,
        'encryption'    value ENCRYPTION
	) 
    FROM
 (select * from $TNAME WHERE VALID_NOW = 'YES');

EOF`
	unset TNAME

	ARC_DEST=`echo ${ARC_DEST}`
	ARC_DEST=${ARC_DEST// /}
	Findstr='\}\{'
	Newstr='},{'

	if [ $FLG = 0 ];then
	    FLG=1
	else
	    echo -e -n ',\n'
	fi
	echo '{'
	echo '"SID" : "'$ORACLE_SID'", "info" : [{'
	echo '"archive_dest":'
	echo '['${ARC_DEST//$Findstr/$Newstr}']'
	echo '}]'
	echo '}'

      done
      echo ']'
# end function GET_DESTINATION_INFO
}

function GET_INSTANCES_INFO_INT {
#. $(dirname $0)/get_instances_info.sh
# get instances info
      echo '['
      FLG=0
      for SIDname in $list_SID; do
        export ORACLE_SID=$SIDname

        TNAME="V\$DATABASE"
        DATABASE_ROLE=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
set head off
set pagesize 0
SELECT DATABASE_ROLE from $TNAME;
EOF`
        OPEN_MODE=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
set head off;
set feedback off;
set pagesize 0
select OPEN_MODE from $TNAME;
quit
EOF`
        unset TNAME

        TNAME="V\$INSTANCE"
        DATABASE_STATUS=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
set head off
set pagesize 0
SELECT STATUS FROM $TNAME;
EOF`
        unset TNAME

	case $DATABASE_ROLE in
		"PRIMARY")

			if [ $FLG = 0 ];then
			    FLG=1
			else
			    echo -e -n ',\n'
			fi

			echo '{'
			echo '"SID" : "'$ORACLE_SID'", "info" : [{'
			echo '"role" : "Primary",'
			echo '"openmode":"'$OPEN_MODE'",'
			echo '"status":"'$DATABASE_STATUS'"'
                        echo '}]'
			echo '}'
		;;
                "PHYSICAL STANDBY")
            		tmp_check_nodata=/tmp/stndbydelay-$ORACLE_SID.tmp
                        TNAME="V\$ARCHIVED_LOG"
                        TIME_DELAY_MINUTES=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
set head off
set pagesize 0
SELECT ROUND((SYSDATE - next_time)*24*60,0) as minutes FROM $TNAME where RECID = (SELECT MAX (RECID) from  $TNAME where applied = 'YES' );
EOF`
                        unset TNAME
                        TIME_DELAY_MINUTES=${TIME_DELAY_MINUTES//no rows selected/}
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

			if [ $FLG = 0 ];then
			    FLG=1
			else
			    echo -e -n ',\n'
			fi

			echo '{'
			echo '"SID" : "'$ORACLE_SID'", "info" : [{'
			echo '"role" : "Physical Standby",'
			echo '"openmode":"'$OPEN_MODE'",'
			echo '"status": "'$DATABASE_STATUS'",'
			echo '"delay":"'$TIME_DELAY_MINUTES'",'
                        echo '"apply":"'$LOGSTDBY_STATE'"'
                        echo '}]'
			echo '}'

                ;;
		*)
			if ! [[ ${list_SID_online[@]} =~ $SIDname ]]; then
			    if [ $FLG = 0 ];then
				FLG=1
			    else
				echo -e -n ',\n'
			    fi

			    echo '{'
			    echo '"SID" : "'$ORACLE_SID'", "info" : [{'
			    echo '"role" : "UNKNOWN",'
			    echo '"openmode":"NOT STARTED",'
			    echo '"status": "NOT STARTED"'
                    	    echo '}]'
			    echo '}'
			fi
		;;
	esac
      done
      echo ']'

# end function GET_INSTANCES_INFO
}

## end declare function

. /home/oracle/.bash_profile

# qwery database instances & tablespaces
list_SID_online=`ps -ef | grep pmon | grep -v grep | grep -v sed | grep -v +ASM | grep -v +APX | awk '{print $8}' | sed "s/ora_pmon_//g"`
IFS=" "; list_SID_online=($list_SID_online); unset IFS;

list_SID=`cat /etc/oratab | grep "^[^#+;]" | sed "s/:.*//g"`
IFS=" "; list_SID=($list_SID); unset IFS;

PRIMARY_DB_LIST=""
STNDBY_DB_LIST=""
NOTSTARTED_DB_LIST=""
TNAME="V\$DATABASE"
for SIDname in $list_SID; do
    if [[ ${list_SID_online[@]} =~ $SIDname ]]; then
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
    else
	NOTSTARTED_DB_LIST=${NOTSTARTED_DB_LIST}" "${SIDname}
    fi

done
unset TNAME

if [ $1'_' == '_' ]; then
# if no parameters - print JSON with instances info
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
	FLG1=0
        if [ $FLG = 0 ];then
	    FLG=1
	else
	    echo -e -n ',\n'
        fi
	echo -e -n  '     { "INSTANCE" : "'
        echo -e -n  $ORACLE_SID'",'
	echo -e -n '\n       "TBS":\n         [\n'
        if ! [[ "$TB_SPACE" == *"tablespace_name"* ]]; then
	    for c_TB_SPACE in $TB_SPACE; do
		if [ $FLG1 = 0 ];then
		    FLG1=1
		else
		    echo -e -n ',\n'
		fi
		echo -e -n  '            {"PRIMARY_INSTANCE":"'$ORACLE_SID'","TABLESPACE":"'$c_TB_SPACE'"}'
	    done
	fi
	echo -e -n '\n         ]}'
    done

    for SIDname in $STNDBY_DB_LIST; do
	ORACLE_SID=$SIDname

	if [ $FLG = 0 ];then
	    FLG=1
	else
	    echo -e -n ',\n'
	fi
	echo -e -n  '     { "INSTANCE" : "'$ORACLE_SID'", \n'
	echo -e -n  '          "PHYSICAL_STNDBY" : [{ "STNDBY_INSTANCE" : "'$ORACLE_SID'" } ]}'
    done

    for SIDname in $NOTSTARTED_DB_LIST; do
	ORACLE_SID=$SIDname

	if [ $FLG = 0 ];then
	    FLG=1
	else
	    echo -e -n ',\n'
	fi
	echo -e -n  '     { "INSTANCE" : "'$ORACLE_SID'", \n'
	echo -e -n  '          "NOT_STARTED" : [{ "NOTSTARTED_INSTANCE" : "'$ORACLE_SID'" } ]}'
    done

    echo -e '\n  ]'
    echo -e '}'
else
  case ${1^^} in
    'GET_TABLESPACES_STATISTIC' )
        DELAIED_GET GET_TABLESPACES_STATISTIC
    ;;
    'GET_TABLESPACES_STATISTIC_INT' )
        GET_TABLESPACES_STATISTIC_INT
    ;;
    'GET_INSTANCES_INFO' )
        DELAIED_GET GET_INSTANCES_INFO
    ;;
    'GET_INSTANCES_INFO_INT' )
        GET_INSTANCES_INFO_INT
    ;;
    'GET_RECOVERY_INFO' )
        DELAIED_GET GET_RECOVERY_INFO
    ;;
    'GET_RECOVERY_INFO_INT' )
        GET_RECOVERY_INFO_INT
    ;;
    'GET_DESTINATION_INFO' )
        DELAIED_GET GET_DESTINATION_INFO
    ;;
    'GET_DESTINATION_INFO_INT' )
        GET_DESTINATION_INFO_INT
    ;;
    *)
    ;;
  esac
fi
