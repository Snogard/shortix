#!/bin/sh

# Set variables for all needed files an paths
PROTONTRICKS_NATIVE="protontricks"
PROTONTRICKS_FLAT="flatpak run com.github.Matoking.protontricks"
PROTONTRICKS_FLATID="com.github.Matoking.protontricks"
LINK_COMMAND="ln -sTf"
PYTHON_COMMAND=python
PIP_COMMAND=pip

CACHE_PATH=$HOME/.cache/Shortix
CONFIG_PATH=$HOME/.config/Shortix
DATA_PATH=$HOME/.local/share/Shortix

TEMP_PATH=/tmp/shortix-$(id -u)
PROTONTRICKS_OUTPUT="$TEMP_PATH/protontricks_output.txt"
LIBRARY_PATH_INFO_OUTPUT="$TEMP_PATH/library_path_info_output.txt"

SHORTIX_DIR=$HOME/Shortix
DEFAULT_LIBRARY_PATH=$HOME/.steam/steam
SHADER_SHORTIX=$SHORTIX_DIR/_Shaders
WORKSHOP_SHORTIX=$SHORTIX_DIR/_Workshop

FIRSTRUN=$CACHE_PATH/first_run
LASTRUN=$CACHE_PATH/last_run

force_flag="false"
print_usage() {
    echo "shortix flags:"
    echo "-f: forces shortix execution"
}

while getopts 'f' flag; do
  case "${flag}" in
    f) force_flag="true" ;;
    *) print_usage
       exit 1 ;;
  esac
done


# Search for a valid script folder
if [ -d "./scripts" ] && [ -f "./shortix.sh" ]; then
    SCRIPT_PATH="./scripts"
elif [ -d "/usr/share/shortix/scripts" ]; then
    SCRIPT_PATH="/usr/share/shortix/scripts"
elif [ -d "$DATA_PATH/scripts" ]; then
    SCRIPT_PATH="$DATA_PATH/scripts"
else
    echo "No script path found, make sure Shortix was installed successfully"
    exit -1
fi

# clears temp folder
if [ -d "$TEMP_PATH" ]; then
    rm -r $TEMP_PATH
fi
mkdir -p $TEMP_PATH
mkdir -p $CACHE_PATH

# pfx_id: Id of the steam game
# returns the library path of the steam game on stdout
get_library_path() {
    local pfx_id=$1

    local id_found=false
    if [ -f "$HOME/.steam/steam/config/libraryfolders.vdf" ]; then
        if [ ! -f $LIBRARY_PATH_INFO_OUTPUT ]; then
            $PYTHON_COMMAND $SCRIPT_PATH/print_library_path_info.py > $LIBRARY_PATH_INFO_OUTPUT
        fi

        while IFS=';' read  game_id library_path; do
            if [ "$pfx_id" = "$game_id" ]; then
                id_found=true
                echo "$library_path"
            fi
        done < $LIBRARY_PATH_INFO_OUTPUT
    fi
    if ! $id_found; then
        echo "$DEFAULT_LIBRARY_PATH"
    fi
}

# game_id: Id of the steam game
# returns the compatdata path of the steam game on stdout
get_compatdata_path(){
    local game_id=$1
    echo "$(get_library_path $game_id)/steamapps/compatdata"
}

# game_id: Id of the steam game
# returns the shadercache path of the steam game on stdout
get_shadercache_path(){
    local game_id=$1
    echo "$(get_library_path $game_id)/steamapps/shadercache"
}

# game_id: Id of the steam game
# returns the workshop content path of the steam game on stdout
get_workshop_path(){
    local game_id=$1
    echo "$(get_library_path $game_id)/steamapps/workshop/content"
}

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


shortix_script () {
    #Check if and how protontricks is installed, if yes run in, if no, stop the script
    if [ "$(command -v $PROTONTRICKS_NATIVE)" ]; then
        PROTONTRICKS=$PROTONTRICKS_NATIVE
    elif [ "$(flatpak info "$PROTONTRICKS_FLATID" >/dev/null 2>&1 && echo "true")" ]; then
        PROTONTRICKS=$PROTONTRICKS_FLAT
    else
        echo "Protontricks could not be found! Please install it. Aborting..."
        exit
    fi

    # Loading python virtual environment if present
    if [ -f "$CONFIG_PATH/venv/bin/activate" ]; then
        source $CONFIG_PATH/venv/bin/activate
    fi

    # Check if python-vdf is installed
    if ! $($PYTHON_COMMAND -c "import vdf" &> /dev/null) ; then
        echo "Python vdf is not installed, please use your package manager or do it manually:"
        echo "$PYTHON_COMMAND -m venv $CONFIG_PATH/venv"
        echo "source $CONFIG_PATH/venv/bin/activate"
        # check if pip is not present
        if [ ! $(command -v $PIP_COMMAND) ]; then
            echo "$PYTHON_COMMAND -m ensurepip --upgrade"
        fi
        echo "$PIP_COMMAND install \"git+https://github.com/solsticegamestudios/vdf\""
        exit
    fi


    eval "$PROTONTRICKS" -l > $PROTONTRICKS_OUTPUT 2> /dev/null

    #remove all lines which doesn't have a round bracket in it
    sed -i -ne '/)/p' $PROTONTRICKS_OUTPUT

    #Remove the "Non_Steam shortcut: " string from temp file
    sed -i 's/Non-Steam shortcut: //' $PROTONTRICKS_OUTPUT

    #Remove semicolons from game names because we use semicolons as separator later on
    sed -i -E 's/\;/ /g' $PROTONTRICKS_OUTPUT

    #Replace the last occurence of closing and opening round brackets and replace them with semicolons and remove trailing space in one go
    sed -i -E 's/ \(([^)]+)\)$/;\1;/' $PROTONTRICKS_OUTPUT

    #Remove non existant symlinks
    find -L $SHORTIX_DIR -maxdepth 1 -type l -delete

    # Check if the id file is present. If true, then append the prefix id to the game name.
    #Create symlinks based on the data from the temp file.
    #IFS defines the semicolon as column separator
    #Then read the both columns as variables and create symlinks based on the data of each line
    #Also create the _Shader and _Workshop directories and create symlinks to the shadercache and workshop content directories.
    #Some games don't use shadercache, if so, the dead end symlink will be removed directly
    #If size file is found add the size to the file name
    mkdir -p $SHADER_SHORTIX
    mkdir -p $WORKSHOP_SHORTIX

    append_id=$([ ! -f $CONFIG_PATH/id ] && echo false)
    append_size=$([ ! -f $CONFIG_PATH/size ] && echo false)

    find -L $SHADER_SHORTIX -maxdepth 1 -type l -delete
    find -L $WORKSHOP_SHORTIX -maxdepth 1 -type l -delete


    while IFS=';' read game_name prefix_id; do
        # Compatdata target
        target="$SHORTIX_DIR/$game_name"
        if [[ ! $target =~ \ -\ [0-9.]+[A-Z] ]]; then
            if $append_id; then
                target="$target ($prefix_id)"
            fi
            if $append_size; then
                SIZE=$(du -shH "$(get_compatdata_path $prefix_id)/$prefix_id" | cut -f1)
                target="$target - $SIZE"
            fi
            $LINK_COMMAND "$(get_compatdata_path $prefix_id)/$prefix_id" "$target"
        fi

        # Shadercache
        target="$SHADER_SHORTIX/$game_name"
        if [[ ! $target =~ \ -\ [0-9.]+[A-Z] ]]; then
            if [ -d $(get_shadercache_path $prefix_id)/$prefix_id ]; then
                if $append_id; then
                    target="$target ($prefix_id)"
                fi
                if $append_size; then
                    SIZE=$(du -shH "$(get_shadercache_path $prefix_id)/$prefix_id" | cut -f1)
                    target="$target - $SIZE"
                fi
                $LINK_COMMAND "$(get_shadercache_path $prefix_id)/$prefix_id" "$target"
            fi
        fi

        # Workshop
        target="$WORKSHOP_SHORTIX/$game_name"
        if [[ ! $target =~ \ -\ [0-9.]+[A-Z] ]]; then
            if [ -d $(get_workshop_path $prefix_id)/$prefix_id ]; then
                if $append_id; then
                    target="$target ($prefix_id)"
                fi
                if $append_size; then
                    SIZE=$(du -shH "$(get_workshop_path $prefix_id)/$prefix_id" | cut -f1)
                    target="$target - $SIZE"
                fi
                $LINK_COMMAND "$(get_workshop_path $prefix_id)/$prefix_id" "$target"
            fi
        fi
    done < $PROTONTRICKS_OUTPUT

    if [ -f $CONFIG_PATH/backup ]; then
            BACKUP_DIR=$(cat $CONFIG_PATH/backup)/Shortix-Backup
            if [ -d "$BACKUP_DIR" ]; then
                rm -rf $BACKUP_DIR
            fi
            mkdir -p "$BACKUP_DIR"
            cp -apR $SHORTIX_DIR/* "$BACKUP_DIR"
            cp -apR $SHORTIX_DIR/.* "$BACKUP_DIR"
    fi

    touch "$LASTRUN"
}

python_check

if [ ! -d "$(get_compatdata_path)" ]; then
    echo "Steam compatibility data directory ($(get_compatdata_path)) could not be found! Aborting..."
    exit
fi

# TODO make a last run for each folder found
if [ ! -f $FIRSTRUN ]; then
    shortix_script
    touch "$FIRSTRUN"
else
    dorun=1
    # if there is lastrun file, only run if there are compatdata folders newer than the lastrun file timestamp
    if [ -f $LASTRUN ]; then
        dorun=0
        lastrun_timestamp=$(date +%s -r "$LASTRUN")
        if [ "$(find $(get_compatdata_path) -newermt "@${lastrun_timestamp}" -type d)" ]; then
            dorun=1
        fi
    fi
    
    if [[ $force_flag == "true" ]]; then
        dorun=1
    fi

    if [ $dorun -eq 1 ]; then
        shortix_script
    fi
fi




echo "Done, you can close this window now!"
