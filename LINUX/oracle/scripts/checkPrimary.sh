#!/bin/bash
#
# Script for the check status of database
# Parameters: SID
# by D.Khenkin 30/10/2022
#
# example: checkPrimary.sh orcl 
#   run only for user oracle
# 
# v.3.1

. /home/oracle/.bash_profile

[[ "$1"_ == "_" ]] && echo "Usage: $0 {SID}" && exit 1

export ORACLE_SID=$1

TNAME="V\$INSTANCE"
DATABASE_STATUS=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysdba << EOF
set head off
set pagesize 0
SELECT STATUS FROM $TNAME;
EOF`
unset TNAME

case $DATABASE_STATUS in
	"OPEN" )
# database opened
	    DATABASE_STATUS=3
	    ;;
# database mounted
	"MOUNTED" )
	    DATABASE_STATUS=2
	    ;;
# database started in "no mount" mode
	"STARTED" )
	    DATABASE_STATUS=1
	    ;;
	*)
# shutdown or not exist
	    DATABASE_STATUS=0
	    ;;
esac
echo $DATABASE_STATUS
