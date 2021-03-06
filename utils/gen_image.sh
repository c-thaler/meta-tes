#!/bin/bash

echo "TES DaveNX image generator"
echo "Copyright (C) 2017 TES Electronic Solutions GmbH"
echo "This program is free software; you can redistribute it and/or modify"
echo "it under the terms of the GNU General Public License as published by"
echo "the Free Software Foundation; either version 2 of the License, or"
echo "(at your option) any later version."
echo ""

if [ "$#" -ne 2 ]; then
	echo "Wrong number of parameters ($#)"

	echo "Usage: $0 BOARD DEPLOY_DIR_IMAGE"

	echo ""
	echo "BOARD - Target board: de10_sockit, sockit"
	echo "DEPLOY_DIR_IMAGE - Path to the Yocto image deploy directory"
	echo ""
	echo "The size of the output image depends on the size of the EXT3"
	echo "image built by bitbake/Yocto. The size of the image's FAT"
	echo "partition is fixed to 64M."
	echo ""
	echo "Example:"
	echo "	./gen_image.sh yocto/build/tmp/deploy/image/cyclone5"
	exit -1
fi

BOARD=$1
DEPLOYDIR=$2

IMAGE=tes-davenx-cdc-eval.img
FAT_SIZE_BLOCKS=$(expr 64 \* 1024 \* 1024 \/ 512)
SIZE_BLOCKS=$(expr 4096 \+ ${FAT_SIZE_BLOCKS})

PRELOADERIMAGE=${DEPLOYDIR}/preloader_de10_sockit.bin
UBOOTIMAGE=${DEPLOYDIR}/u-boot-cyclone5.img
DEVICETREE=${DEPLOYDIR}/zImage-socfpga_cyclone5_${BOARD}_tes_davenx.dtb
KERNELIMAGE=${DEPLOYDIR}/zImage
SYSROOT=${DEPLOYDIR}/tes-davenx-evalkit-image-cyclone5.ext3
FPGABITFILE=${DEPLOYDIR}/socfpga_cyclone5_${BOARD}_davenx_cdc.rbf
BOOTSCRIPT=${DEPLOYDIR}/boot.scr

EXT_SIZE_BLOCKS=$(expr $(stat -Lc%s ${SYSROOT}) \/ 512 \+ 1)
SIZE=$(expr ${SIZE_BLOCKS} \+ ${EXT_SIZE_BLOCKS})

# Generate image file
echo "Generating empty image file..."
dd if=/dev/zero of=${IMAGE} bs=${SIZE} count=512


# Generate partition table
echo "Generating partition table..."
( \
	echo "o"; \
	echo "n"; echo "p"; echo "3"; \
		echo "2048"; echo "4095"; \
	echo "n"; echo "p"; echo "1"; \
		echo ""; echo "+64M"; \
	echo "n"; echo "p"; echo "2"; \
		echo ""; echo ""; \
	echo "t"; echo "1"; echo "c"; \
	echo "t"; echo "3"; echo "a2"; \
	echo "w"; echo "q" \
) | fdisk ${IMAGE}


# Get partition start and size parameters
TEMPVAL=($(fdisk -l ${IMAGE} | grep "\.img1"))
PART_FAT_START=${TEMPVAL[1]}
PART_FAT_SIZE=${TEMPVAL[3]}
TEMPVAL=($(fdisk -l ${IMAGE} | grep "\.img2"))
PART_EXT_START=${TEMPVAL[1]}
PART_EXT_SIZE=${TEMPVAL[3]}


# Installing preloader
echo "Installing preloader..."
dd conv=notrunc if=${PRELOADERIMAGE} of=${IMAGE} seek=2048


# Creating file for FAT partition
echo "Creating FAT partition..."
FATIMG=tmp_${RANDOM}
dd if=/dev/zero of=${FATIMG} bs=64M count=1
mkfs.vfat ${FATIMG}


# Populating FAT partition
echo "Populating FAT partition..."
mcopy -i ${FATIMG} ${KERNELIMAGE} ::zImage
mcopy -i ${FATIMG} ${UBOOTIMAGE} ::u-boot.img 
mcopy -i ${FATIMG} ${DEVICETREE} ::socfpga.dtb 
mcopy -i ${FATIMG} ${FPGABITFILE} ::socfpga.rbf
UBOOTSCR=tmp_${RANDOM}
mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "boot" -d ${BOOTSCRIPT} ${UBOOTSCR}
mcopy -i ${FATIMG} ${UBOOTSCR} ::u-boot.scr


# Wrtiting partitions to image file
echo "Writing partitions to image file..."
dd if=${FATIMG} of=${IMAGE} seek=${PART_FAT_START} bs=512 conv=notrunc
dd if=${SYSROOT} of=${IMAGE} seek=${PART_EXT_START} bs=512 conv=notrunc

rm ${FATIMG} ${UBOOTSCR}

