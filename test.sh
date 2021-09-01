#!/bin/sh

set -eu

find /usr/src/sys > junk

KTRACE="LD_PRELOAD=/usr/obj/lib/libc/libc.so.96.0 MALLOC_OPTIONS=TTD ktrace -tu"
SSH=/usr/src/usr.bin/ssh/ssh/obj/ssh
ctrl=mux$RANDOM
uniqstr=uniqstr$RANDOM
euniqstr="[u]$(echo -n $uniqstr | cut -c 2-)"
$KTRACE $SSH -oControlPath=$PWD/$ctrl -nNFssh.conf $uniqstr 2>&1 | tee ssh.out &
master=$!
trap "kill $master; rm -f $PWD/$ctrl" EXIT
sleep 2

ps -o 'pid dsiz command' | grep $euniqstr | tee -a ssh-mem.log

function do_parallel_work {
	pids=""
	for _ in $(jot $1); do
		cat junk | ssh -S $ctrl localhost cat - 1>/dev/null &
		pids="$pids $!"
	done
	sleep "$(echo "scale=1;.1*$1" | bc)"
	for pid in $pids; do
		wait $pid
	done
}


for _ in $(jot 500); do
	do_parallel_work 9
	ps -o 'pid dsiz command' | grep $euniqstr | tee -a ssh-mem.log
done

echo graceful shutdown
sleep 10
ps -o 'pid dsiz command' | grep $euniqstr | tee -a ssh-mem.log
