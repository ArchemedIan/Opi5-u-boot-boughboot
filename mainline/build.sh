#!/bin/bash
rootdir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"


ubootRef=$1
ubootRepo=$2
boardconfig=$3

if [[ "$ubootRef" == *"-custom"* ]]; then
  ubootRef=$5
fi
if [[ "$ubootRepo" == *"-custom"* ]]; then
  ubootRepo=$6
fi

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

mkdir $rootdir/out

export ROCKCHIP_TPL=$rootdir/rkbin/$(confget -f $rootdir/rkbin/RKBOOT/RK3588MINIALL.ini -s LOADER_OPTION FlashData)
export BL31=$rootdir/rkbin/$(confget -f $rootdir/rkbin/RKTRUST/RK3588TRUST.ini -s BL31_OPTION PATH)
echo $ROCKCHIP_TPL
echo $BL31
cd u-boot
make mrproper
make ${boardconfig}
make KCFLAGS="-fno-peephole2" CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
ls
set -x
ls u-boot*>/dev/null && cp u-boot* $rootdir/out
[ -f idbloader.img ] && cp idbloader.img $rootdir/out
[ -f idbloader-spi.img ] && cp idbloader-spi.img $rootdir/out

exit 0
