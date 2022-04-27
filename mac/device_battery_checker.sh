#!/usr/bin/env bash

# Check battery level of Apple Magic Mouse and Keyboard and Notify if low
# Based on https://apple.stackexchange.com/a/327627

PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin

# Warn at 15% or according to first parameter.  Pass in 101 for testing.
COMPARE=${1:-15}

# Check each device.
# If you have a Trackpad please add the suitable token to this list and test it.
for HIDThingy in Keyboard Mouse; do
    # Determine battery level of Apple Magic Thingy
    BATT=`ioreg -c AppleDeviceManagementHIDEventService -r -l \
         | grep -i $HIDThingy -A 20 | grep BatteryPercent | sed -e 's/.* //'`

    if [ -z "$BATT" ]; then
      echo "No $HIDThingy found."
    elif (( BATT < COMPARE )); then
			afplay /System/Library/Sounds/Hero.aiff
      osascript -e "display alert \"$HIDThingy battery is getting low\" message \"$HIDThingy battery is at ${BATT}%.\""
    fi
done
