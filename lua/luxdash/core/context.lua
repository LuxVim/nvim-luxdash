---Context object for dependency injection
---Holds all dependencies needed for dashboard rendering
local M = {}

---Create a new rendering context
---@param opts table Options for context creation
---@return RenderContext context
function M.create(opts)
  opts = opts or {}

  local dashboard_module = require('luxdash.core.dashboard')
  local cache_module = require('luxdash.core.cache')

  local context = {
    -- Core dependencies
    config = opts.config or require('luxdash').config,
    dashboard = opts.dashboard or dashboard_module.create(),
    cache = opts.cache or cache_module,

    -- Window dimensions
    dimensions = {
      width = opts.width or vim.api.nvim_win_get_width(0),
      height = opts.height or vim.api.nvim_win_get_height(0)
    },

    -- Buffer and window handles
    bufnr = opts.bufnr,
    winid = opts.winid,

    -- Metadata
    metadata = {
      created_at = vim.loop.now(),
      render_count = 0
    }
  }

  ---Update window dimensions
  ---@param width number Window width
  ---@param height number Window height
  function context:update_dimensions(width, height)
    self.dimensions.width = width
    self.dimensions.height = height
  end

  ---Validate context state
  ---@return boolean valid True if context is valid
  ---@return string? error Error message if invalid
  function context:validate()
    if not self.config then
      return false, "Context missing config"
    end

    if not self.dashboard then
      return false, "Context missing dashboard instance"
    end

    if not self.dimensions then
      return false, "Context missing dimensions"
    end

    if self.dimensions.width < 1 or self.dimensions.height < 1 then
      return false, string.format(
        "Invalid dimensions: %dx%d",
        self.dimensions.width,
        self.dimensions.height
      )
    end

    return true
  end

  ---Increment render count
  function context:increment_render_count()
    self.metadata.render_count = self.metadata.render_count + 1
  end

  ---Get context metadata
  ---@return table metadata
  function context:get_metadata()
    return vim.deepcopy(self.metadata)
  end

  return context
end

---Create a context from a window
---@param winid number Window ID
---@param config? table Optional config override
---@return RenderContext context
function M.from_window(winid, config)
  if not vim.api.nvim_win_is_valid(winid) then
    error("Invalid window ID: " .. tostring(winid))
  end

  local width = vim.api.nvim_win_get_width(winid)
  local height = vim.api.nvim_win_get_height(winid)
  local bufnr = vim.api.nvim_win_get_buf(winid)

  return M.create({
    config = config,
    width = width,
    height = height,
    winid = winid,
    bufnr = bufnr
  })
end

return M
