#!/usr/bin/env bash

source "bin/_support/cecho.sh"

spin() {
  spinner="⣾⣽⣻⢿⡿⣟⣯⣷"
  while :; do
    for i in $(seq 0 7); do
      echo -n "${spinner:$i:1}"
      echo -en "\010"
      sleep 1
    done
  done
}

spin &
SPIN_PID=$!
trap "kill -9 $SPIN_PID" $(seq 0 15)
curl -L http://slowwly.robertomurray.co.uk/delay/15000/url/https://www.shellscript.sh/tips/spinner/test.txt
kill -9 $SPIN_PID
