#!/bin/sh

POSIXLY_CORRECT=yes

usage(){
cat << EOF
Usage: ./wana.sh [FILTER] [COMMAND] [LOG [LOG2 [...]]]
View and filter web log files.

Filters:
    -a DATETIME         show queries after this date; 
                        DATETIME must be in format YYYY-MM-DD HH:MM:SS
    -b DATETIME         show queries before this date;
                        DATETIME must be in format YYYY-MM-DD HH:MM:SS
    -ip IPADDR          show queries from this source address IPADDR;
                        IPADDR must be IPv4 or IPv6
    -uri URI            show queries of requests on the webpage URI;
                        URI is standard regular expression

Commands:
    list-ip             list of source IP adresses
    list-hosts          list of source domain names
    list-uri            list of destination sources (URI)
    hist-ip             create histogram of source IPs
    hist-load           create histogram of load

Other options:
    -h, --help          display this help and exit

EOF
}

get_list_ip(){
    echo "$1" | awk '{print $1}' | sort --unique
}

get_list_hosts(){
    IP_ADDRS=$(get_list_ip "$1" | sed 's/\n/ /g')
    for ip in $IP_ADDRS
    do
        host_name=$(host "$ip" | awk '{print $NF}')
        if [ "$host_name" = "3(NXDOMAIN)" ] || [ "$host_name" = "2(SERFAIL)" ] 2>/dev/null; then
            echo "$ip"
        else
            echo "$host_name" | awk 'NR==1'
        fi
    done
}

get_list_uri(){
    echo "$1" | awk '$7 ~ /(\/.*)/ { print $7}' | sort --unique
}

get_hist_ip(){
    echo "$1" | awk '{print $1}' | sort | uniq -c | sort -nrk1 | 
        awk '{printf $2 " ("$1"): "
            for(i=0; i<$1; i++) {printf "#"}
            print ""
        }'
}

get_hist_load(){
    echo "$1" | awk '{print substr($4,2)}' | 
        awk -F "/" '{
            printf substr($3,0,4)"-";
            if($2 == "Jan") "01";
            else if($2 == "Feb") printf "02";
            else if($2 == "Mar") printf "03";
            else if($2 == "Apr") printf "04";
            else if($2 == "May") printf "05";
            else if($2 == "Jun") printf "06";
            else if($2 == "Jul") printf "07";
            else if($2 == "Aug") printf "08";
            else if($2 == "Sep") printf "09";
            else if($2 == "Oct") printf "10";
            else if($2 == "Nov") printf "11";
            else if($2 == "Dec") printf "12";
            print "-"$1"-"substr($3,6,2)"-00"
        }' | sort | uniq -c |
            awk '{printf $2 " ("$1"): "
                for(i=0; i<$1; i++) {printf "#"}
                print ""
            }' | sed -e 's/\-/ /3' -e 's/\-/:/3'
}

date_to_num(){
    echo "$1" |
        awk '{
            gsub("Jan","01",$4);
            gsub("Feb","02",$4);
            gsub("Mar","03",$4);
            gsub("Apr","04",$4);
            gsub("May","05",$4);
            gsub("Jun","06",$4);
            gsub("Jul","07",$4);
            gsub("Aug","08",$4);
            gsub("Sep","09",$4);
            gsub("Oct","10",$4);
            gsub("Nov","11",$4);
            gsub("Dec","12",$4);
            gsub(/\[/, "", $4);
            $4=substr($4,7,4)substr($4,4,2)substr($4,1,2)substr($4,12,8);
            gsub(":", "", $4);
            print
        }'
}

num_to_date(){
    echo "$1" | awk '{
        month=substr($4,5,2);
        if(month == "01") tmp="["substr($4,7,2)"/Jan";
        else if(month == "02") tmp="["substr($4,7,2)"/Feb";
        else if(month == "03") tmp="["substr($4,7,2)"/Mar";
        else if(month == "04") tmp="["substr($4,7,2)"/Apr";
        else if(month == "05") tmp="["substr($4,7,2)"/May";
        else if(month == "06") tmp="["substr($4,7,2)"/Jun";
        else if(month == "07") tmp="["substr($4,7,2)"/Jul";
        else if(month == "08") tmp="["substr($4,7,2)"/Aug";
        else if(month == "09") tmp="["substr($4,7,2)"/Sep";
        else if(month == "10") tmp="["substr($4,7,2)"/Oct";
        else if(month == "11") tmp="["substr($4,7,2)"/Nov";
        else if(month == "12") tmp="["substr($4,7,2)"/Dec";
        $4=tmp"/"substr($4,1,4)":"substr($4,9,2)":"substr($4,11,2)":"substr($4,13,2);
        print
    }'
}


get_logs_after(){
    num_to_date "$(date_to_num "$1" | awk -v date_after="$2" '$4 > date_after')"
}

get_logs_before(){
    num_to_date "$(date_to_num "$1" | awk -v date_before="$2" '$4 < date_before')"
}

get_logs_ip(){
    echo "$1" | awk -v ip_source="$2" '$1 == ip_source'
}

get_logs_uri(){
    echo "$1" | awk -v uri_regex="$2" '$7~uri_regex {print}' 2>/dev/null
}

is_valid_date(){
    echo "$1" | grep -o -E '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-2]{1}[0-9]{1}(:[0-6]{1}[0-9]{1}){2}$' 1>/dev/null
}


list_ip=false
list_hosts=false
list_uri=false
hist_ip=false
hist_load=false
LOGS=

while [ "$1" != "" ]; do
    PARAM=$(echo "$1" | awk -F= '{print $1}')
    case "$PARAM" in
        
        # Help command
        -h|--help)
            usage
            exit 0;;

        # Commands
        list-ip)
            list_ip=true
            shift;;
        list-hosts)
            list_hosts=true
            shift;;
        list-uri)
            list_uri=true
            shift;;
        hist-ip)
            hist_ip=true
            shift;;
        hist-load)
            hist_load=true
            shift;;

        # Filters
        -a)
            is_valid_date "$2"
            is_valid=$?
            if [ $is_valid -ne 0 ]; then
                echo "Wrong datetime format! Valid datetime format is YYYY-MM-DD HH:MM:SS"
                exit 1
            fi
            after_datetime_val=$(echo "$2" | sed -e 's/-//g' -e 's/://g' -e 's/ //g')
            shift 2;;
        -b)
            is_valid_date "$2"
            is_valid=$?
            if [ $is_valid -ne 0 ]; then
                 echo "Wrong datetime format! Valid datetime format is YYYY-MM-DD HH:MM:SS"
                 exit 1
            fi
            before_datetime_val=$(echo "$2" | sed -e 's/-//g' -e 's/://g' -e 's/ //g')
            shift 2;;
        -ip)
            ip_filter_val="$2"
            check_ip="$(echo "$ip_filter_val" | grep -o -E '(^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$)|(([A-Fa-f0-9]{0,4}\:){1,7}[A-Fa-f0-9]{0,4})')"

            if [ "$check_ip" = "" ]; then
                echo "Wrong format of IPv4 or IPv6!"
                exit 1
            fi
            shift 2;;
        -uri)
            uri_filter_val="$2"
            shift 2;;

        # Log files
        *.gz)
            LOGS="$LOGS
$(gunzip -c "$(echo "$1" | awk '{print $1}')")"
            shift;;
        *.log*)
            LOGS="$LOGS
$(cat "$(echo "$1" | awk '{print $1}')")"
            shift;;

        # Invalid options
        *)
            echo "./wana.sh: invalid option -- '$1'"
            echo "Try './wana.sh --help' for more information."
            exit 1
    esac
done

if [ "$LOGS" = "" ]; then
    while read -r line
    do
        LOGS="$LOGS
$line"
    done
fi

LOGS="$(echo "$LOGS" | awk 'NR>1')"


if [ -n "$after_datetime_val" ]; then
    LOGS="$(get_logs_after "$LOGS" "$after_datetime_val")"
fi
if [ -n "$before_datetime_val" ]; then
    LOGS="$(get_logs_before "$LOGS" "$before_datetime_val")"
fi
if [ -n "$ip_filter_val" ]; then
    LOGS="$(get_logs_ip "$LOGS" "$ip_filter_val")"
fi
if [ -n "$uri_filter_val" ]; then
    LOGS="$(get_logs_uri "$LOGS" "$uri_filter_val")"
fi


if [ $list_ip = true ]; then
    LOGS="$(get_list_ip "$LOGS")"
elif [ $list_hosts = true ]; then
    LOGS="$(get_list_hosts "$LOGS")"
elif [ $list_uri = true ]; then
    LOGS="$(get_list_uri "$LOGS")"
elif [ $hist_ip = true ]; then
    LOGS="$(get_hist_ip "$LOGS")"
elif [ $hist_load = true ]; then
    LOGS="$(get_hist_load "$LOGS")"
fi

echo "$LOGS"
exit 0
