---@class Core
---Core API facade for LuxDash
---Provides high-level functions to control dashboard lifecycle
local M = {}

---Open the dashboard
---Creates buffer, builds content, and renders it
function M.open()
  local float_manager = require('luxdash.ui.float_manager')
  if float_manager.is_open() then
    float_manager.close()
    return
  end

  local buffer_manager = require('luxdash.ui.buffer_manager')
  buffer_manager.create()

  -- Create context for building and rendering
  local context_module = require('luxdash.core.context')
  local winid = vim.api.nvim_get_current_win()
  local bufnr = vim.api.nvim_get_current_buf()

  local context = context_module.from_window(winid)
  context.bufnr = bufnr

  M.build(context)
  M.draw(context)
end

---Build dashboard content
---Generates all sections based on current configuration
---@param context? RenderContext Optional context (creates new if not provided)
function M.build(context)
  if not context then
    local context_module = require('luxdash.core.context')
    local winid = vim.api.nvim_get_current_win()
    context = context_module.from_window(winid)
  end

  local builder = require('luxdash.core.builder')
  builder.build(context)
end

---Draw dashboard to buffer
---Renders lines and applies highlights
---@param context RenderContext Rendering context with dashboard content
function M.draw(context)
  if not context then
    vim.notify('LuxDash: Cannot draw without context', vim.log.levels.ERROR)
    return
  end

  local renderer = require('luxdash.core.renderer')
  renderer.draw(context)
end

---Handle window resize
---Rebuilds and redraws dashboard with new dimensions
function M.resize()
  local resizer = require('luxdash.core.resizer')
  resizer.resize()
end

return M