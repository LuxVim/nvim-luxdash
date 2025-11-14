---Width normalization utilities
---Ensures lines are exactly the target width by padding or truncating
local M = {}

---Ensure a line is exactly the target width
---Handles complex format {{hl, text}, ...}, simple format {hl, text}, and plain text
---@param line any Line content (table or string)
---@param target_width number Target width to enforce
---@return any normalized_line Line normalized to exact width
function M.ensure_exact_width(line, target_width)
  -- For complex format lines, calculate width without double-processing
  if type(line) == 'table' and #line > 0 and type(line[1]) == 'table' then
    -- Complex format: {{highlight, text}, {highlight, text}, ...}
    -- Calculate text width directly without using combine_line_parts to avoid double processing
    local text_width = 0
    for _, part in ipairs(line) do
      if type(part) == 'table' and #part >= 2 then
        local part_text = tostring(part[2] or '')
        text_width = text_width + vim.fn.strwidth(part_text)
      end
    end

    if text_width < target_width then
      -- Add padding by appending spaces to the combined text
      local padding = string.rep(' ', target_width - text_width)
      -- Return the original complex format with padding appended
      local padded_line = {}
      for _, part in ipairs(line) do
        table.insert(padded_line, part)
      end
      if target_width > text_width then
        table.insert(padded_line, {'Normal', padding})
      end
      return padded_line
    elseif text_width > target_width then
      -- For complex format lines that exceed width, truncate more intelligently
      return M.truncate_complex_format(line, target_width)
    end
    return line
  elseif type(line) == 'table' and line[2] then
    -- Simple format: {highlight, text}
    local text = tostring(line[2])
    local text_width = vim.fn.strwidth(text)
    if text_width < target_width then
      return {line[1], text .. string.rep(' ', target_width - text_width)}
    elseif text_width > target_width then
      return {line[1], vim.fn.strpart(text, 0, target_width)}
    end
    return line
  else
    -- Plain text
    local text = tostring(line)
    local text_width = vim.fn.strwidth(text)
    if text_width < target_width then
      return text .. string.rep(' ', target_width - text_width)
    elseif text_width > target_width then
      return vim.fn.strpart(text, 0, target_width)
    end
    return text
  end
end

---Truncate a complex format line intelligently
---Preserves key parts at the end (e.g., [1], [2] for recent files)
---@param line table Complex format line {{hl, text}, ...}
---@param target_width number Target width
---@return table truncated_line Truncated line
function M.truncate_complex_format(line, target_width)
  local truncated_line = {}
  local accumulated_width = 0

  -- Special handling for recent files format: preserve key part at the end
  local has_key_part = false
  local key_part = nil
  local key_width = 0

  -- Check if last part looks like a key [1], [2], etc.
  if #line > 0 and type(line[#line]) == 'table' and #line[#line] >= 2 then
    local last_text = tostring(line[#line][2] or '')
    if string.match(last_text, '^%[%d+%]$') then
      has_key_part = true
      key_part = line[#line]
      key_width = vim.fn.strwidth(last_text)
    end
  end

  local available_width = target_width
  if has_key_part then
    available_width = target_width - key_width
  end

  -- Add parts until we run out of space (excluding key part if it exists)
  local parts_to_process = has_key_part and (#line - 1) or #line
  for i = 1, parts_to_process do
    local part = line[i]
    if type(part) == 'table' and #part >= 2 then
      local part_text = tostring(part[2] or '')
      local part_width = vim.fn.strwidth(part_text)

      if accumulated_width + part_width <= available_width then
        -- Part fits completely
        table.insert(truncated_line, part)
        accumulated_width = accumulated_width + part_width
      elseif accumulated_width < available_width then
        -- Part needs to be truncated
        local chars_to_take = available_width - accumulated_width
        if chars_to_take > 0 then
          local truncated_text = vim.fn.strpart(part_text, 0, chars_to_take)
          table.insert(truncated_line, {part[1], truncated_text})
          accumulated_width = available_width
        end
        break
      else
        break
      end
    end
  end

  -- Add key part if it exists
  if has_key_part then
    table.insert(truncated_line, key_part)
  end

  return truncated_line
end

return M
