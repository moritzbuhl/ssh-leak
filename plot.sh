#!/bin/sh

set -e

log=ssh.log.wat

pids=${1:-$(cat $log | cut -d ' ' -f 1 | sort -u)}

plot_cmd="plot"
for pid in $pids; do
	grep "^ *$pid" $log | awk '{ print $2 }' > $log.$pid
	plot_cmd="$plot_cmd '$log.$pid'  with lines, "
done

gnuplot -e "$plot_cmd ; pause -1"