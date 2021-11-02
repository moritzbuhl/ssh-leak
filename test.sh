#!/bin/sh

set -eu

find /usr/src/sys > junk

log=$PWD/run/ssh-mem.log

# test time
N=5000

KTRACE=""
#KTRACE="LD_PRELOAD=/usr/obj/lib/libc/libc.so.96.1 MALLOC_OPTIONS=TTD ktrace -tu"
VERBOSE=""
#VERBOSE="-v"
SSH=/usr/src/usr.bin/ssh/ssh/obj/ssh
ctrl=run/mux$RANDOM
uniqstr=uniqstr$RANDOM
euniqstr="[u]$(echo -n $uniqstr | cut -c 2-)"
eval $KTRACE $SSH $VERBOSE -oControlPath=$PWD/$ctrl -nNFssh.conf $uniqstr 2>&1 | tee run/ssh.out &
master=$!
trap "kill $master; rm -f $PWD/$ctrl" EXIT
sleep 2

ps www -o 'pid dsiz command' | grep $euniqstr | tee -a $log

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


for _ in $(jot $N); do
	do_parallel_work 9 # XXX: this number was not chosen arbitrarily
	    # MaxSession and MaxStartup dont help
	ps www -o 'pid dsiz command' | grep $euniqstr | tee -a $log
done

echo graceful shutdown
sleep 10
ps www -o 'pid dsiz command' | grep $euniqstr | tee -a $log
