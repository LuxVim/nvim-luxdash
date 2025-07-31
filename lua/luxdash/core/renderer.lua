local M = {}
local dashboard_data = require('luxdash.core.dashboard')
local line_utils = require('luxdash.rendering.line_utils')

function M.clear()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
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
  -- Clear all existing highlights first
  vim.api.nvim_buf_clear_namespace(0, -1, 0, -1)
  
  -- Create separate namespaces for different highlight types
  local logo_ns = vim.api.nvim_create_namespace('luxdash_logo')
  local menu_ns = vim.api.nvim_create_namespace('luxdash_menu')
  local other_ns = vim.api.nvim_create_namespace('luxdash_other')
  
  for _, hl in ipairs(all_highlights) do
    local line_idx = hl.line_num - 1
    if line_idx >= 0 and line_idx < #lines then
      local line_text = lines[line_idx + 1] or ''
      local line_length = vim.fn.strwidth(line_text)
      -- Don't constrain logo highlights to line length - they should span their intended width
      local start_col, end_col
      if hl.hl_group and hl.hl_group:match('^LuxDashLogo') then
        start_col = math.max(0, hl.start_col)
        end_col = math.max(start_col, hl.end_col)
      else
        start_col = math.max(0, math.min(hl.start_col, line_length))
        end_col = math.max(start_col, math.min(hl.end_col, line_length))
      end
      
      if start_col < end_col then
        local namespace
        if hl.hl_group and hl.hl_group:match('^LuxDashLogo') then
          namespace = logo_ns
        elseif hl.hl_group and hl.hl_group:match('^LuxDashMenu') then
          namespace = menu_ns
        else
          namespace = other_ns
        end
        
        vim.api.nvim_buf_add_highlight(0, namespace, hl.hl_group, line_idx, start_col, end_col)
      end
    end
  end
end

return M