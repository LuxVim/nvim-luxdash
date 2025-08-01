local M = {}
local colors = require('luxdash.rendering.colors')

function M.render(width, height, config)
  local logo = config.logo or {}
  local logo_color = config.logo_color
  
  if #logo == 0 then
    return {}
  end
  
  -- Pass window width for caching optimization
  local window_width = vim.api.nvim_win_get_width(0)
  local colored_logo = colors.apply_logo_color(logo, logo_color, window_width)
  return colored_logo
end


return M