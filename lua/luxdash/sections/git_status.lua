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
    
    -- Line 1: Branch name only
    if git_info.branch and lines_added < available_height then
      local branch_line = M.format_branch_line(git_info, width)
      table.insert(content, branch_line)
      lines_added = lines_added + 1
    end
    
    -- Line 2: Remote status
    if git_info.ahead_behind and git_info.remote_info and lines_added < available_height then
      local remote_line = M.format_remote_line(git_info, width)
      table.insert(content, remote_line)
      lines_added = lines_added + 1
    end
    
    -- Line 3: File changes summary
    if git_info.status_counts and lines_added < available_height then
      local changes_line = M.format_changes_line(git_info, width)
      if changes_line then
        table.insert(content, changes_line)
        lines_added = lines_added + 1
      end
    end
    
    -- Line 4: Insertions/deletions stats
    if git_info.diff_stats and lines_added < available_height then
      local stats_line = M.format_stats_line(git_info, width)
      if stats_line then
        table.insert(content, stats_line)
        lines_added = lines_added + 1
      end
    end
    
    -- Line 5: Last commit message
    if git_info.commit_info and lines_added < available_height then
      local commit_line = M.format_commit_line(git_info, width)
      table.insert(content, commit_line)
      lines_added = lines_added + 1
    end
    
    -- Line 6: Author info
    if git_info.commit_details and git_info.commit_details.author and lines_added < available_height then
      local author_line = M.format_author_line(git_info, width)
      table.insert(content, author_line)
      lines_added = lines_added + 1
    end
    
    -- Line 7: Date info
    if git_info.commit_details and git_info.commit_details.date and lines_added < available_height then
      local date_line = M.format_date_line(git_info, width)
      table.insert(content, date_line)
      lines_added = lines_added + 1
    end
  end
  
  -- Final safety check: ensure content never exceeds available height
  if #content > available_height then
    local truncated_content = {}
    for i = 1, available_height do
      if content[i] then
        table.insert(truncated_content, content[i])
      end
    end
    content = truncated_content
  end
  
  return content
end

function M.get_git_status()
  local result = {
    is_repo = false,
    branch = nil,
    status_counts = nil,
    commit_info = nil,
    commit_details = nil,
    diff_stats = nil,
    ahead_behind = nil,
    remote_info = nil
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
  
  -- Get last commit info with full details
  local commit_output = vim.fn.system('git log -1 --pretty=format:"%h %s" 2>/dev/null')
  if vim.v.shell_error == 0 and commit_output then
    result.commit_info = vim.trim(commit_output)
  end
  
  -- Get detailed commit information
  local commit_details_output = vim.fn.system('git log -1 --pretty=format:"%an <%ae>%n%ci" 2>/dev/null')
  if vim.v.shell_error == 0 and commit_details_output then
    result.commit_details = M.parse_commit_details(commit_details_output)
  end
  
  -- Get diff stats (insertions/deletions)
  local diff_output = vim.fn.system('git diff --numstat HEAD 2>/dev/null')
  if vim.v.shell_error == 0 then
    result.diff_stats = M.parse_diff_stats(diff_output)
  end
  
  -- Get ahead/behind info with remote branch name
  local remote_branch_output = vim.fn.system('git rev-parse --abbrev-ref @{upstream} 2>/dev/null')
  if vim.v.shell_error == 0 and remote_branch_output then
    result.remote_info = {
      branch = vim.trim(remote_branch_output)
    }
    
    local ahead_behind_output = vim.fn.system('git rev-list --count --left-right @{upstream}...HEAD 2>/dev/null')
    if vim.v.shell_error == 0 and ahead_behind_output then
      result.ahead_behind = M.parse_ahead_behind(ahead_behind_output)
    end
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

function M.parse_commit_details(commit_details_output)
  local lines = vim.split(commit_details_output, '\n')
  if #lines >= 2 then
    local author = lines[1]
    local date_str = lines[2]
    
    -- Parse ISO date and format it
    local formatted_date = M.format_commit_date(date_str)
    
    return {
      author = author,
      date = formatted_date
    }
  end
  return nil
end

function M.format_commit_date(iso_date)
  -- Parse ISO date format: 2025-08-04 14:23:45 +0000
  local year, month, day, hour, min = iso_date:match('(%d+)-(%d+)-(%d+) (%d+):(%d+)')
  if year and month and day and hour and min then
    return string.format('%s-%s-%s %s:%s', year, month, day, hour, min)
  end
  return iso_date -- fallback to original if parsing fails
end

function M.format_branch_line(git_info, width)
  local branch = git_info.branch or 'unknown'
  local branch_text = 'Branch:         ' .. branch
  
  return {
    {'LuxDashGitBranch', M.truncate_text(branch_text, width)}
  }
end

function M.format_remote_line(git_info, width)
  local ab = git_info.ahead_behind
  local remote = git_info.remote_info.branch or 'origin/' .. git_info.branch
  local remote_text = ''
  
  if ab.ahead > 0 then
    remote_text = string.format('Remote:         ⏱ %d commit%s ahead of %s', 
      ab.ahead, ab.ahead == 1 and '' or 's', remote)
  elseif ab.behind > 0 then
    remote_text = string.format('Remote:         ⏱ %d commit%s behind %s', 
      ab.behind, ab.behind == 1 and '' or 's', remote)
  else
    remote_text = 'Remote:         ⏱ up to date with ' .. remote
  end
  
  return {
    {'LuxDashGitSync', M.truncate_text(remote_text, width)}
  }
end

function M.format_changes_line(git_info, width)
  local counts = git_info.status_counts
  if not counts then return nil end
  
  local total_changes = counts.modified + counts.added + counts.deleted + counts.untracked
  if total_changes == 0 then return nil end
  
  local parts = {}
  
  if counts.modified > 0 then
    table.insert(parts, '~' .. counts.modified)
  end
  
  if counts.added > 0 then
    table.insert(parts, '+' .. counts.added)
  end
  
  if counts.deleted > 0 then
    table.insert(parts, '-' .. counts.deleted)
  end
  
  local changes_text = 'File:           ' .. table.concat(parts, ' ')
  
  return {
    {'LuxDashGitSync', M.truncate_text(changes_text, width)}
  }
end

function M.format_stats_line(git_info, width)
  local stats = git_info.diff_stats
  if not stats or (stats.insertions == 0 and stats.deletions == 0) then 
    return nil 
  end
  
  local stats_text = string.format('Diff:           +%d -%d', 
    stats.insertions, stats.deletions)
  
  return {
    {'LuxDashGitDiff', M.truncate_text(stats_text, width)}
  }
end

function M.format_commit_line(git_info, width)
  local commit_msg = git_info.commit_info or 'No commits'
  local commit_text = '📝 Last commit: "' .. commit_msg .. '"'
  
  return {
    {'LuxDashGitCommit', M.truncate_text(commit_text, width)}
  }
end

function M.format_author_line(git_info, width)
  local author = git_info.commit_details.author
  local author_text = '👤 Author:      ' .. author
  
  return {
    {'LuxDashGitCommit', M.truncate_text(author_text, width)}
  }
end

function M.format_date_line(git_info, width)
  local date = git_info.commit_details.date
  local date_text = '📅 Date:        ' .. date  
  
  return {
    {'LuxDashGitCommit', M.truncate_text(date_text, width)}
  }
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