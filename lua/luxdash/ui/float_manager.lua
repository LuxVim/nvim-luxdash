local M = {}

local float_win = nil
local float_buf = nil
local origin_win = nil
local render_generation = 0

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
  -- Store window handle before any operations that might invalidate it
  local win_to_close = float_win
  local buf_to_cleanup = float_buf
  local restore_focus = win_to_close == vim.api.nvim_get_current_win()
  local return_win = origin_win

  -- Clear state immediately to prevent re-entrance
  float_win = nil
  origin_win = nil
  render_generation = render_generation + 1

  -- Validate window still exists before attempting close
  if win_to_close and vim.api.nvim_win_is_valid(win_to_close) then
    -- Emit event for components to cleanup before close (avoids circular dependency)
    if buf_to_cleanup and vim.api.nvim_buf_is_valid(buf_to_cleanup) then
      local bus = require('luxdash.events.bus')
      bus.emit('float_closing', buf_to_cleanup)
    end

    -- Close window with protection
    pcall(vim.api.nvim_win_close, win_to_close, true)
  end
  if restore_focus and return_win and vim.api.nvim_win_is_valid(return_win) then
    vim.api.nvim_set_current_win(return_win)
  end

  -- Handle buffer cleanup
  if buf_to_cleanup and vim.api.nvim_buf_is_valid(buf_to_cleanup) then
    if M.config.hide_buffer then
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf_to_cleanup) then
          pcall(vim.api.nvim_buf_delete, buf_to_cleanup, { force = true })
        end
      end)
      float_buf = nil
    end
  end
end

function M.create_buffer()
  if not float_buf or not vim.api.nvim_buf_is_valid(float_buf) then
    float_buf = vim.api.nvim_create_buf(false, true)

    -- Use vim.bo instead of deprecated nvim_buf_set_option
    vim.bo[float_buf].buftype = 'nofile'
    vim.bo[float_buf].bufhidden = M.config.hide_buffer and 'wipe' or 'hide'
    vim.bo[float_buf].buflisted = false
    vim.bo[float_buf].swapfile = false
    vim.bo[float_buf].modifiable = true
    vim.bo[float_buf].filetype = 'luxdash'
  end

  return float_buf
end

function M.calculate_dimensions()
  local ui = vim.api.nvim_list_uis()[1] or { width = vim.o.columns, height = vim.o.lines }
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
  
  width = math.max(1, math.min(width, ui.width - 2))
  height = math.max(1, math.min(height, ui.height - vim.o.cmdheight - 2))
  local row = math.max(0, math.floor((ui.height - height - 2) / 2))
  local col = math.max(0, math.floor((ui.width - width - 2) / 2))
  
  return {
    width = width,
    height = height,
    row = row,
    col = col
  }
end

function M.open()
  if M.is_open() then
    return
  end
  
  origin_win = vim.api.nvim_get_current_win()
  local buf = M.create_buffer()
  local dimensions = M.calculate_dimensions()
  
  local win_config = {
    relative = M.config.relative,
    width = dimensions.width,
    height = dimensions.height,
    row = dimensions.row,
    col = dimensions.col,
    style = M.config.style,
    border = M.config.border,
    title = M.config.title,
    title_pos = M.config.title_pos,
    zindex = 100
  }
  
  float_win = vim.api.nvim_open_win(buf, true, win_config)
  
  M.configure_window()
  M.setup_autocmds(buf)
  M.setup_keymaps(buf)
  M.render()
  
  return float_win, buf
end

function M.configure_window()
  -- Use vim.wo instead of deprecated nvim_win_set_option
  vim.wo[float_win].number = false
  vim.wo[float_win].relativenumber = false
  vim.wo[float_win].signcolumn = 'no'
  vim.wo[float_win].foldcolumn = '0'
  vim.wo[float_win].cursorline = false
  vim.wo[float_win].wrap = false
end

function M.setup_autocmds(buf)
  local group = vim.api.nvim_create_augroup('LuxDashFloat', { clear = true })
  local win = float_win
  
  vim.api.nvim_create_autocmd('WinClosed', {
    group = group,
    pattern = tostring(float_win),
    callback = function()
      if float_win == win then M.close() end
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
end

function M.setup_keymaps(buf)
  vim.keymap.set('n', '<Esc>', function() M.close() end, { buffer = buf, nowait = true })
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

function M.render()
  render_generation = render_generation + 1
  local generation, win, buf = render_generation, float_win, float_buf
  vim.schedule(function()
    if generation ~= render_generation or win ~= float_win or not M.is_open()
      or not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_win_get_buf(win) ~= buf then return end
    local context = require('luxdash.core.context').from_window(win, require('luxdash').config)
    require('luxdash.core.builder').build(context)
    require('luxdash.core.renderer').draw(context)
  end)
end

function M.resize()
  if not M.is_open() then
    return
  end
  
  local dimensions = M.calculate_dimensions()
  
  vim.api.nvim_win_set_config(float_win, {
    relative = M.config.relative,
    width = dimensions.width,
    height = dimensions.height,
    row = dimensions.row,
    col = dimensions.col
  })
  
  M.render()
end

-- Register event handlers to avoid circular dependencies
local bus = require('luxdash.events.bus')

-- Listen for close requests from other components (e.g., recent_files)
bus.on('request_close', function()
  if M.is_open() then
    M.close()
  end
end)

return M
