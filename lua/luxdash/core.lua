local M = {}

function M.open()
  local float_manager = require('luxdash.ui.float_manager')
  if float_manager.is_open() then
    float_manager.close()
    return
  end
  
  local buffer_manager = require('luxdash.ui.buffer_manager')
  buffer_manager.create()
  M.build()
  M.draw()
end

function M.build()
  local builder = require('luxdash.core.builder')
  builder.build()
end

function M.draw()
  local renderer = require('luxdash.core.renderer')
  renderer.draw()
end

function M.resize()
  local resizer = require('luxdash.core.resizer')
  resizer.resize()
end

return M