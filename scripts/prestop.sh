#!/bin/bash

PROCESS_ID=$(<"/var/run/supervisor/supervisord.pid")
SIGNAL=TERM

kill -$SIGNAL $PROCESS_ID
sleep 20
exit 0
