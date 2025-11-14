local M = {}
local colors = require('luxdash.rendering.colors')

---Render logo section
---@param width number Available width for logo
---@param height number Available height for logo
---@param config table Section configuration
---@return table lines Array of logo lines with highlights
function M.render(width, height, config)
  local logo = config.logo or {}
  local logo_color = config.logo_color

  if #logo == 0 then
    return {}
  end

  -- Use the provided width parameter (from layout) for caching
  -- This ensures correct rendering when window is resized
  local colored_logo = colors.apply_logo_color(logo, logo_color, width)
  return colored_logo
end


return M