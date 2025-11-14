---Line processing orchestration
---Main entry point for processing dashboard lines for rendering
local M = {}

local text_utils = require('luxdash.utils.text')
local logo_renderer = require('luxdash.rendering.logo_renderer')
local highlight_applicator = require('luxdash.rendering.highlight_applicator')

---Process a line for rendering
---Handles logo lines, complex format, simple format, and plain text
---@param line any Line content
---@param pad_left number Left padding amount (0 for logo lines)
---@param window_width number Window width for logo centering
---@return string padded_text Final padded text
---@return table highlights Array of highlight specifications
function M.process_line_for_rendering(line, pad_left, window_width)
  window_width = window_width or vim.api.nvim_win_get_width(0)

  -- Check if this is a logo line with the special 3-element format
  -- Format: {{hl_group, ''}, {hl_group, content}, {hl_group, ''}}
  if type(line) == 'table' and #line == 3 and
     type(line[1]) == 'table' and type(line[2]) == 'table' and type(line[3]) == 'table' and
     line[1][1] and line[1][1]:match('^LuxDashLogo') then
    -- This is the special full-width logo format from colors.apply_logo_color
    return logo_renderer.process_logo_line(line, window_width)
  end

  -- Fallback: Check if ANY part of a complex format has logo highlight
  -- This handles cases where logo format might vary slightly
  if type(line) == 'table' and #line > 0 and type(line[1]) == 'table' then
    for _, part in ipairs(line) do
      if type(part) == 'table' and part[1] and type(part[1]) == 'string' and
         part[1]:match('^LuxDashLogo') and pad_left == 0 then
        -- This is a logo line, use full-width rendering
        -- Convert to expected format if needed
        local content = part[2] or ''
        local hl_group = part[1]
        local normalized_line = {{hl_group, ''}, {hl_group, content}, {hl_group, ''}}
        return logo_renderer.process_logo_line(normalized_line, window_width)
      end
    end
  end

  -- Process different line formats
  if type(line) == 'table' then
    if #line > 0 and type(line[1]) == 'table' then
      -- Complex format: {{highlight, text}, {highlight, text}, ...}
      return M.process_complex_format(line, pad_left)
    elseif line[2] then
      -- Simple format: {highlight, text}
      return M.process_simple_format(line, pad_left)
    end
  end

  -- Plain text
  return M.process_plain_text(line, pad_left), {}
end

---Process complex format line
---@param line table Complex format {{hl, text}, ...}
---@param pad_left number Left padding
---@return string padded_text Final text
---@return table highlights Highlight specifications
function M.process_complex_format(line, pad_left)
  -- Build text and highlights from complex format
  local combined_text = ''
  local highlights = {}
  local current_byte_pos = pad_left  -- Track byte position for highlights

  for _, part in ipairs(line) do
    if type(part) == 'table' and #part >= 2 then
      local hl_group = part[1]
      local text = tostring(part[2] or '')
      local text_byte_len = #text  -- Use byte length, not display width

      -- Add text
      combined_text = combined_text .. text

      -- Add highlight info using byte positions
      if hl_group and text_byte_len > 0 then
        table.insert(highlights, {
          start_col = current_byte_pos,
          end_col = current_byte_pos + text_byte_len,
          hl_group = hl_group
        })
      end

      current_byte_pos = current_byte_pos + text_byte_len
    end
  end

  -- Add left padding
  local padding = text_utils.get_padding(pad_left)
  local padded_text = padding .. combined_text

  return padded_text, highlights
end

---Process simple format line
---@param line table Simple format {hl, text}
---@param pad_left number Left padding
---@return string padded_text Final text
---@return table highlights Highlight specifications
function M.process_simple_format(line, pad_left)
  local hl_group = line[1]
  local text = tostring(line[2] or '')

  -- Add left padding
  local padding = text_utils.get_padding(pad_left)
  local padded_text = padding .. text

  -- Create highlight info using byte positions
  local highlights = {}
  if hl_group and #text > 0 then
    table.insert(highlights, {
      start_col = pad_left,
      end_col = pad_left + #text,  -- Use byte length
      hl_group = hl_group
    })
  end

  return padded_text, highlights
end

---Process plain text line
---@param line any Plain text content
---@param pad_left number Left padding
---@return string padded_text Final text
function M.process_plain_text(line, pad_left)
  local text = tostring(line or '')
  local padding = text_utils.get_padding(pad_left)
  return padding .. text
end

---Apply highlights to buffer (delegates to highlight_applicator)
---@param bufnr number Buffer number
---@param highlights table Array of highlight specifications
---@param lines table Array of line texts
function M.apply_highlights(bufnr, highlights, lines)
  highlight_applicator.apply_highlights(bufnr, highlights, lines)
end

---Ensure logo line coverage (delegates to logo_renderer)
---@param line string Line text
---@param highlights table Highlight specifications
---@param window_width number Target window width
---@return string adjusted_line Adjusted line
---@return table adjusted_highlights Adjusted highlights
function M.ensure_logo_line_coverage(line, highlights, window_width)
  return logo_renderer.ensure_logo_line_coverage(line, highlights, window_width)
end

return M
