#!/bin/bash -x
#
# This should be launched in the background from /etc/rc.local

export LD_LIBRARY_PATH="/opt/svxlink:$LD_LIBRARY_PATH"
SPOOL="/opt/spool"
LOGS="$SPOOL"
QSOS="$SPOOL/qso_recorder"
CALM="/opt/calmlink"
NEWLOG="$LOGS/$(date +log.%Y-%m-%d-%H%M%S.log)"
cd /tmp/

# Compress existing logs.
bzip2 -v "$LOGS"/log.*.log || true

while true
do
  # Reset audio settings.
	sh "$CALM"/audio.sh

	date
	/opt/svxlink/svxlink --config=/opt/calmlink/calmlink.conf
	date

  # If svxlink crashes (sometimes audio is not ready yet),
  #   sleep 10 seconds and try again.
	sleep 10
done >$NEWLOG 2>&1 </dev/null
