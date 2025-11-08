--- Text alignment utilities for nvim-luxdash
--- Handles horizontal and vertical text alignment with padding support
local M = {}
local width_utils = require('luxdash.utils.width')

--- Align text horizontally within given width with optional padding
--- @param text string|any Text to align (will be converted to string)
--- @param width number Total width available for alignment
--- @param alignment string Alignment mode: 'left', 'center', 'right'
--- @param padding table|nil Optional padding {left = number, right = number}
--- @return string aligned_text Aligned text with padding applied
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

--- Align text with highlight group
--- Ensures highlight covers the full aligned width for proper visual appearance
--- @param text string Text to align
--- @param width number Total width available
--- @param alignment string Alignment mode: 'left', 'center', 'right'
--- @param padding table|nil Optional padding
--- @param highlight_group string Highlight group name (for future use)
--- @return string aligned_text Aligned text ready for highlighting
function M.align_text_with_highlight(text, width, alignment, padding, highlight_group)
  local aligned_text = M.align_text(text, width, alignment, padding)
  
  -- For logo highlights, we want the highlight to cover the entire aligned width
  -- but keep the text properly centered - we'll handle this in the highlighting phase
  return aligned_text
end

--- Apply vertical alignment to content with padding
--- Adds empty lines above and/or below content to achieve desired vertical position
--- @param content table Array of lines (strings or formatted line tables)
--- @param width number Width of each line for padding
--- @param height number Total height available for content
--- @param alignment string Vertical alignment: 'top', 'center', 'bottom'
--- @param section_type string Section type: 'main' or 'sub' (sub-sections always use top alignment)
--- @return table aligned_content Content with vertical padding applied
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

--- Extract text and highlight information from a line
--- Handles both simple format {highlight, text} and complex format {{h, t}, {h, t}, ...}
--- @param line string|table Line in various formats
--- @return string text Combined text content
--- @return string|table|nil highlight Highlight group or complex highlight structure
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