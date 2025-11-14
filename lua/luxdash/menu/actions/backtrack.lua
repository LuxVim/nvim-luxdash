local M = {}

function M.command()
  return {
    keymap = "b",
    label = "Backtrack",
    command = function()
      local float = require('luxdash.ui.float_manager')
      if float.is_open() then
        float.close()
      end
      if vim.fn.exists(':Telescope') > 0 then
        vim.cmd('Telescope oldfiles')
      else
        vim.cmd('browse oldfiles')
      end
    end
  }
end

return M