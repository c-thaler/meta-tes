SUMMARY = "U-Boot bootloader fw_printenv/setenv utilities"

LICENSE = "GPLv2+"
LIC_FILES_CHKSUM = "file://Licenses/README;md5=c7383a594871c03da76b3707929d2919"

DEPENDS = "openssl"

require u-boot.inc


S = "${WORKDIR}/git"

INSANE_SKIP_${PN} = "already-stripped"

EXTRA_OEMAKE_class-target = 'CROSS_COMPILE="${TARGET_PREFIX}" CC="${CC} ${CFLAGS} ${LDFLAGS}" HOSTCC="${BUILD_CC} ${BUILD_CFLAGS} ${BUILD_LDFLAGS}" STRIP=true V=1'
EXTRA_OEMAKE_class-native = 'CC="${BUILD_CC} ${BUILD_CFLAGS} ${BUILD_LDFLAGS}" HOSTCC="${BUILD_CC} ${BUILD_CFLAGS} ${BUILD_LDFLAGS}" STRIP=true V=1'
EXTRA_OEMAKE_class-nativesdk = 'CROSS_COMPILE="${HOST_PREFIX}" CC="${CC} ${CFLAGS} ${LDFLAGS}" HOSTCC="${BUILD_CC} ${BUILD_CFLAGS} ${BUILD_LDFLAGS}" STRIP=true V=1'

do_compile () {
        oe_runmake sandbox_defconfig

        # Disable CONFIG_CMD_LICENSE, license.h is not used by tools and
        # generating it requires bin2header tool, which for target build
        # is built with target tools and thus cannot be executed on host.
        sed -i "s/CONFIG_CMD_LICENSE=.*/# CONFIG_CMD_LICENSE is not set/" .config

        oe_runmake cross_tools NO_SDL=1
}

do_install () {
        install -d ${D}${bindir}
        install -m 0755 tools/mkimage ${D}${bindir}/uboot-mkimage
        ln -sf uboot-mkimage ${D}${bindir}/mkimage
}

BBCLASSEXTEND = "native nativesdk"
