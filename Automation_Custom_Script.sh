#!/bin/bash

main () {
	create_setup_log_viewer && create_setup_log_viewer
	include_dependency_strings && echo include_dependency_strings
	create_dependency_scripts && echo create_dependency_scripts
	include_dependency_scripts && echo include_dependency_scripts
	install_dependency_packages && echo install_dependency_packages
	install_visual_recognition_project && echo install_visual_recognition_project
	create_application_launcher && create_application_launcher
	start_vnc_server_service && echo start_vnc_server_service
	delete_setup_log_viewer && echo delete_setup_log_viewer
	finish_by_rebooting
}

STRINGS=$(cat << \EOF
###################################################################
DEPENDENCY_PATH="/boot/automation-script-dependencies"
DEPENDENCY_NAMES="STRINGS SCRIPTS FORCE_INSTALL PATHS"
APT_PACKAGES="libgl1-mesa-glx subversion lynx expect git ssh"
PIP3_PACKAGES="pillow onnxruntime torchvision gdown term-image opencv-python tqdm"
DESKTOP_PACKAGES="kcalc gedit onboard"
PROJECT_NAME="project"
PICTURE_NAME="test.jpg"
PROJECT_INSTALL_FILE_NAME="install.py"
PROJECT_APP_FILE_NAME="classifiers.py"
PROJECT_ANY_CLASS_NAME="Any"
PROJECT_TEST_DATASET_NAME="test-dataset"
PROJECT_GITHUB_LINK="https://github.com/diamond2sword/visual-recognition-project/trunk/project-raspberrypi/project-v1"
EOF
)

PATHS=$(cat << \EOF
###################################################################
ROOT_PATH="/root"
DESKTOP_PATH="$ROOT_PATH/Desktop"
PROJECT_PATH="$DESKTOP_PATH/$PROJECT_NAME"
TEST_DATASET_PATH="$PROJECT_PATH/$PROJECT_TEST_DATASET_NAME"
CLASS_PATHS=(ls -d $TEST_DATA_SET_PATH/*/)
ANY_CLASS_PATH="$TEST_DATASET_PATH/$PROJECT_ANY_CLASS_NAME"
BOOT_SCRIPT_PATH="/var/lib/dietpi-autostart/custom.sh"
SETUP_LOG_VIEWER_PATH="/etc/profile.d/setup_log_viewer.sh"
PROJECT_APP_FILE_PATH=$PROJECT_PATH/$PROJECT_APP_FILE_NAME
APPLICATIONS_PATH="/usr/share/applications"
EOF
)

create_application_launcher () {
rm -rf $APPLICATIONS_PATH/$PROJECT_APP_FILE_NAME.desktop $DESKTOP_PATH/$PROJECT_APP_FILE_NAME.desktop
cat << EOF > $APPLICATIONS_PATH/$PROJECT_APP_FILE_NAME.desktop
[Desktop Entry]
Name=$PROJECT_APP_FILE_NAME
Exec=x-terminal-emulator -e 'python3 $PROJECT_PATH/$PROJECT_APP_FILE_NAME; read'
Type=Application
Categories=Application
EOF
ln -s $APPLICATIONS_PATH/$PROJECT_APP_FILE_NAME.desktop $DESKTOP_PATH/$PROJECT_APP_FILE_NAME.desktop
}

finish_by_rebooting () {
	reboot
}

delete_setup_log_viewer () {
	rm -rf $SETUP_LOG_VIEWER_PATH
}

install_visual_recognition_project () {
	mkdir -p $PROJECT_PATH
	svn export --force $PROJECT_GITHUB_LINK $PROJECT_PATH
	python3 $PROJECT_PATH/$PROJECT_INSTALL_FILE_NAME
}

start_vnc_server_service () (
	systemctl enable vncserver
	systemctl restart vncserver
	timeout 1s /usr/local/bin/vncserver start
)

install_dependency_packages () {
	force_install apt ${APT_PACKAGES[@]}
	force_install pip3 ${PIP3_PACKAGES[@]}
	force_install apt ${DESKTOP_PACKAGES[@]}
}

include_dependency_scripts () {  
	source $DEPENDENCY_PATH/SCRIPTS.sh
	include_dependencies_default
}

create_dependency_scripts () {
	mkdir -p $DEPENDENCY_PATH
	dependency_names=("$DEPENDENCY_NAMES")
	for dependency_name in ${dependency_names[@]}; do {
		commands="${!dependency_name}"
		create_file_for "$commands" $dependency_name
	} done
}

include_dependency_strings () {
	eval "$STRINGS"
}

create_setup_log_viewer () {
cat << "EOF" | sed -r 's/^( |\t)+//g' > /etc/profile.d/setup_log_viewer.sh
	main () {
		force_display_log
	}

	LOG_PATH="/var/tmp/dietpi/logs/dietpi-automation_custom_script.log"
	STOP_PHRASE="STOP_WAIT_FOR_SETUP"

	force_display_log () {
		create_vim_killer
		while true; do {
			is_log_complete && {
				break
			}
			vim $LOG_PATH '+:set updatetime=0 | set autoread | au CursorHold * checktime | call feedkeys("G")'
		} done
	}

	create_vim_killer () { (
		while true; do {
			! is_log_complete && {
				continue
			}
			killall vim
			break
		} done
	) & }	

	is_log_complete () {
		[[ "$(sed -n '/'"$STOP_PHRASE"'/=' $LOG_PATH)" ]]
	}

	main
EOF
}

create_file_for () {
	commands="$1"
	dependency_name=$2
	file_name=$(add_sh_suffix_to $dependency_name)
	file_path=$DEPENDENCY_PATH/$file_name
	touch $file_path
	echo "$commands" > $file_path
	chmod +x $file_path
}

add_sh_suffix_to () {
	dependency_name=$1
	file_name=${dependency_name}.sh
	echo $file_name
}

SCRIPTS=$(cat << \EOF
####################################################################

include_dependencies_default () {
	include PATHS
	include FORCE_INSTALL 5
}

include () {
	dependency_name=$1
	shift
	dependency_args=("$@")
	file_name=$(add_sh_suffix_to $dependency_name)
	file_path=$DEPENDENCY_PATH/$file_name
	source $file_path ${dependency_args[@]}
}

add_sh_suffix_to () {
	dependency_name=$1
	file_name=${dependency_name}.sh
	echo $file_name
}

EOF
)

FORCE_INSTALL=$(cat << \EOF
###################################################################
force_install () {
	package_manager=$1
	shift
	packages=("$@")
	max_i=$MAX_FORCE_INSTALL
	i=0
	while :; do {
		is_force_install_limited && (($i >= $max_i)) && {
			break
		}
		is_installed_all $package_manager ${packages[@]} && {
			break
		}
		i=$(($i + 1))
		update $package_manager
		install_all $package_manager ${packages[@]}
	} done
}

update () {
	package_manager=$1
	sudo=$(get_sudo_string)
	case $package_manager in
		apt|apt-get) {
			yes | $sudo $package_manager update
			yes | $sudo $package_manager upgrade
		};;
		pip3) {
			$sudo pip3 install --upgrade --no-input pip
		};;
		*) {
			echo $package_manager is not defined.
		};;
	esac
}

is_installed_all () {
	package_manager=$1
	shift
	packages=("$@")
	for package in ${packages[@]}; do {
		is_installed $package_manager $package && {
			continue
		}
		return 1
	} done
	return 0
}

install_all () {
	package_manager=$1
	shift
	packages=("$@")
	for package in ${packages[@]}; do {
		install $package_manager $package
	} done
}

is_installed () {
	package_manager=$1
	package=$2
	case $package_manager in
		apt|apt-get) dpkg -s $package &> /dev/null && {
			return 0
		};;
		pip3) python3 -c "import pkgutil, sys; sys.exit(0 if pkgutil.find_loader(\"$package\") else 1)" || pip3 show $package &> /dev/null && {
			return 0
		};;
		*) {
			 echo "$package_manager is not defined."
		};;
	esac
}

get_sudo_string () {
	string=""
	is_installed apt sudo && {
		string=sudo
	}
	echo $string
}

install () {
	package_manager=$1
	package=$2
	sudo=$(get_sudo_string)
	case $package_manager in
		apt | apt-get) {
			yes | $sudo $package_manager install $package
		};;
		pip3) {
			$sudo pip3 install --upgrade --no-input $package
		};;
		*) {
			echo $package_manager is not defined.
		};;
	esac
}

is_force_install_limited () {
	(($MAX_FORCE_INSTALL != 0)) && {
		return 0
	}
}

is_number () {
	(($1 + 0)) &> /dev/null && {
		return 0
	}
}

MAX_FORCE_INSTALL=0

input=$1
is_number $input && {
	MAX_FORCE_INSTALL=$input
}

EOF
)

main
