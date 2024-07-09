#!/bin/bash

# directory of imagefiles [ .png, .jpg, .jpeg ] used for wallpapers
wallpaper_directory="$HOME/Pictures/wallpapers/active/"

if [ ! -d "$wallpaper_directory" ]; then
  echo "Error: Directory $wallpaper_directory does not exist."
  exit 1
fi

# cycle through all items of the wallpaper directory
function cycle_wallpapers() {
    for entry in "$wallpaper_directory"*; do
        if [ -f "$entry" ]; then
            swww img $entry --transition-type wipe --transition-angle 30 --transition-step 90 --transition-fps 120
            echo $entry > $HOME/.config/hypr/Scripts/active_wallpaper
            sleep 180
        else
            echo "Skipping unknown entry: $entry"
        fi
    done

    cycle_wallpapers
}

cycle_wallpapers
