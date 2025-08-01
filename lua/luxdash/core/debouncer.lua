local M = {}

-- Active timers for debouncing
local timers = {}

function M.debounce(key, callback, delay)
  delay = delay or 50 -- Default 50ms delay
  
  -- Cancel existing timer for this key
  if timers[key] then
    vim.fn.timer_stop(timers[key])
  end
  
  -- Create new timer
  timers[key] = vim.fn.timer_start(delay, function()
    timers[key] = nil
    if callback then
      local ok, err = pcall(callback)
      if not ok then
        vim.notify('Debounced callback error: ' .. tostring(err), vim.log.levels.ERROR)
      end
    end
  end)
end

function M.cancel(key)
  if timers[key] then
    vim.fn.timer_stop(timers[key])
    timers[key] = nil
  end
end

function M.cancel_all()
  for key, timer_id in pairs(timers) do
    vim.fn.timer_stop(timer_id)
  end
  timers = {}
end

-- Specific debouncer for resize events
function M.debounce_resize(callback)
  M.debounce('resize', callback, 50)
end

-- Specific debouncer for window changes
function M.debounce_window_change(winnr, callback)
  local key = 'window_change_' .. winnr
  M.debounce(key, callback, 25)
end

-- Cleanup on exit
vim.api.nvim_create_autocmd('VimLeave', {
  callback = function()
    M.cancel_all()
  end
})

return M