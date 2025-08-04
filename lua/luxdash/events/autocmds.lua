local M = {}

function M.setup()
  local window_tracker = require('luxdash.utils.window_tracker')
  local group = vim.api.nvim_create_augroup('LuxDash', { clear = true })
  
  vim.api.nvim_create_autocmd('VimEnter', {
    group = group,
    callback = function()
      if vim.fn.argc() == 0 then
        require('luxdash.core').open()
      end
    end
  })
  
  vim.api.nvim_create_autocmd('VimResized', {
    group = group,
    callback = function()
      local resizer = require('luxdash.core.resizer')
      resizer.resize_debounced()
    end
  })
  
  vim.api.nvim_create_autocmd({'WinEnter', 'BufWinEnter'}, {
    group = group,
    callback = window_tracker.check_and_resize_luxdash
  })
  
  -- Also check on window leave to catch nvim-tree toggles
  vim.api.nvim_create_autocmd('WinLeave', {
    group = group,
    callback = function()
      -- Delay check to allow window operations to complete
      vim.defer_fn(function()
        window_tracker.check_all_luxdash_windows()
      end, 10)
    end
  })
  
  -- Re-apply highlights when colorscheme changes
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = function()
      local highlights = require('luxdash.rendering.highlights')
      highlights.setup()
    end
  })
end

return M