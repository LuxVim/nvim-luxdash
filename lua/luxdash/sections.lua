local M = {}

function M.calculate_layout(winheight, winwidth)
  local top_height = math.floor(winheight * 0.8)
  local bottom_height = winheight - top_height
  
  local top_left_width = math.floor(winwidth * 0.5)
  local top_right_width = winwidth - top_left_width
  
  local bottom_section_width = math.floor(winwidth / 3)
  local bottom_left_width = bottom_section_width
  local bottom_center_width = bottom_section_width
  local bottom_right_width = winwidth - bottom_left_width - bottom_center_width
  
  return {
    top = {
      height = top_height,
      left = { width = top_left_width, height = top_height },
      right = { width = top_right_width, height = top_height }
    },
    bottom = {
      height = bottom_height,
      left = { width = bottom_left_width, height = bottom_height },
      center = { width = bottom_center_width, height = bottom_height },
      right = { width = bottom_right_width, height = bottom_height }
    }
  }
end

function M.load_section(section_name)
  local ok, section_module = pcall(require, 'luxdash.sections.' .. section_name)
  if ok and section_module and type(section_module.render) == 'function' then
    return section_module
  end
  return nil
end

function M.render_section(section_module, width, height, config)
  if not section_module or not section_module.render then
    return {}
  end
  
  local content = section_module.render(width, height, config or {})
  
  if type(content) ~= 'table' then
    return {}
  end
  
  local result = {}
  for i = 1, height do
    local line = content[i] or ''
    if type(line) == 'string' then
      local truncated = M.truncate_line(line, width)
      local padded = M.pad_line_to_width(truncated, width)
      table.insert(result, padded)
    elseif type(line) == 'table' then
      if #line >= 2 and type(line[1]) == 'string' and type(line[2]) == 'string' then
        -- Simple format: {highlight, text}
        local truncated = M.truncate_line(line[2], width)
        local padded = M.pad_line_to_width(truncated, width)
        table.insert(result, {line[1], padded})
      elseif #line > 0 and type(line[1]) == 'table' then
        -- Complex format: {{highlight, text}, {highlight, text}, ...} - pass through as-is
        table.insert(result, line)
      else
        -- Unknown table format - convert to string
        local line_text = tostring(line)
        local truncated = M.truncate_line(line_text, width)
        local padded = M.pad_line_to_width(truncated, width)
        table.insert(result, padded)
      end
    else
      table.insert(result, string.rep(' ', width))
    end
  end
  
  return result
end

function M.truncate_line(line, max_width)
  -- Ensure line is a string
  local line_text = tostring(line or '')
  if vim.fn.strwidth(line_text) <= max_width then
    return line_text
  end
  
  local truncated = ''
  local width = 0
  for i = 1, #line_text do
    local char = line_text:sub(i, i)
    local char_width = vim.fn.strwidth(char)
    if width + char_width > max_width then
      break
    end
    truncated = truncated .. char
    width = width + char_width
  end
  
  return truncated
end

function M.pad_line_to_width(line, target_width)
  local line_text = tostring(line or '')
  local current_width = vim.fn.strwidth(line_text)
  local padding_needed = math.max(0, target_width - current_width)
  return line_text .. string.rep(' ', padding_needed)
end

function M.pad_section_content(content, target_width, target_height)
  local padded = {}
  
  for i = 1, target_height do
    local line = content[i] or ''
    local line_text = type(line) == 'table' and line[2] or line
    local line_width = vim.fn.strwidth(line_text)
    local padding = math.max(0, target_width - line_width)
    
    if type(line) == 'table' then
      table.insert(padded, {line[1], line_text .. string.rep(' ', padding)})
    else
      table.insert(padded, line_text .. string.rep(' ', padding))
    end
  end
  
  return padded
end

function M.combine_sections_horizontally(sections)
  local combined = {}
  local max_lines = 0
  
  for _, section in ipairs(sections) do
    max_lines = math.max(max_lines, #section.content)
  end
  
  for i = 1, max_lines do
    local line_parts = {}
    local highlight_info = {}
    local col_offset = 0
    
    for _, section in ipairs(sections) do
      local line = section.content[i] or ''
      local line_text = type(line) == 'table' and line[2] or line
      local line_hl = type(line) == 'table' and line[1] or nil
      
      table.insert(line_parts, line_text)
      
      if line_hl then
        table.insert(highlight_info, {
          hl_group = line_hl,
          start_col = col_offset,
          end_col = col_offset + vim.fn.strwidth(line_text)
        })
      end
      
      col_offset = col_offset + vim.fn.strwidth(line_text)
    end
    
    local combined_line = table.concat(line_parts)
    if #highlight_info > 0 then
      table.insert(combined, {combined_line, highlight_info})
    else
      table.insert(combined, combined_line)
    end
  end
  
  return combined
end

return M