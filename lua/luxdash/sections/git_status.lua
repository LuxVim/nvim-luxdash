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
    
    -- Branch information with status summary
    if git_info.branch and lines_added < available_height then
      local icon = '󰘬'
      local branch_status = M.format_branch_status(git_info, width - 8)
      local line_parts = {
        {'LuxDashGitBranch', icon .. '  '},
        {'LuxDashGitBranch', branch_status}
      }
      table.insert(content, line_parts)
      lines_added = lines_added + 1
    end
    
    -- Last commit info
    if git_info.commit_info and lines_added < available_height then
      local icon = '󰒲'
      local label = 'Latest: ' .. M.truncate_text(git_info.commit_info, width - 12)
      local line_parts = {
        {'LuxDashGitCommit', icon .. '  '},
        {'LuxDashGitCommit', label}
      }
      table.insert(content, line_parts)
      lines_added = lines_added + 1
    end
    
    -- Working tree status with standard formatting
    if git_info.status_counts and lines_added < available_height then
      local counts = git_info.status_counts
      local total_changes = counts.modified + counts.added + counts.deleted + counts.untracked
      
      if total_changes > 0 then
        -- Show summary line first
        local summary_icon = '󰊢'
        local summary_text = string.format('%d file%s', total_changes, total_changes == 1 and '' or 's')
        local summary_parts = {
          {'LuxDashGitSync', summary_icon .. '  '},
          {'LuxDashGitSync', summary_text}
        }
        table.insert(content, summary_parts)
        lines_added = lines_added + 1
        
        -- Show detailed breakdown with consistent alignment
        if counts.modified > 0 and lines_added < available_height then
          local mod_parts = {
            {'LuxDashGitModified', '    M '},
            {'LuxDashGitModified', string.format('%d modified', counts.modified)}
          }
          table.insert(content, mod_parts)
          lines_added = lines_added + 1
        end
        if counts.added > 0 and lines_added < available_height then
          local add_parts = {
            {'LuxDashGitAdded', '    A '},
            {'LuxDashGitAdded', string.format('%d staged', counts.added)}
          }
          table.insert(content, add_parts)
          lines_added = lines_added + 1
        end
        if counts.deleted > 0 and lines_added < available_height then
          local del_parts = {
            {'LuxDashGitDeleted', '    D '},
            {'LuxDashGitDeleted', string.format('%d deleted', counts.deleted)}
          }
          table.insert(content, del_parts)
          lines_added = lines_added + 1
        end
        if counts.untracked > 0 and lines_added < available_height then
          local unt_parts = {
            {'LuxDashGitUntracked', '    ? '},
            {'LuxDashGitUntracked', string.format('%d untracked', counts.untracked)}
          }
          table.insert(content, unt_parts)
          lines_added = lines_added + 1
        end
      else
        local clean_parts = {
          {'LuxDashGitClean', '󰸞  '},
          {'LuxDashGitClean', 'Working tree clean'}
        }
        table.insert(content, clean_parts)
        lines_added = lines_added + 1
      end
    end
    
    -- Diff statistics
    if git_info.diff_stats and lines_added < available_height then
      local stats = git_info.diff_stats
      if stats.insertions > 0 or stats.deletions > 0 then
        local icon = '󰊤'
        local label = string.format('+%d -%d', stats.insertions, stats.deletions)
        local line_parts = {
          {'LuxDashGitDiff', icon .. '  '},
          {'LuxDashGitDiff', label}
        }
        table.insert(content, line_parts)
        lines_added = lines_added + 1
      end
    end
    
    -- Remote sync status with standard formatting
    if git_info.ahead_behind and lines_added < available_height then
      local ab = git_info.ahead_behind
      local sync_icon = '󰞃'
      local sync_text = ''
      
      if ab.ahead > 0 and ab.behind > 0 then
        sync_text = string.format('Remote: %d ahead, %d behind', ab.ahead, ab.behind)
      elseif ab.ahead > 0 then
        sync_text = string.format('Remote: %d commit%s ahead', ab.ahead, ab.ahead == 1 and '' or 's')
      elseif ab.behind > 0 then
        sync_text = string.format('Remote: %d commit%s behind', ab.behind, ab.behind == 1 and '' or 's')
      else
        sync_text = 'Remote: up to date'
      end
      
      local sync_parts = {
        {'LuxDashGitSync', sync_icon .. '  '},
        {'LuxDashGitSync', sync_text}
      }
      table.insert(content, sync_parts)
      lines_added = lines_added + 1
    end
  end
  
  return content
end

function M.get_git_status()
  local result = {
    is_repo = false,
    branch = nil,
    status_counts = nil,
    commit_info = nil,
    diff_stats = nil,
    ahead_behind = nil
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
  
  -- Get last commit info
  local commit_output = vim.fn.system('git log -1 --pretty=format:"%h %s" 2>/dev/null')
  if vim.v.shell_error == 0 and commit_output then
    result.commit_info = vim.trim(commit_output)
  end
  
  -- Get diff stats (insertions/deletions)
  local diff_output = vim.fn.system('git diff --numstat HEAD 2>/dev/null')
  if vim.v.shell_error == 0 then
    result.diff_stats = M.parse_diff_stats(diff_output)
  end
  
  -- Get ahead/behind info
  local ahead_behind_output = vim.fn.system('git rev-list --count --left-right @{upstream}...HEAD 2>/dev/null')
  if vim.v.shell_error == 0 and ahead_behind_output then
    result.ahead_behind = M.parse_ahead_behind(ahead_behind_output)
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

function M.parse_diff_stats(diff_output)
  local stats = {
    insertions = 0,
    deletions = 0
  }
  
  for line in diff_output:gmatch('[^\r\n]+') do
    local insertions, deletions = line:match('^(%d+)%s+(%d+)')
    if insertions and deletions then
      stats.insertions = stats.insertions + tonumber(insertions)
      stats.deletions = stats.deletions + tonumber(deletions)
    end
  end
  
  return stats
end

function M.parse_ahead_behind(ahead_behind_output)
  local behind, ahead = ahead_behind_output:match('^(%d+)%s+(%d+)')
  if behind and ahead then
    return {
      ahead = tonumber(ahead),
      behind = tonumber(behind)
    }
  end
  return { ahead = 0, behind = 0 }
end

function M.format_branch_status(git_info, max_width)
  local branch_text = git_info.branch or 'unknown'
  
  -- Build status parts
  local status_parts = {}
  
  if git_info.status_counts then
    local counts = git_info.status_counts
    local total_modified = counts.modified + counts.deleted + counts.untracked
    
    if total_modified > 0 then
      table.insert(status_parts, '~' .. total_modified)
    end
    
    if counts.added > 0 then
      table.insert(status_parts, '+' .. counts.added)
    end
  end
  
  if git_info.diff_stats then
    local stats = git_info.diff_stats
    if stats.deletions > 0 then
      table.insert(status_parts, '-' .. stats.deletions)
    end
  end
  
  -- Combine branch name with status
  local full_text = branch_text
  if #status_parts > 0 then
    full_text = branch_text .. ' [' .. table.concat(status_parts, ' ') .. ']'
  end
  
  -- Truncate if too long
  return M.truncate_text(full_text, max_width)
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