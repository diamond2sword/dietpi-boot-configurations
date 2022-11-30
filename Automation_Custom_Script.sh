
echo_as_red() {
	string="$1"
	color_red='\033[0;31m'
	color_reset='\033[m'
	echo -e "$color_red$string$color_reset"
}

echo_as_blue() {
	string="$1"
	color_blue='\033[0;34m'
	color_reset='\033[m'
	echo -e "$color_blue$string$color_reset"
}

echo_as_red "installing graphical desktop application"
{
	echo_as_blue "installing screenshot software"
	apt install -y flameshot

	echo_as_blue "installing image viewer"
	apt install -y eog 
}

echo_as_red "installing office tools"
{
	echo_as_blue "installing PDF document viewer"
	apt install -y evince

	echo_as_blue "installing image scanner"
	apt install -y xsane
}

echo_as_red "installing general tools"
{
	echo_as_blue "installing password manager"
	apt install -y keepassxc 

	echo_as_blue "installing calculator"
	apt install -y kcalc

	echo_as_blue "installing graphical text editor"
	apt install -y gedit

	echo_as_blue "installing advance file manager"
	apt install -y krusader

	echo_as_blue "installing terminal emulator"
	apt install -y konsole

	echo_as_blue "installing archiving or zip/unzip tool"
	apt install -y xarchiver
}

echo_as_red "installing virtual keyboards"
{
	echo_as_blue "installing matchbox keyboard"
	apt install -y matchbox-keyboardo

	echo_as_blue "installing onboard keyboard"
	apt install -y onboard
}

echo_as_red "installing preferred apps"
{

	echo_as_blue "installing web browser"
	apt install -y midori 
}

echo_as_red "registering username: \"admin\" password: \"12345\""
{
	useradd -m -s /bin/bash admin 
	echo admin:12345 | chpasswd
}

echo_as_red "rebooting"
reboot
