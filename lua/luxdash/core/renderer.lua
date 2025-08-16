local M = {}
local dashboard_data = require('luxdash.core.dashboard')
local line_utils = require('luxdash.rendering.line_utils')
local highlight_pool = require('luxdash.core.highlight_pool')
local width_utils = require('luxdash.utils.width')

function M.clear()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
  highlight_pool.clear_all_namespaces()
end

function M.draw()
  vim.bo.modifiable = true
  M.clear()
  M.print()
  vim.api.nvim_win_set_cursor(0, {1, 0})
  vim.bo.modifiable = false
end

function M.print()
  local config = require('luxdash').config
  local winheight = vim.api.nvim_win_get_height(0)
  local winwidth = vim.api.nvim_win_get_width(0)
  
  -- Ensure dashboard is built before rendering
  local dashboard = dashboard_data.get_dashboard()
  if #dashboard == 0 then
    local builder = require('luxdash.core.builder')
    builder.build()
    dashboard = dashboard_data.get_dashboard()
  end
  
  -- Apply buffer padding
  local padding = config.padding or { left = 2, right = 2, top = 1, bottom = 1 }
  local content_width = winwidth - padding.left - padding.right
  local content_height = winheight - padding.top - padding.bottom
  
  local table_width = 0
  for _, line in ipairs(dashboard) do
    local line_text
    if type(line) == 'table' then
      -- Handle different table formats
      if #line > 0 and type(line[1]) == 'table' then
        -- Complex format: {{highlight, text}, {highlight, text}, ...}
        -- Extract text from all parts
        local combined_text = ''
        for _, part in ipairs(line) do
          if type(part) == 'table' and #part >= 2 then
            combined_text = combined_text .. tostring(part[2] or '')
          end
        end
        line_text = combined_text
      elseif line[2] then
        -- Simple format: {highlight, text}
        line_text = tostring(line[2])
      else
        -- Fallback
        line_text = tostring(line[1] or '')
      end
    else
      line_text = tostring(line)
    end
    table_width = math.max(table_width, vim.fn.strwidth(line_text))
  end
  local pad_left = padding.left + math.floor((content_width - table_width) / 2)
  local pad_top = padding.top + math.max(0, math.floor((content_height - #dashboard) / 2))
  
  local lines = {}
  local all_highlights = {}
  
  for _ = 1, pad_top do
    table.insert(lines, '')
  end
  
  for _, line in ipairs(dashboard) do
    -- For logo lines, use pad_left = 0 to bypass renderer padding constraints
    local line_pad_left = pad_left
    
    -- Check if this is a logo line (has logo highlight group)
    local is_logo_line = false
    if type(line) == 'table' then
      if #line > 0 and type(line[1]) == 'table' then
        -- Complex format - check if any part has logo highlight
        for _, part in ipairs(line) do
          if type(part) == 'table' and #part >= 2 and type(part[1]) == 'string' and part[1]:match('^LuxDashLogo') then
            is_logo_line = true
            break
          end
        end
      elseif line[1] and type(line[1]) == 'string' and line[1]:match('^LuxDashLogo') then
        -- Simple format with logo highlight
        is_logo_line = true
      end
    end
    
    -- For logo lines, ignore renderer padding constraints and use full window width
    if is_logo_line then
      line_pad_left = 0
    end
    
    local padded_text, line_highlights = line_utils.process_line_for_rendering(line, line_pad_left)
    table.insert(lines, padded_text)
    
    for _, hl in ipairs(line_highlights) do
      table.insert(all_highlights, {
        line_num = #lines,
        start_col = hl.start_col,
        end_col = hl.end_col,
        hl_group = hl.hl_group
      })
    end
  end
  
  vim.api.nvim_buf_set_lines(0, 0, 0, false, lines)
  
  -- Apply highlights
  line_utils.apply_highlights(all_highlights, lines)
end

function M.apply_highlights(lines, all_highlights)
  -- Use consolidated highlight pool for all highlight management
  highlight_pool.clear_all_namespaces()
  highlight_pool.batch_apply_highlights(all_highlights, lines)
end

return M