local M = {}
local alignment = require('luxdash.alignment')

function M.render(width, height, config)
  local menu_items = config.menu_items or {}
  local extras = config.extras or {}
  local alignment_config = config.alignment or { horizontal = 'center', vertical = 'center' }
  
  local content = {}
  
  for _, item in ipairs(menu_items) do
    table.insert(content, item)
  end
  
  for _, extra in ipairs(extras) do
    table.insert(content, extra)
  end
  
  if #content > 0 then
    table.insert(content, '')
  end
  
  return alignment.align_content(content, width, height, alignment_config)
end

return M