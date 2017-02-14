**usbwcm**: STREAMS module for Wacom USB Tablets


# Description  ########################################################

The usbwcm STREAMS module adds support for a limited number of Wacom
tablets to Solaris 10 / OpenIndiana / illumos. When used alongside a
suitable Xorg driver such as that provided by the linuxwacom project,
it is possible to use these tablets in programs like GIMP, Inkscape,
etc. For more information, please see man usbwcm(7M).

This module has been forked from the illumos project to provide access
to out-of-tree patches that add support for a wider range of devices.
Please see the `uwacom_devs` array contained within
`usr/src/uts/common/sys/usb/clients/usbinput/usbwcm/usbwcm.h` for a
complete list.

  * Wacom Graphire
  * Wacom Graphire 2
  * Wacom Graphire 3
  * Wacom Graphire 4
  * Wacom Bamboo Fun
  * Wacom Bamboo
  * Wacom Bamboo One
  * Wacom Volito
  * Wacom PenStation 2
  * Wacom Volito 2 (4x5 and 2x3)
  * Wacom PenPartner 2
  * Wacom Intuos3 (4x5, 6x8, 9x12, 12x12, 12x19, 6x11, 4x6)
  * Wacom Intuos4 (4x6, 6x9, 8x13, 12x19)
  * Wacom Cintiq 21UX (DTZ-2100)
  * Wacom Cintiq 21UX (DTK-2100)
  * Wacom DTU-2231


# Usage  ##############################################################

[STREAMS Programming Guide]:
  https://docs.oracle.com/cd/E26502_01/html/E35856/index.html


The usbwcm STREAMS module requires no user interaction or configuration.
Once installed, the module should be automatically found and used by
compatible software (e.g. the linuxwacom Xorg driver).

We encourage software developers to make use of higher-level APIs such
as GTK+ or Xlib / XI2 which provide cross-platform access to tablet
data. Developers requiring raw device access can find detailed
information about interfacing with STREAMS modules inside Oracle's
"[STREAMS Programming Guide][]". Briefly, the `I_FIND` and `I_PUSH`
ioctl commands should be used to add the usbwcm module onto stream head
of a STREAMS device node such as `/dev/usb/hid<N>`. These calls will fail
if the module is incompatible with the attached Wacom device. The
`sys/usb/clients/usbinput/usbwcm/usbwcm.h` header includes structure
and ioctl definitions which will be needed to interface with the module.


# Build, Install, and Uninstall #######################################

Building of the usbwcm STREAMS module has only been tested in a limited
number of environments. It is known to work in Solaris 10 05/09 ("U7")
with the use of gcc4 and gmake from the OpenCSW archive. Different
build systems or packages may or may not work.


## Prerequisites ##

[OpenCSW]:
  https://www.opencsw.org/

[linuxwacom project on SourceForge]:
  https://sourceforge.net/projects/linuxwacom/

[linuxwacom project Github mirror]:
  https://github.com/linuxwacom


Your system must have a compatible compiler, linker, and make utility
installed to build the usbwcm module. A full install of Solaris 10
should include a copy of gcc3, Solaris ld, and GNU make in the indicated
locations. If your system is missing a required tool, you can find
versions on your Solaris CD or third-party package archives such as
[OpenCSW][].

**Compatible Compilers:**

  * gcc3 (e.g. `/usr/sfw/bin/gcc`)
  * gcc4 (e.g. `/opt/csw/bin/gcc`)
  * Solaris Studio 9
  * Solaris Studio 10
  * Solaris Studio 11
  * Solaris Studio 12

**Compatible Linkers:**

  * Solaris ld (e.g. `/usr/ccs/bin/ld`)

**Compatible Make Utilities:**

  * GNU make (e.g. `/usr/sfw/bin/gmake` or `/opt/csw/bin/gmake`)

Prior to building, please check that your `$PATH` variable is properly
set and that the `$CC` variable is either empty (for Solaris Studio)
or set to `gcc`.

    $ export PATH=$PATH:/usr/sfw/bin
    $ export CC=gcc

Extract the source code for usbwcm from its tarball into a directory.
You can find the latest version at either the [linuxwacom project on
SourceForge][] or the [linuxwacom project Github mirror][].

    $ bzcat usbwcm-<version>.tar.bz2 | tar xvf -
    $ cd usbwcm-<version>


## Build & Install ##

Run `gmake` to start the build process. If no errors occur, you can
switch to the root account and install the driver with `gmake install`.
Afterwards, reboot the system to ensure it is made aware of the newly-
installed module.

    $ gmake
    $ su root -c "PATH=\"$PATH\" gmake install"
    $ su root -c reboot


## Uninstalling ##

To remove the module, simply run `gmake uninstall` and reboot.

    $ su root -c "PATH=\$PATH\" gmake uninstall"
    $ su root -c reboot


# Development  ########################################################

The linuxwacom project maintains a git repository which is used for
module development. This repository may be cloned with the third-party
`git` utility (e.g. from OpenCSW) with the following command:

    $ git clone git://git.code.sf.net/p/linuxwacom/usbwcm

While developing the driver, it may be useful to manually load and
unload the module from memory. Neither of these commands will have an
effect on the running system since the module must be pushed / popped
from a specific stream head, but they may provide valuable output in
the `dmesg` log.

    # modload usbwcm
    # modunload -i `modinfo | awk '/usbwcm/ {print $1}'`


# Troubleshooting  ####################################################

## Is the module installed? ##

To confirm that the module is installed, run the following command and
examine its output. At least one result should be listed which shares
your machine's architecture. That file should be located in the proper
directory: `/usr/kernel/strmod` for an x86 ELF, `/usr/kernel/strmod/amd64`
for an x86-64 ELF, or `/usr/kernel/strmod/sparcv9` for a SPARC v9 ELF.

    # file `find /usr/kernel/strmod -name usbwcm`


## Is the module loaded? ##

STREAMS modules are loaded on-demand by programs which require their
functionality. Before running the following command, make sure that a
program which uses the tablet is running (e.g. Xorg with the linuxwacom
driver). The command will only print output if the module is loaded.

    # modinfo | grep usbwcm


## Is the software configured properly? ##

Your software may need to be configured before it is able to use a
tablet. The Xorg linuxwacom driver, for instance, you may need to edit
the `/etc/X11/xorg.conf` file before the Xorg libwacom driver will
work. Verify your software has been configured to use the tablet and
that it is using the appropriate device node (the kernel's `dmesg` log
should contain information about which device node is associated with
the tablet).


## Are there any errors? ##

If any errors occurred while setting up the tablet or initializing the
usbwcm module, valuable information may be stored in the `dmesg` log.
Check this and other logs for information that may shed light on your
particular problem. It may be that the installed version of usbwcm does
not support your particular tablet.

    # dmesg | egrep -i "usba|hid|usbwcm|wacom"
    # ls /dev/usb/hid*


# Acknowledgements  ###################################################

[originally developed]:
  https://www.mail-archive.com/opensolaris-arc@mail.opensolaris.org/msg18387.html

This module was [originally developed][] by Pengcheng Chen and is based
on the FreeBSD uwacom driver. Subsequent modifications have been made
by the linuxwacom project to expand the number of supported devices.

