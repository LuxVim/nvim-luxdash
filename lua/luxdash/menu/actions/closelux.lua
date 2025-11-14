local M = {}

function M.command()
  return {
    keymap = "q",
    label = "Close LuxDash",
    command = function()
      local float = require('luxdash.ui.float_manager')
      if float.is_open() then
        float.close()
      else
        vim.cmd('quit')
      end
    end
  }
end

return M