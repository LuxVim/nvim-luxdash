local M = {}

-- Standardized alignment function that can be used by all sections
function M.align_content(content, width, height, alignment_config)
  alignment_config = alignment_config or {}
  local horizontal_alignment = alignment_config.horizontal or 'center'
  local vertical_alignment = alignment_config.vertical or 'center'
  local title_alignment = alignment_config.title_horizontal or horizontal_alignment
  local content_alignment = alignment_config.content_horizontal or horizontal_alignment
  
  local content_height = #content
  local pad_top = 0
  
  -- Calculate vertical padding
  if vertical_alignment == 'top' then
    pad_top = 0
  elseif vertical_alignment == 'bottom' then
    pad_top = math.max(0, height - content_height)
  else -- center
    pad_top = math.max(0, math.floor((height - content_height) / 2))
  end
  
  local aligned = {}
  
  -- Add top padding
  for _ = 1, pad_top do
    table.insert(aligned, string.rep(' ', width))
  end
  
  -- Process content lines
  for i, line in ipairs(content) do
    local line_text, line_hl = M.extract_line_parts(line)
    local is_title = M.is_title_line(line, line_hl)
    local is_separator = M.is_separator_line(line, line_hl)
    local line_alignment = is_title and title_alignment or content_alignment
    
    if type(line_hl) == 'table' and type(line_hl[1]) == 'table' then
      -- Complex multi-highlight structure - convert to simple text for now
      local aligned_line = M.align_line_horizontally(line_text, width, line_alignment)
      table.insert(aligned, aligned_line)
    elseif is_separator then
      -- Separators should maintain their full width without alignment changes
      if line_hl then
        table.insert(aligned, {line_hl, line_text})
      else
        table.insert(aligned, line_text)
      end
    else
      local aligned_line = M.align_line_horizontally(line_text, width, line_alignment)
      
      if line_hl then
        table.insert(aligned, {line_hl, aligned_line})
      else
        table.insert(aligned, aligned_line)
      end
    end
  end
  
  -- Add bottom padding
  local remaining_lines = height - #aligned
  for _ = 1, remaining_lines do
    table.insert(aligned, string.rep(' ', width))
  end
  
  return aligned
end

-- Extract text and highlight information from a line
function M.extract_line_parts(line)
  if type(line) == 'table' then
    if #line >= 2 and type(line[1]) == 'string' and type(line[2]) == 'string' then
      -- Simple format: {highlight, text}
      return line[2], line[1]
    elseif #line > 0 and type(line[1]) == 'table' then
      -- Complex format: {{highlight, text}, {highlight, text}, ...}
      local combined_text = ''
      for _, part in ipairs(line) do
        if type(part) == 'table' and #part >= 2 then
          combined_text = combined_text .. tostring(part[2] or '')
        end
      end
      return combined_text, line -- return the whole structure for later processing
    end
  end
  return tostring(line or ''), nil
end

-- Align a single line horizontally within the given width
function M.align_line_horizontally(text, width, alignment)
  local line_width = vim.fn.strwidth(text)
  
  if alignment == 'left' then
    local pad_right = math.max(0, width - line_width)
    return text .. string.rep(' ', pad_right)
  elseif alignment == 'right' then
    local pad_left = math.max(0, width - line_width)
    return string.rep(' ', pad_left) .. text
  else -- center
    local pad_left = math.max(0, math.floor((width - line_width) / 2))
    local pad_right = math.max(0, width - pad_left - line_width)
    return string.rep(' ', pad_left) .. text .. string.rep(' ', pad_right)
  end
end

-- Convenience function for simple padding without alignment
function M.pad_content(content, width, height)
  return M.align_content(content, width, height, { horizontal = 'left', vertical = 'top' })
end

-- Convenience function for centering content both horizontally and vertically
function M.center_content(content, width, height)
  return M.align_content(content, width, height, { horizontal = 'center', vertical = 'center' })
end

-- Helper function to detect if a line is a title based on highlight group
function M.is_title_line(line, line_hl)
  if type(line_hl) == 'string' then
    return line_hl == 'LuxDashSectionTitle' or line_hl == 'LuxDashMenuTitle'
  end
  return false
end

-- Helper function to detect if a line is a separator that should maintain full width
function M.is_separator_line(line, line_hl)
  if type(line_hl) == 'string' then
    return line_hl == 'LuxDashSectionSeparator'
  end
  return false
end

return M