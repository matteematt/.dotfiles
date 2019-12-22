# Complete Arch Linux Setup 2019

This is a complete readme document to set up arch linux using a UEFI BIOS for Arch Linux 2019. This uses I3 (with gaps) for the Window Manger and XOrg as the display server.

## Part 1 - Installing Arch Linux

This document only covers installing for the exact process I have used before. For this you will need an ethernet connection and a USB drive. It is possible to use Wifi, but it has extra steps that are not covered here.

### Getting the ISO

Download Arch Linux 2019 and write the ISO to a USB stick

Use `lsblk` to view the block devices currently seen by the operating system. Find the USB drive (it helps to look at the size) and the drive should be called `sdX` where `X` is another letter. Partitions on each block device are listed as `sdX(1,2...n)`. To write the arch linux iso run `dd if=/path/to/archlinux.iso of=/dev/sdX status="progres"` where `X` is the letter of the USB drive. Once this has done and reported with no errors, restart the computer and boot into the USB drive.
Once the computer has booted onto the USB stick you should see a plain shell that is running from the USB stick. To install arch linux you run commands from the booted USB.


### Verify Motherboard BIOS Mode

Motherboards either use legacy BIOS with MBR or UEFI. This document only covers UEFI BIOS as I have only ever installed it with UEFI. After this paragraph the reset of the document will only give UEFI instructions, and not point out where the exact differences are. Most of the setup should be the same except for partitioning the drive and setting up the boot partition. To verify your motherboard type run `ls /sys/firmware/efi/efivars`. If this directory does exist then you have UEFI, if not you need to install for legacy BIOS.

### Set up keyboard layout

The default keyboard layout is qwerty USA. To see the available keyboard layouts run `ls /usr/share/kbd/keymaps/**/*.map.gz`. To look for a certain country you may find it helpuful to pipe this output through grep. There may be many options for a country, for UK there is mac, qwerty, dvorak, and more. As I have a standard qwerty UK keyboard I will use `/usr/share/kbd/keymaps/i386/qwerty/uk.map.gz`. To select this run `loadkeys uk`, the uk comes from `uk.map.gz` so switch out whichever layout you need.

### Verify internet connection

As stated previously these instructions assume ethernet connection. If that is not possible it is time for you to see how to connect using Wifi. Ethernet connections should be working automatically. Once you internet is setup you can verify you have a connection with `ping bbc.com` for example.

### Update system clock

`timedatectl set-ntp true`

### Partition the disks

Use `lsblk` again, but this time you need to identify which drive is the drive you want to install arch linux to. If you only have one drive then it is likely `sda`. If you have multiple then you will need to work out which drive it is. Apparently nvme drives show as something different than `sdX`. Once you have identified the drive run `fdisk /dev/sdX`.

#### Using fdisk

Type `m` for help in the fdisk prompt. If this drive already has been used before, keep pressing d to remove to partitions until there are none left. Then press `g` for GPT partition tables.
Type `n` for new partition, enter for defualt drive number (1) and enter for default first sector location. Recommended sector size for boot partition according to the arch wiki of 512MB so type +512M for last sector.
Type `n` for a new partition, enter for the default drive number (2) and enter for the sector start. This is the swap partition, recommended size is 1.5 * your RAM. So I will type +24G for the last sector.
Type `n` for a new partition, enter for the default drive number (3) and enter for the sector start. This is the root directory, you want to just take up the rest of the space so press enter again for the default sector end.
Type `t` to change types. Once you are doing this you can press `l` to see the different disk types. For partition 1 set it to type 1 (EFI System). For partition 2 set it to type 19 (linux swap). For partition 3 set it to type 24 (linux root (x86-64)).
Type `w` to write all these changes and finish using fdisk.

#### Format the partitions

* `mkfs.vfat /dev/sdX1` to set the boot partion.
* `mkswap /dev/sdX2` and `swapon /dev/ddX2` to set the swap partition.
* `mkfs.ext4 /dev/sdx3` ro set the root partition.

#### Mount the partitons

The disk is now ready to be used, but we need to mount it into the filesystem so we can interact with it (such as install to it).

* `mount /dev/sdX3 /mnt` to mount to root partition
* `mkdir /mnt/boot` to create a folder to mount the boot partition into
* `mount /dev/sdX1 /mnt/boot` to mount the boot partition

### Install packages

Install arch linux into the root partition using `pacstrap`. There are lots of choices of packages to install, I am going to install all of the packages in the following list. A lot of these are optional, but are all recomended.

* base and base-devel (base is arch, base-devel has useful packages such as cmake)
* linux and linux-firmware
* man-db and man-pages (optional, man pages for all the different commands)
* inetutils, netctl, dhcpcd (optional, used for networking)
* amd-ucode (use intel-ucode if you have an Intel CPU)
* vim (text editor, use whichever text editor you are comfortable with)

`pacstap /mnt base base-devel linux linux-firmware vim man-db man-pages inetutils netctl dhcpcd amd-ucode`

### Generate fstab

fstab file is used by the system to mount the disks automatically on boot. To generate run `genfstab -U /mnt >> /mnt/etc/fstab` which will generate the file in `/mnt/etc`.

### Change root onto the new system

`arch-chroot /mnt`

You are now running from the new arch linux system.

### Time zone

Set the timezone using `ln -sf /usr/share/zoneinfo/<region>/<city> /etc/localtime`. For met this is `ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime`.
Then run `hwclock --systohc`.

### Localisation

Open `/etc/locale/gen` and uncomment the required lines for your locale. As I am in the UK I am uncommenting the two lines `en_GB.UTF-8 UTF8` and `en_GB ISO-8859-1`. Save the file and then run `locale-gen`.
Create `/etc/locale.conf` and add in your locale. So I add `LANG=en_GB.UTF-8`.
If you are not using the default keyboard layout then you need to set the system to load the layout on startup. Add `/etc/vconsole.conf` and I will add `KEYMAP=uk`.

### Network configuration

Create `/etc/hostname` and add the hostname. I am going for `Arch2019`.
Create `/etc/hosts` and set the file to:
```
127.0.0.1   localhost
::1         localhost
127.0.1.1   Arch2019.localdomain Arch2019
```

### Root password

Run `passwd` to set the root password.

### Boot loader

For this I will be using the systemd bootloader, arch already uses systemd. You could also use GRUB which I think has more features, but this is not covered here.

#### Install Bootloader

Run `bootctl --path=/boot install`

#### Configure the loader.conf

`cd /boot/loader` and edit `loader.conf`. Change the large string before `-*` to arch, so it reads `default arch-*` on the third line.

#### Configure the entries

`cd` into the entries dir and create `arch.conf`. The file should look like below. If you have a Intel CPU and installed `intel-ucode` earlier then substitute that instead of the `amd-ucdoe`.

```
title   Arch Linux
linux   /vmlinuz-linux
initrd  /amd-ucode.img
initrd  /initramfs-linux.img
options root=UUID=<boot UUID> rw
```

To get the UUID of the root partition in the terminal run `blkid` and find the UUID from the line with `/dev/sdX3`. If you use vim you can `:r! blkid` to read the data into your buffer and cut the UUID from there.

### Finished core install

You should now have finished the core install. Run reboot to restart your computer and boot into arch linux.

## Part 2 - Next Steps

Arch linux is installed, but almost nothing else. This next section will cover configuring another user, sound, network, window managers etc.

