#!/bin/sh
# this script simulates the installation from the desktop file

rm -rf /tmp/shortix 
cp -r ./ /tmp/shortix 
mkdir -p $HOME/.local/share/icons 
cp /tmp/shortix/shortix_icon.svg $HOME/.local/share/icons 
/bin/bash /tmp/shortix/shortix_install.sh