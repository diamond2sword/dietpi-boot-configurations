systemctl enable dietpi-fs_partition_resize

NET_CONF_DIR="/etc/network/interfaces.d"

mkdir -p $NET_CONF_DIR
cat << "EOF" > $NET_CONF_DIR/usb0.conf
allow-hotplug usb0
iface usb0 inet static
address 192.168.1.123/24
gateway 192.168.1.1
EOF

cat << "EOF" >> /boot/config.txt

dtoverlay=dwc2,dr_mode=peripheral

EOF

sed -ir '{
  s/(rootwait)/\1 modules-load=dwc2,g_ether /
}' /boot/cmdline.txt
