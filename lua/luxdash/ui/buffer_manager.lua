local M = {}

function M.create()
  vim.cmd('enew')
  
  -- local config = require('luxdash').config
  -- vim.api.nvim_buf_set_name(0, config.name or 'LuxDash')
    vim.bo.buftype = 'nofile'
    vim.bo.bufhidden = 'hide'
    vim.bo.buflisted = false
    vim.bo.swapfile = false
  
    -- Set window-local options for luxdash buffer
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = 'no'
    vim.wo.foldcolumn = '0'
    vim.wo.cursorline = false
    vim.bo.modifiable = true
    vim.bo.filetype = 'luxdash'
  
  M.setup_autocmds()
end

function M.setup_autocmds()
  -- Create autocmd group to handle line number restoration
  vim.api.nvim_create_augroup("LuxdashLineNumbers", { clear = false })
  
  -- Disable line numbers for luxdash filetype
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "luxdash",
    group = "LuxdashLineNumbers",
    callback = function()
      vim.wo.number = false
      vim.wo.relativenumber = false
    end
  })
  
  -- Restore line numbers when leaving luxdash buffer
  vim.api.nvim_create_autocmd("BufLeave", {
    pattern = "*",
    group = "LuxdashLineNumbers", 
    callback = function()
      if vim.bo.filetype == "luxdash" then
        vim.schedule(function()
          -- Only restore if we're in a normal buffer
          if vim.bo.buftype == "" then
            vim.wo.number = true
            vim.wo.relativenumber = true
          end
        end)
      end
    end
  })
end

return M