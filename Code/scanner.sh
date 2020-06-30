
#!/bin/sh

: ${1?"Usage: $0 ip subnet to scan. eg '192.168.1.'"}

LOG=Log.log

X=$1

echo "Scanning IP range ..." 

for addr in `seq 0 1 255 `; do
echo ${X}${addr} >> ${LOG}
( echo ${X}${addr})
( ping -c 3 -t 5 ${X}${addr} > /dev/null && echo ${X}${addr} is Alive ) &
done


DNS="8.8.8.8"
INTERFACE=$(ip route get "${DNS}" | awk -F 'dev ' 'NR == 1 {split($2, a, " "); print a[1]}')
NETWORK_IP=$(ip route | awk "/${INTERFACE}/ && /src/ {print \$1}" | cut --fields=1 --delimiter="/")
CIDR=$(ip route | awk "/${INTERFACE}/ && /src/ {print \$1}" >> ${LOG})
FILTERED=$(echo "${NETWORK_IP}" | awk 'BEGIN{FS=OFS="."} NF--' >> ${LOG})

ip -statistics neighbour flush all &>/dev/null

echo -ne "Pinging ${CIDR}, please wait ...\n"
for HOST in {1..254}; do
  ping "${FILTERED}.${HOST}" -c 1 -w 10 &>/dev/null &
done

for JOB in $(jobs -p); do wait "${JOB}"; done

ip neighbour | \
    awk 'tolower($0) ~ /reachable|stale|delay|probe/{printf ("%5s\t%s\n", $1, $5)}' | \
      sort --version-sort --unique 
