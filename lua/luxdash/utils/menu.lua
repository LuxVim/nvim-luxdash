local M = {}
local highlights = require('luxdash.rendering.highlights')
local icons = require('luxdash.utils.icons')

local menu_options = {}
local menu_width = 30

function M.options(modules)
  menu_options = {}
  
  if not modules or #modules == 0 then
    return menu_options
  end
  
  for _, name in ipairs(modules) do
    local info = M.get_option(name)
    
    -- Always create menu item if we have any info
    if info and info.keymap and info.keymap ~= '' and info.command then
      local label = info.label or name:gsub('^%l', string.upper)
      local icon = info.icon or icons.get_icon(name)
      
      -- Format: icon + label + spaces + [key]
      local text_part = icon .. '  ' .. label
      local key_part = '[' .. info.keymap .. ']'
      local total_width = 24
      local padding_width = math.max(1, total_width - vim.fn.strwidth(text_part) - vim.fn.strwidth(key_part))
      local padding = require('luxdash.utils.width').get_padding(padding_width)
      
      -- Create line with multiple highlight sections
      local line_parts = {
        {'LuxDashMenuIcon', icon .. '  '},
        {'LuxDashMenuText', label},
        {'Normal', padding},
        {'LuxDashMenuKey', key_part}
      }
      
      table.insert(menu_options, line_parts)
      
      -- Set up keymap
      if type(info.command) == 'function' then
        vim.keymap.set('n', info.keymap, info.command, { 
          buffer = true, 
          silent = true 
        })
      else
        vim.keymap.set('n', info.keymap, function()
          vim.cmd(tostring(info.command))
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
      local cmd_result = func_module.command()
      -- Ensure we have valid keymap and command
      if cmd_result and cmd_result.keymap and cmd_result.command then
        return cmd_result
      end
    end
    
    -- Return fallback with valid structure
    return {
      keymap = type:sub(1,1):lower(),
      label = type:gsub('^%l', string.upper),
      command = function() 
        print('Menu action not implemented: ' .. type)
      end
    }
  end)
  
  if ok and result and result.keymap and result.command then
    return result
  else
    -- Ensure fallback always has valid structure
    return {
      keymap = type:sub(1,1):lower(),
      label = type:gsub('^%l', string.upper),
      command = function() 
        print('Menu action failed to load: ' .. type)
      end
    }
  end
end

return M