local M = {}

-- Track window dimensions globally
local win_dimensions = {}

function M.get_dimensions(key)
  return win_dimensions[key]
end

function M.set_dimensions(key, width, height) 
  win_dimensions[key] = {width = width, height = height}
end

function M.has_changed(key, width, height)
  if not win_dimensions[key] then
    return true
  end
  return win_dimensions[key].width ~= width or win_dimensions[key].height ~= height
end

function M.get_key(winnr, bufnr)
  return winnr .. '_' .. bufnr
end

function M.check_and_resize_luxdash()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_option(bufnr, 'filetype') == 'luxdash' then
    local winnr = vim.api.nvim_get_current_win()
    local width = vim.api.nvim_win_get_width(winnr)
    local height = vim.api.nvim_win_get_height(winnr)
    local key = M.get_key(winnr, bufnr)
    
    if M.has_changed(key, width, height) then
      M.set_dimensions(key, width, height)
      local resizer = require('luxdash.core.resizer')
      resizer.resize()
    end
  end
end

function M.check_all_luxdash_windows()
  for _, winnr in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(winnr)
    if vim.api.nvim_buf_get_option(bufnr, 'filetype') == 'luxdash' then
      local width = vim.api.nvim_win_get_width(winnr)
      local height = vim.api.nvim_win_get_height(winnr)
      local key = M.get_key(winnr, bufnr)
      
      if M.has_changed(key, width, height) then
        M.set_dimensions(key, width, height)
        local current_win = vim.api.nvim_get_current_win()
        vim.api.nvim_set_current_win(winnr)
        local resizer = require('luxdash.core.resizer')
        resizer.resize()
        vim.api.nvim_set_current_win(current_win)
      end
    end
  end
end

return M