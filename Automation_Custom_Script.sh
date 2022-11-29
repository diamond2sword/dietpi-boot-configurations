apt install -y midori
apt install -y flameshot 
apt install -y eog 
apt install -y libreoffice 
apt install -y thunderbird 
apt install -y evince 
apt install -y xsane 
apt install -y keepassxc 
apt install -y kcalc 
apt install -y gedit 
apt install -y krusader 
apt install -y konsole 
apt install -y xarchiver
apt install -y python
apt install -y python3
apt install -y thonny

useradd -m -s /bin/bash admin
echo admin:12345 | chpasswd
reboot
