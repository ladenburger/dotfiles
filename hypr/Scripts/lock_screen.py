###############################################################
# Replaces path in hyprlock config with current wallpaperpath #
###############################################################

import os

home_dir = os.path.expanduser('~')
config_path = os.path.join(home_dir, '.config/hypr/hyprlock.conf')
wallpaper = os.path.join(home_dir, '.config/hypr/Scripts/active_wallpaper')

# get current wallpaper
with open(wallpaper, 'r') as file:
    wall_path = file.readline().strip()

with open(config_path, 'r') as file:
    lines = file.readlines()

# replace path var
for i, line in enumerate(lines):
    if line.find('path = ') != -1:
        parts = line.split('path = ')
        if len(parts) > 1:
            lines[i] = f"    path = {wall_path}\n"

with open(config_path, 'w') as file:
    file.writelines(lines)

# lock screen
os.system('hyprlock')
