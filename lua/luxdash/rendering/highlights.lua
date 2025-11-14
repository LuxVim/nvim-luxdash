local M = {}

-- Define default highlight groups for LuxDash
-- These are linked to standard Neovim highlight groups to automatically
-- adapt to any colorscheme. Users can override these in their config if needed.
M.groups = {
  -- Menu highlights
  LuxDashMenuTitle = { link = 'Title' },
  LuxDashMenuIcon = { link = 'Special' },
  LuxDashMenuText = { link = 'Normal' },
  LuxDashMenuKey = { link = 'Number', bold = true },
  LuxDashMenuSeparator = { link = 'NonText' },

  -- Main section highlights (top sections)
  LuxDashMainTitle = { link = 'Title', bold = true },
  LuxDashMainSeparator = { link = 'Special' },

  -- Sub section highlights (bottom sections)
  LuxDashSubTitle = { link = 'Function', bold = true },
  LuxDashSubSeparator = { link = 'Comment' },

  -- Legacy section highlights (for compatibility)
  LuxDashSectionTitle = { link = 'Title', bold = true },
  LuxDashSectionSeparator = { link = 'NonText' },

  -- Recent files highlights
  LuxDashRecentFile = { link = 'Identifier' },
  LuxDashRecentPath = { link = 'Directory' },
  LuxDashRecentIcon = { link = 'Special' },
  LuxDashRecentKey = { link = 'Number', bold = true },

  -- Git status highlights
  -- Links to standard diff/diagnostic groups for consistent theming
  LuxDashGitBranch = { link = 'Function', bold = true },
  LuxDashGitModified = { link = 'WarningMsg' },
  LuxDashGitAdded = { link = 'DiffAdd' },
  LuxDashGitDeleted = { link = 'DiffDelete' },
  LuxDashGitUntracked = { link = 'Comment' },
  LuxDashGitClean = { link = 'DiffAdd', bold = true },
  LuxDashGitCommit = { link = 'Type' },
  LuxDashGitDiff = { link = 'Function' },
  LuxDashGitSync = { link = 'WarningMsg' },

  -- Logo highlights
  LuxDashLogo = { link = 'Title' },

  -- General text
  LuxDashText = { link = 'Normal' },
  LuxDashComment = { link = 'Comment' }
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
