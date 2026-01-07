local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.default_domain = 'WSL:Ticketsolve'
config.color_scheme = 'nord'
config.font = wezterm.font 'Fira Code'
config.font_size = 12.0

config.term = "xterm-256color"
config.front_end = "OpenGL"

config.window_decorations = 'RESIZE'
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}
config.use_resize_increments = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

config.hide_tab_bar_if_only_one_tab = true

wezterm.on('format-window-title', function(tab) 
  local pane = tab.active_pane
  local title = pane.title
  
  if pane.domain_name then
      title = pane.domain_name.gsub(pane.domain_name, "WSL:", "")
  end

  return title
end)

wezterm.on('format-tab-title', function(tab)
  local pane = tab.active_pane
  local title = pane.title
  
  if pane.domain_name then
      title = pane.domain_name.gsub(pane.domain_name, "WSL:", "")
  end

  return title
end)


config.leader = { key = 'l', mods = 'CTRL', timeout_milliseconds = 1000 }

config.keys = {
  {key="Enter", mods="SHIFT", action=wezterm.action{SendString="\x1b\r"}},
  {
    key = 's',
    mods = 'LEADER|CTRL',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'd',
    mods = 'LEADER|CTRL',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
    {
      key = 'c',
      mods = 'CTRL',
      action = wezterm.action_callback(function(window, pane)
        local sel = window:get_selection_text_for_pane(pane)
        if (not sel or sel == '') then
          window:perform_action(wezterm.action.SendKey{ key='c', mods='CTRL' }, pane)
        else
          window:perform_action(wezterm.action{ CopyTo = 'ClipboardAndPrimarySelection' }, pane)
        end
      end),
    },
    { key = 'v', mods = 'CTRL', action = wezterm.action.PasteFrom 'Clipboard' },
    { key = 'v', mods = 'SHIFT|CTRL', action = wezterm.action_callback(function(window, pane)
      window:perform_action(wezterm.action.SendKey{ key='v', mods='CTRL' }, pane) end),
    },
    { key = 'V', mods = 'SHIFT|CTRL', action = wezterm.action_callback(function(window, pane)
      window:perform_action(wezterm.action.SendKey{ key='v', mods='CTRL' }, pane) end),
    },
    { key = 'c', mods = 'ALT', action = wezterm.action.CopyTo 'ClipboardAndPrimarySelection' },
    { key = 'v', mods = 'ALT', action = wezterm.action.PasteFrom 'Clipboard' }
}

config.mouse_bindings = {
  {
    event = { Drag = { streak = 1, button = 'Left' } },
    mods = 'SUPER',
    action = wezterm.action.StartWindowDrag,
  },
  {
    event = { Drag = { streak = 1, button = 'Left' } },
    mods = 'CTRL|SHIFT',
    action = wezterm.action.StartWindowDrag,
  },
}



return config
