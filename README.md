# calmlink-echolink-svxlink
A calm echolink configuration for svxlink connecting by RF to an old VHF ham radio repeater.

This is for Raspberry Pi 3B with Raspbian Jessie OS.

This is a simplified install of an older version of svxlink (from around
2017) with a configuration called "calmlink" that is designed to be an
echolink connection to an old repeater.  It is called "calm" because I've
edited out lots of the features that would create noise on the repeater.
I've also commented out any DTMF controls, since they won't actually go
through our old repeater (N6NFI/R) anyway.

The recommended version of svxlink from
https://github.com/strickyak/svxlink has a hack (
https://github.com/strickyak/svxlink/commit/3ba0e02e916e12cd98b0490347d08caf024a62f0
) to make it more difficult for svxlink's squelch of the audio from
the radio to be triggered by the click heard when the N6NFI/R repeater
quits transmitting.

An optional binaries directory is provided.  If you do not want to build
svxlink binaries yourself, you can replace steps 2, 3, and 4 with copying
the contents of the binaries directory into `/opt/svxlink/`.

This configuration is designed to be used in a "crash only" style.
There is no supported way to shut down the svxlink gently (although the
svxlink daemon does trap SIGKILL and shut down gently, if you like).
You can power down the pi if you want it to stop, or reboot it if you
want it to run a new configuration (after running the `./choose` command
to choose the config directory to activate).

The included configurations use a USB to RS232 Serial cable to control
the PushToTalk on the radio using the CTS (clear to send) line from
the RS232 cable: `SERIAL_PIN=CTS`.  You might want to use a GPIO pin,
so you might change that.

These configs are under MIT license, but svxlink itself is under a
mixture of licenses, but mostly GNU GPL2.

## Setting up Calmlink.

(1)

As root, create these directories and change their owner to
user `pi` so you won't have to be root just to reconfigure calmlink.

    sudo mkdir /opt/svxlink /opt/calmlink /opt/spool /opt/spool/qso_recorder
    sudo chown pi.pi /opt/svxlink /opt/calmlink /opt/spool /opt/spool/qso_recorder

(2)

Get Strick's SVXLINK source from `https://github.com/strickyak/svxlink`.
You could also use the upstream source at `https://github.com/sm0svx/svxlink`
but I don't know if it still works with my configs.

Install libraries (-dev packages for libraries) as recommended in `svxlink/INSTALL.adoc`.
You do not need (lib)rtlsdr or (lib)qt packages.

(3)

Build the svxlink binary as directed in `svxlink/INSTALL.adoc`.
Your commands will look something like this:

    cd svxlink
    cd src
    mkdir build
    cd build
    cmake ..
    make

You should not 'make install'.
(The 'make install' will fail because it depends on a user 'svxlink' that we are not using.)
Also you don't need to 'make doc'.

(4)

While you are still in the `build` directory,
copy the results into /opt/svxlink like this:

    cp -av bin/svxlink /opt/svxlink/
    cp -av lib/* /opt/svxlink/

(5)

Create `/etc/calmlink.sed` with text like the following.
Change the portion between the final slashes to your callsign,
your password for your -L account, and your password
for your -R account.

We put this in the `/etc` directory because it contains your echolink
password, and we don't want to share that if we share a copy of the rest
of our files with someone.  The file must be readable by user pi.  If you
run `sudo touch /etc/calmlink.sed; sudo chown pi.pi /etc/calmlink.sed`
then you should be able to edit it, without being root.

    s/<<<CALLSIGN>>>/Q0XYZ/
    s/<<<ECHOLINK_PASSWORD_L>>>/tesla123-local/
    s/<<<ECHOLINK_PASSWORD_R>>>/tesla123-remote/

(6)

Add this line to your /etc/rc.local.  You will have to be root,
or use `sudo vi /etc/rc.local`.

    nohup /bin/su -l -c 'taskset 8 /bin/bash /opt/calmlink/run.sh' pi > /tmp/calmlink.log 2>&1 &

(7)

Now change directory back to this calmlink distribution.
Examine the files `*.config/audio.sh`.
They are probably good for a first try.
But you may have to adjust the audio gain percentages,
and maybe the grep string.

(8)

Choose your configuration, either l.config or r.config,
depending on whether you are going to use CALLSIGN-R or CALLSIGN-L
to log into echolink.  You can also copy these config directories
into other directories (ending in .config) where you can experiment.

    ./choose.sh l.config/
          or
    ./choose.sh r.config/

I use l.config for "local testing" under echolink account W6REK-L,
where I have the radio tuned either to the "triple nickel"
simplex channel 147.555, or to one of the VHF weather channels in the 162 MHz band.

And I use r.config for normal "remote" operation,
under echolink account W6REK-R,
with the radio correctly configured to communicate duplex with N6NFI/R.

You can examine the differences between l.config and r.config
with the `diff -r -u` command:

    diff -r -u l.config/ r.config/

(9)

Optional.  To run the webserver for archives, add this to /etc/rc.local,
changing the callsign in the title:

    taskset 2 /opt/svxlink/qso_server --bind ":80" --spooldir /opt/spool/qso_recorder --title "N6NFI/R (via Q0XYZ-R EchoLink) Archives" &

and copy `qso_server` from the binaries directory:

    cp binaries/qso_server /opt/svxlink/qso_server

Source for that is at
https://github.com/strickyak/serve-svxlink-qso-recorder but
it is written in a strange language of my own creation (
https://github.com/strickyak/rye ).

(10) Crontabs:

If you don't garbage collect Log files and Qso Recorder archives,
some day your disk will fill up.

Log files will be named `/opt/spool/log.*`.
They are verbose, but they compress really well.
You can keep a year's worth.

Qso Recorder archives will be named `/opt/spool/qso_recorder/*.ogg`.
I keep 31 days, and they use about two-thirds of gigabyte.

I run these in the `root` crontab, although the user `pi` could also do it.

    $ crontab -l root
    ...
    # m h  dom mon dow   command
    0   0  *   *   *     cd /tmp; find /opt/spool/qso_recorder -type f -name \*.ogg  -mtime +31 -print0 | xargs -0 /bin/rm -f
    0   0  *   *   *     cd /tmp; find /opt/spool/ -type f -name log.*.log*  -mtime +500 -print0 | xargs -0 /bin/rm -f

Also I reboot the machine every morning at 4:30 am local.
This occasionally solves problems like a stuck audio device driver,
in case I don't notice.

    # 12:30 GMT is 04:30 PST
    # m h  dom mon dow   command
    30  12 *   *   *     cd /tmp; sync; /sbin/reboot

## Practical Wiring Matters

Remote Shutoff:
I have one of these on the power plug to both the power supply for the radio
and to the raspberry pi, so I can shut it off, or power-cycle the machine
remotely with my cell phone:

[Kasa Smart HS103P2 Plug, Wi-Fi Outlet](https://www.amazon.com/gp/product/B07B8W2KHZ/ref=ppx_yo_dt_b_search_asin_title)

*Radio:*
I use an Icon Mobile Rig capable of 50W, but I have it set to lower power
at 5W.  Sometimes we have a remote net control for 2 or 3 hours,
and if I were running a transmistter at full power, it would probably burn it up.

*Power:*
I use an Astron 12W linear power supply.  Again, it's way overkill.

*Soundcard:*
I use a cheap $10 USB "soundcard" dongle plugged into a USB port on
the Rapsberry Pi.  Between the "soundcard" and the radio, I just have
resistors.  From the soundcard headphone output to the radio, I have a
1000 ohm resistor.  From the radio to the soundcard to the microphone
input, if the radio outputs are "line level", I use 1000 ohm again.
But if the radio output is for driving a speaker at 8 ohms, I use a
smaller value, with higher wattage.

*PTT:*
For the push-to-talk control from the pi to the radio, I use a CMOS CD4049
(hex inverting buffer) to condition the output signal.  You can power the
4049 from the +5V pin on the pi.  The input to this chip may be either
from a GPIO pin or one of the control lines on an RS232 serial dongle,
such as the Clear To Send (CTS) line.  The 4049 can handle the larger
voltages from RS232 on its input.  On the output of the 4049, I run it
through a small diode and a resistor about 100 ohms.  The diode lets
current flow from the open-collector input on the radio to the 4049 when
the 4049 output is in the ground state (logical 0).  Use either 2 or 3
of the individual 4049 buffers in series to make the polarity right.
Be careful that when you reboot the pi, it doesn't activate the PTT.
(That probably means floating +5V output from the pi when not active, and
0V output when active.  So an even number of inverting buffers would work.)
