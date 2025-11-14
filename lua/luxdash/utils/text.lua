---@class TextUtils
---Consolidated text manipulation utilities for LuxDash
---Provides consistent text operations: truncation, padding, alignment, and width calculations
local M = {}

-- Constants for text utilities
local MAX_CACHE_SIZE = 500  -- Maximum number of cached width calculations
local PADDING_CACHE_SIZE = 200  -- Maximum size for pre-computed padding strings
local MIN_TRUNCATE_WIDTH = 3  -- Minimum width before displaying just dots

-- Cache for width calculations to avoid repeated vim.fn calls
local width_cache = {}
local cache_size = 0

---Clear the width cache
function M.clear_cache()
  width_cache = {}
  cache_size = 0
end

-- Pre-computed padding strings for common sizes (performance optimization)
local padding_cache = {}
for i = 1, PADDING_CACHE_SIZE do
  padding_cache[i] = string.rep(' ', i)
end

---Get padding string of specified size
---@param size number Number of spaces
---@return string padding String of spaces
function M.get_padding(size)
  if size <= 0 then
    return ''
  end
  if size <= PADDING_CACHE_SIZE then
    return padding_cache[size]
  end
  return string.rep(' ', size)
end

---Get display width of text (how many columns it occupies on screen)
---Handles multi-byte characters correctly
---@param text string|number Text to measure
---@return number width Display width in columns
function M.get_display_width(text)
  if type(text) ~= 'string' then
    text = tostring(text or '')
  end

  -- Check cache
  if width_cache[text] then
    return width_cache[text]
  end

  local width = vim.fn.strdisplaywidth(text)

  -- Cache the result (with size limit)
  if cache_size < MAX_CACHE_SIZE then
    width_cache[text] = width
    cache_size = cache_size + 1
  end

  return width
end

---Get byte width of text (actual string length)
---@param text string|number Text to measure
---@return number width Byte width
function M.get_byte_width(text)
  if type(text) ~= 'string' then
    text = tostring(text or '')
  end
  return vim.fn.strwidth(text)
end

---Truncate text to fit within maximum width
---@param text string Text to truncate
---@param max_width number Maximum width in display characters
---@param opts? {suffix: string, mode: string, preserve_basename: boolean} Truncation options
---  - suffix: String to append when truncated (default: '...')
---  - mode: Where to truncate: 'end' (default), 'middle', 'start'
---  - preserve_basename: For paths, try to keep filename visible (default: false)
---@return string truncated Truncated text
function M.truncate(text, max_width, opts)
  opts = opts or {}
  local suffix = opts.suffix or '...'
  local mode = opts.mode or 'end'
  local preserve_basename = opts.preserve_basename or false

  local text_str = tostring(text or '')
  local text_width = M.get_display_width(text_str)

  -- No truncation needed
  if text_width <= max_width then
    return text_str
  end

  -- Handle very small widths
  if max_width <= MIN_TRUNCATE_WIDTH then
    return string.rep('.', max_width)
  end

  -- If preserving basename (for file paths), try to show filename
  if preserve_basename and text_str:find('/') then
    local parts = vim.split(text_str, '/')
    local basename = parts[#parts] or text_str
    local basename_width = M.get_display_width(basename)

    -- If just the basename fits with suffix, use that
    if basename_width <= max_width - MIN_TRUNCATE_WIDTH then
      return '...' .. basename
    end

    -- Otherwise, truncate the basename itself
    local target_width = max_width - MIN_TRUNCATE_WIDTH
    local truncated_basename = M.truncate_chars(basename, target_width)
    return '...' .. truncated_basename
  end

  -- Standard truncation based on mode
  local suffix_width = M.get_display_width(suffix)
  local target_width = max_width - suffix_width

  if mode == 'end' then
    local truncated = M.truncate_chars(text_str, target_width)
    return truncated .. suffix
  elseif mode == 'start' then
    local truncated = M.truncate_chars_from_start(text_str, target_width)
    return suffix .. truncated
  elseif mode == 'middle' then
    local half_width = math.floor(target_width / 2)
    local left = M.truncate_chars(text_str, half_width)
    local right = M.truncate_chars_from_start(text_str, target_width - half_width)
    return left .. suffix .. right
  end

  return text_str
end

---Truncate text character by character to exact width
---Internal helper function
---@param text string Text to truncate
---@param target_width number Target width
---@return string truncated Truncated text
function M.truncate_chars(text, target_width)
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

  return result
end

---Truncate text from start character by character
---Internal helper function
---@param text string Text to truncate
---@param target_width number Target width
---@return string truncated Truncated text from end
function M.truncate_chars_from_start(text, target_width)
  -- Build from end to start
  local chars = {}
  local current_width = 0

  for i = #text, 1, -1 do
    local char = text:sub(i, i)
    local char_width = vim.fn.strdisplaywidth(char)

    if current_width + char_width <= target_width then
      table.insert(chars, 1, char)
      current_width = current_width + char_width
    else
      break
    end
  end

  return table.concat(chars)
end

---Pad text on the left
---@param text string|number Text to pad
---@param width number Target width
---@param char? string Character to use for padding (default: ' ')
---@return string padded Left-padded text
function M.pad_left(text, width, char)
  char = char or ' '
  local text_str = tostring(text or '')
  local text_width = M.get_display_width(text_str)

  if text_width >= width then
    return text_str
  end

  local padding_size = width - text_width
  local padding = char == ' ' and M.get_padding(padding_size) or string.rep(char, padding_size)

  return padding .. text_str
end

---Pad text on the right
---@param text string|number Text to pad
---@param width number Target width
---@param char? string Character to use for padding (default: ' ')
---@return string padded Right-padded text
function M.pad_right(text, width, char)
  char = char or ' '
  local text_str = tostring(text or '')
  local text_width = M.get_display_width(text_str)

  if text_width >= width then
    return text_str
  end

  local padding_size = width - text_width
  local padding = char == ' ' and M.get_padding(padding_size) or string.rep(char, padding_size)

  return text_str .. padding
end

---Pad text on both sides to center it
---@param text string|number Text to pad
---@param width number Target width
---@param char? string Character to use for padding (default: ' ')
---@return string padded Centered text
function M.pad_center(text, width, char)
  char = char or ' '
  local text_str = tostring(text or '')
  local text_width = M.get_display_width(text_str)

  if text_width >= width then
    return text_str
  end

  local total_padding = width - text_width
  local left_padding_size = math.floor(total_padding / 2)
  local right_padding_size = total_padding - left_padding_size

  local left_pad = char == ' ' and M.get_padding(left_padding_size) or string.rep(char, left_padding_size)
  local right_pad = char == ' ' and M.get_padding(right_padding_size) or string.rep(char, right_padding_size)

  return left_pad .. text_str .. right_pad
end

---Align text within a given width
---Combines truncation and padding for perfect alignment
---@param text string|number Text to align
---@param width number Target width
---@param alignment? string Alignment: 'left', 'center', 'right' (default: 'center')
---@param opts? {char: string, truncate_opts: table} Additional options
---@return string aligned Aligned text
function M.align(text, width, alignment, opts)
  alignment = alignment or 'center'
  opts = opts or {}
  local char = opts.char or ' '
  local truncate_opts = opts.truncate_opts or {}

  local text_str = tostring(text or '')
  local text_width = M.get_display_width(text_str)

  -- Truncate if needed
  if text_width > width then
    text_str = M.truncate(text_str, width, truncate_opts)
    text_width = M.get_display_width(text_str)
  end

  -- Pad based on alignment
  if alignment == 'left' then
    return M.pad_right(text_str, width, char)
  elseif alignment == 'right' then
    return M.pad_left(text_str, width, char)
  else -- center
    return M.pad_center(text_str, width, char)
  end
end

---Ensure text is exactly the specified width
---Truncates or pads as needed
---@param text string|number Text to adjust
---@param width number Target width
---@return string adjusted Text at exact width
function M.ensure_width(text, width)
  local text_str = tostring(text or '')
  local current_width = M.get_byte_width(text_str)

  if current_width < width then
    return text_str .. M.get_padding(width - current_width)
  elseif current_width > width then
    return text_str:sub(1, width)
  end

  return text_str
end

---Convert text to title case
---@param text string Text to convert
---@return string title Title-cased text
function M.title_case(text)
  return tostring(text):gsub('%w+', function(w)
    return w:sub(1, 1):upper() .. w:sub(2):lower()
  end)
end

return M
