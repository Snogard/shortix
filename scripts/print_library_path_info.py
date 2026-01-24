#!/usr/bin/python
import os
import vdf


lib_file = vdf.load(open(os.environ['HOME'] + "/.steam/steam/config/libraryfolders.vdf"))

for library_index, library_data in lib_file["libraryfolders"].items():
    path = library_data["path"]
    apps = library_data["apps"]
    for game_id in apps:
        print(game_id + ";"+path+";")
