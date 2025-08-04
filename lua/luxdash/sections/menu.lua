local M = {}

function M.render(width, height, config)
  local menu_items = config.menu_items or {}
  
  local content = {}
  
  for _, item in ipairs(menu_items) do
    table.insert(content, item)
  end
  
  return content
end

return M
