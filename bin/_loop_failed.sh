#!/bin/bash

# loop ueber jobstates.rb

# MA MA

schwellwert=20
sleeptime=30

while true; do
    today=$(date +%Y-%m-%d)
    failed=$(jobstates.rb -d prod -i ${today} -s 1% | grep -i fail | wc -l)
    echo "$(date) FAILED = ${failed}"
    if [[ ${failed} -gt ${schwellwert} ]]; then
        echo "$(date) ALERT! Mehr als $schwellwert Jobs FAILED."
        # tu was! HOLD ALL! EMAIL! SMS!
        exit 1
    else
        echo "$(date) OK"
    fi
    echo "$(date) sleeping $sleeptime sec ..."
    sleep $sleeptime
    if [[ -n $ENDZEIT_ERREICH ]]; then
      echo "$(date) DONE."
      exit 0
    fi
done
