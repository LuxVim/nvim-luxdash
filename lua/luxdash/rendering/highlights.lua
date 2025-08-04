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
  LuxDashRecentPath = { fg = '#ff7801' },
  LuxDashRecentIcon = { fg = '#ff7801' },
  LuxDashRecentKey = { fg = '#db2dee', bold = true },
  
  -- Git status highlights using standard git colors
  LuxDashGitBranch = { fg = '#58a6ff', bold = true },     -- Blue for branch
  LuxDashGitModified = { fg = '#f0883e' },                -- Orange for modified (M)
  LuxDashGitAdded = { fg = '#3fb950' },                   -- Green for staged/added (A)
  LuxDashGitDeleted = { fg = '#f85149' },                 -- Red for deleted (D)
  LuxDashGitUntracked = { fg = '#8b949e' },               -- Gray for untracked (?)
  LuxDashGitClean = { fg = '#3fb950', bold = true },      -- Green for clean status
  LuxDashGitCommit = { fg = '#d2a8ff' },                  -- Purple for commit info
  LuxDashGitDiff = { fg = '#58a6ff' },                    -- Blue for diff stats
  LuxDashGitSync = { fg = '#f0883e' },                    -- Orange for sync status
  
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
