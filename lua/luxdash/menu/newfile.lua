local M = {}

function M.command()
  return {
    keymap = "n",
    label = "New File",
    command = function()
      local float = require('luxdash.ui.float_manager')
      if float.is_open() then
        float.close()
      end
      vim.cmd('enew')
    end
  }
end

return M