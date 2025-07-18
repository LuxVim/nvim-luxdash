local M = {}

local menu_options = {}
local menu_width = 26

function M.options(modules)
  menu_options = {}
  
  for _, name in ipairs(modules) do
    local info = M.get_option(name)
    
    if info.keymap and info.command then
      local label = info.label or name:gsub('^%l', string.upper)
      local text = string.format('[%s]  %s', info.keymap, label)
      local padding = math.max(0, menu_width - vim.fn.strwidth(text))
      local padded = '      ' .. text .. string.rep(' ', padding)
      
      table.insert(menu_options, padded)
      
      vim.keymap.set('n', info.keymap, info.command, { 
        buffer = true, 
        silent = true 
      })
    end
  end
  
  table.insert(menu_options, '')
  return menu_options
end

function M.get_option(type)
  local ok, result = pcall(function()
    local key = 'luxdash_menu_' .. type
    local func_name = 'luxdash.menu.' .. type .. '.command'
    local global_config = vim.g[key]
    
    if global_config and type(global_config) == 'table' then
      return global_config
    end
    
    local ok_func, func_module = pcall(require, func_name)
    if ok_func and func_module and func_module.command then
      return func_module.command()
    end
    
    return {}
  end)
  
  if ok then
    return result
  else
    error('No menu configuration defined for ' .. type)
  end
end

return M