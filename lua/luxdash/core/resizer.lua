local M = {}
local debouncer = require('luxdash.core.debouncer')
local cache = require('luxdash.core.cache')

function M.resize()
  M.resize_immediate()
end

function M.resize_debounced()
  debouncer.debounce_resize(function()
    M.resize_immediate()
  end)
end

function M.resize_immediate()
  -- Invalidate layout cache on resize
  cache.invalidate_layout()
  
  for _, winnr in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(winnr) then
      local bufnr = vim.api.nvim_win_get_buf(winnr)
      if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_option(bufnr, 'filetype') == 'luxdash' then
        local current_win = vim.api.nvim_get_current_win()
        local ok, _ = pcall(function()
          vim.api.nvim_set_current_win(winnr)
          local builder = require('luxdash.core.builder')
          local renderer = require('luxdash.core.renderer')
          builder.build()
          renderer.draw()
          vim.api.nvim_set_current_win(current_win)
        end)
        if not ok then
          -- If resize fails, restore current window
          if vim.api.nvim_win_is_valid(current_win) then
            vim.api.nvim_set_current_win(current_win)
          end
        end
      end
    end
  end
end

return M