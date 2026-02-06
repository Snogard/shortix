![Shortix](https://raw.githubusercontent.com/Jannomag/shortix/main/shortix_logo.svg)     
A script that creates human readable symlinks for Proton game prefixes

# Latest update
Fixed nested symlink by using `ln -sTf` instead of just `ln -sf`. This was mentioned by [@MKReyesH](https://github.com/MKReyesH) in issue [#8](https://github.com/Jannomag/shortix/issues/8). Thanks for this!
To update just run the desktop shortcut or redownload it from the releases (nothing got changed to the shortcut itself).
  
# Prerequireties
### Steam OS
You need to install Protontricks from Discover on your Steam Deck, that's it.

### Others 
Requried:
- Protontricks (either systen wide or flatpak)
- python 3

Optional:
- pip 3
- [python vdf](https://github.com/solsticegamestudios/vdf)

# Installation 
## Arch Linux and derivatives
AUR package is available [here](https://aur.archlinux.org/shortix)  
You can either use an AUR helper or make the package manually:
1. `git clone https://aur.archlinux.org/shortix.git`
2. `cd shortix`
3. `makepkg -fsic`

## Automatic (StamOS and others)
Download the [installer](https://github.com/Jannomag/shortix/releases/latest/download/shortix_installer.desktop) to the Desktop and double click it.    
##### Attention for Firefox users: I noticed that Firefox will append ".download" to the file. I don't know why, but you need to remove this, so the file is called "shortex_installer.desktop" in order to be executable.    

The installer will you ask you three things:
- Add prefix id to the game name - this will make the shortcuts look like this: `Game Name (12345678)`
- Add size of the target to the game name - this will make the shortcut look like this: `Game Name (12345678) - 1.6G` (or `Game Name - 1.6G` if you disabled prefix ids).
- Install the Shortix service - this will allow Shortix to be executed automatically after a time interval (default is 30 Minutes). This will work in Game Mode as well.
  
If you changed your mind about the service, just run the "Update Shortix" again.

Afterwards there's a new directory in you home directory, called Shortix.    
In there you'll find all created symlinks / shortcuts to the installed games - which were found by Protontricks.  
You'll also find two subdirectories called "\_Shaders" and "\_Workshop". In there you'll find shortcuts to all available shadercache directories and workshop content respectively.

In the Shortix directory you'll also find the `shortix.sh` and `remove_prefix.sh` scripts.    
With `shortix.sh` you can run Shortix manually (run this in a Terminal or use right click and choose "Run in Konsole" if you're running KDE).    
For `remove_prefix.sh` read the tutorial below.

### Configurtion
Shortix configuration is located inside `$HOME/.config/Shortix`. There you can find empty files named `id`, `size` and/or `backup` and a folder for your python virtual environment. If you don't want ids or sizes to be appended to the game name anymore, delete `id` or/and `size` and if you don't want backups anymore, you can delete `backup`. Vice versa you can add create those file yourself if you did't have them before hand. Keep in mind that you'll have to run the script manually at least once to apply the changes you've made (read below).

If you want to rerun the script manually, just delete all symlinks and the cache files `first_run` and `last_run` in `$HOME/.cache/Shortix`. Both files are cache files for letting the script know if it already ran at least once. Then just run the shortix.sh in a terminal.

## Manual (Steam OS)
1. Go to the /tmp folder using `cd /tmp`
2. Clone this repo with `git clone https://github.com/Jannomag/shortix`
3. Create Shortix directory with `mkdir -p $HOME/Shortix $HOME/.config/Shortix $HOME/.local/share/Shortix`
4. Copy the script with `cp /tmp/shortix/shortix.sh $HOME/Shortix`
5. Copy the scripts folder with `cp -r /tmp/shortix/scripts $HOME/.local/share/Shortix/`
6. Configure a python virtual environment:
    1. `python -m venv $HOME/.config/Shortix/venv`
    2. `source $CONFIG_PATH/venv/bin/activate`
    3. `python -m ensurepip --upgrade`
    4. `pip install "git+https://github.com/solsticegamestudios/vdf"`
7. (Optional) Create and empty `id` and/or `size` and/or `backup` file in `$HOME/.config/Shortix` to append the id and size to the game name and to enable the backup functionality
8. Copy the systemd service with `cp /tmp/shortix/shortix.service $HOME/.config/systemd/user`
9. Reload systemd daemon with `systemctl --user daemon-reload`
10. Enable service with `systemctl --user enable shortix.service`
11. Start service with `systemctl --user start shortix.service`
12. Done (all those steps does the `shortix_installer.sh` for you

NOTE for distro package creators: shortix accepts the scripts folder to be located in `/usr/share/shortix/scripts` wich takes priority from the user folder

# Background and explanation
I just wanted to have easier access to the prefixes for the games on my Steam Deck, so I created Shortix.
What it does is really simple:
- Run protontricks to get a list of all installed games, including Non-Steam games.
- Use the data to create symlinks in `$HOME/Shortix`
- If there's a dead end symlink, it will get removed
- The script will be executed every 15 minutes by a systemd user service

To change the restart interval you need to change two things:
1. in `$HOME/Shortix/shortix.sh` - change the value of the TIME variable in minutes
2. in `$HOME/.config/systemd/user/shortix.service` - change the 1800s value to your desired value in seconds

If you want you can also change the directory. For this modify the directory within the shortix.sh and also in the shortix.service file.

You can also run the script manually either by using the terminal directly using this command: `/bin/bash $HOME/Shortix/shortix.sh` or right click on the file and chosse "Run in Konsole".

# Prefix removal script
I've added a script called `remove_prefix.sh` to the Shortix directory.    
This script allows you to remove not just the shortcut but also the whole prefix directory.  
This will also work for shadercache shortcuts, just drag&drop those instead.
Run this script in a terminal (or do right click -> "Run in Konsole" for KDE / Steam Deck).    
Then you can drag an drop all shortcuts from the Shortix directory of which you want to remove the prefix directory.    
Afterwards press enter, the script will notify you about the paths.    
It will also ask you if you really want to delete them.    
**Pleas note: The deletion will remove the prefix / shadercache completely! This will also remove savegames (except cloud saves) and other game specific user data - finally!**

# Flags

- -`f`: force Shortix execution

# Uninstall
To uninstall run the "Update Shortix" from the desktop and choose "no" when the script asks you if you want to install the service.
Afterwards delete the Shortix directory in your home directory and the "Update Shortix" from desktop.
That's it.

# Tested systems / distros
- Steam Deck (SteamOS 3.4)
- EndeavourOS
- Ubuntu 22.04

# Known issues
- ~~- if the name of a game contains round brackets, for example "Aaa aaa Aaa: Aaa Aaa (16-bit)" (thanks to [u/octopus_erectus](https://www.reddit.com/r/SteamDeck/comments/13luaiz/release_shortix_a_script_for_human_readable/jksiery/?utm_source=share&utm_medium=ios_app&utm_name=ioscss&utm_content=1&utm_term=1&context=3)) the script will fail. I will try to fix this when I find a bit time. For now a workaround can be to rename the games, but I don't know if this work for native Steam games.~~
(fixed)
- It can happen that some games with strange characters will cause problems. To keep Shortix working I decided to remove semicolons from game names before it will link anything (this will just affect the shortcut names, not the actual game name in steam or wherever!). If you notice such problems, please feel free to open an issue. I can't test it with every game on steam, of course. (fixed, I guess)

# Contribution
If you have any suggestions, let me know!
