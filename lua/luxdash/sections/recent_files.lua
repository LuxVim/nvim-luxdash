local M = {}
local text_utils = require('luxdash.utils.text')
local icons = require('luxdash.utils.icons')

-- Constants for recent files section
local MAX_FILES_LIMIT = 9  -- Maximum number of recent files to display
local MIN_FILENAME_WIDTH = 3  -- Minimum width for filename display
local MIN_PADDING = 2  -- Minimum padding between filename and key
local ICON_SPACING = 2  -- Spacing after icon

function M.render(width, height, config, context)
  -- Clear any existing keymaps for this section first
  local bufnr = context and context.bufnr
  if bufnr then M.clear_file_keymaps(bufnr) end
  
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
  max_files = math.min(max_files, available_height, MAX_FILES_LIMIT)
  -- Additional safety: ensure we have at least 1 line of height to work with
  if available_height <= 0 then
    max_files = 0
  end
  
  local recent_files = M.get_recent_entries(max_files, context and context.cwd)
  
  local content = {}
  
  if #recent_files == 0 then
    table.insert(content, {'LuxDashComment', 'No recent files'})
  else
    for i, entry in ipairs(recent_files) do
      local file = entry.label
      local icon = icons.get_file_icon(file)
      local key_part = '[' .. tostring(i) .. ']'
      
      -- Calculate exact width for filename to maintain alignment within content width
      -- Priority: icon + key + minimum padding must always fit
      local icon_width = vim.fn.strwidth(icon .. string.rep(' ', ICON_SPACING))
      local key_width = vim.fn.strwidth(key_part)
      local reserved_width = icon_width + key_width + MIN_PADDING

      -- Calculate available width for filename (ensure we always have space for key)
      local available_filename_width = math.max(MIN_FILENAME_WIDTH, content_width - reserved_width)

      -- Truncate filename to fit in available space using new text utils
      local display_name = text_utils.truncate(file, available_filename_width, {
        suffix = '...',
        preserve_basename = true
      })
      local actual_filename_width = vim.fn.strwidth(display_name)
      
      -- Calculate padding to fill remaining space
      local used_width = icon_width + actual_filename_width + key_width
      local padding_length = math.max(MIN_PADDING, content_width - used_width)

      -- Final safety check: if somehow we still exceed content width, reduce padding
      if used_width + padding_length > content_width then
        padding_length = math.max(1, content_width - used_width)
      end
      
      local padding = string.rep(' ', padding_length)
      
      -- Create line with multiple highlight sections (always preserving the key)
      local line_parts = {
        {'LuxDashRecentIcon', icon .. string.rep(' ', ICON_SPACING)},
        {'LuxDashRecentFile', display_name},
        {'Normal', padding},
        {'LuxDashRecentKey', key_part}
      }
      
      table.insert(content, line_parts)
      
      -- Set up numerical keymap to open the file
      if bufnr then M.setup_file_keymap(i, entry.path, bufnr) end
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

function M.relative_under_root(file, root)
  local windows = vim.fn.has('win32') == 1 or root:match('^%a:[/\\]') or root:match('^\\\\')
  if windows then
    file, root = file:gsub('\\', '/'), root:gsub('\\', '/')
  end
  file = vim.fs.normalize(file, { expand_env = false })
  root = vim.fs.normalize(root, { expand_env = false }):gsub('/+$', '')
  local prefix = root .. '/'
  local compared_file, compared_prefix = file, prefix
  if windows then compared_file, compared_prefix = file:lower(), prefix:lower() end
  if compared_file:sub(1, #compared_prefix) == compared_prefix then
    return file:sub(#prefix + 1)
  end
end

function M.get_recent_entries(max_count, cwd)
  local recent_files = {}
  
  local oldfiles = vim.v.oldfiles or {}
  cwd = cwd or vim.fn.getcwd()
  local count = 0
  
  for _, file in ipairs(oldfiles) do
    if count >= max_count then
      break
    end
    
    if vim.fn.filereadable(file) == 1 then
      local full_path = vim.fn.fnamemodify(file, ':p')
      local label = M.relative_under_root(full_path, cwd)
      if label then
        table.insert(recent_files, { path = full_path, label = label })
        count = count + 1
      end
    end
  end
  
  return recent_files
end

function M.get_recent_files(max_count, cwd)
  return vim.tbl_map(function(entry) return entry.label end, M.get_recent_entries(max_count, cwd))
end

-- Store recent files keymaps in a global namespace to avoid conflicts
local recent_files_keymaps = {}

-- Setup autocmd to clean up keymaps when buffers are deleted
local cleanup_group = vim.api.nvim_create_augroup('LuxDashRecentFilesCleanup', { clear = true })

vim.api.nvim_create_autocmd('BufDelete', {
  group = cleanup_group,
  callback = function(args)
    local buf = args.buf
    -- Clean up keymap tracking for deleted buffer
    if recent_files_keymaps[buf] then
      recent_files_keymaps[buf] = nil
    end
  end,
  desc = 'Clean up LuxDash recent files keymaps on buffer delete'
})

function M.clear_file_keymaps(bufnr)
  local current_buf = bufnr or vim.api.nvim_get_current_buf()
  
  -- Only clear if we're in a luxdash buffer and have stored keymaps
  if vim.api.nvim_buf_is_valid(current_buf) and recent_files_keymaps[current_buf] then
    -- Clear only the keymaps we set for recent files
    for key, _ in pairs(recent_files_keymaps[current_buf]) do
      pcall(vim.keymap.del, 'n', key, { buffer = current_buf })
    end
    recent_files_keymaps[current_buf] = nil
  end
end

function M.setup_file_keymap(index, filepath, bufnr)
  local key = tostring(index)
  
  -- Get the current buffer to ensure we're setting the keymap on the correct buffer
  local current_buf = bufnr or vim.api.nvim_get_current_buf()
  local full_path = vim.fn.fnamemodify(filepath, ':p')
  
  -- Only set keymap if we're in a luxdash buffer
  if current_buf > 0 and vim.api.nvim_buf_is_valid(current_buf) and vim.bo[current_buf].filetype == 'luxdash' then
    -- Initialize keymap storage for this buffer if not exists
    if not recent_files_keymaps[current_buf] then
      recent_files_keymaps[current_buf] = {}
    end
    
    -- Store the keymap reference to track what we set
    recent_files_keymaps[current_buf][key] = full_path
    
    vim.keymap.set('n', key, function()
      -- Open the file in current window
      if vim.fn.filereadable(full_path) == 1 then
        require('luxdash.events.bus').emit('request_close')
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

-- Register event handlers to avoid circular dependencies
local bus = require('luxdash.events.bus')

-- Listen for float closing events to cleanup keymaps
bus.on('float_closing', function(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    M.clear_file_keymaps(bufnr)
  end
end)

return M
