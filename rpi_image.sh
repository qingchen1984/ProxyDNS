#!/bin/sh
rm -rf tmpgit
mkdir tmpgit
cd tmpgit
git clone git://github.com/parrotgeek1/proxydns2.git
cd proxydns2
CCPREFIX="$HOME/arm-none-linux-gnueabi/bin/arm-none-linux-gnueabi-" EXTRAFLAGS="-DEMBEDDED -static" ./make.sh
mv proxydns2 ../../
cd ../../
rm -rf tmpgit

rm -rf initrd sdcard
mkdir -p initrd sdcard
cd initrd
mkdir dev mnt proc sys root
cd ..

rm -rf kl1
mkdir kl1
cd kl1
curl -L -o kl1.deb http://mirrordirector.raspbian.org/raspbian/pool/main/k/klibc/`curl -sL http://mirrordirector.raspbian.org/raspbian/pool/main/k/klibc/ | grep 'klibc-utils_' | sort | tail -n 1 | tr '<' '\n' | grep '^a href="' | grep -F '.deb"' | cut -d '"' -f 2`
ar x kl1.deb
rm debian-binary control*
xzcat data.tar.xz | tar xf -
mv usr/lib/klibc/bin/kinit ../initrd/
cd ..
rm -rf kl1

cd initrd
cp ../proxydns2 root/
chown -R 0:0 .
chmod -R 0755 .
find . | cpio -H newc -o > ../sdcard/initrd
gzip ../sdcard/initrd
cd ..

curl -L -o fw.zip https://github.com/Hexxeh/rpi-firmware/archive/master.zip
unzip -o fw.zip
mv rpi-firmware-master/* sdcard/
rm -rf fw.zip rpi-firmware-master
cd sdcard
rm -rf modules overlays vc *.symvers start{,_db,_x}.elf git_hash *.md fixup{,_db,_x}.elf
cat << EOF > config.txt
gpu_mem=16
hdmi_safe=1
boot_delay=0
disable_splash=1
initramfs initrd.gz followkernel
EOF

echo 'smsc95xx.turbo_mode=N root=/dev/ram0 rootwait init=/proxydns2 rdinit=/kinit devtmpfs.mount=1 quiet loglevel=3 ip=dhcp' > cmdline.txt
mkdir proxydns2
cd proxydns2
printf "185.37.37.37" > host.txt
printf 54 > port.txt

cd ..
chmod -R 0755 .

cd ..
rm -rf initrd proxydns2
echo Done