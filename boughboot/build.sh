#!/bin/bash
rootdir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

ubootRef=$1
ubootRepo=$2
boardconfig=$3

if [[ "$ubootRef" == *"custom_"* ]]; then
  ubootRef=$4
fi
if [[ "$ubootRepo" == *"custom_"* ]]; then
  ubootRepo=$5
fi
boardName=$6

sudo apt-get update
sudo apt-get install gcc-12 gcc-12-aarch64-linux-gnu python3-pyelftools confget

sudo ln -sf cpp-12 /usr/bin/cpp
sudo ln -sf gcc-12 /usr/bin/gcc
sudo ln -sf gcc-ar-12 /usr/bin/gcc-ar
sudo ln -sf gcc-nm-12 /usr/bin/gcc-nm
sudo ln -sf gcc-ranlib-12 /usr/bin/gcc-ranlib
sudo ln -sf gcov-12 /usr/bin/gcov
sudo ln -sf gcov-dump-12 /usr/bin/gcov-dump
sudo ln -sf gcov-tool-12 /usr/bin/gcov-tool

sudo ln -sf aarch64-linux-gnu-cpp-12 /usr/bin/aarch64-linux-gnu-cpp
sudo ln -sf aarch64-linux-gnu-gcc-12 /usr/bin/aarch64-linux-gnu-gcc
sudo ln -sf aarch64-linux-gnu-gcc-ar-12 /usr/bin/aarch64-linux-gnu-gcc-ar
sudo ln -sf aarch64-linux-gnu-gcc-nm-12 /usr/bin/aarch64-linux-gnu-gcc-nm
sudo ln -sf aarch64-linux-gnu-gcc-ranlib-12 /usr/bin/aarch64-linux-gnu-gcc-ranlib
sudo ln -sf aarch64-linux-gnu-gcov-12 /usr/bin/aarch64-linux-gnu-gcov
sudo ln -sf aarch64-linux-gnu-gcov-dump-12 /usr/bin/aarch64-linux-gnu-gcov-dump
sudo ln -sf aarch64-linux-gnu-gcov-tool-12 /usr/bin/aarch64-linux-gnu-gcov-tool

git clone --branch master "https://github.com/rockchip-linux/rkbin.git" rkbin

git clone --branch ${ubootRef} "${ubootRepo}" u-boot
[ -f $rootdir/u-boot/configs/${boardconfig} ] || exit 1

cat << TEOF >> $rootdir/u-boot/configs/${boardconfig}
CONFIG_CC_OPTIMIZE_LIBS_FOR_SPEED=y
CONFIG_LIBAVB=y
CONFIG_ZLIB_UNCOMPRESS=y
CONFIG_BZIP2=y
CONFIG_ENV_IS_NOWHERE=y
CONFIG_ENV_IS_IN_SPI_FLASH=y
CONFIG_ENV_SECT_SIZE_AUTO=y
CONFIG_VERSION_VARIABLE=y
CONFIG_CMD_CAT=y
CONFIG_CMD_SETEXPR=y
CONFIG_CMD_XXD=y
CONFIG_CMD_CLS=y
CONFIG_CMD_INI=y
CONFIG_CMD_SYSBOOT=y
CONFIG_CMD_UUID=y
CONFIG_CMD_BTRFS=y
CONFIG_CMD_EXT4_WRITE=y
CONFIG_CMD_FS_UUID=y
CONFIG_CMD_LSBLK=y
CONFIG_CMD_MBR=y
CONFIG_CMD_GPT_RENAME=y
CONFIG_SYS_PROMPT="BB> "
CONFIG_CMD_CONFIG=y
CONFIG_CMD_BOOTZ=y
CONFIG_CMD_ADTIMG=y
CONFIG_CMD_ABOOTIMG=y
CONFIG_CMD_GREPENV=y
CONFIG_CMD_ERASEENV=y
CONFIG_CMD_ENV_CALLBACK=y
CONFIG_CMD_ENV_FLAGS=y
CONFIG_CMD_NVEDIT_EFI=y
CONFIG_CMD_NVEDIT_INDIRECT=y
CONFIG_CMD_NVEDIT_INFO=y
CONFIG_CMD_NVEDIT_LOAD=y
CONFIG_CMD_NVEDIT_SELECT=y
CONFIG_CMD_ZIP=y
CONFIG_BOOTCOMMAND="bootflow scan"
CONFIG_CHROMEOS=y
CONFIG_BOOTDELAY=1
CONFIG_BOOTSTD_FULL=y
CONFIG_BOOTMETH_CROS=y
CONFIG_LOCALVERSION="boughboot"
CONFIG_CC_OPTIMIZE_FOR_SPEED=y
CONFIG_ANDROID_BOOT_IMAGE=y
CONFIG_ENV_SIZE=0x1f000
TEOF

grep "CONFIG_ROCKCHIP_SPI_IMAGE=y" $rootdir/u-boot/configs/${boardconfig} >/dev/null || echo -e "CONFIG_ROCKCHIP_SPI_IMAGE=y" >> $rootdir/u-boot/configs/${boardconfig}
echo -e "CONFIG_BOOTSTD_FULL=y" >> $rootdir/u-boot/configs/${boardconfig}
#echo -e "CONFIG_USE_PREBOOT=y" >> $rootdir/u-boot/configs/${boardconfig}
#echo -e "CONFIG_PREBOOT=\"setenv boot_targets \\\"${bootorder}\\\"\"" >> $rootdir/u-boot/configs/${boardconfig}
echo -e "CONFIG_BOOTCOMMAND=\"bootflow scan -b\"" >> $rootdir/u-boot/configs/${boardconfig} #pci enum; nvme scan;

cp $rootdir/v2-1-4-rockchip-rk3588-Fix-boot-from-SPI-flash.diff $rootdir/u-boot/

#tail $rootdir/u-boot/configs/${boardconfig}

mkdir $rootdir/out

export ROCKCHIP_TPL=$rootdir/rkbin/$(confget -f $rootdir/rkbin/RKBOOT/RK3588MINIALL.ini -s LOADER_OPTION FlashData)
export BL31=$rootdir/rkbin/$(confget -f $rootdir/rkbin/RKTRUST/RK3588TRUST.ini -s BL31_OPTION PATH)
echo $ROCKCHIP_TPL
echo $BL31
cd u-boot
make mrproper
make ${boardconfig}
grep "BROM_BOOTSOURCE_SPINOR_RK3588 = 6" arch/arm/include/asm/arch-rockchip/bootrom.h && patch -p1 < v2-1-4-rockchip-rk3588-Fix-boot-from-SPI-flash.diff 
make KCFLAGS="-fno-peephole2" CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
ls
#set -x
#ls u-boot*>/dev/null && cp u-boot* $rootdir/out
#[ -f idbloader.img ] && cp idbloader.img $rootdir/out
#[ -f idbloader-spi.img ] && cp idbloader-spi.img $rootdir/out
cp u-boot-rockchip-spi.bin $rootdir/out/u-boot-$boardName-$ubootRef-spi-$orderUnder.bin
exit 0
