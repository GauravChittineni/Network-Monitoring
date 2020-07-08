# Network-Monitoring

As per the mail sent i should be creating an automation script for managing all devices on a network via snaptots
1.scan the network for devices- add the list of ip addresses to a file. take a snapshot of the devices
   snapshots should be given an automatically generated timestamp.
2.roll back all devices in a list to a previous snapshot. the menu should find a list of available snapshots to 
  present to the user.
3. consideration for performance and security is necessary.

1. scanning the network for devices:
   -open the terminal and create an scanner.sh file and add the below code into it and execute it.

------------------start of the code Scanner.sh----------------------

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

----------------------- End of code scanner.sh------------------------------------

   -enter command sudo bash scanner.sh 192.168.1.
   -list of ip addresses can be seen here when executed.
   -enter command nano log.log
   - all the list of ip addresses are stored here in the log.
2. capturing a snapshot:
   -open the terminal and create an snapshotcapture.sh file and place the below code into it and execute it.
    -Screencapture is a command line tool that is used to capture the snapshots of the devices for given time intervals. 
    The tool can be installed on the command-line using apt-get install screencapture using sudo privileges.

-----------------------------------Start of the code Snapshotcapture.sh ----------------------------------

   #!/usr/bin/env bash

set -e

font="$HOME/Library/Fonts/digital-7 (mono).ttf"
output="$HOME/Downloads/caps"

sz="403,94,1061,1026"

timeout=2
fontFill="black"

# create a directory for the output images

mkdir -p ${output}

# loop
while [[ 1 ]];do
  date=$(date +%d\-%m\-%Y\_%H.%M.%S)
	file="/tmp/${date}.png"
	screencapture -t png -R${sz} -x ${file}
	
	# ou

	output="${output}/${date}.png"

	# Dimensions of the image
	measure=$(identify -format "%w %h" "$file")
	width=${measure%% *}
	height=${measure#* }

	# date stamp
	timestamp=$(stat -f "%Sm" ${file})

	# Decide the font size automatically
	if [[ ${width} -ge ${height} ]]
		then
		p_size=$(($width/30))
	else
		p_size=$(($height/30))
	fi

	# write the output to a file
	echo "Writing file: $output"
	convert "$file" -gravity SouthEast -font "$font" -pointsize ${p_size} -fill ${fontFill} -annotate +${p_size}+${p_size} "${timestamp}" "$output"

	rm ${file}

    # use intervals
	sleep ${timeout}
done

exit 0 

----------------------------- End of the Code snapshotcapture.sh ------------------------------------------

   -snapshot will be captured with automatically generated timestamp.
3. rolling back of devices:
   -open the terminal and create rollback.sh file and add the below code into it and execute it.

------------------------------Start of the code Rollback.sh---------------------------------------

   #!/usr/bin/env bash

# the path containing the logs of the snapshots

PATH="/var/local/log/snp"
# the date of the snapshots
date=$(date "+%Y-%m-%d-%H%M%S")
# log file used
LOG="${PATH}/snp_${date}.log"

! [[ -d ${PATH} ]] && mkdir -p ${PATH}

# execute
exec >  >(tee -a "$LOG")
exec 2> >(tee -a "$LOG" >&2)

cmd="$@"

# log to a file

echo "> Logging to: ${LOG}"

snapshot_=$(snapper create --type=pre --cleanup-algorithm=number --print-number --description="${cmd}")
echo "> New pre snapshot with number ${snapshot_}."
echo -e "> Running command \"${cmd}\".\n"

eval "${cmd}"

snapshot_=$(snapper create --type=post --cleanup-algorithm=number --print-number --pre-number="$snapshot_")
echo -e "\n> New post snapshot with number ${snapshot_}."

# execute the commands
# recover the snapshots

echo "> Running command \"${cmd}\"."
snapshot_=$(snapper create --command "${cmd}" --print-number --cleanup-algorithm=number --description="${cmd}" | tail -1)
echo -e "\n> New pre-post snapshot with numbers ${snapshot_}."

--------------------------------- End of the code Rollback.sh-----------------------------

   -the devices are rolled back into the previous snapshot.

