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
  
  -- Limit max_files to available height
  max_files = math.min(max_files, available_height)
  
  local recent_files = M.get_recent_files(max_files)
  
  local content = {}
  
  if #recent_files == 0 then
    table.insert(content, {'LuxDashComment', 'No recent files'})
  else
    for i, file in ipairs(recent_files) do
      local display_name = M.truncate_filename(file, width - 2)
      table.insert(content, {'LuxDashRecentFile', display_name})
    end
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


return M