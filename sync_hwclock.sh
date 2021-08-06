#!/bin/bash

# Location of sync logfile
LOGFILE="/var/log/ntplog.log"

if [ ! -f $LOGFILE ]; then
  touch $LOGFILE
fi

# Set the maximum allowed difference in seconds between Hw-Clock and Sys-Clock
maxDiffSec="5"

msgNoConnection="No connection to time-server"
msgConnection="Connection to time-server"

# Check for NTP connection
if ( ntpq -p | grep -q "^*"  ); then
        echo $msgConnection
        echo "---------------------------------"

        secHwClock=$(sudo hwclock --verbose | grep "^Hw clock time" | awk '{print $(NF-3)}')
        echo "HwClock: $secHwClock sec"

        secSysClock=$(date +"%s")
        echo "SysClock: $secSysClock sec"
        echo "---------------------------------"

        secDiff=$(($secHwClock-$secSysClock))

        # Compute absolute value
        if ( echo $secDiff | grep -q "-" ); then
            secDiff=$(echo $secDiff | cut -d "-" -f 2)
        fi

        echo "Difference: $secDiff sec"

        msgDiff="HwClock difference: $secDiff sec"
        if [ "$secDiff" -gt "$maxDiffSec" ] ; then
                echo "---------------------------------"
                echo "The difference between Hw- and Sys-Clock is more than $maxDiffSec sec."
                echo "Hw-Clock will be updated"

                # Update hwclock from system clock
                sudo hwclock -w
                msgDiff="$msgDiff --> HW-Clock updated."
        fi
        if !(awk '/./{line=$0} END{print line}' $LOGFILE | grep -q "$msgConnection") || [ "$secDiff" -gt "$maxDiffSec" ]; then
                echo $(date)": "$msgConnection". "$msgDiff >> $LOGFILE
        fi
else
        # No NTP connection
        echo $msgNoConnection
        if !(awk '/./{line=$0} END{print line}' $LOGFILE | grep -q "$msgNoConnection"); then
                echo $(date)": $msgNoConnection" >> $LOGFILE
        fi
fi
