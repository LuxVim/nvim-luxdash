local M = {}

function M.render(width, height, config)
  local menu_items = config.menu_items or {}
  
  -- Calculate available height for content (subtract title and underline if present)
  local available_height = height
  if config.show_title ~= false then
    available_height = available_height - 1  -- title
    if config.show_underline ~= false then
      available_height = available_height - 1  -- underline
    end
    if config.title_spacing ~= false then
      available_height = available_height - 1  -- spacing
    end
  end
  
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
