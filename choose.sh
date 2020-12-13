#!/bin/bash
#
#  Run this command to choose a config subdirectory and install it
#  as the current calmlink config.
#
#  To launch your "local" (testing) -L config:
#      ./choose.sh l.config
#  
#  To launch your "remote" (production) -R config:
#      ./choose.sh r.config
#
#  Prerequisites:
#    /opt/calmlink must exist and you should own it (sudo mkdir /opt/calmlink && sudo chown pi /opt/calmlink).
#    /etc/calmlink.sed must exist, be configured, and you can read it.

case $# in
  1) : ok ;;
  *) echo "Usage:  $0 DIRNAME.config  (to choose that calmlink configuration directory)" >&2
     exit 13 ;;
esac

case "$1" in
  *.config ) : ok ;;
  *.config/ ) : ok ;;
  * ) echo "ERROR: Configuration directory names must end in .config" >&2
      exit 13 ;;
esac

if test -d "$1/"
then : ok
else
  echo "ERROR: No such directory: $(ls -d "$1")" >&2
  exit 13
fi

rm -f /opt/calmlink/*.*

for x in "$1"/*.*
do
  B="$(basename "$x")"
  sed -f /etc/calmlink.sed < "$x" > "/opt/calmlink/$B" &&
  echo "... ran sed from '$x' to '/opt/calmlink/$B'" >&2
done

echo "... sync ..." >&2
sync
echo "DONE.  Run 'sudo reboot' to start the new config." >&2
