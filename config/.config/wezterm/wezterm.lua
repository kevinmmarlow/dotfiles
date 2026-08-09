local wezterm = require "wezterm"

local config = wezterm.config_builder()
local action = wezterm.action
local is_windows = os.getenv("OS") and os.getenv("OS"):lower():find("windows")
local is_macos = wezterm.target_triple:lower():find("darwin") ~= nil

-- ui: read color scheme from ~/.config/themes/
local themes_dir = wezterm.home_dir .. "/.config/themes"
wezterm.add_to_config_reload_watch_list(themes_dir .. "/current")

local function read_wezterm_theme()
  local f = io.open(themes_dir .. "/current", "r")
  if not f then return nil, nil end
  local name = nil
  for line in f:lines() do
    local k, v = line:match("^(%w+)=(.+)$")
    if k == "wezterm" then name = v; break end
  end
  f:close()
  if not name then return nil, nil end

  local sf = io.open(themes_dir .. "/wezterm/" .. name, "r")
  if not sf then return nil, nil end
  local scheme = sf:read("*l")
  local alert = sf:read("*l")
  sf:close()
  return scheme, alert
end

local wezterm_scheme, wezterm_alert_scheme = read_wezterm_theme()
config.color_scheme = wezterm_scheme or "rose-pine-moon"
config.max_fps = 120

config.font = wezterm.font("Hack Nerd Font", { weight = "Regular" })

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
-- raised from the default 16 so TAB_MIN_WIDTH padding isn't truncated back down
config.tab_max_width = 32
config.window_decorations = "TITLE | RESIZE"
config.window_frame = {
  font = wezterm.font("Hack Nerd Font", { weight = "Bold" }),
}

config.inactive_pane_hsb = {
  saturation = 0.7,
  brightness = 0.8,
}

-- CMD+click opens the file under the cursor in its macOS default app.
-- Bare paths aren't hyperlinks by default, only URL-like schemes are, so
-- wrap anything path-shaped as a file:// URI; opening that shells out to
-- `open`, which macOS resolves to the default app for that file type.
config.hyperlink_rules = wezterm.default_hyperlink_rules()
-- Earlier rules claim overlapping ranges, so the default URL rules keep real URLs,
-- and the ~ rule must precede the absolute-path rule.
-- file:// has no notion of ~, so expand it: "file://~/x" parses ~ as the hostname.
table.insert(config.hyperlink_rules, {
  regex = [[(?:^|[\s"'(\[])~(/[\w./\-]+)]],
  format = "file://" .. wezterm.home_dir .. "$1",
})
-- Absolute only: a relative path needs the pane cwd, which a static format can't
-- reach. The regex crate has no lookbehind, so match a leading delimiter and keep
-- only the path in $1; without it "src/index.ts" resolves to /index.ts.
table.insert(config.hyperlink_rules, {
  regex = [[(?:^|[\s"'(\[])(/[\w./\-]+)]],
  format = "file://$1",
})

config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CMD",
    action = action.OpenLinkAtMouseCursor,
  },
  -- suppress the default click behavior on the matching Down event so it
  -- doesn't also move the cursor / start a selection
  {
    event = { Down = { streak = 1, button = "Left" } },
    mods = "CMD",
    action = action.Nop,
  },
  -- macOS convention: selecting text shouldn't clobber the clipboard on its
  -- own. Default binds these to CompleteSelectionOrOpenLinkAtMouseCursor /
  -- CompleteSelection with ClipboardAndPrimarySelection, which copies on
  -- every click-release. Cmd+C (default keybinding) still copies explicitly.
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = action.CompleteSelection("PrimarySelection"),
  },
  {
    event = { Up = { streak = 2, button = "Left" } },
    mods = "NONE",
    action = action.CompleteSelection("PrimarySelection"),
  },
  {
    event = { Up = { streak = 3, button = "Left" } },
    mods = "NONE",
    action = action.CompleteSelection("PrimarySelection"),
  },
}

if is_windows then
  config.win32_system_backdrop = "Acrylic"
  config.window_background_opacity = 0.7
  config.window_frame.font_size = 10.0
end

if is_macos then
  config.window_background_opacity = 0.97
  config.macos_window_background_blur = 20
  config.font_size = 15.0
  config.window_frame.font_size = 13.0
end

-- shell
if is_windows then
  config.default_domain = "WSL:Ubuntu-24.04"
end

-- keys
local maximize_window = wezterm.action_callback(function(window, _pane)
  window:maximize()
end)

local function cycle_pane(direction)
  return wezterm.action_callback(function(window, _pane)
    local panes = window:active_tab():panes_with_info()
    local active_idx
    for i, p in ipairs(panes) do
      if p.is_active then active_idx = i end
    end
    local next_idx = ((active_idx - 1 + direction) % #panes) + 1
    panes[next_idx].pane:activate()
  end)
end

local rename_tab = action.PromptInputLine({
  description = "New tab name:",
  action = wezterm.action_callback(function(window, _pane, line)
    if line then
      window:active_tab():set_title(line)
    end
  end),
})

local open_lazygit = wezterm.action_callback(function(window, pane)
  local cwd_uri = pane:get_current_working_dir()
  local cwd = cwd_uri and cwd_uri.file_path or wezterm.home_dir
  window:perform_action(
    action.SpawnCommandInNewTab({ args = { "/bin/zsh", "-l", "-c", "lazygit" }, cwd = cwd }),
    pane
  )
end)

local ANGELLIST_DIR = wezterm.home_dir .. "/Development/ANGEL_LIST"
local open_angellist_layout = wezterm.action_callback(function(window, _pane)
  local mux_window = window:mux_window()
  local _tab, left, _win = mux_window:spawn_tab({ cwd = ANGELLIST_DIR })
  local right_top = left:split({ direction = "Right", cwd = ANGELLIST_DIR, size = 0.5 })
  right_top:split({ direction = "Bottom", cwd = ANGELLIST_DIR, size = 0.5 })
end)

config.leader = { key = "Space", mods = "CTRL" }
config.keys = {
  { key = "m", mods = "CTRL|SHIFT", action = maximize_window },
  { key = "t", mods = "LEADER", action = action.SpawnTab("CurrentPaneDomain") },
  { key = "r", mods = "LEADER", action = rename_tab },
  { key = "a", mods = "LEADER", action = open_angellist_layout },
  { key = "g", mods = "LEADER", action = open_lazygit },
  { key = "n", mods = "LEADER", action = action.SpawnWindow },
  { key = "\\", mods = "LEADER", action = action.SplitPane({ direction = "Right" }) },
  { key = "-", mods = "LEADER", action = action.SplitPane({ direction = "Down" }) },
  { key = "x", mods = "LEADER", action = action.CloseCurrentPane({ confirm = true }) },
  { key = "w", mods = "LEADER", action = action.ShowTabNavigator },
  { key = "p", mods = "LEADER", action = action.ActivateCommandPalette },
  { key = "[", mods = "LEADER", action = action.ActivateTabRelative(-1) },
  { key = "]", mods = "LEADER", action = action.ActivateTabRelative(1) },

  -- explicit even though they match wezterm's defaults; CMD+arrow line-jump wasn't
  -- taking effect via the merged defaults alone
  { key = "LeftArrow", mods = "CMD", action = action.SendString("\x01") },
  { key = "RightArrow", mods = "CMD", action = action.SendString("\x05") },
  { key = "LeftArrow", mods = "OPT", action = action.SendString("\x1bb") },
  { key = "RightArrow", mods = "OPT", action = action.SendString("\x1bf") },
  -- Cmd+Delete: kill from cursor to start of line (Ctrl-U, bound to vi-kill-line/
  -- kill-whole-line by zsh's defaults). Option+Delete already works unbound since
  -- WezTerm's default alt-sends-escape passes it through as backward-kill-word.
  { key = "Backspace", mods = "CMD", action = action.SendString("\x15") },

  -- Shift+Home / Shift+End and Shift+Alt+Arrow: zsh-shift-select (see .zshrc) binds
  -- these exact xterm sequences to select-to-line-boundary / select-word widgets
  { key = "LeftArrow", mods = "CMD|SHIFT", action = action.SendString("\x1b[1;2H") },
  { key = "RightArrow", mods = "CMD|SHIFT", action = action.SendString("\x1b[1;2F") },
  { key = "LeftArrow", mods = "OPT|SHIFT", action = action.SendString("\x1b[1;4D") },
  { key = "RightArrow", mods = "OPT|SHIFT", action = action.SendString("\x1b[1;4C") },

  { key = "[", mods = "CMD", action = cycle_pane(-1) },
  { key = "]", mods = "CMD", action = cycle_pane(1) },
  { key = "[", mods = "CMD|SHIFT", action = action.ActivateTabRelative(-1) },
  { key = "]", mods = "CMD|SHIFT", action = action.ActivateTabRelative(1) },
}

for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "LEADER",
    action = action.ActivateTab(i - 1),
  })
end

-- al console danger/caution indicator
-- zsh (see ~/.zsh/configs/al-console-env.zsh) sets AL_CONSOLE_ENV via OSC 1337 SetUserVar
-- around `al console create|exec -e prod|staging`. WezTerm swaps the window color scheme
-- to the theme's alert variant (light/contrasting) so the session is unmissable.
local AL_ENV_LABELS = {
  prod = "DANGER",
  staging = "CAUTION",
}

wezterm.on("update-right-status", function(window, pane)
  local env = pane:get_user_vars().AL_CONSOLE_ENV
  local overrides = window:get_config_overrides() or {}

  if AL_ENV_LABELS[env] then
    if wezterm_alert_scheme and overrides.color_scheme ~= wezterm_alert_scheme then
      overrides.color_scheme = wezterm_alert_scheme
      window:set_config_overrides(overrides)
    end
    window:set_right_status(wezterm.format({
      { Attribute = { Intensity = "Bold" } },
      { Text = "  " .. AL_ENV_LABELS[env] .. "  " },
    }))
  else
    if overrides.color_scheme then
      overrides.color_scheme = nil
      window:set_config_overrides(overrides)
    end
    window:set_right_status("")
  end
end)

-- WezTerm has tab_max_width but no minimum, so short titles are center-padded here
local TAB_MIN_WIDTH = 20

local function pad_to_min_width(text, min_width)
  -- column_width, not #text: titles can contain wide/multibyte glyphs
  local pad = min_width - wezterm.column_width(text)
  if pad <= 0 then return text end
  local left = math.floor(pad / 2)
  return string.rep(" ", left) .. text .. string.rep(" ", pad - left)
end

wezterm.on("format-tab-title", function(tab, _tabs, _panes, _config, _hover, max_width)
  -- tab_title is empty unless explicitly renamed; only then does it win over the live pane title
  local title = (tab.tab_title and #tab.tab_title > 0) and tab.tab_title or tab.active_pane.title
  local env = tab.active_pane.user_vars.AL_CONSOLE_ENV
  if AL_ENV_LABELS[env] then
    title = " " .. AL_ENV_LABELS[env] .. " | " .. title .. " "
  end
  return pad_to_min_width(title, math.min(TAB_MIN_WIDTH, max_width))
end)

return config
