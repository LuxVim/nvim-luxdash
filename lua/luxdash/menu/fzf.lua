local M = {}

function M.command()
  return {
    keymap = "f",
    label = "Find Files",
    command = function()
      local float = require('luxdash.ui.float_manager')
      if float.is_open() then
        float.close()
      end
      if vim.fn.exists(':Telescope') > 0 then
        vim.cmd('Telescope find_files')
      elseif vim.fn.exists(':FzfLua') > 0 then
        vim.cmd('FzfLua files')
      else
        vim.cmd('edit .')
      end
    end
  }
end

return M