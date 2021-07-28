# Operating Systems - Project 1
## Web log analyzer
---

Shell script for analysis of logs from webserver.\
POSIX-ly correct.\
Tested on `Linux` and `FreeBSD`.

**Author:** Peter Koprda <xkoprd00@stud.fit.vutbr.cz>


## Usage
```
$ ./wana [FILTER] [COMMAND] [LOG [LOG2 [...]]
```

### Filters:
```
-a DATETIME         show queries after this date; 
                    DATETIME must be in format YYYY-MM-DD HH:MM:SS
-b DATETIME         show queries before this date;
                    DATETIME must be in format YYYY-MM-DD HH:MM:SS
-ip IPADDR          show queries from this source address IPADDR;
                    IPADDR must be IPv4 or IPv6
-uri URI            show queries of requests on the webpage URI;
                    URI is standard regular expression
```

### Commands:
```
list-ip             list of source IP adresses
list-hosts          list of source domain names
list-uri            list of destination sources (URI)
hist-ip             create histogram of source IPs
hist-load           create histogram of load
```

### Example:
```
$ ./wana.sh -a 2019-02-21 00:00:00 -b 2019-02-22 00:00:00 hist-ip log1 log2
```
```
$ ./wana.sh -uri "/robots\.txt" list-ip log1 log2 log3
```
When no log file is provided, script reads logs from standard input:
```
$ ./wana.sh list-ip
```
Script also accept log files compressed with tool `gzip`:
```
$ ./wana.sh list-ip log.gz
```
