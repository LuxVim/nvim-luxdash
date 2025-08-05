local M = {}

function M.render(width, height, config)
  local max_files = config.max_files or 10
  -- Calculate available height for content (subtract title and underline if present)
  local available_height = height
  if config.show_title ~= false then
    available_height = available_height - 1  -- title
    if config.show_underline ~= false then
      available_height = available_height - 1  -- underline
    end
    if config.title_spacing ~= false then
      available_height = available_height - 1  -- spacing
    end
  end
  
  -- Strictly limit max_files to prevent overflow
  -- Ensure we never exceed the allocated height regardless of configuration
  max_files = math.min(max_files, available_height, 9)
  -- Additional safety: ensure we have at least 1 line of height to work with
  if available_height <= 0 then
    max_files = 0
  end
  
  local recent_files = M.get_recent_files(max_files)
  
  local content = {}
  
  if #recent_files == 0 then
    table.insert(content, {'LuxDashComment', 'No recent files'})
  else
    for i, file in ipairs(recent_files) do
      local icon = M.get_file_icon(file)
      local key_part = '[' .. tostring(i) .. ']'
      
      -- Calculate exact width for filename to maintain alignment
      local icon_width = vim.fn.strwidth(icon .. '  ')
      local key_width = vim.fn.strwidth(key_part)
      local padding_width = 1 -- minimum padding
      local available_filename_width = width - icon_width - key_width - padding_width
      
      -- Truncate filename to exact width needed for alignment
      local display_name = M.truncate_filename_for_alignment(file, available_filename_width)
      
      -- Create padding to align keymaps
      local actual_filename_width = vim.fn.strwidth(display_name)
      local final_padding_width = width - icon_width - actual_filename_width - key_width
      local padding = string.rep(' ', math.max(1, final_padding_width))
      
      -- Create line with multiple highlight sections (similar to menu format)
      local line_parts = {
        {'LuxDashRecentIcon', icon .. '  '},
        {'LuxDashRecentFile', display_name},
        {'Normal', padding},
        {'LuxDashRecentKey', key_part}
      }
      
      table.insert(content, line_parts)
      
      -- Set up numerical keymap to open the file
      M.setup_file_keymap(i, file)
    end
  end
  
  -- Final safety check: ensure content never exceeds available height
  -- This prevents any overflow regardless of configuration errors
  if #content > available_height then
    local truncated_content = {}
    for i = 1, available_height do
      table.insert(truncated_content, content[i])
    end
    content = truncated_content
  end
  
  return content
end

function M.get_recent_files(max_count)
  local recent_files = {}
  
  local oldfiles = vim.v.oldfiles or {}
  local cwd = vim.fn.getcwd()
  local count = 0
  
  for _, file in ipairs(oldfiles) do
    if count >= max_count then
      break
    end
    
    if vim.fn.filereadable(file) == 1 then
      if vim.startswith(file, cwd) then
        local relative_path = vim.fn.fnamemodify(file, ':.')
        table.insert(recent_files, relative_path)
        count = count + 1
      end
    end
  end
  
  return recent_files
end

function M.truncate_filename(filename, max_width)
  if vim.fn.strwidth(filename) <= max_width then
    return filename
  end
  
  local parts = vim.split(filename, '/')
  if #parts > 1 then
    local basename = parts[#parts]
    if vim.fn.strwidth(basename) <= max_width - 3 then
      return '...' .. basename
    end
  end
  
  if max_width > 3 then
    return filename:sub(1, max_width - 3) .. '...'
  else
    return filename:sub(1, max_width)
  end
end

function M.truncate_filename_for_alignment(filename, max_width)
  if max_width <= 0 then
    return ""
  end
  
  if vim.fn.strwidth(filename) <= max_width then
    return filename
  end
  
  -- Always truncate from the beginning to maintain consistent alignment
  if max_width <= 3 then
    return string.rep('.', max_width)
  end
  
  -- Find the right truncation point to fit exactly in max_width
  local truncated = filename
  local current_width = vim.fn.strwidth(truncated)
  
  while current_width > max_width - 3 do
    -- Remove characters from the beginning until we have space for "..."
    local char_removed = false
    for i = 1, #truncated do
      local char = truncated:sub(i, i)
      truncated = truncated:sub(i + 1)
      current_width = vim.fn.strwidth(truncated)
      char_removed = true
      break
    end
    
    if not char_removed then
      break
    end
    
    if current_width <= max_width - 3 then
      break
    end
  end
  
  return '...' .. truncated
end

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

function M.setup_file_keymap(index, filepath)
  local key = tostring(index)
  
  vim.keymap.set('n', key, function()
    -- Close the float manager if open
    local float = require('luxdash.ui.float_manager')
    if float.is_open() then
      float.close()
    end
    
    -- Open the file in current window
    local full_path = vim.fn.fnamemodify(filepath, ':p')
    if vim.fn.filereadable(full_path) == 1 then
      vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
    else
      vim.notify('File not found: ' .. filepath, vim.log.levels.WARN)
    end
  end, { 
    buffer = true, 
    silent = true,
    desc = 'Open recent file: ' .. filepath
  })
end

return M