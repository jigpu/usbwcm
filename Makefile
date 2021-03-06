# Documentation specifically says to use this linker. GNU ld (gld)
# does not appear to work.
LD=/usr/ccs/bin/ld
SHELL=/usr/bin/sh

UTSBASE=$(CURDIR)/usr/src/uts
OBJS_DIR=$(CURDIR)

ARCH=$(shell isainfo -k)
ifeq ($(ARCH), sparcv9)
    KERNEL_DIR=/usr/kernel/strmod/sparcv9
else ifeq ($(ARCH), amd64)
    KERNEL_DIR=/usr/kernel/strmod/amd64
else ifeq ($(ARCH), i386)
    KERNEL_DIR=/usr/kernel/strmod
endif
$(info using architecture '$(ARCH)')

COMPILER=unknown
ifneq      (, $(findstring gcc version 3, $(shell $(CC) -v 2>&1))) # GCC 3
    COMPILER=gnu
else ifneq (, $(findstring gcc version 4, $(shell $(CC) -v 2>&1))) # GCC 4
    COMPILER=gnu
else ifneq (, $(findstring Sun C 5.6, $(shell $(CC) -V 2>&1)))     # Sun Studio 9
    COMPILER=sun
    ifeq ($(ARCH), amd64)
        $(warn Sun Studio 9 does not support amd64 architecture!)
    endif
else ifneq (, $(findstring Sun C 5.7, $(shell $(CC) -V 2>&1)))     # Sun Studio 10
    COMPILER=sun
else ifneq (, $(findstring Sun C 5.8, $(shell $(CC) -V 2>&1)))     # Sun Studio 11
    COMPILER=sun
else ifneq (, $(findstring Sun C 5.9, $(shell $(CC) -V 2>&1)))     # Sun Studio 12
    COMPILER=sun12
else ifneq (, $(findstring Sun C 5.10, $(shell $(CC) -V 2>&1)))    # Sun Studio 12 Update 1
    COMPILER=sun12
endif
$(info using compiler '$(shell which $(CC))' [$(COMPILER)])

ifeq ($(COMPILER), unknown)
    $(warning Compiler unknown -- module may not compile correctly!)
endif

# CFLAGS and LDFLAGS based on the "Device Driver Tutorial" and
# "Writing Device Drivers" documents from Oracle:
#
#  * https://docs.oracle.com/cd/E18752_01/html/817-5789/frymm.html#fgouv
#  * https://docs.oracle.com/cd/E26505_01/html/E27000/loading-1.html#loading-29

ifeq      ($(COMPILER)-$(ARCH), sun12-sparcv9)
    CFLAGS+=-m64
else ifeq ($(COMPILER)-$(ARCH), sun12-amd64)
    CFLAGS+=-m64 -xarch=sse2a
else ifeq ($(COMPILER)-$(ARCH), sun12-i386)
    CFLAGS+=""
else ifeq ($(COMPILER)-$(ARCH), sun-sparcv9)
    CFLAGS+=-xarch=v9
else ifeq ($(COMPILER)-$(ARCH), sun-amd64)
    CFLAGS+=-xarch=amd64 -xmodel=kernel
else ifeq ($(COMPILER)-$(ARCH), sun-i386)
    CFLAGS+=""
else ifeq ($(COMPILER)-$(ARCH), gnu-sparcv9)
    CFLAGS+=-ffreestanding -nodefaultlibs -std=c99 -m64 -mcpu=v9 -mcmodel=medlow -fno-pic -mno-fpu
else ifeq ($(COMPILER)-$(ARCH), gnu-amd64)
    CFLAGS+=-ffreestanding -nodefaultlibs -std=c99 -m64 -mcmodel=kernel -mno-red-zone
else ifeq ($(COMPILER)-$(ARCH), gnu-i386)
    CFLAGS+=-ffreestanding -nodefaultlibs -std=c99
else
    $(warning Unrecognized compiler / architecture combination!)
endif

CFLAGS+=-D_KERNEL -I$(UTSBASE)/common
LDFLAGS+=-r -dy -N misc/usba

# Solaris packaging based on tutorials found at following URLs:
#
#  * http://www.garex.net/sun/packaging/pkginfo.html
#  * http://www.ibiblio.org/pub/packages/solaris/i86pc/html/creating.solaris.packages.html
PKG=WACusbwcm
PKGVERSION=$(shell git describe | sed "s/^\(.*\)-\([0-9]*\)-\(g[0-9a-f]\{7,7\}\)\$$/\1+r\2.\3/")
define PKGINFO
PKG=$(PKG)
NAME="Kernel STREAMS module for Wacom tablets"
VERSION="$(PKGVERSION)"
ARCH="$(ARCH)"
CLASSES="system none"
CATEGORY="system"
VENDOR="Linuxwacom Project"
EMAIL="linuxwacom-discuss@lists.sourceforge.net"
endef
define PKGPROTO
i pkginfo=pkginfo
f none $(KERNEL_DIR)/usbwcm=$(OBJS_DIR)/usbwcm 0644 root other
endef
export PKGINFO
export PKGPROTO


.PHONY: all clean install uninstall package

all: $(OBJS_DIR)/usbwcm

clean:
	rm -f $(OBJS_DIR)/usbwcm $(OBJS_DIR)/usbwcm.o
	rm -rf $(PKG)/ *.pkg.tar.gz pkginfo Prototype

install: $(OBJS_DIR)/usbwcm
	mkdir -p $(DESTDIR)/$(KERNEL_DIR)
	cp $(OBJS_DIR)/usbwcm $(DESTDIR)/$(KERNEL_DIR)

uninstall:
	rm -f $(DESTDIR)/$(KERNEL_DIR)/usbwcm

package: $(PKG)-$(PKGVERSION)-$(ARCH).pkg.tar.gz

%.pkg.tar.gz: $(OBJS_DIR)/usbwcm
	@if test -z "$(PKGVERSION)" ; then echo "Unknown PKGVERSION. Please set on the 'make' commandline"; exit 1; fi
	echo "$$PKGINFO" > pkginfo
	echo "$$PKGPROTO" > Prototype
	pkgmk -o -d . -f Prototype
	tar -cf - -C . WACusbwcm | gzip -9 -c > $@

$(OBJS_DIR)/%.o: $(UTSBASE)/common/io/usb/clients/usbinput/usbwcm/%.c
	$(CC) $(CFLAGS) -o $@ -c $<

$(OBJS_DIR)/%: $(OBJS_DIR)/%.o
	$(LD) $(LDFLAGS) -o $@ $<
