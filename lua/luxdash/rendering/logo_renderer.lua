---Logo-specific rendering utilities
---Handles centering, width coverage, and special formatting for logos
local M = {}

local text_utils = require('luxdash.utils.text')

---Process a logo line with full-width highlighting
---@param line table Logo line in format {{hl_group, ''}, {hl_group, content}, {hl_group, ''}}
---@param window_width number Window width for centering
---@return string padded_text Full-width text
---@return table highlights Highlight specifications
function M.process_logo_line(line, window_width)
  local highlight_group = line[1][1]
  local content_text = line[2][2] or ''
  local winwidth = window_width or vim.api.nvim_win_get_width(0)

  local content_display_width = vim.fn.strdisplaywidth(content_text)
  local full_width_text

  if content_display_width > winwidth then
    full_width_text = M.trim_content_to_width(content_text, winwidth)
  else
    full_width_text = M.center_content_in_width(content_text, winwidth)
  end

  return full_width_text, {{
    start_col = 0,
    end_col = #full_width_text,  -- Use byte length for highlight
    hl_group = highlight_group
  }}
end

---Center content within specified width with padding
---@param content_text string Content to center
---@param width number Target width
---@return string centered_text Content centered with padding to exact width
function M.center_content_in_width(content_text, width)
  local content_display_width = vim.fn.strdisplaywidth(content_text)
  local total_padding_needed = width - content_display_width
  local left_padding_size = math.max(0, math.floor(total_padding_needed / 2))
  local right_padding_size = math.max(0, total_padding_needed - left_padding_size)

  local left_spaces = string.rep(' ', left_padding_size)
  local right_spaces = string.rep(' ', right_padding_size)
  local full_width_text = left_spaces .. content_text .. right_spaces

  -- Verify and adjust if needed (handles edge cases with multi-byte chars)
  local current_width = vim.fn.strwidth(full_width_text)
  if current_width < width then
    full_width_text = full_width_text .. string.rep(' ', width - current_width)
  elseif current_width > width then
    -- Trim from end if too long
    while vim.fn.strwidth(full_width_text) > width and #full_width_text > 0 do
      full_width_text = full_width_text:sub(1, -2)
    end
  end

  return full_width_text
end

---Trim content to fit within specified width
---@param content_text string Content to trim
---@param width number Maximum width
---@return string trimmed_content Content trimmed to fit exact width
function M.trim_content_to_width(content_text, width)
  local content_display_width = vim.fn.strdisplaywidth(content_text)
  if content_display_width <= width then
    return content_text
  end

  -- Trim from both sides to center the visible portion
  local excess_chars = content_display_width - width
  local trim_left = math.floor(excess_chars / 2)

  local trimmed_content = content_text
  if trim_left > 0 then
    local byte_pos = 1
    local display_count = 0
    for i = 1, #content_text do
      local char = content_text:sub(byte_pos, byte_pos)
      if char:byte() < 128 or char:byte() > 191 then
        display_count = display_count + vim.fn.strdisplaywidth(char)
        if display_count >= trim_left then break end
      end
      byte_pos = byte_pos + 1
    end
    trimmed_content = content_text:sub(byte_pos)
  end

  -- Now trim from the right to hit exact width
  local final_content = ""
  local display_width = 0
  for i = 1, #trimmed_content do
    local char = trimmed_content:sub(i, i)
    local char_width = vim.fn.strdisplaywidth(char)
    if display_width + char_width <= width then
      final_content = final_content .. char
      display_width = display_width + char_width
    else
      break
    end
  end

  -- Pad to exact width if needed
  local current_width = vim.fn.strdisplaywidth(final_content)
  if current_width < width then
    final_content = final_content .. string.rep(' ', width - current_width)
  end

  return final_content
end

---Ensure logo line coverage matches window width
---Used to guarantee logo highlights extend full width
---@param line string Line text
---@param highlights table Highlight specifications
---@param window_width number Target window width
---@return string adjusted_line Line adjusted to window width
---@return table adjusted_highlights Highlights adjusted for new width
function M.ensure_logo_line_coverage(line, highlights, window_width)
  local line_width = vim.fn.strdisplaywidth(line)

  if line_width < window_width then
    -- Pad to full width
    local padding = string.rep(' ', window_width - line_width)
    line = line .. padding

    -- Extend logo highlights to cover padding
    for _, hl in ipairs(highlights) do
      if hl.hl_group and hl.hl_group:match('^LuxDashLogo') then
        hl.end_col = window_width
      end
    end
  elseif line_width > window_width then
    -- Trim to fit (shouldn't happen normally, but handle it)
    line = M.trim_content_to_width(line, window_width)

    -- Adjust highlight end positions
    for _, hl in ipairs(highlights) do
      if hl.end_col > window_width then
        hl.end_col = window_width
      end
    end
  end

  return line, highlights
end

---Check if a line is a logo line
---@param line any Line content
---@return boolean is_logo True if line contains logo highlight
function M.is_logo_line(line)
  if type(line) ~= 'table' then
    return false
  end

  -- Check complex format
  if #line > 0 and type(line[1]) == 'table' then
    for _, part in ipairs(line) do
      if type(part) == 'table' and #part >= 2 and
         type(part[1]) == 'string' and part[1]:match('^LuxDashLogo') then
        return true
      end
    end
  -- Check simple format
  elseif line[1] and type(line[1]) == 'string' and line[1]:match('^LuxDashLogo') then
    return true
  end

  return false
end

return M
