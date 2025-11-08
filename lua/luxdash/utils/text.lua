--- Shared text utilities for nvim-luxdash
--- Provides common text manipulation functions to reduce duplication across sections
local M = {}

local constants = require('luxdash.constants')

--- Truncate text to fit within maximum width
--- Adds ellipsis if text is too long
--- @param text string Text to truncate
--- @param max_width number Maximum width in display characters
--- @return string truncated_text Truncated text with ellipsis if needed
function M.truncate_with_ellipsis(text, max_width)
  if vim.fn.strwidth(text) <= max_width then
    return text
  end

  if max_width <= constants.TEXT.MIN_ELLIPSIS_WIDTH then
    return text:sub(1, max_width)
  end

  -- Truncate and add ellipsis
  return text:sub(1, max_width - #constants.TEXT.ELLIPSIS) .. constants.TEXT.ELLIPSIS
end

--- Smart truncate that prefers showing basename over full path
--- Useful for file paths where the filename is more important than the full path
--- @param filepath string File path to truncate
--- @param max_width number Maximum width in display characters
--- @return string truncated_path Truncated path prioritizing basename
function M.truncate_path_smart(filepath, max_width)
  if vim.fn.strwidth(filepath) <= max_width then
    return filepath
  end

  if max_width <= constants.TEXT.MIN_ELLIPSIS_WIDTH then
    return string.rep('.', max_width)
  end

  -- Try to show basename with ellipsis prefix
  local parts = vim.split(filepath, '/')
  local basename = parts[#parts] or filepath
  local basename_width = vim.fn.strwidth(basename)

  -- If just the basename fits with ellipsis prefix, use that
  if basename_width <= max_width - #constants.TEXT.ELLIPSIS then
    return constants.TEXT.ELLIPSIS .. basename
  end

  -- Otherwise, truncate the basename itself
  local target_basename_width = max_width - #constants.TEXT.ELLIPSIS
  local truncated_basename = basename

  -- Simple truncation from the end to preserve start of filename
  while vim.fn.strwidth(truncated_basename) > target_basename_width and #truncated_basename > 0 do
    truncated_basename = truncated_basename:sub(1, -2)
  end

  return constants.TEXT.ELLIPSIS .. truncated_basename
end

--- Pad text to exact width with spaces
--- @param text string Text to pad
--- @param target_width number Target width
--- @param align string Alignment: 'left', 'center', 'right' (default 'left')
--- @return string padded_text Text padded to exact width
function M.pad_to_width(text, target_width, align)
  align = align or 'left'
  local text_width = vim.fn.strdisplaywidth(text)

  if text_width >= target_width then
    return M.truncate_with_ellipsis(text, target_width)
  end

  local total_padding = target_width - text_width

  if align == 'center' then
    local left_pad = math.floor(total_padding / 2)
    local right_pad = total_padding - left_pad
    return string.rep(' ', left_pad) .. text .. string.rep(' ', right_pad)
  elseif align == 'right' then
    return string.rep(' ', total_padding) .. text
  else -- left
    return text .. string.rep(' ', total_padding)
  end
end

--- Strip ANSI color codes from text
--- Useful for processing git output or other terminal text
--- @param text string Text with potential ANSI codes
--- @return string clean_text Text without ANSI codes
function M.strip_ansi_codes(text)
  -- Pattern matches ANSI escape sequences
  return text:gsub('\27%[[0-9;]*m', '')
end

--- Word wrap text to fit within width
--- Breaks on word boundaries when possible
--- @param text string Text to wrap
--- @param width number Maximum line width
--- @return table lines Array of wrapped lines
function M.word_wrap(text, width)
  local lines = {}
  local current_line = ''
  local current_width = 0

  for word in text:gmatch('%S+') do
    local word_width = vim.fn.strdisplaywidth(word)
    local space_width = current_width > 0 and 1 or 0

    if current_width + space_width + word_width <= width then
      if current_width > 0 then
        current_line = current_line .. ' '
        current_width = current_width + 1
      end
      current_line = current_line .. word
      current_width = current_width + word_width
    else
      if current_line ~= '' then
        table.insert(lines, current_line)
      end
      current_line = word
      current_width = word_width
    end
  end

  if current_line ~= '' then
    table.insert(lines, current_line)
  end

  return lines
end

--- Escape special characters for display
--- Prevents issues with special characters in filenames or text
--- @param text string Text to escape
--- @return string escaped_text Escaped text safe for display
function M.escape_special_chars(text)
  return text:gsub('[%c]', ''):gsub('[\t]', ' ')
end

--- Count visual display width of text
--- Handles multi-byte characters correctly
--- @param text string Text to measure
--- @return number width Display width in columns
function M.display_width(text)
  return vim.fn.strdisplaywidth(text)
end

--- Trim whitespace from both ends of string
--- @param text string Text to trim
--- @return string trimmed_text Text without leading/trailing whitespace
function M.trim(text)
  return vim.trim(text)
end

return M
