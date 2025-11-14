---Dashboard renderer - draws dashboard content to buffer using dependency injection
local M = {}

local line_utils = require('luxdash.rendering.line_utils')
local highlight_pool = require('luxdash.core.highlight_pool')

---Clear buffer content and highlights
---@param bufnr number Buffer number
function M.clear(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
  highlight_pool.clear_all_namespaces()
end

---Draw dashboard using context
---@param context RenderContext Rendering context with dashboard content
function M.draw(context)
  -- Validate context
  local valid, err = context:validate()
  if not valid then
    vim.notify('LuxDash: Invalid context - ' .. err, vim.log.levels.ERROR)
    return
  end

  local bufnr = context.bufnr or vim.api.nvim_get_current_buf()
  local winid = context.winid or vim.api.nvim_get_current_win()

  if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_win_is_valid(winid) then
    return
  end

  vim.bo[bufnr].modifiable = true
  M.clear(bufnr)
  M.print(context, bufnr, winid)

  if vim.api.nvim_win_is_valid(winid) then
    pcall(vim.api.nvim_win_set_cursor, winid, {1, 0})
  end

  vim.bo[bufnr].modifiable = false
end

---Print dashboard content to buffer
---@param context RenderContext Rendering context
---@param bufnr number Buffer number
---@param winid number Window ID
function M.print(context, bufnr, winid)
  if not vim.api.nvim_win_is_valid(winid) or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local config = context.config
  local width = context.dimensions.width
  local height = context.dimensions.height

  -- Get dashboard lines from context
  local dashboard = context.dashboard:get_lines()

  -- Apply buffer padding
  local padding = config.padding or { left = 2, right = 2, top = 1, bottom = 1 }
  local content_width = width - padding.left - padding.right
  local content_height = height - padding.top - padding.bottom
  
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
    
    -- Pass window width to line_utils for correct logo rendering
    local padded_text, line_highlights = line_utils.process_line_for_rendering(line, line_pad_left, width)
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
  
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_set_lines(bufnr, 0, 0, false, lines)
  end

  -- Apply highlights
  line_utils.apply_highlights(bufnr, all_highlights, lines)
end

return M