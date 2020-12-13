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
