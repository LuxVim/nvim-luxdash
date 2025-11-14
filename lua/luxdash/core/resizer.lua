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
  -- Invalidate all caches on resize to force fresh render
  cache.invalidate_all()

  -- Also clear color cache (logo gradients)
  local colors = require('luxdash.rendering.colors')
  colors.clear_color_cache()

  local current_win = vim.api.nvim_get_current_win()
  local current_win_config = vim.api.nvim_win_get_config(current_win)

  -- Don't interfere if user is currently in a floating window
  if current_win_config.relative ~= '' then
    return
  end

  for _, winnr in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(winnr) then
      local bufnr = vim.api.nvim_win_get_buf(winnr)
      if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == 'luxdash' then
        local ok, err = pcall(function()
          -- Create context for the luxdash window
          local context_module = require('luxdash.core.context')
          local config = require('luxdash').config
          local context = context_module.from_window(winnr, config)
          context.bufnr = bufnr

          -- Build and render with context
          local builder = require('luxdash.core.builder')
          local renderer = require('luxdash.core.renderer')

          builder.build(context)
          renderer.draw(context)
        end)
        if not ok then
          vim.notify('LuxDash resize failed: ' .. tostring(err), vim.log.levels.WARN)
          -- If resize fails, restore current window
          if vim.api.nvim_win_is_valid(current_win) then
            pcall(vim.api.nvim_set_current_win, current_win)
          end
        end
      end
    end
  end
end

return M