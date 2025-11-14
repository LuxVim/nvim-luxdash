local M = {}
local text_utils = require('luxdash.utils.text')
local icons = require('luxdash.utils.icons')

-- Constants for recent files section
local MAX_FILES_LIMIT = 9  -- Maximum number of recent files to display
local MIN_FILENAME_WIDTH = 3  -- Minimum width for filename display
local MIN_PADDING = 2  -- Minimum padding between filename and key
local ICON_SPACING = 2  -- Spacing after icon

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
  max_files = math.min(max_files, available_height, MAX_FILES_LIMIT)
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
      -- Request float manager close via event bus (avoids circular dependency)
      local bus = require('luxdash.events.bus')
      bus.emit('request_close')

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

-- Register event handlers to avoid circular dependencies
local bus = require('luxdash.events.bus')

-- Listen for float closing events to cleanup keymaps
bus.on('float_closing', function(bufnr)
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        local old_buf = vim.api.nvim_get_current_buf()
        pcall(vim.api.nvim_set_current_buf, bufnr)
        pcall(M.clear_file_keymaps)
        if vim.api.nvim_buf_is_valid(old_buf) then
          pcall(vim.api.nvim_set_current_buf, old_buf)
        end
      end
    end)
  end
end)

return M