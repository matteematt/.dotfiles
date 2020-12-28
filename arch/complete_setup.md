# Complete Arch Linux Setup 2020

This is a complete readme document to set up arch linux using a UEFI BIOS for Arch Linux 2020. This uses I3 (with gaps) for the Window Manger and XOrg as the display server.

## Part 1 - Installing Arch Linux

This document only covers installing for the exact process I have used before. For this you will need an ethernet connection and a USB drive. It is possible to use Wifi, but it has extra steps that are not covered here.

### Getting the ISO

Download Arch Linux 2020 and write the ISO to a USB stick

Use `lsblk` to view the block devices currently seen by the operating system. Find the USB drive (it helps to look at the size) and the drive should be called `sdX` where `X` is another letter. Partitions on each block device are listed as `sdX(1,2...n)`. To write the arch linux iso run `dd if=/path/to/archlinux.iso of=/dev/sdX status="progress"` where `X` is the letter of the USB drive. Once this has done and reported with no errors, restart the computer and boot into the USB drive.
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

Use `lsblk` again, but this time you need to identify which drive is the drive you want to install arch linux to. If you only have one drive then it is likely `sda`. If you have multiple then you will need to work out which drive it is. Once you have identified the drive run `fdisk /dev/sdX`.

> nvme drives appear as nvmeXn1, which each of their partitions Y being nvmeXn1pY

#### Using fdisk

Type `m` for help in the fdisk prompt. If this drive already has been used before, keep pressing d to remove to partitions until there are none left. Then press `g` for GPT partition tables.
Type `n` for new partition, enter for defualt drive number (1) and enter for default first sector location. Recommended sector size for boot partition according to the arch wiki of 512MB so type +512M for last sector.
Type `n` for a new partition, enter for the default drive number (2) and enter for the sector start. This is the swap partition, recommended size is 1.5 * your RAM. So I will type +24G for the last sector. N.B: You can get away with more or less swap depending on what you are doing. Once I upgraded my PC with 32Gb or RAM I only created a 32GB sector. You could use far less swap if you would like, YMMV.
Type `n` for a new partition, enter for the default drive number (3) and enter for the sector start. This is the root directory, you want to just take up the rest of the space so press enter again for the default sector end.
Type `t` to change types. Once you are doing this you can press `l` to see the different disk types. For partition 1 set it to type 1 (EFI System). For partition 2 set it to type 19 (linux swap). For partition 3 set it to type 24 (linux root (x86-64)).
Type `w` to write all these changes and finish using fdisk.

> The numbers of the partition types may change over time, double check the names rather than blindly following the numbers

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

#### Install Arch Linux

Install arch linux into the root partition using `pacstrap`. There are lots of choices of packages to install, I am going to install all of the packages in the following list. A lot of these are optional, but are all recomended.

* base and base-devel (base is arch, base-devel has useful packages such as cmake)
* linux and linux-firmware
* man-db and man-pages (optional, man pages for all the different commands)
* inetutils, netctl, dhcpcd (optional, used for networking)
* amd-ucode (use intel-ucode if you have an Intel CPU)
* vim (text editor, use whichever text editor you are comfortable with)

`pacstrap /mnt base base-devel linux linux-firmware vim man-db man-pages inetutils netctl dhcpcd amd-ucode`

### Generate fstab

fstab file is used by the system to mount the disks automatically on boot. To generate run `genfstab -U /mnt >> /mnt/etc/fstab` which will generate the file in `/mnt/etc`.

### Change root onto the new system

`arch-chroot /mnt`

You are now running from the new arch linux system.

### Time zone

Set the timezone using `ln -sf /usr/share/zoneinfo/<region>/<city> /etc/localtime`. For met this is `ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime`.
Then run `hwclock --systohc`.

### Localisation

Open `/etc/locale.gen` and uncomment the required lines for your locale. As I am in the UK I am uncommenting the two lines `en_GB.UTF-8 UTF8` and `en_GB ISO-8859-1`. Save the file and then run `locale-gen`.
Create `/etc/locale.conf` and add in your locale. So I add `LANG=en_GB.UTF-8`.
If you are not using the default keyboard layout then you need to set the system to load the layout on startup. Add `/etc/vconsole.conf` and I will add `KEYMAP=uk`.

### Network configuration

Create `/etc/hostname` and add the hostname. I am going for `Arch2020`.
Create `/etc/hosts` and set the file to:
```
127.0.0.1   localhost
::1         localhost
127.0.1.1   Arch2020.localdomain Arch2020
```

### Root password

Run `passwd` to set the root password.

### Boot loader

#### systemd bootloader

##### Install Bootloader

Run `bootctl --path=/boot install`

##### Configure the loader.conf

`cd /boot/loader` and edit `loader.conf`. Change the large string before `-*` to arch, so it reads `default arch-*` on the third line.

##### Configure the entries

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

### Add another user

`useradd -m -g wheel <user>` and then `passwd <user>`. Adding to the wheel group so you can elevate your privileges with `sudo`. To allow wheel group to do this edit the `/etc/sudoers` file and remove the comment from the line `%wheel ALL=(ALL) ALL`. You can now logout of the root user and login as your new user.

### Setting up network connection

This is only to set up ethernet connection. To ensure the ethernet connection service is started during launch we add it to systemd. To list the available internet devices run `ip link`. Find the ethernet one, for example `enp2s0`. Then run `sudo systemctl enable dhcpcd@<device>`, so mine would be `dhcpcd@enp2s0`.

> You may need to start the systemd service for ethernet right now - "enable" sets to start on startup, "start" starts the service now

### Shell

Using `zsh` rather than `bash` for the shell environment. To change the default shell for the user run `chsh -s
/bin/zsh`.

### Audio

Now there is an internet connection we can use the `pacman` package manager. Get the alsa utils using `pacman -S alsa-utils`. Configure the sound using `alsamixer`, remember to un-mute the device using `m`.

### Other packages

You can install any packages you need with `pacman`. Some good packages to get at this time would be ssh access and git access. `sudo pacman -S git openssh`. Once the ssh key has been set up for git you can run `ssh-add` once per boot and add your password so you don't need to keep adding in the password again. Starting the agent with `ssh-agent` is taken care of in the `~/.xinitrc` which is used for the graphical environment in part 3.

> Follow the github guide on setting up ssh to see how to create the RSA public key required for ssh

#### Dotfiles

With git we can now pull our dotfiles into our home directory. You may need a browser such as chromium at this point to access the repo online. One we have dotfiles we can start installing configs such as out `.vimrc` and `.zshrc`. There is an install script provided which should sort out symlinks and some linuxbrew files. You will need to install linuxbrew before running this script so it can run everything.

> You may need to clone this with https if you have not yet been able to setup the ssh. To be able to push changes to the branch you will want to be using ssh clone so don't commit changes to the repo before cloning again with ssh later

#### Linuxbrew

To run our vim config some packages such as bat need installing through brew. Install brew. The `.zshrc` from the dotfiles already has the linuxbrew path set. Install the required brew packages using the `install.sh` dotfiles script, remember to set the path for fzf.
`sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
`

#### Misc Packages

##### AUR

Here is a list of useful packages that I use. AUR packages are installed with git clone and then running `makepkg -si` in the cloned directory. `-s` checks for dependencies using pacman, and `-i` installs the build package after a successful build. To update a package you can `git pull` and then run `makepkg -si` again, or you can use a tool like `yay` which can automate this process.
The best way I have found so far for checking whether AUR packages need to be updated is just to use the i3 blocks AUR plugin, which is set up in the i3 blocks config.

* Vim config uses ctags, to do this you [need a package from the AUR](https://aur.archlinux.org/packages/universal-ctags-git/)
* [Spotify from the AUR](https://aur.archlinux.org/packages/spotify/)
* [ckb-next](https://aur.archlinux.org/packages/ckb-next/) is an open source port of the proprietary corsair CUE software for mac and linux. To start as a systemd service `sudo systemctl enable ckb-next-daemon.service`
* [yay](https://aur.archlinux.org/packages/yay/) is a AUR helper which uses the same API as pacman for updating AUR packages

## Part 3 - Graphical Environment

This covers the i3 gaps window manager and other items for the graphical environment.

### Fonts

Over the next steps we are going to start working with a graphical environment so its a good time to get some fonts. You can get some useful fonts from google using `pacman -S noto-fonts`. To install the nerd front from the dotfiles `cp ~/.dotfiles/Monaco Nerd Font Complete Mono.otf /usr/share/fonts/<create a folder>/` and then run `fc-cache` to refresh the fonts cache. The nerd font should now be installed for use.

### Install the display server

`sudo pacman -S xorg-server xorg-xinit` and remember to symlink the `.xinitrc` and `.Xresources` from the dotfiles. NOTE: your graphical environment will go back to using USA layout so you need to add your country code in `.xinitrc`. Mine contains `setxkbmap gb`.

Start the display server when logged in with `startx`.

### Graphics card driver

#### AMD Radeon

For my AMD graphics card I could use the mesa driver provided at `sudo pacman -S mesa`

#### NVIDIA

NVIDIA cards are slightly move involved (a lot more involved if you are wanting to use open source drivers or are using
a legacy graphics card). I just used the proprietary NVIDIA drivers, and because my graphics card is fairly new its
still supported. I can just use the `nvidea` package from pacman, there are instructions on the wiki on how to verify
whether the card is still supported.

You will need to download a different version of the nvidia package depending on what type of kernel is in use (linux or
linux-lts etc.). You can also use a pacman hook to update `initramfs` with nvidia updates, the hook code is on the wiki.
You need to also change the hook code slightly depending on the kernel in use.

### Window Manager

`pacman -S i3-gaps i3blocks terminator dmenu`

* i3-gaps is the window manager based on i3 but with optional gaps between windows
* i3blocks is used on the status bar. By default i3 uses i3status but this configuratiuon uses i3blocks instead
* terminator is the terminal emulator used in the graphical environment
* dmenu is used to launch programs

Make sure to symlink the configs for i3!

From the i3 conf, i3 is attempting to put workspace 10 on `DVI-I-1` monitor. The name of monitors to configure this can be found by running `xrandr --listmonitors`.

ckb-next is the program used to control the corsair hardware. It is launched on startup of i3wm, but the GUI is sent to the scratchpad as it is not needed to be interacted with every session. To interact with the GUI it must be brought back from the scratchpad.

#### i3blocks

i3blocks is the status indicators shown on the right hand size of the i3 bar. They are customised in a `i3blocks.conf` file which should be symlinked. They work by running scripts at set intervals and showing STDOUT in the i3 bar. Some of the scripts used have dependencies - a link to a pack on github is found in the conf file. Clone this to `~/installs/misc`. The required dependency for each script is a comment above each block. Some will require packages to be downloaded.

### Terminal Emulator

I am using alacritty for the terminal emulator on the most recent install. This just requires the `yml` config file from
the dotfiles. If you use a different terminal emulator you will need to add config and change the i3 config to use the
new terminal instead.

### Setting up monitors

Use `xrandr` and `arandr` to set up multiple monitors such as resolutions. You can then get the output from arandr and add it to the i3 config. However, this is not currently used as the default it working fine.

## Part 4 - Misc

### Add windows to systemd boot menu from another disk

For an EFI install, if both Windows and Arch are installed on the same drive then systemd boot should detect the Windows
boot files and auto generate the boot `conf` files, which would only require you to edit the `/boot/loader/loader.conf`
file to add a `timeout` option so you could choose which system to boot.

If your Windows install is on another drive you can set up the dual booting with a clever trick
* `sudo lsblk` to find the name of the windows boot partition. On my most recent install this was `100M` and the first
		partition on the Windows drive.
* `mkdir /mnt/tmp` to create a directory to mount the windows disk into.
* `mount /dev/<win boot partion> /mnt/tmp` to mount the windows disk onto the filesystem.
* `cp -r /mnt/tmp/EFI/Microsoft /boot/EFI/` to copy the boot files into the systemd boot settings.
* Ensure `loader.conf` is configured with a timeout as mentioned in the above paragraph.

### systemd-boot build hook

Arch wiki has an explanation of how to set up a build hook to automate the update process of systemd-book for either
secure or normal boot. Using secure boot you can get the hook to resign the kernel.

### pacman config

#### Config

As well as using hooks, `pacman` can be configured using `/etc/pacman.conf`. One configuration I like is to un-comment
the `Color` option to get coloured output when using `-Q` query commands.

#### pacman mirror list

The mirror list that pacman uses can be found at `/etc/pacman.d/mirrorlist`. You can follow these steps to update this
file with the fastest mirrors for your region

* Ensure you have the `pacman-contrib` package installed as you need the included `rankmirrors` script
* Make a backup of the current mirror list
* `curl -s "https://archlinux.org/mirrorlist/?country=GB&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 -` can be used to get the 5 fastest mirrors for the region `GB`. You can change the country or add multiple if required.
* Edit the mirror list with these 5 fastest mirrors.

> It is recommended to recalculate the best mirrors occasionally

### Redshift

Redshift the is blue light filter program that I use to emulate the nightlight features of MacOS and Windows. Download
the package from the AUR and then use the config provided in `arch/.config/redshift.conf` to control it (the install
script should symlink the `conf`.

To get the service to run at startup you can use systemd, but its a user service so you invoke it with `systemctl --user
enable redshift.service` (notice no `sudo` and the `--user` flag). I had issues with the provided service file that
comes with the install - an example file with included modifications can be found at `arch/.config/redshift.service`.
