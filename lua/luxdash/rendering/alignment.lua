local M = {}
local width_utils = require('luxdash.utils.width')

-- Align text horizontally within given width with optional padding
function M.align_text(text, width, alignment, padding)
  local text_str = tostring(text or '')
  
  -- Apply padding if provided
  local left_pad = padding and padding.left or 0
  local right_pad = padding and padding.right or 0
  local available_width = math.max(0, width - left_pad - right_pad)
  
  local result
  if alignment == 'left' then
    result = width_utils.left_align_text(text_str, available_width)
  elseif alignment == 'right' then
    result = width_utils.right_align_text(text_str, available_width)
  else -- center
    result = width_utils.center_text(text_str, available_width)
  end
  
  -- Add section padding
  local left_padding = width_utils.get_padding(left_pad)
  local right_padding = width_utils.get_padding(right_pad)
  return left_padding .. result .. right_padding
end

-- Align text with highlight group, ensuring highlight covers the full aligned width
function M.align_text_with_highlight(text, width, alignment, padding, highlight_group)
  local aligned_text = M.align_text(text, width, alignment, padding)
  
  -- For logo highlights, we want the highlight to cover the entire aligned width
  -- but keep the text properly centered - we'll handle this in the highlighting phase
  return aligned_text
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
  local empty_line = width_utils.get_padding(width)
  for _ = 1, pad_top do
    table.insert(aligned, empty_line)
  end
  
  -- Add content
  for _, line in ipairs(content) do
    table.insert(aligned, line)
  end
  
  -- Add bottom padding (only for sub-sections or when content doesn't exceed height)
  if section_type == 'sub' or #aligned <= height then
    local remaining_lines = height - #aligned
    local empty_line = width_utils.get_padding(width)
    for _ = 1, remaining_lines do
      table.insert(aligned, empty_line)
    end
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