# Welcome

# Dependencies
## Hyprland Packages
`pacman -S hyprland hyprpaper `

## NeoVim Packages
My NeoVim dependencies

```pacman -S neovim ripgrep stylua && npm i -g prettier```

ripgrep is required for telescope

stylua and prettier are required for nvim/formatter

# Configuration
## HyprlandWM
### Workspace Behaviour
I like to use the first five workspaces on my main monitor. 

use `hyprctl monitors` to list your devices if you want to change it.

You may remove these lines from the `hypr/hyprland.conf` 
if this is not desired:
```
workspace=1,monitor:DP-1
workspace=2,monitor:DP-1
...
workspace=6,monitor:DP-2
...
```

# Misc
## Get NVIDIA working with Wayland (state March 2024)
### Archlinux & NVIDIA propriatery drivers

```
/etc/mkinitcpio.conf
```
```
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```
More information on the [wiki](https://wiki.archlinux.org/title/NVIDIA), 
including hooks for autogenerating initramfs with new driver...
****
I also needed to change the env vars in order to start a Wayland session 
using SDDM.

``` 
/etc/environment
```
``` 
GBM_BACKEND=nvidia-drm
__GLX_VENDOR_LIBRARY_NAME=nvidia
ENABLE_VKBASALT=1
LIBVA_DRIVER_NAME=nvidia

WLR_NO_HARDWARE_CURSORS=1 # if your cursor is invisible
```
