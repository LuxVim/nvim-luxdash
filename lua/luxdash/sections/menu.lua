local M = {}

function M.render(width, height, config)
  local menu_items = config.menu_items or {}
  local section_renderer = require('luxdash.rendering.section_renderer')
  
  -- Use standardized height calculation
  local available_height = section_renderer.calculate_available_height(height, config)
  
  -- Ensure we have at least 1 line of height to work with
  if available_height <= 0 then
    return {}
  end
  
  local content = {}
  
  -- Limit menu items to available height to prevent overflow
  local max_items = math.min(#menu_items, available_height)
  
  for i = 1, max_items do
    local item = menu_items[i]
    if item then
      table.insert(content, item)
    end
  end
  
  return content
end

return M
