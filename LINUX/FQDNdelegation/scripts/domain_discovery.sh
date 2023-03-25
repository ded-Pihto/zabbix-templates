#!/bin/bash
#
# Script for zabbix-agent. Discovery FQDN domain name from parameters and get timeleft defore end of delegation
#
# Usage :
#   domain_discovery.sh discovery|left DNS1,DNS2,DNS3,..,DNSN
#     where 
#	discovery - convert DNS's list to separete item
#	left      - get timeleft defore end of delegation
#	DNS1,DNS2,DNS3,..,DNSN - list of FQDNs, coma separation 
#
#
# v.1.0 by D.Khenkin

. /root/.bash_profile

[[ $2_ == _ ]] && echo " Usage $0 discovery|left DNS1,DNS2,DNS3,..,DNSn"\n && exit 1

command=$1
parameter=$2

case $command in
    "discovery" )
	Domain_list=$parameter
	JSON=$(for i in ${Domain_list//,/ }; do printf "{\"{#DOMAIN}\":\"$i\"},"; done | sed 's/^\(.*\).$/\1/')
#'
	printf "{\"data\":["
	printf "$JSON"
	printf "]}"
	;;

    "left" )
	DOMAIN="$parameter"
	data=$(whois $DOMAIN | grep -E 'paid|Expir|expir' | grep -o -E '[0-9]{4}.[0-9]{2}.[0-9]{2}|[0-9]{2}/[0-9]{2}/[0-9]{4}' | tr . / | awk 'NR == 1')
	expire=$((`date -d "$data" '+%s'`))
	today=$((`date '+%s'`))
	lefts=$(($expire - $today))
	leftd=$(($lefts/86400))
	echo $leftd
	;;
    *)
	echo " Usage $0 discovery|left DNS1,DNS2,DNS3,..,DNSn"\n ; exit 1
	;;
esac
