xrdb ~/.Xresources
eval $(ssh-agent)
setxkbmap -option caps:escape
setxkbmap gb
numlockx on
systemctl --user import-environment DISPLAY
exec i3
