local M = {}
local icons = require('luxdash.utils.icons')
local text_utils = require('luxdash.utils.text')

-- Constants for git command execution
local GIT_TIMEOUT_MS = 2000  -- 2 seconds timeout for git commands
local GIT_CACHE_TTL_MS = 5000  -- 5 seconds TTL for cache

-- Cache for git status to avoid running git commands on every render
local git_cache = {
  data = nil,
  timestamp = 0,
  ttl = GIT_CACHE_TTL_MS,
  cwd = nil
}

---Execute a git command with timeout protection
---@param cmd string The git command to execute
---@return string|nil output Command output or nil on failure
---@return boolean success Whether the command succeeded
local function safe_git_cmd(cmd)
  local output
  local success = false
  local timer_expired = false

  -- Create a timer that will set a flag if command takes too long
  local timer = vim.loop.new_timer()
  if not timer then
    return nil, false
  end

  timer:start(GIT_TIMEOUT_MS, 0, function()
    timer_expired = true
    timer:stop()
    timer:close()
  end)

  -- Execute command
  output = vim.fn.system(cmd)
  success = vim.v.shell_error == 0

  -- Stop timer if still running
  if not timer_expired then
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end

  -- If timer expired, consider it a failure
  if timer_expired then
    return nil, false
  end

  if success and output then
    return output, true
  end

  return nil, false
end

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
  -- Check cache validity
  local now = vim.loop.now()
  local cwd = vim.fn.getcwd()

  if git_cache.data and
     git_cache.cwd == cwd and
     (now - git_cache.timestamp) < git_cache.ttl then
    return git_cache.data
  end

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

  local branch_output, branch_success = safe_git_cmd('git branch --show-current 2>/dev/null')
  if branch_success and branch_output then
    result.is_repo = true
    result.branch = vim.trim(branch_output)
  else
    -- Cache even negative results to avoid repeated git calls
    git_cache.data = result
    git_cache.timestamp = now
    git_cache.cwd = cwd
    return result
  end
  
  local status_output, status_success = safe_git_cmd('git status --porcelain 2>/dev/null')
  if status_success and status_output then
    result.status_counts = M.parse_git_status(status_output)
  end
  
  -- Get last commit info with full details
  local commit_output, commit_success = safe_git_cmd('git log -1 --pretty=format:"%h %s" 2>/dev/null')
  if commit_success and commit_output then
    result.commit_info = vim.trim(commit_output)
  end
  
  -- Get detailed commit information
  local commit_details_output, commit_details_success = safe_git_cmd('git log -1 --pretty=format:"%an <%ae>%n%ci" 2>/dev/null')
  if commit_details_success and commit_details_output then
    result.commit_details = M.parse_commit_details(commit_details_output)
  end
  
  -- Get diff stats (insertions/deletions)
  local diff_output, diff_success = safe_git_cmd('git diff --numstat HEAD 2>/dev/null')
  if diff_success and diff_output then
    result.diff_stats = M.parse_diff_stats(diff_output)
  end
  
  -- Get ahead/behind info with remote branch name
  local remote_branch_output, remote_success = safe_git_cmd('git rev-parse --abbrev-ref @{upstream} 2>/dev/null')
  if remote_success and remote_branch_output then
    result.remote_info = {
      branch = vim.trim(remote_branch_output)
    }

    local ahead_behind_output, ahead_behind_success = safe_git_cmd('git rev-list --count --left-right @{upstream}...HEAD 2>/dev/null')
    if ahead_behind_success and ahead_behind_output then
      result.ahead_behind = M.parse_ahead_behind(ahead_behind_output)
    end
  end

  -- Cache the result
  git_cache.data = result
  git_cache.timestamp = now
  git_cache.cwd = cwd

  return result
end

-- Clear cache manually if needed (e.g., after git operations)
function M.clear_cache()
  git_cache.data = nil
  git_cache.timestamp = 0
  git_cache.cwd = nil
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
  local icon = icons.get_git_icon('branch')
  local branch_text = icon .. '  Branch:       ' .. branch

  return {
    {'LuxDashGitBranch', text_utils.truncate(branch_text, width, { suffix = '...' })}
  }
end

function M.format_remote_line(git_info, width)
  local ab = git_info.ahead_behind
  local icon = icons.get_git_icon('remote')
  local remote_text = ''
  
  if ab.ahead > 0 then
    remote_text = string.format('%s  Remote:       Ahead %d commit%s', 
      icon, ab.ahead, ab.ahead == 1 and '' or 's')
  elseif ab.behind > 0 then
    remote_text = string.format('%s  Remote:       Behind %d commit%s', 
      icon, ab.behind, ab.behind == 1 and '' or 's')
  else
    remote_text = icon .. '  Remote:       Up to date'
  end
  
  return {
    {'LuxDashGitSync', text_utils.truncate(remote_text, width, { suffix = '...' })}
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
  
  local icon = icons.get_git_icon('changes')
  local changes_text = icon .. '  File:         ' .. table.concat(parts, ' ')
  
  return {
    {'LuxDashGitSync', text_utils.truncate(changes_text, width, { suffix = '...' })}
  }
end

function M.format_stats_line(git_info, width)
  local stats = git_info.diff_stats
  if not stats or (stats.insertions == 0 and stats.deletions == 0) then 
    return nil 
  end
  
  local icon = icons.get_git_icon('diff')
  local stats_text = string.format('%s  Diff:         +%d -%d', 
    icon, stats.insertions, stats.deletions)
  
  return {
    {'LuxDashGitDiff', text_utils.truncate(stats_text, width, { suffix = '...' })}
  }
end

function M.format_commit_line(git_info, width)
  local commit_msg = git_info.commit_info or 'No commits'
  local icon = icons.get_git_icon('commit')
  local commit_text = icon .. '  Last commit: "' .. commit_msg .. '"'
  
  return {
    {'LuxDashGitCommit', text_utils.truncate(commit_text, width, { suffix = '...' })}
  }
end

function M.format_author_line(git_info, width)
  local author = git_info.commit_details.author
  local icon = icons.get_git_icon('author')
  local author_text = icon .. '  Author:       ' .. author
  
  return {
    {'LuxDashGitCommit', text_utils.truncate(author_text, width, { suffix = '...' })}
  }
end

function M.format_date_line(git_info, width)
  local date = git_info.commit_details.date
  local icon = icons.get_git_icon('date')
  local date_text = icon .. '  Date:         ' .. date  
  
  return {
    {'LuxDashGitCommit', text_utils.truncate(date_text, width, { suffix = '...' })}
  }
end

return M