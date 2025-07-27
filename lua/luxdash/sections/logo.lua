local M = {}
local colors = require('luxdash.colors')

function M.render(width, height, config)
  local logo = config.logo or {}
  local logo_color = config.logo_color
  
  if #logo == 0 then
    return {}
  end
  
  local colored_logo = colors.apply_logo_color(logo, logo_color)
  return colored_logo
end


return M