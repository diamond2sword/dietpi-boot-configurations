main () {
	fix_fs_partition
	configure_usb_for_vnc
}

NET_CONF_DIR="/etc/network/interfaces.d"

configure_usb_for_vnc () {
eval << "EOF" | sed -r 's/^(\t| )+//g'
	mkdir -p $NET_CONF_DIR
	
	cat << "EOF2" > $NET_CONF_DIR/usb0.conf
		allow-hotplug usb0
		iface usb0 inet static
		address 192.168.1.123/24
		gateway 192.168.1.1
	EOF2

	cat << "EOF2" >> /boot/config.txt
		dtoverlay=dwc2,dr_mode=peripheral
	EOF2

	sed -ir '{
		s/(rootwait)/\1 modules-load=dwc2,g_ether /
	}' /boot/cmdline.txt
EOF
}

fix_fs_partition () {
 	systemctl enable dietpi-fs_partition_resize
}

main "$@"
