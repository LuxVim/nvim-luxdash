local M = {}

-- Align text horizontally within given width with optional padding
function M.align_text(text, width, alignment, padding)
  -- Ensure text is a string
  local text_str = tostring(text or '')
  local text_width = vim.fn.strwidth(text_str)
  
  -- Apply padding if provided
  local left_pad = padding and padding.left or 0
  local right_pad = padding and padding.right or 0
  local available_width = math.max(0, width - left_pad - right_pad)
  
  local result
  if alignment == 'left' then
    local pad_right = math.max(0, available_width - text_width)
    result = text_str .. string.rep(' ', pad_right)
  elseif alignment == 'right' then
    local pad_left = math.max(0, available_width - text_width)
    result = string.rep(' ', pad_left) .. text_str
  else -- center
    local pad_left = math.max(0, math.floor((available_width - text_width) / 2))
    local pad_right = math.max(0, available_width - pad_left - text_width)
    result = string.rep(' ', pad_left) .. text_str .. string.rep(' ', pad_right)
  end
  
  -- Add section padding
  return string.rep(' ', left_pad) .. result .. string.rep(' ', right_pad)
end

-- Apply vertical alignment to content
function M.apply_vertical_alignment(content, width, height, alignment, section_type)
  local content_height = #content
  local pad_top = 0
  
  -- For sub-sections (bottom area), always use top alignment to ensure consistent title positioning
  if section_type == 'sub' then
    pad_top = 0
  else
    -- Calculate vertical padding for main sections
    if alignment == 'top' then
      pad_top = 0
    elseif alignment == 'bottom' then
      pad_top = math.max(0, height - content_height)
    else -- center
      pad_top = math.max(0, math.floor((height - content_height) / 2))
    end
  end
  
  local aligned = {}
  
  -- Add top padding
  for _ = 1, pad_top do
    table.insert(aligned, string.rep(' ', width))
  end
  
  -- Add content
  for _, line in ipairs(content) do
    table.insert(aligned, line)
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
      return combined_text, line
    end
  end
  return tostring(line or ''), nil
end

return M