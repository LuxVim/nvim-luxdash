local M = {}

function M.create()
  vim.cmd('enew')
  
  -- Don't set buffer name to make it qualify as "open" for vim-luxpane
  -- local config = require('luxdash').config
  -- vim.api.nvim_buf_set_name(0, config.name or 'LuxDash')
  
  vim.bo.buftype = 'nofile'
  vim.bo.bufhidden = 'hide'
  vim.bo.buflisted = false
  vim.bo.swapfile = false
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = 'no'
  vim.wo.foldcolumn = '0'
  vim.wo.cursorline = false
  vim.bo.modifiable = true
  vim.bo.filetype = 'luxdash'
end

return M