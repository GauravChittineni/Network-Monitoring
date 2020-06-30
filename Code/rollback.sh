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