#/bin/sh
# Terminal color variables:
NC='\033[0m'  
CY='\033[1;96m'
RE='\033[1;91m'  
YL='\033[1;93m'

PROTONTRICKS_NATIVE="protontricks"
PROTONTRICKS_FLAT="flatpak run com.github.Matoking.protontricks"
PROTONTRICKS_FLATID="com.github.Matoking.protontricks"

CONFIG_PATH=$HOME/.config/Shortix
DATA_PATH=$HOME/.local/share/Shortix

PYTHON_COMMAND=python
PIP_COMMAND=pip

echo "Creating Folder at $DATA_PATH"
mkdir -p "$DATA_PATH"

if [ "$(command -v kdialog)" ]; then
	USEKDIALOG=true
else
	USEKDIALOG=false
fi

# removes the destination folder and then copies the source folder into the destination
# from: path to the source folder
# to: path to the destination folder
replace_folder(){
	local from=$1
	local to=$2

	if [ -d "$to" ]; then
		rm -r "$to"
	fi

	cp -r "$from" "$to"
}

# Displays a message to the user. Uses kdialog if present otherwise it prints to stdout
# title: title of the window 
# message: message to be displayed
display_message(){
	title=$1
	message=$2

	if [ $USEKDIALOG == true ]; then
  		kdialog --title "$title" --msgbox "$message"
  	else
		echo "$message"
  	fi
}

#Check if and how protontricks is installed, if yes run, if no, stop the script
if [ "$(command -v $PROTONTRICKS_NATIVE)" ]; then
	echo "Protontricks is installed natively"
elif [ "$(flatpak info "$PROTONTRICKS_FLATID" >/dev/null 2>&1 && echo "true")" ]; then
	echo "Protontricks is installed as Flatpak"
else
	if [ $USEKDIALOG == true ]; then
		kdialog --title "Shortix installer" --error "Protontricks not found! Please install Protontricks either as Flatpak or native by using pacman or yay."
		exit
	else
		echo -e "${RE}Protontricks could not be found! Please install it. Aborting...${NC}"
		read -n 1 -s -r -p "Press any key to continue"
		exit
	fi

fi

# Checks if python 3 is installed and saves the correct binary in PYTHON_COMMAND
python_check(){
    if [ "$(command -v python)" ]; then
        if [[ $(python -c 'import sys; print(sys.version_info[:][0])') -eq 2 ]] && [ "$(command -v python3)" ]; then
            PYTHON_COMMAND=python3
			PIP_COMMAND=pip3
        elif [[ $(python -c 'import sys; print(sys.version_info[:][0])') -eq 3 ]]; then
            PYTHON_COMMAND=python
			PIP_COMMAND=pip
        else
            echo "Python 3 could not be found! Please install it. Aborting..."
            exit
        fi
    elif [ "$(command -v python3)" ]; then
        PYTHON_COMMAND=python3
		PIP_COMMAND=pip3
    else
        echo "Python 3 could not be found! Please install it. Aborting..."
        exit
    fi
}

python_check

# Loading python virtual environment if present
if [ -f "$CONFIG_PATH/venv/bin/activate" ]; then
    source $CONFIG_PATH/venv/bin/activate
fi

# Check if python-vdf is installed system wide otherwise ask the user to create a virtual environment
if ! $($PYTHON_COMMAND -c "import vdf" &> /dev/null) ; then

	if [ $USEKDIALOG == true ]; then
		kdialog --title "Shortix Dependency Checker" --yesno "Would you like to install python vdf system wide yourself or would you like shortix to make a vritual environment?\nNOTE: click 'yes' if you are on SteamOS or other immutable distros." 2> /dev/null
		case $? in
		0)  venv_choice='y'
			;;
		1)  venv_choice='n'
			;;
		2)	venv_choice='n'
			;;
		esac
	else
	    echo "Would you like to install python vdf system wide yourself or would you like shortix to make a vritual environment?
NOTE: type 'y' if you are on SteamOS or other immutable distros."
		while [[ ! $venv_choice = 'y' ]] && [[ ! $venv_choice = 'n' ]]; do
			read  -n 1 -p "(y/n):" venv_choice
			if [[ ! $venv_choice = 'y' ]] && [[ ! $venv_choice = 'n' ]]; then
				echo " is not a valid choice."
			fi
		done
	fi

    if [[ $venv_choice = 'n' ]]; then
		display_message "Shortix Dependency Checker" "Use your package manager to install python vdf and relaunch shortix"
		exit 0
    elif [[ $venv_choice = 'y' ]]; then
        if [ -d "$CONFIG_PATH/venv" ]; then
            rm -r "$CONFIG_PATH/venv"
        fi
        echo "Installing python vdf inside a virtual environment"
        mkdir -p $CONFIG_PATH
        $PYTHON_COMMAND -m venv $CONFIG_PATH/venv
        source $CONFIG_PATH/venv/bin/activate
        # check if pip is not present
        if [ ! $(command -v $PIP_COMMAND) ]; then
            $PYTHON_COMMAND -m ensurepip --upgrade
        fi
        $PIP_COMMAND install "git+https://github.com/solsticegamestudios/vdf"
    fi
fi



if [ -d $HOME/Shortix/ ] || [ -f $HOME/.config/systemd/user/shortix.service ]; then
  TYPE="updater"
  if [ $USEKDIALOG == true ]; then
  	kdialog --title "Shortix $TYPE" --msgbox "Welcome to Shortix! This setup will update Shortix."
  else
  	echo -e "${CY}Welcome to Shortix-$TYPE. This setup will update Shortix.${NC}"
  	sleep 1
  fi
  rm -rf $HOME/Shortix
else
  TYPE="installer"
  if [ $USEKDIALOG == true ]; then
  	kdialog --title "Shortix installer" --msgbox "Welcome to Shortix! This setup will install Shortix."
  else
  	echo "${CY}Welcome to Shortix-$TYPE. This setup will install Shortix.${NC}"
  	sleep 1
  fi
fi

mkdir -p $HOME/Shortix
cp /tmp/shortix/shortix.sh $HOME/Shortix
cp /tmp/shortix/remove_prefix.sh $HOME/Shortix
replace_folder "/tmp/shortix/scripts" "$DATA_PATH/scripts"
cp /tmp/shortix/shortix_uninstall.sh $HOME/Shortix
chmod +x $HOME/Shortix/shortix.sh
chmod +x $HOME/Shortix/remove_prefix.sh
chmod +x $HOME/Shortix/shortix_uninstall.sh


if [ $USEKDIALOG == true ]; then
	kdialog --title "Shortix $TYPE" --yesno "Would you like to add the prefix id to the shortcut name?\nLike this:\nGame Name (123455678)" 2> /dev/null
	case $? in
	0)  if [ ! -f $CONFIG_PATH/id ]; then
	      touch $CONFIG_PATH/id
	    fi
	    ;;
	1)  if [ -f $CONFIG_PATH/id ]; then
	      rm -rf $CONFIG_PATH/id
	    fi
	    ;;
	esac
else
	read -p "Would you like to add the prefix id to the shortcut name? ike this: Game Name (123455678) " yn
	case $yn in
	yY)  if [ ! -f $CONFIG_PATH/id ]; then
	      touch $CONFIG_PATH/id
	    fi
	    ;;
	nN)  if [ -f $CONFIG_PATH/id ]; then
	      rm -rf $CONFIG_PATH/id
	    fi
	    ;;
	esac
fi

if [ $USEKDIALOG == true ]; then
	if [ -f $CONFIG_PATH/id ]; then
	  kdialog --title "Shortix $TYPE" --yesno "Would you also like to add the size of the target directory to the shortcut name?\nLike this: \nGame Name (123455678) - 1.6G" 2> /dev/null
	  case $? in
	  0)  if [ ! -f $CONFIG_PATH/size ]; then
		touch $CONFIG_PATH/size
	      fi
	      ;;
	  1)  if [ -f $CONFIG_PATH/size ]; then
		rm -rf $CONFIG_PATH/size
	      fi
	      ;;
	  esac
	else
	  kdialog --title "Shortix $TYPE" --yesno "Would you like to add the size of the target directory to the shortcut name?\nLike this:\nGame Name - 1.6G?"
	  case $? in
	  0)  if [ ! -f $CONFIG_PATH/size ]; then
		touch $CONFIG_PATH/size
	      fi
	      ;;
	  1)  if [ -f $CONFIG_PATH/size ]; then
		rm -rf $CONFIG_PATH/size
	      fi
	      ;;
	  esac
	fi
else
	if [ -f $CONFIG_PATH/id ]; then
	  read -p "Would you also like to add the size of the target directory to the shortcut name? Like this: Game Name (123455678) - 1.6G " yn 
	  case $yn in
	  yY)  if [ ! -f $CONFIG_PATH/size ]; then
		touch $CONFIG_PATH/size
	      fi
	      ;;
	  nN)  if [ -f $CONFIG_PATH/size ]; then
		rm -rf $CONFIG_PATH/size
	      fi
	      ;;
	  esac
	else
	  read -p "Would you like to add the size of the target directory to the shortcut name?\nLike this:\nGame Name - 1.6G? " yn
	  case $yn in
	  yY)  if [ ! -f $CONFIG_PATH/size ]; then
		touch $CONFIG_PATH/size
	      fi
	      ;;
	  nN)  if [ -f $CONFIG_PATH/size ]; then
		rm -rf $CONFIG_PATH/size
	      fi
	      ;;
	  esac
	fi
fi

if [ $USEKDIALOG == true ]; then
	kdialog --title "Shortix $TYPE" --yesno "Would you like to setup system service for background updates?"
	case $? in
	0)  if [ ! -d $HOME/.config/systemd/user ]; then
	    mkdir -p $HOME/.config/systemd/user
	    fi
	    cp /tmp/shortix/shortix.service $HOME/.config/systemd/user
	    systemctl --user daemon-reload
	    if ! systemctl is-enabled --quiet --user shortix.service; then
	      systemctl --user enable shortix.service
	    fi
	    systemctl --user restart shortix.service
	    ;;
	1)  if systemctl is-enabled --quiet --user shortix.service; then
	      systemctl --user disable shortix.service
	    fi
	    if [ -f $HOME/.config/systemd/user/shortix.service ]; then
	      rm $HOME/.config/systemd/user/shortix.service
	    fi
	      systemctl --user daemon-reload
	    ;;
	esac
else
	read -p "Would you like to setup system service for background updates? " yn
	case $yn in
	yY)  if [ ! -d $HOME/.config/systemd/user ]; then
	    mkdir -p $HOME/.config/systemd/user
	    fi
	    cp /tmp/shortix/shortix.service $HOME/.config/systemd/user
	    systemctl --user daemon-reload
	    if ! systemctl is-enabled --quiet --user shortix.service; then
	      systemctl --user enable shortix.service
	    fi
	    systemctl --user restart shortix.service
	    ;;
	nN)  if systemctl is-enabled --quiet --user shortix.service; then
	      systemctl --user disable shortix.service
	    fi
	    if [ -f $HOME/.config/systemd/user/shortix.service ]; then
	      rm $HOME/.config/systemd/user/shortix.service
	    fi
	      systemctl --user daemon-reload
	    ;;
	esac
fi

if [ $USEKDIALOG == true ]; then
	kdialog --title "Shortix Backup" --yesno "Would you like to create a backup of Shortix on a different location?\nIf yes, please select the location where the Shortix-Backup directory should be created."
	case $? in
	  0)  if [ ! -f $CONFIG_PATH/backup ]; then
		touch $CONFIG_PATH/backup
	      fi
	      ;;
	  1)  if [ -f $CONFIG_PATH/backup ]; then
		rm -rf $CONFIG_PATH/backup
	      fi
	      ;;
	esac
else
	read -p "Would you like to create a backup of Shortix on a different location?" yn
	case $yn in
	  yY)  if [ ! -f $CONFIG_PATH/backup ]; then
		touch $CONFIG_PATH/backup
	      fi
	      ;;
	  nN)  if [ -f $CONFIG_PATH/backup ]; then
		rm -rf $CONFIG_PATH/backup
	      fi
	      ;;
	esac
fi

if [ $USEKDIALOG == true ]; then
	if [ -f $CONFIG_PATH/backup ]; then
	  kdialog --getexistingdirectory . > $CONFIG_PATH/backup
	  mkdir -p $(cat $CONFIG_PATH/backup)/Shortix-Backup
	fi
else
	if [ -f $CONFIG_PATH/backup ]; then
 	read -p "Please enter your path where the Shortix-Backup directory should be created (like '/home/deck'): " backdir
  	mkdir -p $backdir/Shortix-Backup
   	fi
fi


if [ -f $HOME/.config/user-dirs.dirs ]; then
  source $HOME/.config/user-dirs.dirs
  if [ $XDG_DESKTOP_DIR/shortix_installer.desktop ]; then
    sed -i 's/Install/Update/' /tmp/shortix/shortix_installer.desktop
    mv /tmp/shortix/shortix_installer.desktop $XDG_DESKTOP_DIR/shortix_updater.desktop
    rm -rf $XDG_DESKTOP_DIR/shortix_installer.desktop
    chmod +x $XDG_DESKTOP_DIR/shortix_updater.desktop
  fi
fi

if [ $USEKDIALOG == true ]; then
	kdialog --title "Shortix $TYPE" --msgbox "Shortix is set up!"
else
	echo -e "${YL}Short is set up!${NC}"
	sleep 4
fi

[ $? = 0 ] && exit
