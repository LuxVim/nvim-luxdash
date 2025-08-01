local M = {}

local float_win = nil
local float_buf = nil

M.config = {
  width = 0.9,
  height = 0.9,
  border = 'rounded',
  title = ' LuxDash ',
  title_pos = 'center',
  relative = 'editor',
  style = 'minimal',
  hide_buffer = false
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
end

function M.is_open()
  return float_win ~= nil and vim.api.nvim_win_is_valid(float_win)
end

function M.close()
  if M.is_open() then
    vim.api.nvim_win_close(float_win, true)
    float_win = nil
  end
  
  if float_buf and vim.api.nvim_buf_is_valid(float_buf) then
    if M.config.hide_buffer then
      vim.api.nvim_buf_delete(float_buf, { force = true })
      float_buf = nil
    end
  end
end

function M.create_buffer()
  if not float_buf or not vim.api.nvim_buf_is_valid(float_buf) then
    float_buf = vim.api.nvim_create_buf(false, true)
    
    vim.api.nvim_buf_set_option(float_buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(float_buf, 'bufhidden', M.config.hide_buffer and 'wipe' or 'hide')
    vim.api.nvim_buf_set_option(float_buf, 'buflisted', false)
    vim.api.nvim_buf_set_option(float_buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(float_buf, 'modifiable', true)
    vim.api.nvim_buf_set_option(float_buf, 'filetype', 'luxdash')
  end
  
  return float_buf
end

function M.open()
  if M.is_open() then
    return
  end
  
  local buf = M.create_buffer()
  
  local ui = vim.api.nvim_list_uis()[1]
  local width, height
  
  if M.config.width <= 1 then
    width = math.floor(ui.width * M.config.width)
  else
    width = math.min(M.config.width, ui.width - 4)
  end
  
  if M.config.height <= 1 then
    height = math.floor(ui.height * M.config.height)
  else
    height = math.min(M.config.height, ui.height - 4)
  end
  
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)
  
  local win_config = {
    relative = M.config.relative,
    width = width,
    height = height,
    row = row,
    col = col,
    style = M.config.style,
    border = M.config.border,
    title = M.config.title,
    title_pos = M.config.title_pos,
    zindex = 100
  }
  
  float_win = vim.api.nvim_open_win(buf, true, win_config)
  
  vim.api.nvim_win_set_option(float_win, 'number', false)
  vim.api.nvim_win_set_option(float_win, 'relativenumber', false)
  vim.api.nvim_win_set_option(float_win, 'signcolumn', 'no')
  vim.api.nvim_win_set_option(float_win, 'foldcolumn', '0')
  vim.api.nvim_win_set_option(float_win, 'cursorline', false)
  vim.api.nvim_win_set_option(float_win, 'wrap', false)
  
  local group = vim.api.nvim_create_augroup('LuxDashFloat', { clear = true })
  
  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    pattern = tostring(float_win),
    callback = function()
      M.close()
      vim.api.nvim_del_augroup_by_id(group)
    end,
    once = true
  })
  
  vim.api.nvim_create_autocmd('VimResized', {
    group = group,
    callback = function()
      if M.is_open() then
        M.resize()
      end
    end
  })
  
  vim.keymap.set('n', '<Esc>', function() M.close() end, { buffer = buf, nowait = true })
  
  return float_win, buf
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
    vim.schedule(function()
      require('luxdash.core').build()
      require('luxdash.core').draw()
    end)
  end
end

function M.resize()
  if not M.is_open() then
    return
  end
  
  local ui = vim.api.nvim_list_uis()[1]
  local width, height
  
  if M.config.width <= 1 then
    width = math.floor(ui.width * M.config.width)
  else
    width = math.min(M.config.width, ui.width - 4)
  end
  
  if M.config.height <= 1 then
    height = math.floor(ui.height * M.config.height)
  else
    height = math.min(M.config.height, ui.height - 4)
  end
  
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)
  
  vim.api.nvim_win_set_config(float_win, {
    relative = M.config.relative,
    width = width,
    height = height,
    row = row,
    col = col
  })
  
  require('luxdash.core').resize()
end

return M