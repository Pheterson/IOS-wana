####
## Project name:    wana
##  Description:    Web log analyzer
##                  Program is written in shell script
##      Subject:    Operating Systems
##       Author:    Peter Koprda
##       School:    Faculty of Information Technology, Brno University of Technology
##         Date:    March 2019
####

#!/bin/sh

POSIXLY_CORRECT=yes

## This function prints out source IP addresses
list_ip()
{
    while [ "$#" -gt "0" ]
    do
        echo "$1" | grep -o -E  '^([A-Fa-f0-9]{0,4}\:){1,7}[A-Fa-f0-9]{0,4}' | sort --unique      #IPv6
        echo "$1" | grep -o -E  '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sort --unique  #IPv4
        shift
    done
}

## This function prints out source domain names
list_hosts()
{        
    while [ "$#" -gt "0" ]
    do
        ips="$(echo "$1" | awk -F- '{print $1}' | sort --unique )"
        for i in $ips
        do
            hosts=$( host "$i" | awk -F" " '{print $NF}' )
            if [ "$hosts" = "3(NXDOMAIN)" ] 2>dev>null; then
                echo "$i"
            elif [ "$hosts" = "2(SERFAIL)" ] 2>dev>null; then
                echo "$i"
            else
                echo "$hosts"
            fi
        done
        shift
    done
}

## This function prints out list of uniform resource identifier (URI)
list_uri()
{
    while [ "$#" -gt "0" ]
    do
        echo "$1" | awk '{
            if($6=="\"GET" || $6=="\"POST" || $6=="\"HEAD")
            print $7;
            }'|sort -u
        shift
    done
}

## This function prints out histogram of sum by source IP addresses
hist_ip()
{
    while [ "$#" -gt "0" ]
    do
        adress=$(echo "$1" | awk '{print $1}'  |sort | uniq -c | sort -r) 
        echo ${adress} | awk '{
            for(i=1;i<=$NR;i++)
            {
                printf $(2*i)" (" $(2*i-1) "): ";
                for(j=0;j<$(2*i-1);j++)
                {
                    printf "#"
                }
                print "" 
            } 
        }' 
        shift
    done
}

## This function prints out histogram of load
hist_load()
{
    while [ "$#" -gt "0" ]
    do
        TIMELOAD=$(echo "$1" | awk '{print $4}' | tr -d "[" | sed 's/\// /' | sed 's/\// /' | sed 's/:/ /g')
        
        TIMELOAD=$(echo "$TIMELOAD" | awk '{t = $1; 
                    $1=$3; 
                    $3=t;
                    print;
                    }')

        TIMELOAD=$(echo "$TIMELOAD" | sed 's/Jan/01/' | sed 's/Feb/02/' | sed 's/Mar/03/' | sed 's/Apr/04/' | sed 's/May/05/' | 
        sed 's/Jun/06/' | sed 's/Jul/07/' | sed 's/Aug/08/' | sed 's/Sep/09/' | sed 's/Oct/10/' | sed 's/Nov/11/' | sed 's/Dec/12/')
        TIMELOAD=$(echo "$TIMELOAD" | sed 's/ /-/' | sed 's/ /-/' )
        echo "$TIMELOAD"
        shift
    done
}

## FIlter for date and time in stdin
datetimefilter()
{
    DATE=$(echo "$2" | awk '{print $1}')
    TIME=$(echo "$2" | awk '{print $2}')
    if  [ "$DATE" != "$(echo "$DATE" | grep -E '[12][0-9]{3}-(0?[1-9]|10|11|12)-(0?[1-9]|[12][0-9]|3[01])')" ]; then 
        (>&2 echo "Invalid date")
        exit 1
    fi
    if  [ "$TIME" != "$(echo "$TIME" | grep -E '([0-9]|0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]')" ]; then
        (>&2 echo "Invalid time")
        exit 1
    fi
                
    DATE=$(echo "$DATE" | tr -d '-')
    TIME=$(echo "$TIME" | tr -d ':')

    if [ "$1" = "-a" ]; then
        DATETIMEA="$DATE$TIME"
    else
        DATETIMEB="$DATE$TIME"
    fi           
}

## Filter for date and time in log files
date_filter()
{
    LOGS="$3"
    DATE=$(echo "$LOGS" | awk '{print $4}' | tr -d '[' | sed 's/\// /' | sed 's/\// /' | sed 's/:/ /' | tr -d ':')
    DATE=$(echo "$DATE" | awk '{t = $1; 
                    $1=$3; 
                    $3=t;
                    print;
                    }')
    DATE=$(echo "$DATE" | sed 's/Jan/01/' | sed 's/Feb/02/' | sed 's/Mar/03/' | sed 's/Apr/04/' | sed 's/May/05/' | sed 's/Jun/06/' |
                        sed 's/Jul/07/' | sed 's/Aug/08/' | sed 's/Sep/09/' | sed 's/Oct/10/' | sed 's/Nov/11/' | sed 's/Dec/12/')
    DATE=$(echo "$DATE" | tr -d ' ')

    if [ "$1" = "-a" ];then
        LOGS=$(echo "$LOGS" | awk '{
                            if($DATE>$DATETIMEA)
                            {
                                LOGS=$DATE
                            }
                       }')
    fi

    #echo "$LOGS"
    if [ "$1" = "-b" ];then
        LOGS=$(echo "$LOGS" | awk '{
                            if($DATE<$DATETIMEB)
                            {
                                LOGS=$DATE
                            }
                        }')
    fi
    
}

## Filter for ip addresses
ip_filter()
{
    IP="$1"
    LOGS="$2"
    LOGS=$(echo "$LOGS" | grep -E "$IP")
}

## Filter for uri addresses
uri_filter()
{
    URI=$(echo "$1" | awk '{print $1}')
    LOGS="$2"
    LOGS=$(echo "$LOGS" | grep -E "$URI")
}


########################################
################# MAIN #################

if [ "$1" != "list-ip" ] && [ "$1" != "list-hosts" ] && [ "$1" != "list-uri" ] && [ "$1" != "hist-ip" ] && [ "$1" != "hist-load" ] &&
    [ "$1" != "-a" ] && [ "$1" != "-b" ] && [ "$1" != "-ip" ] && [ "$1" != "-uri" ];then
    while [ "$#" -gt "0" ]
    do
        if [ -f "$1" ]; then
            if  echo "$1" | grep -Eq '\w*gz\b'
            then
                LOGS="$LOGS $(gunzip -c "$1")"
            else
                LOGS="$LOGS $(cat "$1")"
            fi
        fi
        shift
    done
    echo "$LOGS"
    exit 0
fi

case "$1" in
        list-ip)
            shift
            command="list-ip"
            ;;
        list-hosts)
            shift
            command="list-hosts"
            ;;
        list-uri)
            shift
            command="list-uri"
            ;;
        hist-ip)
            shift
            command="hist-ip"
            ;;
        hist-load)
            shift
            command="hist-load"
            ;;
esac

########## NO LOGS ##########
if [ "$#" -eq "0" ] ; then
    LOGS="$(cat)"
fi

TIMEATRIGGER=false
TIMEAERROR=0

TIMEBTRIGGER=false
TIMEBERROR=0

IPTRIGGER=false
IPERROR=0

URITRIGGER=false
URIERROR=0

while [ "$#" -gt "0" ]
do
    case "$1" in
        -a)
            TIMEATRIGGER=true
            TIMEAERROR=$TIMEAERROR+1
            if [ "$TIMEAERROR" = "2" ];then
                (>&2 echo "Two same date filters!")
                exit 1
            fi
            datetimefilter "$1" "$2" #check date and time
            shift 2
            ;;
        -b)
            TIMEBTRIGGER=true
            TIMEBERROR=$TIMEBERROR+1
            if [ "$TIMEBERROR" = "2" ];then
                (>&2 echo "Two same date filters!")
                exit 1
            fi
            datetimefilter "$1" "$2" #check date and time
            shift 2
            ;;
        -ip)
            IPADDR="$2"
            IPTRIGGER=true
            IPERROR=$IPERROR+1
            if [ "$IPERROR" = "2" ];then
                (>&2 echo "Two ip filters!")
                exit 1
            fi
            if [ "$IPADDR" = "$(echo "$IPADDR" | grep -o -E '^([A-Fa-f0-9]{0,4}\:){1,7}[A-Fa-f0-9]{0,4}')" ] ||
            [ "$IPADDR" = "$(echo "$IPADDR" | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')" ]; then
                shift 2 
            else
                (>&2echo "Wrong IP!")
                exit 1
            fi
            ;;
        -uri)
            URI="$2"
            URITRIGGER=true
            URIERROR=$URIERROR+1
            if [ "$URIERROR" = "2" ]; then
                (>&2 echo "Two uri filters!")
                exit 1
            fi
            shift 2
            ;;
        *)
            if [ -f "$1" ]; then
                    if  echo "$1" | grep -Eq '\w*gz\b'
                    then
                        LOGS="$LOGS $(gunzip -c "$1")"
                    else
                        LOGS="$LOGS $(cat "$1")"
                    fi
                    shift
            else
                if [ "$1" != "list-ip" ] && [ "$1" != "list-hosts" ] && [ "$1" != "list-uri" ] && [ "$1" != "hist-ip" ] && [ "$1" != "hist-load" ];then
                    (>&2 echo "Wrong filter")
                    exit 1
                fi
                shift
            fi
            ;;
    esac
done

case "$1" in
        list-ip)
            shift
            command="list-ip"
            ;;
        list-hosts)
            shift
            command="list-hosts"
            ;;
        list-uri)
            shift
            command="list-uri"
            ;;
        hist-ip)
            shift
            command="hist-ip"
            ;;
        hist-load)
            shift
            command="hist-load"
            ;;
esac

########## TRIGGERS FOR FILTERS ##########
if [ "$TIMEATRIGGER" = true ]; then
    date_filter "-a" "$DATETIMEA" "$LOGS"
fi

if [ "$TIMEBTRIGGER" = true ]; then
    date_filter "-b" "$DATETIMEB" "$LOGS"
fi

if [ "$IPTRIGGER" = true ]; then
    ip_filter "$IP" "$LOGS"
fi

if [ "$URITRIGGER" = true ]; then 
    uri_filter "$URI" "$LOGS" 
fi


########## COMMANDS ##########
case "$command" in
    list-ip)
        list_ip "$LOGS" |sort -u
        ;;
    list-hosts)
        list_hosts "$LOGS" |sort -u
        ;;
    list-uri)
        list_uri "$LOGS" |sort -u
        ;;
    hist-ip)
        hist_ip "$LOGS"
        ;;
    hist-load)
        hist_load "$LOGS"
        ;;    
esac

exit 0

