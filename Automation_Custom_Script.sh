#!/bin/bash

main () {
	include_dependency_strings
	create_dependency_scripts
	include_dependency_scripts
	install_dependency_packages
	install_visual_recognition_project
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
EOF
)

finish_by_rebooting () {
    reboot
}

install_visual_recognition_project () {
    mkdir -p $PROJECT_PATH
    svn export --force $PROJECT_GITHUB_LINK $PROJECT_PATH
    python3 $PROJECT_PATH/$PROJECT_FILE_INSTALL_NAME
}

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
