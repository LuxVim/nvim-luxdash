local M = {}

function M.render(width, height, config)
  -- Clear any existing keymaps for this section first
  M.clear_file_keymaps()
  
  local max_files = config.max_files or 10
  
  -- Account for section padding that will be applied by section renderer
  local content_width = width
  if config.padding then
    local left_padding = config.padding.left or 0
    local right_padding = config.padding.right or 0
    content_width = width - left_padding - right_padding
  end
  
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
      
      -- Calculate exact width for filename to maintain alignment within content width
      -- Priority: icon + key + minimum padding must always fit
      local icon_width = vim.fn.strwidth(icon .. '  ')
      local key_width = vim.fn.strwidth(key_part)
      local minimum_padding = 2 -- minimum padding between filename and key
      local reserved_width = icon_width + key_width + minimum_padding
      
      -- Calculate available width for filename (ensure we always have space for key)
      local available_filename_width = math.max(3, content_width - reserved_width) -- minimum 3 chars for filename
      
      -- Truncate filename to fit in available space
      local display_name = M.truncate_filename_for_alignment(file, available_filename_width)
      local actual_filename_width = vim.fn.strwidth(display_name)
      
      -- Calculate padding to fill remaining space
      local used_width = icon_width + actual_filename_width + key_width
      local padding_length = math.max(minimum_padding, content_width - used_width)
      
      -- Final safety check: if somehow we still exceed content width, reduce padding
      if used_width + padding_length > content_width then
        padding_length = math.max(1, content_width - used_width)
      end
      
      local padding = string.rep(' ', padding_length)
      
      -- Create line with multiple highlight sections (always preserving the key)
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
  
  -- Handle very small widths
  if max_width <= 3 then
    return string.rep('.', max_width)
  end
  
  -- For better alignment, prefer showing the filename (basename) over the full path
  local parts = vim.split(filename, '/')
  local basename = parts[#parts] or filename
  
  -- If just the basename fits with "..." prefix, use that
  local basename_width = vim.fn.strwidth(basename)
  if basename_width <= max_width - 3 then
    return '...' .. basename
  end
  
  -- Otherwise, truncate the basename itself
  local target_basename_width = max_width - 3
  local truncated_basename = basename
  
  -- Simple truncation from the end to preserve start of filename
  while vim.fn.strwidth(truncated_basename) > target_basename_width do
    truncated_basename = truncated_basename:sub(1, -2)
  end
  
  return '...' .. truncated_basename
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

-- Store recent files keymaps in a global namespace to avoid conflicts
local recent_files_keymaps = {}

function M.clear_file_keymaps()
  local current_buf = vim.api.nvim_get_current_buf()
  
  -- Only clear if we're in a luxdash buffer and have stored keymaps
  if vim.bo[current_buf].filetype == 'luxdash' and recent_files_keymaps[current_buf] then
    -- Clear only the keymaps we set for recent files
    for key, _ in pairs(recent_files_keymaps[current_buf]) do
      pcall(vim.keymap.del, 'n', key, { buffer = current_buf })
    end
    recent_files_keymaps[current_buf] = nil
  end
end

function M.setup_file_keymap(index, filepath)
  local key = tostring(index)
  
  -- Get the current buffer to ensure we're setting the keymap on the correct buffer
  local current_buf = vim.api.nvim_get_current_buf()
  
  -- Only set keymap if we're in a luxdash buffer
  if vim.bo[current_buf].filetype == 'luxdash' then
    -- Initialize keymap storage for this buffer if not exists
    if not recent_files_keymaps[current_buf] then
      recent_files_keymaps[current_buf] = {}
    end
    
    -- Store the keymap reference to track what we set
    recent_files_keymaps[current_buf][key] = filepath
    
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
      buffer = current_buf, 
      silent = true,
      desc = 'Open recent file: ' .. filepath
    })
  end
end

return M