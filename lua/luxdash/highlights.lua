local M = {}

-- Define default highlight groups for LuxDash
M.groups = {
  -- Menu highlights
  LuxDashMenuTitle = { fg = '#569cd6', bold = true },
  LuxDashMenuIcon = { fg = '#4ec9b0' },
  LuxDashMenuText = { fg = '#d4d4d4' },
  LuxDashMenuKey = { fg = '#dcdcaa', bold = true },
  LuxDashMenuSeparator = { fg = '#606060' },
  
  -- Main section highlights (top sections)
  LuxDashMainTitle = { fg = '#569cd6', bold = true },
  LuxDashMainSeparator = { fg = '#569cd6' },
  
  -- Sub section highlights (bottom sections)
  LuxDashSubTitle = { fg = '#4ec9b0', bold = true },
  LuxDashSubSeparator = { fg = '#d4d4d4' },
  
  -- Legacy section highlights (for compatibility)
  LuxDashSectionTitle = { fg = '#569cd6', bold = true },
  LuxDashSectionSeparator = { fg = '#606060' },
  
  -- Recent files highlights
  LuxDashRecentFile = { fg = '#d4d4d4' },
  LuxDashRecentPath = { fg = '#9cdcfe' },
  
  -- Git status highlights
  LuxDashGitBranch = { fg = '#4ec9b0' },
  LuxDashGitModified = { fg = '#dcdcaa' },
  LuxDashGitAdded = { fg = '#4ec9b0' },
  LuxDashGitDeleted = { fg = '#f44747' },
  LuxDashGitUntracked = { fg = '#ce9178' },
  LuxDashGitClean = { fg = '#4ec9b0' },
  
  -- Logo highlights (existing)
  LuxDashLogo = { fg = '#569cd6' },
  
  -- General text
  LuxDashText = { fg = '#d4d4d4' },
  LuxDashComment = { fg = '#6a9955' }
}

function M.setup()
  for group, opts in pairs(M.groups) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

-- Get a highlight group name with fallback
function M.get_hl(name, fallback)
  if M.groups[name] then
    return name
  end
  return fallback or 'Normal'
end

return M