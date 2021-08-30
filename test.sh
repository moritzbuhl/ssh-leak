#!/bin/sh

set -eu

find /usr/src/sys > junk

ctrl=mux$RANDOM
uniqstr=uniqstr$RANDOM
euniqstr="[u]$(echo -n $uniqstr | cut -c 2-)"
ssh -vvv -oControlPath=$PWD/$ctrl -nNF ssh.conf $uniqstr &
master=$!
sleep 2

ps -o 'pid dsiz command' | grep $euniqstr | tee -a ssh.log.wat

function do_parallel_work {
	for _ in $(jot $1); do
		cat junk | ssh -S $ctrl localhost cat - 2>&1 1>/dev/null &
	done
	sleep "$(echo "scale=1;.1*$1" | bc)"
}


for _ in $(jot 500); do
	do_parallel_work 6
	wait $!
	ps -o 'pid dsiz command' | grep $euniqstr | tee -a ssh.log.wat
done

echo Done
ps -o 'pid dsiz command' | grep $euniqstr | tee -a ssh.log.wat

kill $master
