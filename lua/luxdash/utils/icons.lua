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

-- File extension to icon mapping
M.file_icons = {
  -- Programming languages
  lua = '󰢱',
  py = '󰌠',
  js = '󰌞',
  ts = '󰛦',
  jsx = '󰜈',
  tsx = '󰜈',
  html = '󰌝',
  css = '󰌜',
  scss = '󰌜',
  sass = '󰌜',
  json = '󰘦',
  xml = '󰗀',
  yml = '󰈙',
  yaml = '󰈙',
  toml = '󰈙',
  ini = '󰈙',
  conf = '󰈙',
  config = '󰈙',

  -- Web & markup
  vue = '󰡄',
  svelte = '󰟏',
  php = '󰌟',
  rb = '󰴉',
  go = '󰟓',
  rs = '󱘗',
  c = '󰙱',
  cpp = '󰙲',
  cc = '󰙲',
  cxx = '󰙲',
  h = '󰙱',
  hpp = '󰙲',
  java = '󰬷',
  kt = '󱈙',
  swift = '󰛥',
  dart = '󰻂',

  -- Shell & scripts
  sh = '󱆃',
  bash = '󱆃',
  zsh = '󱆃',
  fish = '󱆃',
  ps1 = '󰨊',
  bat = '󰨊',
  cmd = '󰨊',

  -- Data & documents
  md = '󰍔',
  txt = '󰈙',
  rtf = '󰈙',
  pdf = '󰈦',
  doc = '󰈦',
  docx = '󰈦',
  xls = '󰈛',
  xlsx = '󰈛',
  ppt = '󰈧',
  pptx = '󰈧',

  -- Images
  png = '󰈟',
  jpg = '󰈟',
  jpeg = '󰈟',
  gif = '󰈟',
  svg = '󰈟',
  ico = '󰈟',
  webp = '󰈟',
  bmp = '󰈟',

  -- Other
  log = '󰌱',
  lock = '󰌾',
  gitignore = '󰊢',
  dockerfile = '󰡨',
  makefile = '󱌢',
  CMakeLists = '󱌢'
}

function M.get_icon(name)
  return M.default_icons[name] or '󰘬'
end

function M.get_git_icon(name)
  return M.git_icons[name] or '󰘬'
end

function M.get_file_icon(filepath)
  -- Extract filename from path
  local filename = vim.fn.fnamemodify(filepath, ':t')

  -- Handle special filenames
  local special_files = {
    ['Dockerfile'] = '󰡨',
    ['dockerfile'] = '󰡨',
    ['Makefile'] = '󱌢',
    ['makefile'] = '󱌢',
    ['CMakeLists.txt'] = '󱌢',
    ['.gitignore'] = '󰊢',
    ['.gitmodules'] = '󰊢',
    ['.gitattributes'] = '󰊢',
    ['package.json'] = '󰎙',
    ['package-lock.json'] = '󰎙',
    ['yarn.lock'] = '󰎙',
    ['Cargo.toml'] = '󱘗',
    ['Cargo.lock'] = '󱘗',
    ['go.mod'] = '󰟓',
    ['go.sum'] = '󰟓'
  }

  if special_files[filename] then
    return special_files[filename]
  end

  -- Extract extension
  local extension = vim.fn.fnamemodify(filepath, ':e'):lower()

  -- Return icon for extension or default
  return M.file_icons[extension] or '󰈙'
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