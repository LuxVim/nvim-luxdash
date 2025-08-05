local M = {}

-- Generic icons for menu items
M.default_icons = {
  newfile = '󰷈',
  backtrack = '󰋚',
  fzf = '󰍉',
  closelux = '󰅖',
  new = '󰷈',
  recent = '󰋚',
  search = '󰍉',
  quit = '󰅖'
}

-- Git-specific icons
M.git_icons = {
  branch = '󰘬',
  remote = '󰓂',
  changes = '󰊢',
  diff = '󰦒',
  commit = '󰜘',
  author = '󰀉',
  date = '󰃭'
}

function M.get_icon(name)
  return M.default_icons[name] or '󰘬'
end

function M.get_git_icon(name)
  return M.git_icons[name] or '󰘬'
end

function M.set_icon(name, icon)
  M.default_icons[name] = icon
end

function M.register_icons(icon_table)
  for name, icon in pairs(icon_table or {}) do
    M.default_icons[name] = icon
  end
end

return M