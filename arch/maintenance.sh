#!/bin/bash

# There are more manual things that its worth checking, more info on the wiki
# https://wiki.archlinux.org/index.php/System_maintenance
# example, checking systemd for failed services

# Check for arch news and update if there is no news
echo "Updating system"
sudo informant check && sudo pacman -Syu

# Update AUR packages
echo "Updating AUR"
yay -Syu

# Update brew packages
echo "Updating brew"
brew update && brew upgrade

# Keep a backup of the currently installed pacman packages, *not* listing
# dependencies but pacman will take care of that. TODO: this list includes
# things like amd-ucode and nvidia so be careful if changing hardware
# Includes AUR packages
# Use AUR to see how to install from this list
echo "Backup installed packages list"
pacman -Qqet > ~/.dotfiles/arch/pkglist.txt
brew list --versions > ~/.dotfiles/arch/brewlist.txt
rsync -a --exclude='yay' $HOME/.cache $HOME/.cache.bak

# Clear pacman cache, but keep the three most recent versions
echo "Clearing pacman cache"
sudo paccache -rk3 -v

# Regenerate a new list of mirrors, keep an old backup
echo "Updating mirror list"
tmpList="/tmp/mirrorlist"
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
echo -e "#Generated by maintenance.sh\n#Last updated: $(date)" > "$tmpList"
curl -s "https://archlinux.org/mirrorlist/?country=FR&country=GB&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - >> "$tmpList"
retVal=$?
if [ $retVal -ne 0 ]; then
  echo "Error updating mirrorlist, not overwriting current list. Exit code $retVal"
else
  sudo cp "$tmpList" /etc/pacman.d/mirrorlist
fi

# TODO?
# update hosts file with ad blocking URLs?

# Check for orphaned packages, either remove these or mark as explicit
echo "Orphaned packages:"
pacman -Qtd

# Clean up systemd logs as they can grown very large
sudo journalctl --vacuum-time=12weeks

echo -e "\\nUpdate nvim packages with"
echo "nvim $HOME/.dotfiles/config/nvim/lua/user/plugins.lua"
