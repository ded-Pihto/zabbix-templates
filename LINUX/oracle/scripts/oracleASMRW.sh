#!/bin/bash
# 
# Script for read statistis read\write on ORACLE +ASM resource
# for zabbix agent
# by Khenkin D. 12/06/2021
#
# run only for user grid
# v.1.8
#
if ! [ $USER == "grid" ]; then
  echo Use this script only from user \"grid\" for Oracle ASM+
  exit 1
fi
. /home/grid/.bash_profile

if ! [ "$2" == "" ]; then
    tmpstr=`asmcmd iostat -G $2 --suppressheader 2>/dev/null`
    readarray -t RWBytesTable <<<"$tmpstr"
fi

SumBytes=0

case "$1" in
    "read" )
	for RWbytes in "${RWBytesTable[@]}"; do
	    SumBytes=$(($SumBytes +   `echo $RWbytes | awk '{print $3}'`))
        done
        echo $SumBytes
	;;
    "write" )
	for RWbytes in "${RWBytesTable[@]}"; do
	    SumBytes=$(($SumBytes +   `echo $RWbytes | awk '{print $4}'`))
        done
        echo $SumBytes
	;;
    *)
	echo "Must set parameters read|write ASMDISKGROUP"
    ;;
esac
