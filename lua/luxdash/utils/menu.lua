local M = {}
local highlights = require('luxdash.rendering.highlights')
local icons = require('luxdash.utils.icons')

local menu_options = {}
local menu_width = 30

function M.options(modules)
  menu_options = {}
  
  for _, name in ipairs(modules) do
    local info = M.get_option(name)
    
    if info.keymap and info.keymap ~= '' and info.command then
      local label = info.label or name:gsub('^%l', string.upper)
      local icon = info.icon or icons.get_icon(name)
      
      -- Format: icon + label + spaces + [key]
      local text_part = icon .. '  ' .. label
      local key_part = '[' .. info.keymap .. ']'
      local total_width = 24
      local padding_width = math.max(1, total_width - vim.fn.strwidth(text_part) - vim.fn.strwidth(key_part))
      local padding = string.rep(' ', padding_width)
      
      -- Create line with multiple highlight sections
      local line_parts = {
        {'LuxDashMenuIcon', icon .. '  '},
        {'LuxDashMenuText', label},
        {'Normal', padding},
        {'LuxDashMenuKey', key_part}
      }
      
      table.insert(menu_options, line_parts)
      
      if type(info.command) == 'function' then
        vim.keymap.set('n', info.keymap, info.command, { 
          buffer = true, 
          silent = true 
        })
      else
        vim.keymap.set('n', info.keymap, function()
          vim.cmd(info.command)
        end, { 
          buffer = true, 
          silent = true 
        })
      end
    end
  end
  
  return menu_options
end

function M.get_option(type)
  local ok, result = pcall(function()
    local key = 'luxdash_menu_' .. type
    local func_name = 'luxdash.menu.' .. type
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
    return {
      keymap = '',
      label = type:gsub('^%l', string.upper),
      command = function() end
    }
  end
end

return M