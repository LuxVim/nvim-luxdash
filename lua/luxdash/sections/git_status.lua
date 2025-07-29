local M = {}

function M.render(width, height, config)
  local git_info = M.get_git_status()
  
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
  
  local content = {}
  
  if not git_info.is_repo then
    table.insert(content, {'LuxDashComment', 'Not a git repo'})
  else
    local lines_added = 0
    
    if git_info.branch and lines_added < available_height then
      local branch_line = '󰘬 ' .. M.truncate_text(git_info.branch, width - 8)
      table.insert(content, {'LuxDashGitBranch', branch_line})
      lines_added = lines_added + 1
    end
    
    if git_info.status_counts and lines_added < available_height then
      local counts = git_info.status_counts
      if counts.modified > 0 and lines_added < available_height then
        table.insert(content, {'LuxDashGitModified', M.truncate_text('󰷈 Modified: ' .. counts.modified, width)})
        lines_added = lines_added + 1
      end
      if counts.added > 0 and lines_added < available_height then
        table.insert(content, {'LuxDashGitAdded', M.truncate_text('󰐕 Added: ' .. counts.added, width)})
        lines_added = lines_added + 1
      end
      if counts.deleted > 0 and lines_added < available_height then
        table.insert(content, {'LuxDashGitDeleted', M.truncate_text('󰍵 Deleted: ' .. counts.deleted, width)})
        lines_added = lines_added + 1
      end
      if counts.untracked > 0 and lines_added < available_height then
        table.insert(content, {'LuxDashGitUntracked', M.truncate_text('󰋖 Untracked: ' .. counts.untracked, width)})
        lines_added = lines_added + 1
      end
      
      if counts.modified == 0 and counts.added == 0 and counts.deleted == 0 and counts.untracked == 0 and lines_added < available_height then
        table.insert(content, {'LuxDashGitClean', '󰸞 Clean'})
        lines_added = lines_added + 1
      end
    end
  end
  
  return content
end

function M.get_git_status()
  local result = {
    is_repo = false,
    branch = nil,
    status_counts = nil
  }
  
  local branch_output = vim.fn.system('git branch --show-current 2>/dev/null')
  if vim.v.shell_error == 0 and branch_output then
    result.is_repo = true
    result.branch = vim.trim(branch_output)
  else
    return result
  end
  
  local status_output = vim.fn.system('git status --porcelain 2>/dev/null')
  if vim.v.shell_error == 0 then
    result.status_counts = M.parse_git_status(status_output)
  end
  
  return result
end

function M.parse_git_status(status_output)
  local counts = {
    modified = 0,
    added = 0,
    deleted = 0,
    untracked = 0
  }
  
  for line in status_output:gmatch('[^\r\n]+') do
    local status_code = line:sub(1, 2)
    
    if status_code:match('^M') or status_code:match('^.M') then
      counts.modified = counts.modified + 1
    elseif status_code:match('^A') or status_code:match('^.A') then
      counts.added = counts.added + 1
    elseif status_code:match('^D') or status_code:match('^.D') then
      counts.deleted = counts.deleted + 1
    elseif status_code:match('^%?%?') then
      counts.untracked = counts.untracked + 1
    end
  end
  
  return counts
end

function M.truncate_text(text, max_width)
  if vim.fn.strwidth(text) <= max_width then
    return text
  end
  
  if max_width > 3 then
    return text:sub(1, max_width - 3) .. '...'
  else
    return text:sub(1, max_width)
  end
end


return M