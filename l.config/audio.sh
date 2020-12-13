#!/bin/bash -x
# Set audio gain levels for Speaker and Mic.

# Detect the correct audio mixer device
# by trying different numbers until we find one
# that has left and right playback channels.
# A raspberry pi has no bultin stereo playback,
# so this should detect the USB soundcard dongle.
# *** You may have to adjust the grep pattern. ***
C=1  ;# Default if this loop fails to find it.
for i in 0 1 2 3
do
  if amixer -c $i | grep 'Playback channels: Front Left - Front Right'
  then C="$i"
       break
  fi
done

# Set Speaker and Mic audio gain.
amixer -c $C set Speaker 42%
amixer -c $C set Mic     42%
amixer -c $C
