local M = {}

function M.render(width, height, config)
  local git_info = M.get_git_status()
  
  local content = {}
  
  if not git_info.is_repo then
    table.insert(content, {'LuxDashComment', 'Not a git repo'})
  else
    if git_info.branch then
      local branch_line = '󰘬 ' .. M.truncate_text(git_info.branch, width - 8)
      table.insert(content, {'LuxDashGitBranch', branch_line})
    end
    
    if git_info.status_counts then
      local counts = git_info.status_counts
      if counts.modified > 0 then
        table.insert(content, {'LuxDashGitModified', '󰷈 Modified: ' .. counts.modified})
      end
      if counts.added > 0 then
        table.insert(content, {'LuxDashGitAdded', '󰐕 Added: ' .. counts.added})
      end
      if counts.deleted > 0 then
        table.insert(content, {'LuxDashGitDeleted', '󰍵 Deleted: ' .. counts.deleted})
      end
      if counts.untracked > 0 then
        table.insert(content, {'LuxDashGitUntracked', '󰋖 Untracked: ' .. counts.untracked})
      end
      
      if counts.modified == 0 and counts.added == 0 and counts.deleted == 0 and counts.untracked == 0 then
        table.insert(content, {'LuxDashGitClean', '󰸞 Clean'})
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