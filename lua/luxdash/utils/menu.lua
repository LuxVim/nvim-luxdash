local M = {}
local highlights = require('luxdash.rendering.highlights')
local icons = require('luxdash.utils.icons')

local menu_options = {}
local menu_width = 30
local keymaps = {}

function M.clear(bufnr)
  if not bufnr then return end
  for key in pairs(keymaps[bufnr] or {}) do
    pcall(vim.keymap.del, 'n', key, { buffer = bufnr })
  end
  keymaps[bufnr] = nil
end

vim.api.nvim_create_autocmd('BufDelete', { callback = function(args) keymaps[args.buf] = nil end })

---Render menu items and bind their actions to an explicit dashboard buffer.
---@param modules string[]
---@param bufnr? integer Missing or stale targets render without installing mappings.
function M.options(modules, bufnr, max_items)
  menu_options = {}
  local can_bind = type(bufnr) == 'number' and bufnr > 0
    and vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == 'luxdash'
  if can_bind then M.clear(bufnr); keymaps[bufnr] = {} end
  
  for _, name in ipairs(modules) do
    if #menu_options >= (max_items or math.huge) then break end
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
      
      if can_bind then
        local command = info.command
        if type(command) ~= 'function' then
          command = function()
            vim.cmd(info.command)
          end
        end
        vim.keymap.set('n', info.keymap, command, { buffer = bufnr, silent = true })
        keymaps[bufnr][info.keymap] = true
      end
    end
  end
  
  return menu_options
end

function M.get_option(type)
  local ok, result = pcall(function()
    local key = 'luxdash_menu_' .. type
    -- Updated path to look in menu/actions subdirectory
    local func_name = 'luxdash.menu.actions.' .. type
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
