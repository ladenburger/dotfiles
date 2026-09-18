hl.monitor({
    output   = "DP-3",
    mode     = "1920x1080@100",
    position = "0x400",
    scale    = "auto",
})
hl.monitor({
    output   = "DP-2",
    mode     = "2560x1440@165",
    position = "1920x0",
    scale    = "auto",
})
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@100",
    position = "4480x405",
    scale    = "auto",
})

local terminal    = "alacritty"
local fileManager = "thunar"

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.on("hyprland.start", function ()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")

    hl.exec_cmd("/usr/bin/gentoo-pipewire-launcher")
    hl.exec_cmd("/usr/libexec/hyprpolkitagent")
    hl.exec_cmd("ptt-fix")
    hl.exec_cmd("fcitx5 -d -r")
    hl.exec_cmd("awww-daemon")

    hl.exec_cmd("env QT_IM_MODULE=none qs")
    hl.exec_cmd("hypridle")

    hl.exec_cmd([[sh -c "sleep 2; pkill -f xdg-desktop-portal"]])
end)

hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")
hl.env("SDL_IM_MODULE", "fcitx")
hl.env("GLFW_IM_MODULE", "ibus")

hl.config({
  xwayland = {
    force_zero_scaling = true
  }
})

hl.config({
    general = {

        gaps_in  = 8,
        gaps_out = { top = 20, right = 25, bottom = 25, left = 25 },

        border_size = 2,

        col = {
            active_border   = "rgba(e8c597ff)",
            inactive_border = "rgba(3c3836ff)",
        },

        resize_on_border = false,

        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {

        rounding       = 12,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOut",   { type = "bezier", points = { {0.16, 1},    {0.3, 1}    } })
hl.curve("snappy",    { type = "bezier", points = { {0.3, 0},     {0, 1}      } })
hl.curve("overshoot", { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.06} } })

hl.animation({ leaf = "global",        enabled = true, speed = 5,   bezier = "easeOut" })
hl.animation({ leaf = "border",        enabled = true, speed = 6,   bezier = "easeOut" })
hl.animation({ leaf = "windows",       enabled = true, speed = 3.6, bezier = "overshoot", style = "popin 90%" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 3.6, bezier = "overshoot", style = "popin 90%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 2.2, bezier = "snappy",    style = "popin 92%" })
hl.animation({ leaf = "fade",          enabled = true, speed = 2.6, bezier = "easeOut" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 2.6, bezier = "easeOut" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 2,   bezier = "easeOut" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3,   bezier = "easeOut" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 3.2, bezier = "overshoot", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 2.4, bezier = "snappy",    style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 2.6, bezier = "easeOut" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2.2, bezier = "easeOut" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 3.5, bezier = "easeOut",   style = "slidefade 20%" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 3.5, bezier = "easeOut",   style = "slidefade 20%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3.5, bezier = "easeOut",   style = "slidefade 20%" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,   bezier = "easeOut" })

hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
hl.window_rule({
    name  = "no-gaps-wtv1",
    match = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding    = 0,
})
hl.window_rule({
    name  = "no-gaps-f1",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding    = 0,
})

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

hl.config({
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = false,
    },
})

hl.config({
    input = {
        kb_layout  = "us,de",

        kb_options = "",
        kb_variant = "",
        kb_model   = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

local mainMod = "SUPER"

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())

hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + Escape", hl.dsp.global("quickshell:powermenu"))
hl.bind(mainMod .. " + Tab", hl.dsp.global("quickshell:alttab"))
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.global("quickshell:alttabPrev"))
hl.bind(mainMod .. " + SUPER_L", hl.dsp.global("quickshell:alttabConfirm"), { release = true })
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D", hl.dsp.global("quickshell:launcher"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("~/.config/quickshell/scripts/bookmarks.sh"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("~/.config/quickshell/scripts/snippets.sh"))

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("~/.config/hypr/scripts/togglegaps.sh"))

hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprshot -m region -o ~/files/pictures/screenshots"))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

hl.bind("ALT + Shift_L",  hl.dsp.global("quickshell:imcycle"), { locked = true })
hl.bind("ALT + Shift_R",  hl.dsp.global("quickshell:imcycle"), { locked = true })
hl.bind("SHIFT + Alt_L",  hl.dsp.global("quickshell:imcycle"), { locked = true })

hl.bind(mainMod .. " + H",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J",  hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.exec_cmd("~/.config/hypr/scripts/ws.sh " .. i))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.exec_cmd("~/.config/hypr/scripts/ws.sh " .. i .. " move"))
end

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "m-1" }))

for i = 1, 10 do
    local p = (i <= 5)
    hl.workspace_rule({ workspace = tostring(i),      monitor = "DP-3",     persistent = p, default = (i == 1) })
    hl.workspace_rule({ workspace = tostring(i + 10), monitor = "DP-2",     persistent = p, default = (i == 1) })
    hl.workspace_rule({ workspace = tostring(i + 20), monitor = "HDMI-A-1", persistent = p, default = (i == 1) })
end

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

local suppressMaximizeRule = hl.window_rule({

    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({

    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    name  = "anki-float-dialogs",
    match = { class = "^anki$" },

    float  = true,
    center = true,
    size   = "55% 70%",
})

hl.window_rule({

    name  = "anki-main-tiled",
    match = { class = "^anki$", title = "^.* - Anki$" },

    float = false,
})

local ankiDialogSizes = {
    { "browser",         "^Browse .*",           "75% 80%" },
    { "add",             "^Add$",                "55% 70%" },
    { "edit-current",    "^Edit Current$",       "55% 70%" },
    { "preview",         "^Preview$",            "40% 60%" },
    { "stats",           "^Statistics$",         "80% 85%" },
    { "preferences",     "^Preferences$",        "50% 70%" },
    { "deck-options",    "^Options for .*",      "50% 75%" },
    { "fields",          "^Fields for .*",       "45% 60%" },
    { "card-types",      "^Card Types for .*",   "75% 80%" },
    { "change-notetype", "^Change Note Type$",   "60% 70%" },
    { "notetypes",       "^Manage Note Types$",  "45% 55%" },
    { "addons",          "^Add-ons$",            "55% 65%" },
}

for _, rule in ipairs(ankiDialogSizes) do
    hl.window_rule({
        name  = "anki-size-" .. rule[1],
        match = { class = "^anki$", title = rule[2] },

        size = rule[3],
    })
end

-- Per-machine overrides, if this box has any (hypr/local.lua, untracked).
do
    local path = (os.getenv("HOME") or "") .. "/.config/hypr/local.lua"
    local chunk = loadfile(path)
    if chunk then chunk() end
end
