local M = {}
local constants = require('luxdash.constants')

-- Pre-computed padding strings for common sizes
local padding_cache = {}
for i = 1, constants.CACHE.MAX_PADDING_SIZE do
  padding_cache[i] = string.rep(' ', i)
end

function M.get_padding(size)
  if size <= 0 then return '' end
  if size <= constants.CACHE.MAX_PADDING_SIZE then
    return padding_cache[size]
  end
  return string.rep(' ', size)
end

function M.get_display_width(text)
  if type(text) ~= 'string' then
    text = tostring(text or '')
  end
  return vim.fn.strdisplaywidth(text)
end

function M.get_byte_width(text)
  if type(text) ~= 'string' then
    text = tostring(text or '')
  end
  return vim.fn.strwidth(text)
end

function M.center_text(text, target_width)
  local text_width = M.get_display_width(text)
  if text_width >= target_width then
    return M.trim_text(text, target_width)
  end
  
  local total_padding = target_width - text_width
  local left_padding = math.floor(total_padding / 2)
  local right_padding = total_padding - left_padding
  
  return M.get_padding(left_padding) .. text .. M.get_padding(right_padding)
end

function M.left_align_text(text, target_width)
  local text_width = M.get_display_width(text)
  if text_width >= target_width then
    return M.trim_text(text, target_width)
  end
  
  local right_padding = target_width - text_width
  return text .. M.get_padding(right_padding)
end

function M.right_align_text(text, target_width)
  local text_width = M.get_display_width(text)
  if text_width >= target_width then
    return M.trim_text(text, target_width)
  end
  
  local left_padding = target_width - text_width
  return M.get_padding(left_padding) .. text
end

function M.trim_text(text, target_width)
  local text_width = M.get_display_width(text)
  if text_width <= target_width then
    return text .. M.get_padding(target_width - text_width)
  end
  
  -- Simple character-by-character trimming for now
  local result = ''
  local current_width = 0
  
  for i = 1, #text do
    local char = text:sub(i, i)
    local char_width = vim.fn.strdisplaywidth(char)
    
    if current_width + char_width <= target_width then
      result = result .. char
      current_width = current_width + char_width
    else
      break
    end
  end
  
  -- Pad to exact width
  local padding_needed = target_width - current_width
  if padding_needed > 0 then
    result = result .. M.get_padding(padding_needed)
  end
  
  return result
end

function M.ensure_exact_width(text, target_width)
  local current_width = M.get_byte_width(text)
  if current_width < target_width then
    return text .. M.get_padding(target_width - current_width)
  elseif current_width > target_width then
    return text:sub(1, target_width)
  end
  return text
end

-- Get the actual highlight width needed for a text (considers display vs byte width)
function M.get_highlight_width(text, window_width)
  local display_width = vim.fn.strdisplaywidth(text)
  local byte_width = vim.fn.strwidth(text)
  
  -- For logo highlighting, we want to highlight the full window width
  -- but the text might have different display vs byte characteristics
  return window_width
end

-- Optimized full-width processing for logo lines
-- Special handling for braille and other display-width characters
function M.create_full_width_text(content, window_width)
  local content_text = tostring(content or '')
  local content_display_width = vim.fn.strdisplaywidth(content_text)
  
  if content_display_width > window_width then
    -- Content is wider than window - center by trimming
    return M.trim_text_for_logo(content_text, window_width)
  else
    -- Content fits within window - center with padding
    return M.center_text_for_logo(content_text, window_width)
  end
end

-- Logo-specific text centering that ensures exact width for highlighting
function M.center_text_for_logo(text, target_width)
  local content_display_width = vim.fn.strdisplaywidth(text)
  local total_padding_needed = target_width - content_display_width
  local left_pad_size = math.max(0, math.floor(total_padding_needed / 2))
  local right_pad_size = math.max(0, total_padding_needed - left_pad_size)
  
  local left_spaces = M.get_padding(left_pad_size)
  local right_spaces = M.get_padding(right_pad_size)
  local full_width_text = left_spaces .. text .. right_spaces
  
  -- Ensure exact target width using byte width for final adjustment
  local current_byte_width = vim.fn.strwidth(full_width_text)
  if current_byte_width < target_width then
    full_width_text = full_width_text .. M.get_padding(target_width - current_byte_width)
  elseif current_byte_width > target_width then
    -- Trim carefully to preserve display characters
    full_width_text = full_width_text:sub(1, target_width)
  end
  
  return full_width_text
end

-- Logo-specific text trimming that handles braille characters correctly
function M.trim_text_for_logo(text, target_width)
  local content_display_width = vim.fn.strdisplaywidth(text)
  local excess_chars = content_display_width - target_width
  local trim_left = math.floor(excess_chars / 2)
  
  local trimmed_text = text
  if trim_left > 0 then
    -- Character-by-character trimming respecting display width
    local byte_pos = 1
    local display_count = 0
    local i = 1
    
    while i <= #text and display_count < trim_left do
      local char = text:sub(i, i)
      local char_byte = char:byte()
      
      -- Skip UTF-8 continuation bytes
      if char_byte < 128 or char_byte > 191 then
        display_count = display_count + vim.fn.strdisplaywidth(char)
        if display_count >= trim_left then
          byte_pos = i
          break
        end
      end
      i = i + 1
    end
    
    trimmed_text = text:sub(byte_pos)
  end
  
  -- Now trim to exact target width while preserving display characters
  local final_content = ""
  local display_width = 0
  local i = 1
  
  while i <= #trimmed_text and display_width < target_width do
    local char = trimmed_text:sub(i, i)
    local char_display_width = vim.fn.strdisplaywidth(char)
    
    if display_width + char_display_width <= target_width then
      final_content = final_content .. char
      display_width = display_width + char_display_width
    else
      break
    end
    i = i + 1
  end
  
  -- Pad to exact target width
  local current_display_width = vim.fn.strdisplaywidth(final_content)
  if current_display_width < target_width then
    final_content = final_content .. M.get_padding(target_width - current_display_width)
  end
  
  return final_content
end

return M