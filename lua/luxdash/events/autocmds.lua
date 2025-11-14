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
  
  -- Re-apply highlights and refresh dashboard when colorscheme changes
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = group,
    callback = function()
      local highlights = require('luxdash.rendering.highlights')
      highlights.setup()

      -- Clear color cache to refresh theme-based gradients
      local colors = require('luxdash.rendering.colors')
      colors.clear_color_cache()

      -- Clear highlight pool cache as well
      local highlight_pool = require('luxdash.core.highlight_pool')
      highlight_pool.clear_highlight_cache()

      -- Refresh all luxdash windows with new theme colors
      vim.defer_fn(function()
        -- Check if any luxdash buffers are open before refreshing
        local has_luxdash = false
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == 'luxdash' then
            has_luxdash = true
            break
          end
        end

        if has_luxdash then
          local resizer = require('luxdash.core.resizer')
          resizer.resize_immediate()
        end
      end, 50) -- Small delay to ensure colorscheme is fully applied
    end
  })
end

return M