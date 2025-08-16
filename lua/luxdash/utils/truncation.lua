local M = {}

-- Enhanced truncation strategies for different content types
function M.truncate_text(text, max_width, strategy)
  if vim.fn.strwidth(text) <= max_width then
    return text
  end
  
  strategy = strategy or 'end'
  
  if max_width <= 3 then
    return string.rep('.', max_width)
  end
  
  if strategy == 'middle' then
    return M.truncate_middle(text, max_width)
  elseif strategy == 'start' then
    return M.truncate_start(text, max_width)
  elseif strategy == 'smart_path' then
    return M.truncate_smart_path(text, max_width)
  elseif strategy == 'preserve_extension' then
    return M.truncate_preserve_extension(text, max_width)
  else
    return M.truncate_end(text, max_width)
  end
end

-- Truncate from end (default)
function M.truncate_end(text, max_width)
  return text:sub(1, max_width - 3) .. '...'
end

-- Truncate from start 
function M.truncate_start(text, max_width)
  local start_pos = vim.fn.strwidth(text) - max_width + 4
  return '...' .. text:sub(start_pos)
end

-- Truncate from middle, preserving start and end
function M.truncate_middle(text, max_width)
  local prefix_len = math.floor((max_width - 3) / 2)
  local suffix_len = max_width - 3 - prefix_len
  local prefix = text:sub(1, prefix_len)
  local suffix = text:sub(-suffix_len)
  return prefix .. '...' .. suffix
end

-- Smart path truncation - preserve filename and show ... for path
function M.truncate_smart_path(text, max_width)
  local parts = vim.split(text, '/')
  if #parts > 1 then
    local filename = parts[#parts]
    local filename_width = vim.fn.strwidth(filename)
    
    -- If just filename fits with "..." prefix, use that
    if filename_width <= max_width - 3 then
      return '...' .. filename
    end
    
    -- Otherwise truncate the filename itself
    return M.truncate_end(filename, max_width)
  end
  
  return M.truncate_end(text, max_width)
end

-- Preserve file extension when truncating
function M.truncate_preserve_extension(text, max_width)
  local name, ext = text:match("^(.+)(%..+)$")
  if name and ext then
    local ext_width = vim.fn.strwidth(ext)
    local available_name_width = max_width - ext_width - 3
    
    if available_name_width > 0 then
      local truncated_name = name:sub(1, available_name_width)
      return truncated_name .. '...' .. ext
    end
  end
  
  return M.truncate_end(text, max_width)
end

-- Git commit message truncation - preserve start and end
function M.truncate_commit_message(message, max_width)
  -- Remove quotes if present
  local clean_message = message:gsub('^"(.*)"$', '%1')
  return M.truncate_middle(clean_message, max_width)
end

-- Git branch truncation - preserve prefix type (feature/, bugfix/, etc.)
function M.truncate_branch_name(branch, max_width)
  local prefix, name = branch:match("^([^/]+/)(.+)$")
  if prefix and name then
    local prefix_width = vim.fn.strwidth(prefix)
    local available_name_width = max_width - prefix_width - 3
    
    if available_name_width > 3 then
      local truncated_name = name:sub(1, available_name_width)
      return prefix .. truncated_name .. '...'
    end
  end
  
  return M.truncate_end(branch, max_width)
end

return M