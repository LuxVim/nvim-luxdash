---Line formatting utilities
---Combines line parts with highlights into final text and highlight specifications
local M = {}

---Combine multiple line parts into single line in complex format
---@param parts table Array of line parts (can be strings, {hl, text}, or {{hl, text}, ...})
---@return table combined_line Line in complex format {{hl, text}, {hl, text}, ...}
function M.combine_line_parts(parts)
  local result = {}

  for _, part in ipairs(parts) do
    if type(part) == 'table' then
      if #part >= 2 and type(part[1]) == 'string' and type(part[2]) == 'string' then
        -- Simple format: {highlight_group, text} - add as-is
        table.insert(result, part)
      elseif #part > 0 and type(part[1]) == 'table' then
        -- Complex format: {{hl, text}, {hl, text}, ...} - add all parts
        for _, nested_part in ipairs(part) do
          if type(nested_part) == 'table' and #nested_part >= 2 then
            table.insert(result, nested_part)
          end
        end
      end
    else
      -- Plain text - wrap in Normal highlight
      local text = tostring(part)
      if #text > 0 then
        table.insert(result, {'Normal', text})
      end
    end
  end

  return result
end

return M
