#!/bin/bash
# 
# Script for the check a space in ORACLE +ASM resource
# for zabbix agent
# by Khenkin D. 04/01/2022
#
# run only for user grid
# v.1.9
#
if ! [ $USER == "grid" ]; then
  echo Use this script only from user \"grid\" for Oracle ASM+
  exit 1
fi

. /home/grid/.bash_profile

SYSTEMTBS="v\$asm_Disk"

FuncGetASMdata() {
IFS=' ' read -r -a OUTSTR <<<`asmcmd lsdg -g $1 2>/dev/null | grep State`
for column_num in  "${!OUTSTR[@]}"
do
    case ${OUTSTR[$column_num]} in
	"Total_MB")
	    TOTAL_INDEX=$((column_num + 1))
	;;
	"Free_MB")
	    FREE_INDEX=$((column_num + 1))
	;;
	*)
        ;;
    esac
done

OUTSTR=`asmcmd lsdg -g $1 --suppressheader 2>/dev/null`

TOTAL=`echo $OUTSTR | awk -v position=$TOTAL_INDEX '{printf $position }'`
FREE=`echo $OUTSTR | awk -v position=$FREE_INDEX '{printf $position }'`
USED=$(($TOTAL - $FREE))
PFREE=$(echo "scale=3; 100 * $FREE / $TOTAL" | bc)
}

FuncGetASMwithCandidate() {
TOTAL_WITH_CANDIDATE=`$ORACLE_HOME/bin/sqlplus -SILENT / as sysasm << EOF
    set head off
    set pagesize 0
    SET NUMF 9999999999999999999;
    select sum(os_mb) as TOTAL from $SYSTEMTBS;
EOF`
}

FuncQueryASMGroup() {
IFS=' ' read -r -a OUTSTR <<<`asmcmd lsdg 2>/dev/null | grep State`
for column_num in  "${!OUTSTR[@]}"
do
    case ${OUTSTR[$column_num]} in
	"Name")
	    NAME_INDEX=$((column_num + 1))
	;;
	*)
        ;;
    esac
done

IFS='/' read -r -a OUTSTR <<<`asmcmd lsdg --suppressheader 2>/dev/null`

echo '{'
echo '"data":['
FLG=0
for asmGroupInfo in  "${OUTSTR[@]}"
do
    ASM_GROUP_NAME=`echo $asmGroupInfo | awk -v position=$NAME_INDEX '{printf $position }'`


    if [ $FLG = 0 ];then
	FLG=1
    else
	echo -e -n ',\n'
    fi
    echo -e -n  '     { "{#ASM_GROUP}" : "'
    echo -e -n  $ASM_GROUP_NAME'" }'
done

echo -e '\n  ]'
echo -e '}'
}

case $1 in
    queryASM)
	FuncQueryASMGroup
	OUTSTR=""
	;;
    total)
	FuncGetASMdata $2
	OUTSTR=$TOTAL
	;;
    free)
	FuncGetASMdata $2
	OUTSTR=$FREE
	;;
    used)
	FuncGetASMdata $2
	OUTSTR=$USED
	;;
    pfree)
	FuncGetASMdata $2
	OUTSTR=$PFREE
	;;
    reserv)
	FuncGetASMwithCandidate
	OUTSTR=$TOTAL_WITH_CANDIDATE
	;;
    *)
	echo "Run as grid user only"
	echo "Must be $0 queryASM|free|pfree|used|total|reserv [ASMgroup]"
	OUTSTR=""
	;;
esac

echo $OUTSTR
