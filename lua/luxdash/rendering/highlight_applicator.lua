---Highlight application utilities
---Applies highlight groups to buffer lines
local M = {}

local highlight_pool = require('luxdash.core.highlight_pool')

---Apply highlights to buffer using highlight_pool's batch API
---@param bufnr number Buffer number
---@param highlights table Array of highlight specifications
---@param lines table Array of line texts
function M.apply_highlights(bufnr, highlights, lines)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  -- Use the highlight pool's batch apply function
  -- This handles namespace grouping, logo highlight extension, etc.
  highlight_pool.batch_apply_highlights(bufnr, highlights, lines)
end

return M
