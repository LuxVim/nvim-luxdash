local M = {}

function M.render(width, height, config)
  local menu_items = config.menu_items or {}
  local extras = config.extras or {}
  
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
  
  return content
end

return M